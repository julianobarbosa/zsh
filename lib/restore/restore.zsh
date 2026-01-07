#!/usr/bin/env zsh
# Story 2.4: Configuration Restore from Backup
# Restore configuration from a backup

# Track pre-restore backup for rollback
typeset -g _ZSH_TOOL_PRE_RESTORE_BACKUP=""

# Stub for partial restore (AC11 - future enhancement)
# Usage: --files ".zshrc,.zshrc.local"
_zsh_tool_restore_partial_stub() {
  local files_list="$1"
  _zsh_tool_log WARN "Partial restore with --files is not yet implemented"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Partial Restore (Future Enhancement)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "The --files flag is planned but not yet implemented."
  echo "Requested files: $files_list"
  echo ""
  echo "For now, use full restore: zsh-tool-restore apply <backup-id>"
  echo ""
  return 1
}

# Parse backup manifest
_zsh_tool_parse_manifest() {
  local backup_path=$1
  local manifest="${backup_path}/manifest.json"

  if [[ ! -f "$manifest" ]]; then
    _zsh_tool_log WARN "No manifest found in backup"
    return 1
  fi

  cat "$manifest"
}

# Display backup contents
_zsh_tool_display_backup_contents() {
  local backup_path=$1

  echo ""
  echo "This will restore:"

  local files_count=0

  if [[ -f "${backup_path}/.zshrc" ]]; then
    echo "  - .zshrc"
    ((files_count++))
  fi

  if [[ -f "${backup_path}/.zsh_history" ]]; then
    echo "  - .zsh_history"
    ((files_count++))
  fi

  if [[ -d "${backup_path}/oh-my-zsh-custom" ]]; then
    local custom_files=$(find "${backup_path}/oh-my-zsh-custom" -type f | wc -l | tr -d ' ')
    echo "  - .oh-my-zsh/custom/ (${custom_files} files)"
    ((files_count++))
  fi

  if [[ -f "${backup_path}/.zshrc.local" ]]; then
    echo "  - .zshrc.local"
    ((files_count++))
  fi

  echo ""
  echo "Total: $files_count items"
  echo ""
}

# Restore single file from backup (atomic copy via temp file)
# AC5: Atomic file operations
# AC12: Permission error handling with actionable messages
_zsh_tool_restore_file() {
  local source=$1
  local dest=$2

  if [[ ! -e "$source" ]]; then
    _zsh_tool_log WARN "Source file not found: $source"
    return 1
  fi

  # Create parent directory if needed
  local dest_dir="$(dirname "$dest")"
  if ! mkdir -p "$dest_dir" 2>/dev/null; then
    _zsh_tool_log ERROR "Permission denied creating directory: $dest_dir"
    echo "  Try running with sudo or check directory permissions:"
    echo "    sudo mkdir -p $dest_dir"
    return 2  # Return 2 for permission errors
  fi

  # Copy file atomically (via temp file in same directory)
  local temp_file="${dest}.tmp.$$"
  local cp_output
  cp_output=$(cp -Rp "$source" "$temp_file" 2>&1)
  local cp_result=$?

  if [[ $cp_result -ne 0 ]]; then
    rm -f "$temp_file" 2>/dev/null
    if echo "$cp_output" | grep -qi "permission denied\|operation not permitted"; then
      _zsh_tool_log ERROR "Permission denied copying: $source"
      echo "  Try running with sudo or check file permissions:"
      echo "    sudo cp -Rp \"$source\" \"$dest\""
      return 2  # Return 2 for permission errors
    else
      _zsh_tool_log ERROR "Failed to copy: $source - $cp_output"
      return 1
    fi
  fi

  # Atomic move
  local mv_output
  mv_output=$(mv "$temp_file" "$dest" 2>&1)
  local mv_result=$?

  if [[ $mv_result -ne 0 ]]; then
    rm -f "$temp_file" 2>/dev/null
    if echo "$mv_output" | grep -qi "permission denied\|operation not permitted"; then
      _zsh_tool_log ERROR "Permission denied moving to: $dest"
      echo "  Try running with sudo or check file permissions"
      return 2
    else
      _zsh_tool_log ERROR "Failed to move: $temp_file -> $dest - $mv_output"
      return 1
    fi
  fi

  return 0
}

