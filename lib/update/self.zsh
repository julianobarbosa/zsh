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

# Create backup before update with timestamped directory
_zsh_tool_backup_before_update() {
  local backup_reason="${1:-update}"
  local timestamp=$(date '+%Y-%m-%d-%H%M%S')
  local backup_dir="${ZSH_TOOL_CONFIG_DIR}/backups/backup-${timestamp}"

  _zsh_tool_log INFO "Creating backup: ${backup_dir}"

  # Create backup directory
  mkdir -p "$backup_dir"

  # If create_backup function exists (from backup.zsh), use it
  if type _zsh_tool_create_backup &>/dev/null; then
    _zsh_tool_create_backup "$backup_reason"
    return $?
  fi

  # Otherwise, simple file copy
  if [[ -d "$ZSH_TOOL_INSTALL_DIR" ]]; then
    cp -R "$ZSH_TOOL_INSTALL_DIR"/* "$backup_dir/" 2>/dev/null || {
      _zsh_tool_log ERROR "Backup failed"
      return 1
    }
    _zsh_tool_log INFO "Backup created successfully"
    return 0
  fi

  return 1
}

# Display changelog between versions
_zsh_tool_display_changelog() {
  if ! _zsh_tool_is_git_repo; then
    return 1
  fi

  cd "$ZSH_TOOL_INSTALL_DIR"

  local current_version=$(_zsh_tool_get_current_version)
  local remote_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo "main")
  local new_version=$(git describe --tags origin/$remote_branch 2>/dev/null || git rev-parse --short origin/$remote_branch 2>/dev/null)

  echo ""
  echo "Updates available:"
  echo ""

  # Show commits between current and remote
  git log HEAD..origin/$remote_branch --oneline --no-decorate 2>/dev/null | while read line; do
    echo "  - $line"
  done

  echo ""
  echo "Current version: $current_version"
  echo "New version: $new_version"
  echo ""

  cd - >/dev/null
}

# Apply update (git pull)
_zsh_tool_apply_update() {
  if ! _zsh_tool_is_git_repo; then
    _zsh_tool_log ERROR "Tool not installed as git repository, cannot update"
    return 1
  fi

  _zsh_tool_log INFO "Applying update..."

  # Create backup before update
  _zsh_tool_create_backup "pre-update" || {
    _zsh_tool_log ERROR "Backup failed, aborting update"
    return 1
  }

  cd "$ZSH_TOOL_INSTALL_DIR"

  local current_sha=$(git rev-parse HEAD)
  local remote_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo "main")

  # Pull latest changes
  git pull origin $remote_branch 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local pull_status=${pipestatus[1]}

  if [[ $pull_status -ne 0 ]]; then
    _zsh_tool_log ERROR "Update failed, rolling back..."
    git reset --hard $current_sha 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    cd - >/dev/null
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

  # If validation failed, rollback
  if [[ "$validation_failed" == true ]]; then
    _zsh_tool_log ERROR "Post-update validation failed, rolling back..."
    git reset --hard $current_sha 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    cd - >/dev/null
    return 1
  fi

  cd - >/dev/null

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

# Rollback to previous version
_zsh_tool_rollback_update() {
  local target_version="${1:-HEAD~1}"

  if ! _zsh_tool_is_git_repo; then
    _zsh_tool_log ERROR "Tool not installed as git repository, cannot rollback"
    return 1
  fi

  _zsh_tool_log INFO "Rolling back to: $target_version"

  cd "$ZSH_TOOL_INSTALL_DIR"

  git checkout "$target_version" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local checkout_status=${pipestatus[1]}

  cd - >/dev/null

  if [[ $checkout_status -eq 0 ]]; then
    local version=$(_zsh_tool_get_current_version)
    _zsh_tool_log INFO "✓ Rolled back to: $version"
    _zsh_tool_update_state "tool_version.current" "\"$version\""
    return 0
  else
    _zsh_tool_log ERROR "Rollback failed"
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
