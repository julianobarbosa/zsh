#!/usr/bin/env zsh
# Story 2.1: Self-Update Mechanism
# Update the zsh-tool itself to the latest version

# Get tool installation directory
ZSH_TOOL_INSTALL_DIR="${ZSH_TOOL_INSTALL_DIR:-${HOME}/.local/bin/zsh-tool}"

# Backup directory for tool installation backups (separate from config backups)
ZSH_TOOL_INSTALL_BACKUP_DIR="${ZSH_TOOL_CONFIG_DIR}/backups/tool-install"

# Source backup utilities for pre-update backups
# Use script directory to locate backup.zsh relative to this file
_ZSH_TOOL_SELF_DIR="${0:A:h}"
source "${_ZSH_TOOL_SELF_DIR}/../install/backup.zsh" 2>/dev/null || {
  _zsh_tool_log WARN "Failed to source backup.zsh - backup functionality may be limited"
}

# Check if tool is in a git repository
_zsh_tool_is_git_repo() {
  [[ -d "${ZSH_TOOL_INSTALL_DIR}/.git" ]]
}

# Get local version from VERSION file or git
_zsh_tool_get_local_version() {
  # Try VERSION file first
  if [[ -f "${ZSH_TOOL_INSTALL_DIR}/VERSION" ]]; then
    cat "${ZSH_TOOL_INSTALL_DIR}/VERSION"
    return 0
  fi

  # Fall back to git (use subshell to avoid cd pollution)
  if _zsh_tool_is_git_repo; then
    local version=$(
      cd "$ZSH_TOOL_INSTALL_DIR" || exit 1
      git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown"
    )
    echo "$version"
    return 0
  fi

  echo "unknown"
  return 1
}

# Get current version (alias for backward compatibility)
_zsh_tool_get_current_version() {
  _zsh_tool_get_local_version
}

# Compare two semantic versions
# Returns: 0 if v1 < v2 (update available), 1 otherwise
# IMPORTANT: Only returns 0 (update available) for valid semver comparisons
# Non-semver versions (git hashes, etc.) return 1 (no update) for safety
_zsh_tool_compare_versions() {
  local v1="$1"
  local v2="$2"

  # Helper function to validate semver format
  # Valid semver: X.Y.Z where X, Y, Z are non-negative integers without leading zeros
  # (except for 0 itself). We allow up to 3 digits per component (0-999) for practicality.
  _is_valid_semver() {
    local ver="$1"
    # Must match X.Y.Z pattern with no leading zeros (except standalone 0)
    # Valid: 0.0.0, 1.2.3, 10.20.30, 999.999.999
    # Invalid: 01.2.3, 1.02.3, 1.2.03, 1000.0.0
    if [[ ! "$ver" =~ ^(0|[1-9][0-9]{0,2})\.(0|[1-9][0-9]{0,2})\.(0|[1-9][0-9]{0,2})$ ]]; then
      return 1
    fi
    return 0
  }

  # Safety check: both versions must be provided
  if [[ -z "$v1" ]] || [[ -z "$v2" ]]; then
    return 1  # Missing version, don't suggest update
  fi

  # Handle non-semver versions safely
  # For git hashes, tags, or other non-semver: we CANNOT determine ordering
  # Return 1 (no update) for safety - the caller should use git SHA comparison instead
  if ! _is_valid_semver "$v1" || ! _is_valid_semver "$v2"; then
    # Log a debug message if logging is available
    if type _zsh_tool_log &>/dev/null; then
      _zsh_tool_log DEBUG "Version comparison skipped: non-semver versions (v1=${v1}, v2=${v2})"
    fi
    # CRITICAL: Do NOT use string comparison for non-semver versions
    # String comparison is dangerous and can lead to incorrect update suggestions
    # Example: "abc123" < "def456" alphabetically, but that doesn't mean def456 is newer
    return 1
  fi

  # Extract version components using parameter expansion (more efficient than cut)
  local v1_major="${v1%%.*}"
  local v1_rest="${v1#*.}"
  local v1_minor="${v1_rest%%.*}"
  local v1_patch="${v1_rest#*.}"

  local v2_major="${v2%%.*}"
  local v2_rest="${v2#*.}"
  local v2_minor="${v2_rest%%.*}"
  local v2_patch="${v2_rest#*.}"

  # Compare major version
  if (( v1_major < v2_major )); then
    return 0  # Update available
  elif (( v1_major > v2_major )); then
    return 1  # Current is newer
  fi

  # Compare minor version
  if (( v1_minor < v2_minor )); then
    return 0  # Update available
  elif (( v1_minor > v2_minor )); then
    return 1  # Current is newer
  fi

  # Compare patch version
  if (( v1_patch < v2_patch )); then
    return 0  # Update available
  else
    return 1  # Same or current is newer
  fi
}

