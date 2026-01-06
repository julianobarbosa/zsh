#!/usr/bin/env zsh
# Story 2.1: Self-Update Mechanism
# Update the zsh-tool itself to the latest version

# Get tool installation directory
ZSH_TOOL_INSTALL_DIR="${ZSH_TOOL_INSTALL_DIR:-${HOME}/.local/bin/zsh-tool}"

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
_zsh_tool_compare_versions() {
  local v1="$1"
  local v2="$2"

  # Helper function to validate semver bounds (max 999 per component)
  _is_valid_semver() {
    local ver="$1"
    if [[ ! "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      return 1
    fi
    local major=$(echo "$ver" | cut -d. -f1)
    local minor=$(echo "$ver" | cut -d. -f2)
    local patch=$(echo "$ver" | cut -d. -f3)
    # Check bounds (0-999 for each component)
    if [[ $major -gt 999 ]] || [[ $minor -gt 999 ]] || [[ $patch -gt 999 ]]; then
      return 1
    fi
    return 0
  }

  # Handle non-semver versions (git hashes, tags, etc.)
  if ! _is_valid_semver "$v1" || ! _is_valid_semver "$v2"; then
    # For non-semver, only report update available if versions are different
    # AND local is not "unknown" (which would indicate a problem)
    if [[ "$v1" == "unknown" ]]; then
      # Can't determine local version, don't suggest update
      return 1
    fi
    # Different versions - but for non-semver we can't determine which is newer
    # Only return update available if they differ (caller should use git SHA comparison)
    if [[ "$v1" != "$v2" ]] && [[ -n "$v2" ]]; then
      return 0
    fi
    return 1
  fi

  # Split versions into components (zsh arrays are 1-indexed)
  local v1_major=$(echo "$v1" | cut -d. -f1)
  local v1_minor=$(echo "$v1" | cut -d. -f2)
  local v1_patch=$(echo "$v1" | cut -d. -f3)

  local v2_major=$(echo "$v2" | cut -d. -f1)
  local v2_minor=$(echo "$v2" | cut -d. -f2)
  local v2_patch=$(echo "$v2" | cut -d. -f3)

  # Compare major
  if [[ $v1_major -lt $v2_major ]]; then
    return 0  # Update available
  elif [[ $v1_major -gt $v2_major ]]; then
    return 1  # Current is newer
  fi

  # Compare minor
  if [[ $v1_minor -lt $v2_minor ]]; then
    return 0  # Update available
  elif [[ $v1_minor -gt $v2_minor ]]; then
    return 1  # Current is newer
  fi

  # Compare patch
  if [[ $v1_patch -lt $v2_patch ]]; then
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

    # Fetch latest changes
    git fetch origin 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    local fetch_status=${pipestatus[1]}

    if [[ $fetch_status -ne 0 ]]; then
      echo "fetch_failed"
      exit 1
    fi

    # Compare local vs remote
    local current_sha=$(git rev-parse HEAD 2>/dev/null)
    local remote_sha=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)

    if [[ "$current_sha" == "$remote_sha" ]]; then
      echo "up_to_date"
    else
      echo "updates_available"
    fi
  )

  case "$check_result" in
    cd_failed)
      _zsh_tool_log ERROR "Failed to access install directory"
      return 1
      ;;
    fetch_failed)
      _zsh_tool_log WARN "Failed to fetch updates (network issue?)"
      return 1
      ;;
    up_to_date)
      _zsh_tool_log INFO "✓ Tool is up to date"
      return 1  # No updates available
      ;;
    updates_available)
      _zsh_tool_log INFO "Updates available!"
      return 0  # Updates available
      ;;
    *)
      _zsh_tool_log WARN "Unknown check result"
      return 1
      ;;
  esac
}

