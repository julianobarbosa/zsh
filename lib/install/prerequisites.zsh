#!/usr/bin/env zsh
# Story 1.1: Prerequisite Detection and Installation
# Detect and install Homebrew, git, Xcode CLI tools

# Check if Homebrew is installed
_zsh_tool_check_homebrew() {
  if _zsh_tool_is_installed brew; then
    local version=$(brew --version | head -1 | awk '{print $2}')
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
  local pre_install_state=$(_zsh_tool_load_state)

  if ! _zsh_tool_prompt_confirm "Install Homebrew now?"; then
    _zsh_tool_log error "Homebrew is required. Installation aborted."
    return 1
  fi

  # Run official Homebrew install script
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
    local version=$(git --version | awk '{print $3}')
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
  local pre_install_state=$(_zsh_tool_load_state)

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

    _zsh_tool_log error "Please try: brew install git manually"
    return 1
  fi
}

# Check if Xcode Command Line Tools are installed
_zsh_tool_check_xcode_cli() {
  if xcode-select -p >/dev/null 2>&1; then
    local path=$(xcode-select -p)
    _zsh_tool_log info "Xcode Command Line Tools found at $path"
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
    local version=$(jq --version 2>/dev/null)
    _zsh_tool_log info "$version already installed"
    return 0
  else
    _zsh_tool_log warn "jq not found"
    return 1
  fi
}

# Install jq via Homebrew
_zsh_tool_install_jq() {
  _zsh_tool_log info "jq is recommended for safe JSON state manipulation"

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
    return 1
  fi
}

# Main prerequisite check and install
_zsh_tool_check_prerequisites() {
  _zsh_tool_log info "Checking prerequisites..."

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
      _zsh_tool_log error "Homebrew required to install git"
      return 1
    fi

    _zsh_tool_install_git || return 1
  fi

  # Check jq (optional - enhances state management)
  if ! _zsh_tool_check_jq; then
    jq_needed=true
    _zsh_tool_install_jq || {
      _zsh_tool_log warn "Continuing without jq - using fallback state management"
    }
  fi

  # Check Xcode CLI (optional)
  if ! _zsh_tool_check_xcode_cli; then
    _zsh_tool_install_xcode_cli
  fi

  # Update state with prerequisites status
  local jq_installed=$(command -v jq >/dev/null 2>&1 && echo "true" || echo "false")
  local xcode_installed=$(xcode-select -p >/dev/null 2>&1 && echo "true" || echo "false")

  if command -v jq >/dev/null 2>&1; then
    # Safe JSON manipulation with jq
    local state=$(_zsh_tool_load_state)
    local updated_state=$(echo "$state" | jq --argjson hb true --argjson git true \
      --argjson jq "$jq_installed" --argjson xcode "$xcode_installed" \
      '. + {prerequisites: {homebrew: $hb, git: $git, jq: $jq, xcode_cli: $xcode}}')
    _zsh_tool_save_state "$updated_state"
  else
    # Fallback: Use jq-like merge pattern with sed
    _zsh_tool_log warn "jq not available - using sed-based state update"
    local state=$(_zsh_tool_load_state)

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

    _zsh_tool_save_state "$state"
  fi

  _zsh_tool_log info "✓ Prerequisites check complete"
  return 0
}
