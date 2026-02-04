#!/usr/bin/env zsh
# Story 1.1: Prerequisite Detection and Installation
# Detect and install Homebrew, git, Xcode CLI tools

# shellcheck disable=SC2001
# SC2001: sed expressions are used intentionally for JSON manipulation fallback
# when jq is not available. See _zsh_tool_check_prerequisites() for details.

# Check if Homebrew is installed
_zsh_tool_check_homebrew() {
  if _zsh_tool_is_installed brew; then
    local version
    version=$(brew --version | head -1 | awk '{print $2}')
    _zsh_tool_log info "Homebrew $version already installed"
    return 0
  else
    _zsh_tool_log warn "Homebrew not found"
    return 1
  fi
}

# Install Homebrew with rollback support
_zsh_tool_install_homebrew() {
  _zsh_tool_log info "Installing Homebrew..."

  # Save pre-installation state for potential rollback
  local pre_install_state
  pre_install_state=$(_zsh_tool_load_state)

  if ! _zsh_tool_prompt_confirm "Install Homebrew now?"; then
    _zsh_tool_log error "Homebrew is required. Installation aborted."
    return 1
  fi

  # Run official Homebrew install script
  # First verify curl succeeds before passing to bash
  local install_script
  install_script=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
  if [[ -z "$install_script" ]]; then
    _zsh_tool_log error "Failed to download Homebrew install script (network error or empty response)"
    _zsh_tool_log info "Rolling back state changes..."
    _zsh_tool_save_state "$pre_install_state"
    _zsh_tool_log error "Please check your network connection and try again"
    return 1
  fi

  /bin/bash -c "$install_script"
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log info "Homebrew installed successfully"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    return 0
  else
    _zsh_tool_log error "Homebrew installation failed"
    _zsh_tool_log info "Rolling back state changes..."

    # Rollback: restore pre-installation state
    _zsh_tool_save_state "$pre_install_state"
    _zsh_tool_log info "State rolled back to pre-installation"

    _zsh_tool_log error "Please install manually: https://brew.sh"
    return 1
  fi
}

# Check if git is installed
_zsh_tool_check_git() {
  if _zsh_tool_is_installed git; then
    local version
    version=$(git --version | awk '{print $3}')
    _zsh_tool_log info "git $version already installed"
    return 0
  else
    _zsh_tool_log warn "git not found"
    return 1
  fi
}

# Install git via Homebrew with rollback support
_zsh_tool_install_git() {
  _zsh_tool_log info "Installing git..."

  # Save pre-installation state for potential rollback
  local pre_install_state
  pre_install_state=$(_zsh_tool_load_state)

  brew install git
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log info "git installed successfully"
    return 0
  else
    _zsh_tool_log error "git installation failed"
    _zsh_tool_log info "Rolling back state changes..."

    # Rollback: restore pre-installation state
    _zsh_tool_save_state "$pre_install_state"
    _zsh_tool_log info "State rolled back to pre-installation"

    _zsh_tool_log error "Please install manually: brew install git"
    return 1
  fi
}

# Check if Xcode Command Line Tools are installed
_zsh_tool_check_xcode_cli() {
  if xcode-select -p >/dev/null 2>&1; then
    local xcode_path
    xcode_path=$(xcode-select -p)
    _zsh_tool_log info "Xcode Command Line Tools found at $xcode_path"
    return 0
  else
    _zsh_tool_log warn "Xcode Command Line Tools not found"
    return 1
  fi
}

# Prompt to install Xcode CLI tools
_zsh_tool_install_xcode_cli() {
  _zsh_tool_log info "Xcode Command Line Tools are recommended but not required"
  _zsh_tool_log info "Git installed via Homebrew will work without them"

  if _zsh_tool_prompt_confirm "Install Xcode Command Line Tools now?"; then
    xcode-select --install
    _zsh_tool_log info "Follow the GUI prompts to complete installation"
    _zsh_tool_log info "You can continue with zsh-tool installation"
  fi

  return 0
}

# Check if jq is installed
_zsh_tool_check_jq() {
  if _zsh_tool_is_installed jq; then
    local version
    version=$(jq --version 2>/dev/null)
    _zsh_tool_log info "jq $version already installed"
    return 0
  else
    _zsh_tool_log warn "jq not found"
    return 1
  fi
}

