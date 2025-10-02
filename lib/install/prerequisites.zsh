#!/usr/bin/env zsh
# Story 1.1: Prerequisite Detection and Installation
# Detect and install Homebrew, git, Xcode CLI tools

# Check if Homebrew is installed
_zsh_tool_check_homebrew() {
  if _zsh_tool_is_installed brew; then
    local version=$(brew --version | head -1 | awk '{print $2}')
    _zsh_tool_log INFO "Homebrew $version already installed"
    return 0
  else
    _zsh_tool_log WARN "Homebrew not found"
    return 1
  fi
}

# Install Homebrew
_zsh_tool_install_homebrew() {
  _zsh_tool_log INFO "Installing Homebrew..."

  if ! _zsh_tool_prompt_confirm "Install Homebrew now?"; then
    _zsh_tool_log ERROR "Homebrew is required. Installation aborted."
    return 1
  fi

  # Run official Homebrew install script
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log INFO "Homebrew installed successfully"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    return 0
  else
    _zsh_tool_log ERROR "Homebrew installation failed"
    _zsh_tool_log ERROR "Please install manually: https://brew.sh"
    return 1
  fi
}

# Check if git is installed
_zsh_tool_check_git() {
  if _zsh_tool_is_installed git; then
    local version=$(git --version | awk '{print $3}')
    _zsh_tool_log INFO "git $version already installed"
    return 0
  else
    _zsh_tool_log WARN "git not found"
    return 1
  fi
}

# Install git via Homebrew
_zsh_tool_install_git() {
  _zsh_tool_log INFO "Installing git..."

  brew install git
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log INFO "git installed successfully"
    return 0
  else
    _zsh_tool_log ERROR "git installation failed"
    return 1
  fi
}

# Check if Xcode Command Line Tools are installed
_zsh_tool_check_xcode_cli() {
  if xcode-select -p >/dev/null 2>&1; then
    local path=$(xcode-select -p)
    _zsh_tool_log INFO "Xcode Command Line Tools found at $path"
    return 0
  else
    _zsh_tool_log WARN "Xcode Command Line Tools not found"
    return 1
  fi
}

# Prompt to install Xcode CLI tools
_zsh_tool_install_xcode_cli() {
  _zsh_tool_log INFO "Xcode Command Line Tools are recommended but not required"
  _zsh_tool_log INFO "Git installed via Homebrew will work without them"

  if _zsh_tool_prompt_confirm "Install Xcode Command Line Tools now?"; then
    xcode-select --install
    _zsh_tool_log INFO "Follow the GUI prompts to complete installation"
    _zsh_tool_log INFO "You can continue with zsh-tool installation"
  fi

  return 0
}

# Check if jq is installed
_zsh_tool_check_jq() {
  if _zsh_tool_is_installed jq; then
    local version=$(jq --version 2>/dev/null)
    _zsh_tool_log INFO "$version already installed"
    return 0
  else
    _zsh_tool_log WARN "jq not found"
    return 1
  fi
}

# Install jq via Homebrew
_zsh_tool_install_jq() {
  _zsh_tool_log INFO "jq is required for safe JSON manipulation in Amazon Q integration"

  if ! _zsh_tool_prompt_confirm "Install jq now?"; then
    _zsh_tool_log WARN "jq installation skipped"
    _zsh_tool_log WARN "Amazon Q integration may not work without jq"
    return 1
  fi

  if ! _zsh_tool_is_installed brew; then
    _zsh_tool_log ERROR "Homebrew required to install jq"
    return 1
  fi

  brew install jq
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log INFO "jq installed successfully"
    return 0
  else
    _zsh_tool_log ERROR "jq installation failed"
    return 1
  fi
}

# Main prerequisite check and install
_zsh_tool_check_prerequisites() {
  _zsh_tool_log INFO "Checking prerequisites..."

  local homebrew_needed=false
  local git_needed=false
  local jq_needed=false

  # Check Homebrew
  if ! _zsh_tool_check_homebrew; then
    homebrew_needed=true
    _zsh_tool_install_homebrew || return 1
  fi

  # Check git
  if ! _zsh_tool_check_git; then
    git_needed=true

    if ! _zsh_tool_is_installed brew; then
      _zsh_tool_log ERROR "Homebrew required to install git"
      return 1
    fi

    _zsh_tool_install_git || return 1
  fi

  # Check jq (required for Amazon Q integration)
  if ! _zsh_tool_check_jq; then
    jq_needed=true
    _zsh_tool_install_jq || {
      _zsh_tool_log WARN "Continuing without jq - Amazon Q integration will be limited"
    }
  fi

  # Check Xcode CLI (optional)
  if ! _zsh_tool_check_xcode_cli; then
    _zsh_tool_install_xcode_cli
  fi

  # Update state
  local state=$(_zsh_tool_load_state)
  state=$(echo "$state" | sed 's/}/,"prerequisites":{"homebrew":true,"git":true,"jq":'$(command -v jq >/dev/null 2>&1 && echo "true" || echo "false")',"xcode_cli":'$(xcode-select -p >/dev/null 2>&1 && echo "true" || echo "false")'}}/')
  _zsh_tool_save_state "$state"

  _zsh_tool_log INFO "✓ Prerequisites check complete"
  return 0
}