# Verify restore success
_zsh_tool_verify_restore() {
  local backup_path=$1

  local all_ok=true

  # Verify .zshrc
  if [[ -f "${backup_path}/.zshrc" ]]; then
    if [[ ! -f "${HOME}/.zshrc" ]]; then
      _zsh_tool_log WARN ".zshrc not restored"
      all_ok=false
    fi
  fi

  # Verify .zsh_history
  if [[ -f "${backup_path}/.zsh_history" ]]; then
    if [[ ! -f "${HOME}/.zsh_history" ]]; then
      _zsh_tool_log WARN ".zsh_history not restored"
      all_ok=false
    fi
  fi

  if [[ "$all_ok" == true ]]; then
    _zsh_tool_log INFO "✓ Restore verification passed"
    return 0
  else
    _zsh_tool_log WARN "Restore verification completed with warnings"
    return 1
  fi
}

# Rollback restore on failure
# AC10: Automatic rollback on mid-operation failure
_zsh_tool_rollback_restore() {
  local pre_restore_backup=$1

  if [[ -z "$pre_restore_backup" ]] || [[ ! -d "$pre_restore_backup" ]]; then
    _zsh_tool_log ERROR "Cannot rollback: no pre-restore backup available"
    return 1
  fi

  _zsh_tool_log WARN "Rolling back to pre-restore state..."
  echo ""
  echo "Restore failed mid-operation. Rolling back..."
  echo ""

  # Use restore logic but skip backup creation to prevent infinite loop
  local rollback_failed=0

  if [[ -f "${pre_restore_backup}/.zshrc" ]]; then
    _zsh_tool_log INFO "Rolling back .zshrc..."
    if ! _zsh_tool_restore_file "${pre_restore_backup}/.zshrc" "${HOME}/.zshrc"; then
      _zsh_tool_log ERROR "Failed to rollback .zshrc"
      rollback_failed=1
    fi
  fi

  if [[ -f "${pre_restore_backup}/.zsh_history" ]]; then
    _zsh_tool_log INFO "Rolling back .zsh_history..."
    if ! _zsh_tool_restore_file "${pre_restore_backup}/.zsh_history" "${HOME}/.zsh_history"; then
      _zsh_tool_log ERROR "Failed to rollback .zsh_history"
      rollback_failed=1
    fi
  fi

  if [[ -d "${pre_restore_backup}/oh-my-zsh-custom" ]]; then
    _zsh_tool_log INFO "Rolling back Oh My Zsh custom..."
    if ! _zsh_tool_restore_file "${pre_restore_backup}/oh-my-zsh-custom" "${HOME}/.oh-my-zsh/custom"; then
      _zsh_tool_log ERROR "Failed to rollback Oh My Zsh custom"
      rollback_failed=1
    fi
  fi

  if [[ -f "${pre_restore_backup}/.zshrc.local" ]]; then
    _zsh_tool_log INFO "Rolling back .zshrc.local..."
    if ! _zsh_tool_restore_file "${pre_restore_backup}/.zshrc.local" "${HOME}/.zshrc.local"; then
      _zsh_tool_log ERROR "Failed to rollback .zshrc.local"
      rollback_failed=1
    fi
  fi

  if [[ $rollback_failed -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Rollback completed successfully"
    echo "Rollback completed. Original state restored."
    return 0
  else
    _zsh_tool_log ERROR "Rollback completed with errors"
    echo "Rollback completed with errors. Some files may not have been restored."
    return 1
  fi
}

# Main restore function
# AC2: Apply restore from selected backup
# AC3: Display manifest before confirmation
# AC4: Pre-restore backup created automatically
# AC7: --force flag skips confirmation
# AC10: Rollback on mid-operation failure
_zsh_tool_restore_from_backup() {
  local backup_id=""
  local force_mode=false
  local skip_backup=false
  local partial_files=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force|-f)
        force_mode=true
        shift
        ;;
      --no-backup)
        # Internal flag used during rollback to prevent infinite loop
        skip_backup=true
        shift
        ;;
      --files)
        # AC11: Partial restore stub (future enhancement)
        shift
        partial_files="$1"
        shift
        ;;
      --files=*)
        # AC11: Partial restore stub (future enhancement)
        partial_files="${1#--files=}"
        shift
        ;;
      *)
        backup_id="$1"
        shift
        ;;
    esac
  done

  # AC11: Handle partial restore request (stub)
  if [[ -n "$partial_files" ]]; then
    _zsh_tool_restore_partial_stub "$partial_files"
    return $?
  fi

  if [[ -z "$backup_id" ]]; then
    _zsh_tool_log ERROR "Backup ID required"
    echo "Usage: zsh-tool-restore apply <backup-number-or-timestamp> [--force]"
    echo ""
    echo "Options:"
    echo "  --force, -f    Skip confirmation prompt"
    return 1
  fi

  # If backup_id is a number, convert to timestamp
  if [[ "$backup_id" =~ ^[0-9]+$ ]]; then
    local backups=($(ls -1t "$ZSH_TOOL_BACKUP_DIR" 2>/dev/null))
    if [[ ${#backups[@]} -eq 0 ]]; then
      _zsh_tool_log ERROR "No backups available"
      return 1
    fi
    if [[ $backup_id -gt ${#backups[@]} ]] || [[ $backup_id -lt 1 ]]; then
      _zsh_tool_log ERROR "Invalid backup number: $backup_id (available: 1-${#backups[@]})"
      return 1
    fi
    backup_id="${backups[$((backup_id))]}"
  fi

  local backup_path="${ZSH_TOOL_BACKUP_DIR}/${backup_id}"

  # AC9: Backup not found displays error with available backup list
  if [[ ! -d "$backup_path" ]]; then
    _zsh_tool_log ERROR "Backup not found: $backup_id"
    echo ""
    echo "Available backups:"
    _zsh_tool_list_backups
    return 1
  fi

  _zsh_tool_log INFO "Restoring from backup: $backup_id"

  # AC3: Display manifest showing what will be restored
  _zsh_tool_display_backup_contents "$backup_path"

  # AC7: Skip confirmation with --force flag
  if [[ "$force_mode" != true ]]; then
    echo "Current state will be backed up first."
    echo ""

    if ! _zsh_tool_prompt_confirm "Continue?"; then
      _zsh_tool_log INFO "Restore cancelled"
      return 1
    fi
  else
    echo "Force mode enabled, skipping confirmation..."
    echo ""
  fi

  # AC4: Create pre-restore backup (unless in rollback mode)
  local pre_restore_backup_path=""
  if [[ "$skip_backup" != true ]]; then
    _zsh_tool_log INFO "Creating pre-restore backup..."

    # Capture backup count before creating new backup (race-condition safe)
    local backups_before=$(ls -1d "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | wc -l | tr -d ' ')
    local expected_timestamp=$(date +%Y-%m-%d-%H%M%S)

    if ! _zsh_tool_create_backup "pre-restore"; then
      _zsh_tool_log ERROR "Pre-restore backup failed, aborting"
      return 1
    fi

    # Verify backup was created by checking count increased
    local backups_after=$(ls -1d "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | wc -l | tr -d ' ')
    if [[ $backups_after -le $backups_before ]]; then
      _zsh_tool_log ERROR "Pre-restore backup verification failed"
      return 1
    fi

    # Get the most recent backup path (just created)
    # Safe: we verified count increased, so this is our backup
    pre_restore_backup_path=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)
    pre_restore_backup_path="${pre_restore_backup_path%/}"  # Remove trailing slash
    _ZSH_TOOL_PRE_RESTORE_BACKUP="$pre_restore_backup_path"
  fi

  # Restore files with rollback support
  local restored_files=()
  local restore_failed=0

  if [[ -f "${backup_path}/.zshrc" ]]; then
    _zsh_tool_log INFO "Restoring .zshrc..."
    if _zsh_tool_restore_file "${backup_path}/.zshrc" "${HOME}/.zshrc"; then
      restored_files+=(".zshrc")
    else
      restore_failed=1
    fi
  fi

  # AC10: Rollback on failure
  if [[ $restore_failed -eq 1 ]] && [[ -n "$pre_restore_backup_path" ]]; then
    _zsh_tool_log ERROR "Restore failed during .zshrc - initiating rollback"
    _zsh_tool_rollback_restore "$pre_restore_backup_path"
    return 1
  fi

  if [[ -f "${backup_path}/.zsh_history" ]]; then
    _zsh_tool_log INFO "Restoring .zsh_history..."
    if _zsh_tool_restore_file "${backup_path}/.zsh_history" "${HOME}/.zsh_history"; then
      restored_files+=(".zsh_history")
    else
      restore_failed=1
    fi
  fi

  if [[ $restore_failed -eq 1 ]] && [[ -n "$pre_restore_backup_path" ]]; then
    _zsh_tool_log ERROR "Restore failed during .zsh_history - initiating rollback"
    _zsh_tool_rollback_restore "$pre_restore_backup_path"
    return 1
  fi

  if [[ -d "${backup_path}/oh-my-zsh-custom" ]]; then
    _zsh_tool_log INFO "Restoring Oh My Zsh custom..."
    if _zsh_tool_restore_file "${backup_path}/oh-my-zsh-custom" "${HOME}/.oh-my-zsh/custom"; then
      restored_files+=(".oh-my-zsh/custom/")
    else
      restore_failed=1
    fi
  fi

  if [[ $restore_failed -eq 1 ]] && [[ -n "$pre_restore_backup_path" ]]; then
    _zsh_tool_log ERROR "Restore failed during oh-my-zsh-custom - initiating rollback"
    _zsh_tool_rollback_restore "$pre_restore_backup_path"
    return 1
  fi

  if [[ -f "${backup_path}/.zshrc.local" ]]; then
    _zsh_tool_log INFO "Restoring .zshrc.local..."
    if _zsh_tool_restore_file "${backup_path}/.zshrc.local" "${HOME}/.zshrc.local"; then
      restored_files+=(".zshrc.local")
    else
      restore_failed=1
    fi
  fi

  if [[ $restore_failed -eq 1 ]] && [[ -n "$pre_restore_backup_path" ]]; then
    _zsh_tool_log ERROR "Restore failed during .zshrc.local - initiating rollback"
    _zsh_tool_rollback_restore "$pre_restore_backup_path"
    return 1
  fi

  # Verify restore
  _zsh_tool_verify_restore "$backup_path"

  # AC6: Update state with restore metadata
  _zsh_tool_update_state "last_restore.timestamp" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  _zsh_tool_update_state "last_restore.from_backup" "\"${backup_id}\""

  # Build JSON array with proper escaping (M2 fix)
  local files_json=""
  local first=true
  for file in "${restored_files[@]}"; do
    # Escape backslashes and quotes for JSON
    local escaped_file="${file//\\/\\\\}"
    escaped_file="${escaped_file//\"/\\\"}"
    if [[ "$first" == true ]]; then
      files_json="\"${escaped_file}\""
      first=false
    else
      files_json="${files_json},\"${escaped_file}\""
    fi
  done
  _zsh_tool_update_state "last_restore.files_restored" "[${files_json}]"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✓ Restore complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Restored files:"
  for file in "${restored_files[@]}"; do
    echo "  - $file"
  done
  echo ""
  # AC8: Prompt user to reload shell
  echo "Reload your shell: exec zsh"
  echo ""

  # Clear global variable after successful restore (L1 fix)
  _ZSH_TOOL_PRE_RESTORE_BACKUP=""

  return 0
}