# Install jq via Homebrew with rollback support
_zsh_tool_install_jq() {
  _zsh_tool_log info "jq is recommended for safe JSON state manipulation"

  # Save pre-installation state for potential rollback
  local pre_install_state
  pre_install_state=$(_zsh_tool_load_state)

  if ! _zsh_tool_prompt_confirm "Install jq now?"; then
    _zsh_tool_log warn "jq installation skipped"
    _zsh_tool_log warn "State updates will use fallback method without jq"
    return 1
  fi

  if ! _zsh_tool_is_installed brew; then
    _zsh_tool_log error "Homebrew required to install jq"
    return 1
  fi

  brew install jq
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log info "jq installed successfully"
    return 0
  else
    _zsh_tool_log error "jq installation failed"
    _zsh_tool_log info "Rolling back state changes..."

    # Rollback: restore pre-installation state
    _zsh_tool_save_state "$pre_install_state"
    _zsh_tool_log info "State rolled back to pre-installation"

    return 1
  fi
}

# Main prerequisite check and install
_zsh_tool_check_prerequisites() {
  _zsh_tool_log info "Checking prerequisites..."

  # Check Homebrew
  if ! _zsh_tool_check_homebrew; then
    _zsh_tool_install_homebrew || return 1
  fi

  # Check git
  if ! _zsh_tool_check_git; then
    if ! _zsh_tool_is_installed brew; then
      _zsh_tool_log error "Homebrew required to install git"
      return 1
    fi

    _zsh_tool_install_git || return 1
  fi

  # Check jq (optional - enhances state management)
  if ! _zsh_tool_check_jq; then
    _zsh_tool_install_jq || {
      _zsh_tool_log warn "Continuing without jq - using fallback state management"
    }
  fi

  # Check Xcode CLI (optional)
  if ! _zsh_tool_check_xcode_cli; then
    _zsh_tool_install_xcode_cli
  fi

  # Update state with prerequisites status
  local jq_installed xcode_installed
  jq_installed=$(command -v jq >/dev/null 2>&1 && echo "true" || echo "false")
  xcode_installed=$(xcode-select -p >/dev/null 2>&1 && echo "true" || echo "false")

  if command -v jq >/dev/null 2>&1; then
    # Safe JSON manipulation with jq
    local state updated_state
    state=$(_zsh_tool_load_state)

    # Validate state is valid JSON before attempting update
    if [[ -z "$state" ]] || ! echo "$state" | jq empty 2>/dev/null; then
      _zsh_tool_log warn "State file corrupted or empty, initializing fresh state"
      state='{"version":"1.0.0"}'
    fi

    updated_state=$(echo "$state" | jq --argjson hb true --argjson git true \
      --argjson jq "$jq_installed" --argjson xcode "$xcode_installed" \
      '. + {prerequisites: {homebrew: $hb, git: $git, jq: $jq, xcode_cli: $xcode}}' 2>/dev/null)

    # Verify jq produced valid output
    if [[ -z "$updated_state" ]] || ! echo "$updated_state" | jq empty 2>/dev/null; then
      _zsh_tool_log error "Failed to update state JSON, keeping original state"
    else
      _zsh_tool_save_state "$updated_state"
    fi
  else
    # Fallback: Use jq-like merge pattern with sed
    # WARNING: This sed-based JSON manipulation is fragile and assumes well-formed
    # JSON without nested objects in prerequisites. It handles simple key:value
    # pairs but may break with complex JSON structures. When possible, install jq
    # for robust JSON manipulation.
    _zsh_tool_log warn "jq not available - using sed-based state update"
    local state
    state=$(_zsh_tool_load_state)

    # If state is empty or malformed, create base structure
    if [[ -z "$state" ]] || ! echo "$state" | grep -q "prerequisites"; then
      state='{"prerequisites":{}}'
    fi

    # Update individual prerequisite fields using sed
    state=$(echo "$state" | sed 's/"homebrew":[^,}]*/"homebrew":true/')
    state=$(echo "$state" | sed 's/"git":[^,}]*/"git":true/')
    state=$(echo "$state" | sed 's/"jq":[^,}]*/"jq":'"${jq_installed}"'/')
    state=$(echo "$state" | sed 's/"xcode_cli":[^,}]*/"xcode_cli":'"${xcode_installed}"'/')

    # If fields don't exist, add them
    state=$(echo "$state" | sed 's/\("prerequisites":\s*{\)/\1"homebrew":true,"git":true,"jq":'"${jq_installed}"',"xcode_cli":'"${xcode_installed}"',/' | sed 's/,,/,/g' | sed 's/,}/}/g')

    # Basic validation: ensure state still looks like JSON before saving
    if [[ "$state" == "{"*"}" ]]; then
      _zsh_tool_save_state "$state"
    else
      _zsh_tool_log error "sed-based state update produced invalid JSON, state not saved"
    fi
  fi

  _zsh_tool_log info "✓ Prerequisites check complete"
  return 0
}