# Create backup of tool source files before update with timestamped directory
# This backs up the TOOL ITSELF (for rollback), not user configs (AC4 requirement)
_zsh_tool_backup_before_update() {
  local backup_reason="${1:-update}"
  local timestamp=$(date '+%Y-%m-%d-%H%M%S')
  local backup_dir="${ZSH_TOOL_CONFIG_DIR}/backups/tool-backup-${timestamp}"

  _zsh_tool_log INFO "Creating tool backup: ${backup_dir}"

  # Create backup directory with secure permissions
  if ! mkdir -p -m 700 "$backup_dir"; then
    _zsh_tool_log ERROR "Failed to create tool backup directory"
    return 1
  fi

  # Back up tool source files for rollback capability (AC4/AC7)
  if [[ -d "$ZSH_TOOL_INSTALL_DIR" ]]; then
    # Copy critical directories and files
    local -a items_to_backup=(
      "lib"
      "templates"
      "VERSION"
      "install.sh"
    )

    for item in "${items_to_backup[@]}"; do
      local source="${ZSH_TOOL_INSTALL_DIR}/${item}"
      if [[ -e "$source" ]]; then
        if ! cp -Rp "$source" "$backup_dir/" 2>/dev/null; then
          _zsh_tool_log ERROR "Failed to backup: $item"
          rm -rf "$backup_dir"
          return 1
        fi
      fi
    done

    # Store backup path in state for potential file-based recovery
    _zsh_tool_update_state "tool_version.last_backup_dir" "\"${backup_dir}\""
    _zsh_tool_update_state "tool_version.last_backup_time" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

    _zsh_tool_log INFO "Tool backup created successfully: ${backup_dir}"
    return 0
  fi

  _zsh_tool_log ERROR "Install directory not found: $ZSH_TOOL_INSTALL_DIR"
  return 1
}

# Display changelog between versions
_zsh_tool_display_changelog() {
  if ! _zsh_tool_is_git_repo; then
    return 1
  fi

  local current_version=$(_zsh_tool_get_current_version)

  # Use subshell to avoid cd pollution and handle errors
  local changelog_info
  changelog_info=$(
    cd "$ZSH_TOOL_INSTALL_DIR" || exit 1

    local remote_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo "main")
    local new_version=$(git describe --tags origin/$remote_branch 2>/dev/null || git rev-parse --short origin/$remote_branch 2>/dev/null)

    echo "REMOTE_BRANCH=$remote_branch"
    echo "NEW_VERSION=$new_version"
    echo "---COMMITS---"
    git log HEAD..origin/$remote_branch --oneline --no-decorate 2>/dev/null
  )

  if [[ $? -ne 0 ]]; then
    _zsh_tool_log ERROR "Failed to access install directory for changelog"
    return 1
  fi

  # Parse changelog info
  local remote_branch=$(echo "$changelog_info" | grep "^REMOTE_BRANCH=" | cut -d= -f2)
  local new_version=$(echo "$changelog_info" | grep "^NEW_VERSION=" | cut -d= -f2)
  local commits=$(echo "$changelog_info" | sed -n '/^---COMMITS---$/,$p' | tail -n +2)

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

# Apply update (git pull)
_zsh_tool_apply_update() {
  if ! _zsh_tool_is_git_repo; then
    _zsh_tool_log ERROR "Tool not installed as git repository, cannot update"
    return 1
  fi

  _zsh_tool_log INFO "Applying update..."

  # Create backup before update (AC4 requirement)
  # Back up tool source files for rollback capability
  _zsh_tool_backup_before_update "pre-update" || {
    _zsh_tool_log ERROR "Backup of tool files failed, aborting update"
    return 1
  }

  # Also back up user config files
  _zsh_tool_create_backup "pre-update" 2>/dev/null || {
    _zsh_tool_log WARN "User config backup skipped or failed (continuing anyway)"
  }

  # Use pushd/popd for safe directory change with proper error handling
  if ! pushd "$ZSH_TOOL_INSTALL_DIR" >/dev/null 2>&1; then
    _zsh_tool_log ERROR "Failed to access install directory: $ZSH_TOOL_INSTALL_DIR"
    return 1
  fi

  local current_sha=$(git rev-parse HEAD)
  local remote_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo "main")

  # Pull latest changes - capture git status directly
  local pull_output
  pull_output=$(git pull origin $remote_branch 2>&1)
  local pull_status=$?

  # Log the output
  echo "$pull_output" >> "$ZSH_TOOL_LOG_FILE"

  if [[ $pull_status -ne 0 ]]; then
    _zsh_tool_log ERROR "Update failed, rolling back..."
    git reset --hard $current_sha >> "$ZSH_TOOL_LOG_FILE" 2>&1
    popd >/dev/null 2>&1
    return 1
  fi

  # Post-update validation: verify critical files exist and update succeeded
  local validation_failed=false
  local new_sha=$(git rev-parse HEAD)

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

  # If validation failed, rollback (AC7 requirement)
  if [[ "$validation_failed" == true ]]; then
    _zsh_tool_log ERROR "Post-update validation failed, rolling back..."
    git reset --hard $current_sha >> "$ZSH_TOOL_LOG_FILE" 2>&1
    popd >/dev/null 2>&1
    return 1
  fi

  popd >/dev/null 2>&1

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

