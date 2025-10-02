#!/usr/bin/env zsh
# Oh My Zsh installation module
# Prerequisite for plugins and themes

OMZ_INSTALL_DIR="${HOME}/.oh-my-zsh"
OMZ_INSTALL_SCRIPT="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# Check if Oh My Zsh is installed
_zsh_tool_check_omz() {
  if [[ -d "$OMZ_INSTALL_DIR" && -f "${OMZ_INSTALL_DIR}/oh-my-zsh.sh" ]]; then
    local version=$(cd "$OMZ_INSTALL_DIR" && git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    _zsh_tool_log INFO "Oh My Zsh $version already installed"
    return 0
  else
    _zsh_tool_log WARN "Oh My Zsh not found"
    return 1
  fi
}

# Install Oh My Zsh
_zsh_tool_install_omz() {
  _zsh_tool_log INFO "Installing Oh My Zsh..."

  # Download and run official install script (unattended mode)
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL $OMZ_INSTALL_SCRIPT)"
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Oh My Zsh installed successfully"

    # Get version
    local version=$(cd "$OMZ_INSTALL_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    # Update state
    local state=$(_zsh_tool_load_state)
    state=$(echo "$state" | sed 's/}/,"omz":{"installed":true,"version":"'$version'","path":"'${OMZ_INSTALL_DIR//\//\\/}'"}}/')
    _zsh_tool_save_state "$state"

    return 0
  else
    _zsh_tool_log ERROR "Oh My Zsh installation failed"
    return 1
  fi
}

# Verify Oh My Zsh installation integrity
_zsh_tool_verify_omz() {
  if [[ ! -f "${OMZ_INSTALL_DIR}/oh-my-zsh.sh" ]]; then
    _zsh_tool_log ERROR "Oh My Zsh main script not found"
    return 1
  fi

  if [[ ! -d "${OMZ_INSTALL_DIR}/plugins" ]]; then
    _zsh_tool_log ERROR "Oh My Zsh plugins directory not found"
    return 1
  fi

  if [[ ! -d "${OMZ_INSTALL_DIR}/themes" ]]; then
    _zsh_tool_log ERROR "Oh My Zsh themes directory not found"
    return 1
  fi

  _zsh_tool_log DEBUG "Oh My Zsh installation verified"
  return 0
}

# Ensure Oh My Zsh is installed (install if missing)
_zsh_tool_ensure_omz() {
  if _zsh_tool_check_omz; then
    _zsh_tool_verify_omz || return 1
    return 0
  else
    _zsh_tool_install_omz || return 1
    return 0
  fi
}
