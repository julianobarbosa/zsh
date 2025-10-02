#!/usr/bin/env zsh
# Story 2.2: Oh My Zsh Update
# Update Oh My Zsh framework

OMZ_INSTALL_DIR="${HOME}/.oh-my-zsh"

# Get current Oh My Zsh version
_zsh_tool_get_omz_version() {
  if [[ ! -d "$OMZ_INSTALL_DIR" ]]; then
    echo "not-installed"
    return 1
  fi

  cd "$OMZ_INSTALL_DIR"
  local version=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  cd - >/dev/null
  echo "$version"
}

# Check for Oh My Zsh updates
_zsh_tool_check_omz_updates() {
  if [[ ! -d "$OMZ_INSTALL_DIR" ]]; then
    _zsh_tool_log WARN "Oh My Zsh not installed"
    return 1
  fi

  _zsh_tool_log INFO "Checking Oh My Zsh updates..."

  cd "$OMZ_INSTALL_DIR"

  # Fetch latest changes
  git fetch origin 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local fetch_status=${PIPESTATUS[1]}

  if [[ $fetch_status -ne 0 ]]; then
    _zsh_tool_log WARN "Failed to fetch Oh My Zsh updates"
    cd - >/dev/null
    return 1
  fi

  # Check if updates available
  local current_sha=$(git rev-parse HEAD 2>/dev/null)
  local remote_sha=$(git rev-parse origin/master 2>/dev/null)

  cd - >/dev/null

  if [[ "$current_sha" == "$remote_sha" ]]; then
    return 1  # No updates
  else
    return 0  # Updates available
  fi
}

# Update Oh My Zsh
_zsh_tool_update_omz() {
  if [[ ! -d "$OMZ_INSTALL_DIR" ]]; then
    _zsh_tool_log ERROR "Oh My Zsh not installed"
    return 1
  fi

  _zsh_tool_log INFO "Updating Oh My Zsh..."

  cd "$OMZ_INSTALL_DIR"

  local current_version=$(_zsh_tool_get_omz_version)

  # Pull latest changes
  git pull origin master 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local pull_status=${PIPESTATUS[1]}

  if [[ $pull_status -ne 0 ]]; then
    _zsh_tool_log ERROR "Failed to update Oh My Zsh"
    cd - >/dev/null
    return 1
  fi

  local new_version=$(_zsh_tool_get_omz_version)
  local commit_count=$(git rev-list ${current_version}..${new_version} --count 2>/dev/null || echo "0")

  cd - >/dev/null

  _zsh_tool_log INFO "✓ Oh My Zsh updated (${current_version} → ${new_version}, ${commit_count} commits)"

  # Update state
  _zsh_tool_update_state "omz.version" "\"master-${new_version}\""
  _zsh_tool_update_state "omz.last_update" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  return 0
}
