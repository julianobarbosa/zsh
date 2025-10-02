#!/usr/bin/env zsh
# Story 2.4: Configuration Restore from Backup
# Restore configuration from a backup

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

# Restore single file from backup
_zsh_tool_restore_file() {
  local source=$1
  local dest=$2

  if [[ ! -e "$source" ]]; then
    _zsh_tool_log WARN "Source file not found: $source"
    return 1
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$dest")"

  # Copy file atomically (via temp file)
  local temp_file="${dest}.tmp"
  cp -R "$source" "$temp_file" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null

  if [[ $? -eq 0 ]]; then
    mv "$temp_file" "$dest" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    return 0
  else
    rm -f "$temp_file"
    return 1
  fi
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

# Main restore function
_zsh_tool_restore_from_backup() {
  local backup_id=$1

  if [[ -z "$backup_id" ]]; then
    _zsh_tool_log ERROR "Backup ID required"
    echo "Usage: zsh-tool-restore apply <backup-number-or-timestamp>"
    return 1
  fi

  # If backup_id is a number, convert to timestamp
  if [[ "$backup_id" =~ ^[0-9]+$ ]]; then
    local backups=($(ls -1t "$ZSH_TOOL_BACKUP_DIR" 2>/dev/null))
    backup_id="${backups[$((backup_id - 1))]}"
  fi

  local backup_path="${ZSH_TOOL_BACKUP_DIR}/${backup_id}"

  if [[ ! -d "$backup_path" ]]; then
    _zsh_tool_log ERROR "Backup not found: $backup_id"
    echo ""
    echo "Available backups:"
    _zsh_tool_list_backups
    return 1
  fi

  _zsh_tool_log INFO "Restoring from backup: $backup_id"

  # Display backup contents
  _zsh_tool_display_backup_contents "$backup_path"

  # Confirm restore
  echo "Current state will be backed up first."
  echo ""

  if ! _zsh_tool_prompt_confirm "Continue?"; then
    _zsh_tool_log INFO "Restore cancelled"
    return 1
  fi

  # Create pre-restore backup
  _zsh_tool_log INFO "Creating pre-restore backup..."
  _zsh_tool_create_backup "pre-restore" || {
    _zsh_tool_log ERROR "Pre-restore backup failed, aborting"
    return 1
  }

  # Restore files
  local restored_files=()

  if [[ -f "${backup_path}/.zshrc" ]]; then
    _zsh_tool_log INFO "Restoring .zshrc..."
    if _zsh_tool_restore_file "${backup_path}/.zshrc" "${HOME}/.zshrc"; then
      restored_files+=(".zshrc")
    fi
  fi

  if [[ -f "${backup_path}/.zsh_history" ]]; then
    _zsh_tool_log INFO "Restoring .zsh_history..."
    if _zsh_tool_restore_file "${backup_path}/.zsh_history" "${HOME}/.zsh_history"; then
      restored_files+=(".zsh_history")
    fi
  fi

  if [[ -d "${backup_path}/oh-my-zsh-custom" ]]; then
    _zsh_tool_log INFO "Restoring Oh My Zsh custom..."
    if _zsh_tool_restore_file "${backup_path}/oh-my-zsh-custom" "${HOME}/.oh-my-zsh/custom"; then
      restored_files+=(".oh-my-zsh/custom/")
    fi
  fi

  if [[ -f "${backup_path}/.zshrc.local" ]]; then
    _zsh_tool_log INFO "Restoring .zshrc.local..."
    if _zsh_tool_restore_file "${backup_path}/.zshrc.local" "${HOME}/.zshrc.local"; then
      restored_files+=(".zshrc.local")
    fi
  fi

  # Verify restore
  _zsh_tool_verify_restore "$backup_path"

  # Update state
  _zsh_tool_update_state "last_restore.timestamp" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  _zsh_tool_update_state "last_restore.from_backup" "\"${backup_id}\""

  local files_json=$(printf '"%s",' "${restored_files[@]}" | sed 's/,$//')
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
  echo "Reload your shell: exec zsh"
  echo ""

  return 0
}
