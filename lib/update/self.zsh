#!/usr/bin/env zsh
# Story 2.1: Self-Update Mechanism
# Update the zsh-tool itself to the latest version

# Get tool installation directory
ZSH_TOOL_INSTALL_DIR="${ZSH_TOOL_INSTALL_DIR:-${HOME}/.local/bin/zsh-tool}"

# Check if tool is in a git repository
_zsh_tool_is_git_repo() {
  [[ -d "${ZSH_TOOL_INSTALL_DIR}/.git" ]]
}

# Get current version (git tag or commit SHA)
_zsh_tool_get_current_version() {
  if ! _zsh_tool_is_git_repo; then
    echo "unknown"
    return 1
  fi

  cd "$ZSH_TOOL_INSTALL_DIR"
  local version=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  cd - >/dev/null
  echo "$version"
}

# Check for available updates
_zsh_tool_check_for_updates() {
  if ! _zsh_tool_is_git_repo; then
    _zsh_tool_log WARN "Tool not installed as git repository, cannot check for updates"
    return 1
  fi

  _zsh_tool_log INFO "Checking for updates..."

  cd "$ZSH_TOOL_INSTALL_DIR"

  # Fetch latest changes
  git fetch origin 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local fetch_status=${PIPESTATUS[1]}

  if [[ $fetch_status -ne 0 ]]; then
    _zsh_tool_log WARN "Failed to fetch updates (network issue?)"
    cd - >/dev/null
    return 1
  fi

  # Compare local vs remote
  local current_sha=$(git rev-parse HEAD 2>/dev/null)
  local remote_sha=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)

  cd - >/dev/null

  if [[ "$current_sha" == "$remote_sha" ]]; then
    _zsh_tool_log INFO "✓ Tool is up to date"
    return 1  # No updates available
  else
    _zsh_tool_log INFO "Updates available!"
    return 0  # Updates available
  fi
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
  local pull_status=${PIPESTATUS[1]}

  if [[ $pull_status -ne 0 ]]; then
    _zsh_tool_log ERROR "Update failed, rolling back..."
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

  _zsh_tool_log INFO "✓ Update complete: $new_version"
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
  local checkout_status=${PIPESTATUS[1]}

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