# Check for available updates
_zsh_tool_check_for_updates() {
  if ! _zsh_tool_is_git_repo; then
    _zsh_tool_log WARN "Tool not installed as git repository, cannot check for updates"
    return 1
  fi

  _zsh_tool_log INFO "Checking for updates..."

  # Use subshell to avoid cd pollution
  local check_result
  check_result=$(
    cd "$ZSH_TOOL_INSTALL_DIR" || { echo "cd_failed"; exit 1; }

    # Fetch latest changes - capture output and status separately to avoid pipestatus issues
    local fetch_output
    fetch_output=$(git fetch origin 2>&1)
    local fetch_status=$?

    # Append to log file if it exists and is writable
    if [[ -n "$ZSH_TOOL_LOG_FILE" ]] && [[ -w "$(dirname "$ZSH_TOOL_LOG_FILE")" ]]; then
      echo "$fetch_output" >> "$ZSH_TOOL_LOG_FILE"
    fi

    if [[ $fetch_status -ne 0 ]]; then
      echo "fetch_failed:${fetch_output}"
      exit 1
    fi

    # Compare local vs remote
    local current_sha=$(git rev-parse HEAD 2>/dev/null)
    local remote_sha=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)

    if [[ -z "$remote_sha" ]]; then
      echo "no_remote"
      exit 1
    fi

    if [[ "$current_sha" == "$remote_sha" ]]; then
      echo "up_to_date"
    else
      echo "updates_available"
    fi
  )

  # Handle different result cases
  case "$check_result" in
    cd_failed)
      _zsh_tool_log ERROR "Failed to access install directory"
      return 1
      ;;
    fetch_failed:*)
      local fetch_error="${check_result#fetch_failed:}"
      _zsh_tool_log WARN "Failed to fetch updates (network issue?): ${fetch_error}"
      return 1
      ;;
    no_remote)
      _zsh_tool_log WARN "Could not determine remote branch (origin/main or origin/master)"
      return 1
      ;;
    up_to_date)
      _zsh_tool_log INFO "Tool is up to date"
      return 1  # No updates available
      ;;
    updates_available)
      _zsh_tool_log INFO "Updates available!"
      return 0  # Updates available
      ;;
    *)
      _zsh_tool_log WARN "Unknown check result: ${check_result}"
      return 1
      ;;
  esac
}

# Create backup of TOOL INSTALLATION before update (AC4)
# This backs up the zsh-tool itself, NOT user configurations
# Returns the backup directory path via stdout if successful
_zsh_tool_backup_before_update() {
  local backup_reason="${1:-update}"
  local timestamp=$(date '+%Y-%m-%d-%H%M%S')
  local backup_dir="${ZSH_TOOL_INSTALL_BACKUP_DIR}/backup-${timestamp}"

  _zsh_tool_log INFO "Creating tool installation backup: ${backup_dir}"

  # Ensure backup directory exists with secure permissions
  if ! mkdir -p -m 700 "$backup_dir"; then
    _zsh_tool_log ERROR "Failed to create tool backup directory: ${backup_dir}"
    return 1
  fi

  # Verify source directory exists
  if [[ ! -d "$ZSH_TOOL_INSTALL_DIR" ]]; then
    _zsh_tool_log ERROR "Tool installation directory not found: ${ZSH_TOOL_INSTALL_DIR}"
    rm -rf "$backup_dir"
    return 1
  fi

  # Copy entire tool installation (excluding .git to save space, we have git for rollback)
  # Use rsync if available for better reliability, otherwise fall back to cp
  if command -v rsync >/dev/null 2>&1; then
    if ! rsync -a --exclude='.git' "${ZSH_TOOL_INSTALL_DIR}/" "${backup_dir}/"; then
      _zsh_tool_log ERROR "Tool backup failed (rsync)"
      rm -rf "$backup_dir"
      return 1
    fi
  else
    # Fallback to cp - use subshell to avoid cd pollution
    if ! (
      cd "$ZSH_TOOL_INSTALL_DIR" || exit 1
      # Copy all files except .git directory
      for item in *; do
        [[ "$item" == ".git" ]] && continue
        cp -R "$item" "$backup_dir/" || exit 1
      done
      # Copy hidden files except .git
      for item in .*; do
        [[ "$item" == "." || "$item" == ".." || "$item" == ".git" ]] && continue
        cp -R "$item" "$backup_dir/" 2>/dev/null || true
      done
    ); then
      _zsh_tool_log ERROR "Tool backup failed (cp)"
      rm -rf "$backup_dir"
      return 1
    fi
  fi

  # Create backup manifest
  local manifest_file="${backup_dir}/BACKUP_MANIFEST.json"
  local current_version=$(_zsh_tool_get_local_version)
  local current_sha=""
  if _zsh_tool_is_git_repo; then
    current_sha=$(cd "$ZSH_TOOL_INSTALL_DIR" && git rev-parse HEAD 2>/dev/null || echo "unknown")
  fi

  cat > "$manifest_file" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "reason": "${backup_reason}",
  "version": "${current_version}",
  "git_sha": "${current_sha}",
  "install_dir": "${ZSH_TOOL_INSTALL_DIR}"
}
EOF

  _zsh_tool_log INFO "Tool installation backup created: ${backup_dir}"

  # Output backup directory path for use by callers
  echo "$backup_dir"
  return 0
}