# Restore from file-based backup (fallback for git failures)
_zsh_tool_restore_from_backup() {
  local backup_dir="$1"

  if [[ -z "$backup_dir" ]]; then
    # Try to get last backup from state
    local state=$(_zsh_tool_load_state 2>/dev/null)
    if [[ -n "$state" ]]; then
      backup_dir=$(echo "$state" | grep -o '"last_backup_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    fi
  fi

  if [[ -z "$backup_dir" ]] || [[ ! -d "$backup_dir" ]]; then
    _zsh_tool_log ERROR "No valid backup directory found for restore"
    return 1
  fi

  _zsh_tool_log INFO "Restoring from backup: $backup_dir"

  # Restore files from backup
  local -a items_to_restore=(
    "lib"
    "templates"
    "VERSION"
    "install.sh"
  )

  for item in "${items_to_restore[@]}"; do
    local backup_source="${backup_dir}/${item}"
    local restore_dest="${ZSH_TOOL_INSTALL_DIR}/${item}"

    if [[ -e "$backup_source" ]]; then
      # Remove existing and restore from backup
      rm -rf "$restore_dest" 2>/dev/null
      if ! cp -Rp "$backup_source" "$restore_dest" 2>/dev/null; then
        _zsh_tool_log ERROR "Failed to restore: $item"
        return 1
      fi
    fi
  done

  _zsh_tool_log INFO "✓ Restored from backup successfully"
  return 0
}

# Rollback to previous version (AC7 requirement)
_zsh_tool_rollback_update() {
  local target_version="${1:-HEAD~1}"

  # Try git-based rollback first
  if _zsh_tool_is_git_repo; then
    _zsh_tool_log INFO "Rolling back to: $target_version"

    # Use pushd/popd for safe directory change with proper error handling
    if ! pushd "$ZSH_TOOL_INSTALL_DIR" >/dev/null 2>&1; then
      _zsh_tool_log ERROR "Failed to access install directory: $ZSH_TOOL_INSTALL_DIR"
      # Fall through to file-based restore
    else
      # Capture git checkout status directly
      local checkout_output
      checkout_output=$(git checkout "$target_version" 2>&1)
      local checkout_status=$?

      # Log the output
      echo "$checkout_output" >> "$ZSH_TOOL_LOG_FILE"

      popd >/dev/null 2>&1

      if [[ $checkout_status -eq 0 ]]; then
        local version=$(_zsh_tool_get_current_version)
        _zsh_tool_log INFO "✓ Rolled back to: $version"
        _zsh_tool_update_state "tool_version.current" "\"$version\""
        return 0
      fi

      _zsh_tool_log WARN "Git rollback failed, trying file-based restore..."
    fi
  fi

  # Fallback: file-based restore from backup
  if _zsh_tool_restore_from_backup; then
    local version=$(_zsh_tool_get_current_version)
    _zsh_tool_log INFO "✓ Restored to: $version"
    _zsh_tool_update_state "tool_version.current" "\"$version\""
    return 0
  fi

  _zsh_tool_log ERROR "Rollback failed - both git and file-based restore failed"
  return 1
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
    echo "  git clone https://github.com/julianobarbosa/zsh ~/.local/bin/zsh-tool"
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
