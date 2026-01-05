#!/usr/bin/env zsh
# Story 2.2: Oh My Zsh Update
# Update Oh My Zsh framework

OMZ_INSTALL_DIR="${HOME}/.oh-my-zsh"

# Get current Oh My Zsh version (use subshell to avoid cd pollution)
_zsh_tool_get_omz_version() {
  if [[ ! -d "$OMZ_INSTALL_DIR" ]]; then
    echo "not-installed"
    return 1
  fi

  (
    cd "$OMZ_INSTALL_DIR" || exit 1
    git rev-parse --short HEAD 2>/dev/null || echo "unknown"
  )
}

# Check for Oh My Zsh updates (use subshell to avoid cd pollution)
_zsh_tool_check_omz_updates() {
  if [[ ! -d "$OMZ_INSTALL_DIR" ]]; then
    _zsh_tool_log WARN "Oh My Zsh not installed"
    return 1
  fi

  _zsh_tool_log INFO "Checking Oh My Zsh updates..."

  local check_result
  check_result=$(
    cd "$OMZ_INSTALL_DIR" || { echo "cd_failed"; exit 1; }

    # Fetch latest changes
    git fetch origin 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    local fetch_status=${pipestatus[1]}

    if [[ $fetch_status -ne 0 ]]; then
      echo "fetch_failed"
      exit 1
    fi

    # Check if updates available
    local current_sha=$(git rev-parse HEAD 2>/dev/null)
    local remote_sha=$(git rev-parse origin/master 2>/dev/null)

    if [[ "$current_sha" == "$remote_sha" ]]; then
      echo "no_updates"
    else
      echo "updates_available"
    fi
  )

  case "$check_result" in
    cd_failed|fetch_failed)
      _zsh_tool_log WARN "Failed to fetch Oh My Zsh updates"
      return 1
      ;;
    no_updates)
      return 1  # No updates
      ;;
    updates_available)
      return 0  # Updates available
      ;;
    *)
      return 1
      ;;
  esac
}

# Update Oh My Zsh (use subshell to avoid cd pollution)
_zsh_tool_update_omz() {
  if [[ ! -d "$OMZ_INSTALL_DIR" ]]; then
    _zsh_tool_log ERROR "Oh My Zsh not installed"
    return 1
  fi

  _zsh_tool_log INFO "Updating Oh My Zsh..."

  local current_version=$(_zsh_tool_get_omz_version)

  # Use subshell for git operations
  local update_result
  update_result=$(
    cd "$OMZ_INSTALL_DIR" || { echo "cd_failed"; exit 1; }

    # Pull latest changes
    git pull origin master 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    local pull_status=${pipestatus[1]}

    if [[ $pull_status -ne 0 ]]; then
      echo "pull_failed"
      exit 1
    fi

    echo "success"
  )

  if [[ "$update_result" != "success" ]]; then
    _zsh_tool_log ERROR "Failed to update Oh My Zsh"
    return 1
  fi

  local new_version=$(_zsh_tool_get_omz_version)
  local commit_count=$(
    cd "$OMZ_INSTALL_DIR" && git rev-list ${current_version}..${new_version} --count 2>/dev/null || echo "0"
  )

  _zsh_tool_log INFO "✓ Oh My Zsh updated (${current_version} → ${new_version}, ${commit_count} commits)"

  # Update state
  _zsh_tool_update_state "omz.version" "\"master-${new_version}\""
  _zsh_tool_update_state "omz.last_update" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  return 0
}