# Display changelog between versions
_zsh_tool_display_changelog() {
  if ! _zsh_tool_is_git_repo; then
    return 1
  fi

  local current_version=$(_zsh_tool_get_current_version)

  # Use subshell to avoid cd pollution
  local changelog_info
  changelog_info=$(
    cd "$ZSH_TOOL_INSTALL_DIR" || exit 1
    local remote_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo "main")
    local new_version=$(git describe --tags origin/$remote_branch 2>/dev/null || git rev-parse --short origin/$remote_branch 2>/dev/null)

    echo "NEW_VERSION:${new_version}"
    echo "COMMITS_START"
    git log HEAD..origin/$remote_branch --oneline --no-decorate 2>/dev/null
    echo "COMMITS_END"
  )

  local new_version=$(echo "$changelog_info" | grep "^NEW_VERSION:" | cut -d: -f2)
  local commits=$(echo "$changelog_info" | sed -n '/^COMMITS_START$/,/^COMMITS_END$/p' | grep -v "^COMMITS_")

  echo ""
  echo "Updates available:"
  echo ""

  # Show commits between current and remote
  echo "$commits" | while read line; do
    [[ -n "$line" ]] && echo "  - $line"
  done

  echo ""
  echo "Current version: $current_version"
  echo "New version: $new_version"
  echo ""
}

# Restore tool installation from backup (AC7 - Rollback mechanism)
# Usage: _zsh_tool_restore_from_backup <backup_dir>
_zsh_tool_restore_from_backup() {
  local backup_dir="$1"

  if [[ -z "$backup_dir" ]] || [[ ! -d "$backup_dir" ]]; then
    _zsh_tool_log ERROR "Invalid or missing backup directory: ${backup_dir}"
    return 1
  fi

  _zsh_tool_log INFO "Restoring tool installation from backup: ${backup_dir}"

  # Verify backup has manifest (indicates valid backup)
  if [[ ! -f "${backup_dir}/BACKUP_MANIFEST.json" ]]; then
    _zsh_tool_log ERROR "Invalid backup: missing BACKUP_MANIFEST.json"
    return 1
  fi

  # Restore files using rsync or cp (preserve .git directory)
  if command -v rsync >/dev/null 2>&1; then
    if ! rsync -a --exclude='BACKUP_MANIFEST.json' "${backup_dir}/" "${ZSH_TOOL_INSTALL_DIR}/"; then
      _zsh_tool_log ERROR "Restore from backup failed (rsync)"
      return 1
    fi
  else
    # Fallback to cp
    for item in "${backup_dir}"/*; do
      local fname=$(basename "$item")
      [[ "$fname" == "BACKUP_MANIFEST.json" ]] && continue
      if ! cp -R "$item" "${ZSH_TOOL_INSTALL_DIR}/"; then
        _zsh_tool_log ERROR "Restore from backup failed (cp): $fname"
        return 1
      fi
    done
    # Restore hidden files
    for item in "${backup_dir}"/.*; do
      local fname=$(basename "$item")
      [[ "$fname" == "." || "$fname" == ".." ]] && continue
      cp -R "$item" "${ZSH_TOOL_INSTALL_DIR}/" 2>/dev/null || true
    done
  fi

  _zsh_tool_log INFO "Tool installation restored from backup"
  return 0
}

# Apply update (git pull) with proper backup and rollback (AC4, AC7)
_zsh_tool_apply_update() {
  if ! _zsh_tool_is_git_repo; then
    _zsh_tool_log ERROR "Tool not installed as git repository, cannot update"
    return 1
  fi

  _zsh_tool_log INFO "Applying update..."

  # AC4: Create backup of tool installation before update
  local backup_dir
  backup_dir=$(_zsh_tool_backup_before_update "pre-update")
  local backup_status=$?

  if [[ $backup_status -ne 0 ]] || [[ -z "$backup_dir" ]]; then
    _zsh_tool_log ERROR "Tool backup failed, aborting update for safety"
    return 1
  fi

  _zsh_tool_log INFO "Backup created at: ${backup_dir}"

  # Use subshell for git operations to avoid cd pollution
  local update_result
  update_result=$(
    cd "$ZSH_TOOL_INSTALL_DIR" || { echo "CD_FAILED"; exit 1; }

    local current_sha=$(git rev-parse HEAD 2>/dev/null)
    local remote_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo "main")

    echo "CURRENT_SHA:${current_sha}"
    echo "REMOTE_BRANCH:${remote_branch}"

    # Pull latest changes - capture both stdout and stderr
    local pull_output
    pull_output=$(git pull origin "$remote_branch" 2>&1)
    local pull_status=$?

    if [[ $pull_status -ne 0 ]]; then
      echo "PULL_FAILED"
      echo "PULL_ERROR:${pull_output}"
      exit 1
    fi

    echo "PULL_SUCCESS"
    echo "NEW_SHA:$(git rev-parse HEAD 2>/dev/null)"
  )

  # Parse update results
  local current_sha=$(echo "$update_result" | grep "^CURRENT_SHA:" | cut -d: -f2)
  local remote_branch=$(echo "$update_result" | grep "^REMOTE_BRANCH:" | cut -d: -f2)

  # Check for failures
  if echo "$update_result" | grep -q "^CD_FAILED$"; then
    _zsh_tool_log ERROR "Failed to access install directory"
    return 1
  fi

  if echo "$update_result" | grep -q "^PULL_FAILED$"; then
    local pull_error=$(echo "$update_result" | grep "^PULL_ERROR:" | cut -d: -f2-)
    _zsh_tool_log ERROR "Git pull failed: ${pull_error}"
    _zsh_tool_log INFO "Attempting git rollback..."

    # AC7: Try git reset first
    local git_rollback_result
    git_rollback_result=$(
      cd "$ZSH_TOOL_INSTALL_DIR" || exit 1
      git reset --hard "$current_sha" 2>&1
      echo "STATUS:$?"
    )

    if echo "$git_rollback_result" | grep -q "^STATUS:0$"; then
      _zsh_tool_log INFO "Git rollback successful"
    else
      _zsh_tool_log WARN "Git rollback failed, restoring from backup..."
      if ! _zsh_tool_restore_from_backup "$backup_dir"; then
        _zsh_tool_log ERROR "CRITICAL: Both git rollback and backup restore failed!"
        _zsh_tool_log ERROR "Manual intervention required. Backup available at: ${backup_dir}"
        return 1
      fi
      _zsh_tool_log INFO "Restored from backup successfully"
    fi
    return 1
  fi

  # Post-update validation: verify critical files exist and update succeeded
  local validation_failed=false
  local new_sha=$(echo "$update_result" | grep "^NEW_SHA:" | cut -d: -f2)

  # Check 1: Verify HEAD actually changed (update was applied)
  if [[ "$current_sha" == "$new_sha" ]]; then
    _zsh_tool_log WARN "Update did not change HEAD - may already be up to date"
  fi

  # Check 2: Verify VERSION file exists and is readable
  if [[ ! -f "${ZSH_TOOL_INSTALL_DIR}/VERSION" ]]; then
    _zsh_tool_log ERROR "Post-update validation failed: VERSION file missing"
    validation_failed=true
  elif [[ ! -r "${ZSH_TOOL_INSTALL_DIR}/VERSION" ]]; then
    _zsh_tool_log ERROR "Post-update validation failed: VERSION file not readable"
    validation_failed=true
  fi

  # Check 3: Verify critical library files exist
  local critical_files=(
    "lib/update/self.zsh"
    "lib/core/utils.zsh"
  )
  for file in "${critical_files[@]}"; do
    if [[ ! -f "${ZSH_TOOL_INSTALL_DIR}/${file}" ]]; then
      _zsh_tool_log ERROR "Post-update validation failed: critical file missing: ${file}"
      validation_failed=true
    fi
  done

  # AC7: If validation failed, rollback
  if [[ "$validation_failed" == true ]]; then
    _zsh_tool_log ERROR "Post-update validation failed, initiating rollback..."

    # Try git reset first
    local git_rollback_result
    git_rollback_result=$(
      cd "$ZSH_TOOL_INSTALL_DIR" || exit 1
      git reset --hard "$current_sha" 2>&1
      echo "STATUS:$?"
    )

    if echo "$git_rollback_result" | grep -q "^STATUS:0$"; then
      _zsh_tool_log INFO "Git rollback successful"
    else
      _zsh_tool_log WARN "Git rollback failed, restoring from backup..."
      if ! _zsh_tool_restore_from_backup "$backup_dir"; then
        _zsh_tool_log ERROR "CRITICAL: Both git rollback and backup restore failed!"
        _zsh_tool_log ERROR "Manual intervention required. Backup available at: ${backup_dir}"
        return 1
      fi
      _zsh_tool_log INFO "Restored from backup successfully"
    fi
    return 1
  fi

  # Update state
  local new_version=$(_zsh_tool_get_current_version)
  _zsh_tool_update_state "tool_version.current" "\"$new_version\""
  _zsh_tool_update_state "tool_version.previous" "\"$current_sha\""
  _zsh_tool_update_state "tool_version.last_update" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  _zsh_tool_log INFO "Post-update validation passed"
  _zsh_tool_log INFO "Update complete: $new_version"
  echo ""
  echo "Reload shell to apply updates: exec zsh"
  echo ""

  return 0
}

# Rollback to previous version using git
_zsh_tool_rollback_update() {
  local target_version="${1:-HEAD~1}"

  if ! _zsh_tool_is_git_repo; then
    _zsh_tool_log ERROR "Tool not installed as git repository, cannot rollback"
    return 1
  fi

  _zsh_tool_log INFO "Rolling back to: $target_version"

  # Use subshell to avoid cd pollution
  local rollback_result
  rollback_result=$(
    cd "$ZSH_TOOL_INSTALL_DIR" || { echo "CD_FAILED"; exit 1; }

    # Capture checkout output and status separately (avoid pipestatus complexity)
    local checkout_output
    checkout_output=$(git checkout "$target_version" 2>&1)
    local checkout_status=$?

    # Append to log file if it exists
    if [[ -n "$ZSH_TOOL_LOG_FILE" ]] && [[ -w "$(dirname "$ZSH_TOOL_LOG_FILE")" ]]; then
      echo "$checkout_output" >> "$ZSH_TOOL_LOG_FILE"
    fi

    if [[ $checkout_status -eq 0 ]]; then
      echo "SUCCESS"
    else
      echo "FAILED:${checkout_output}"
    fi
  )

  if [[ "$rollback_result" == "CD_FAILED" ]]; then
    _zsh_tool_log ERROR "Failed to access install directory"
    return 1
  fi

  if [[ "$rollback_result" == "SUCCESS" ]]; then
    local version=$(_zsh_tool_get_current_version)
    _zsh_tool_log INFO "Rolled back to: $version"
    _zsh_tool_update_state "tool_version.current" "\"$version\""
    return 0
  else
    local error_msg="${rollback_result#FAILED:}"
    _zsh_tool_log ERROR "Rollback failed: ${error_msg}"
    return 1
  fi
}

# Main self-update command
_zsh_tool_self_update() {
  local check_only=false

  # Parse flags
  if [[ "$1" == "--check" ]]; then
    check_only=true
  fi

  if ! _zsh_tool_is_git_repo; then
    _zsh_tool_log WARN "Tool not installed as git repository"
    echo ""
    echo "To enable self-update, reinstall with:"
    echo "  git clone https://github.com/yourteam/zsh-tool ~/.local/bin/zsh-tool"
    echo "  ~/.local/bin/zsh-tool/install.sh"
    echo ""
    return 1
  fi

  # Check for updates
  if _zsh_tool_check_for_updates; then
    # Updates available
    _zsh_tool_display_changelog

    if [[ "$check_only" == true ]]; then
      return 0
    fi

    # Prompt to update
    if _zsh_tool_prompt_confirm "Update now?"; then
      _zsh_tool_apply_update
    else
      _zsh_tool_log INFO "Update cancelled"
      return 1
    fi
  else
    # No updates available or check failed
    return 1
  fi
}
