#!/usr/bin/env zsh
# Amazon Q Developer CLI Integration
# Manages installation, configuration, and integration with zsh

# Amazon Q CLI configuration
AMAZONQ_CONFIG_DIR="${HOME}/.aws/amazonq"
AMAZONQ_SETTINGS_FILE="${AMAZONQ_CONFIG_DIR}/settings.json"
AMAZONQ_APP_PATH="/Applications/Amazon Q.app"

# Check if Amazon Q CLI is installed
_amazonq_is_installed() {
  _zsh_tool_is_installed "q"
}

# Detect Amazon Q installation
_amazonq_detect() {
  _zsh_tool_log INFO "Detecting Amazon Q CLI installation..."

  if _amazonq_is_installed; then
    local version=$(q --version 2>/dev/null | head -n1)
    _zsh_tool_log INFO "✓ Amazon Q CLI detected: $version"
    return 0
  else
    _zsh_tool_log INFO "Amazon Q CLI not found"
    return 1
  fi
}

# Guide user through Amazon Q installation
_amazonq_install() {
  _zsh_tool_log INFO "Amazon Q CLI installation required"

  # Check if already installed
  if _amazonq_is_installed; then
    _zsh_tool_log INFO "✓ Amazon Q CLI already installed"
    return 0
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Amazon Q CLI Installation Guide"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Amazon Q Developer CLI provides AI-powered command completions"
  echo "and inline suggestions for your terminal."
  echo ""
  echo "Installation steps:"
  echo "  1. Visit: https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing.html"
  echo "  2. Download Amazon Q for macOS (.dmg file)"
  echo "  3. Install the application"
  echo "  4. Launch Amazon Q and follow setup wizard"
  echo "  5. Enable shell integrations when prompted"
  echo "  6. Grant macOS accessibility permissions if requested"
  echo ""
  echo "Alternatively, you can install via Homebrew (if available):"
  echo "  brew install --cask amazon-q"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if _zsh_tool_prompt_confirm "Have you installed Amazon Q CLI?"; then
    if _amazonq_is_installed; then
      _zsh_tool_log INFO "✓ Amazon Q CLI installation verified"
      return 0
    else
      _zsh_tool_log WARN "Amazon Q CLI 'q' command not found in PATH"
      _zsh_tool_log WARN "Try reloading your shell: exec zsh"
      return 1
    fi
  else
    _zsh_tool_log WARN "Amazon Q CLI installation skipped"
    return 1
  fi
}

# Configure shell integration for zsh
_amazonq_configure_shell_integration() {
  _zsh_tool_log INFO "Configuring Amazon Q shell integration for zsh..."

  # Check if Amazon Q is installed
  if ! _amazonq_is_installed; then
    _zsh_tool_log ERROR "Amazon Q CLI must be installed first"
    return 1
  fi

  # Check if shell integration is already configured
  if [[ -f "${HOME}/.zshrc" ]] && grep -q "Amazon Q post block" "${HOME}/.zshrc"; then
    _zsh_tool_log INFO "✓ Amazon Q shell integration already configured"
    return 0
  fi

  # Amazon Q typically adds integration automatically during installation
  # If not present, guide user to run initialization
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Amazon Q Shell Integration Setup"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Shell integration may need manual setup."
  echo ""
  echo "To initialize Amazon Q shell integration:"
  echo "  1. Open Amazon Q application"
  echo "  2. Go to Settings/Preferences"
  echo "  3. Enable 'Shell Integration' for zsh"
  echo "  4. Reload your shell: exec zsh"
  echo ""
  echo "Or run the shell integration command manually:"
  echo "  q init zsh >> ~/.zshrc"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  _zsh_tool_log INFO "✓ Shell integration guidance provided"
  return 0
}

# Run Amazon Q health check
_amazonq_health_check() {
  _zsh_tool_log INFO "Running Amazon Q health check..."

  if ! _amazonq_is_installed; then
    _zsh_tool_log ERROR "Amazon Q CLI not installed"
    return 1
  fi

  echo ""
  echo "Running 'q doctor' to check Amazon Q configuration..."
  echo ""

  # Run q doctor
  q doctor
  local exit_code=$?

  echo ""

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Amazon Q health check passed"
    return 0
  else
    _zsh_tool_log WARN "Amazon Q health check reported issues"
    _zsh_tool_log INFO "Review output above and fix any reported problems"
    return 1
  fi
}

# Configure Amazon Q settings file
_amazonq_configure_settings() {
  local disabled_clis=("$@")

  _zsh_tool_log INFO "Configuring Amazon Q settings..."

  # Ensure config directory exists
  mkdir -p "$AMAZONQ_CONFIG_DIR"

  # Create or update settings.json
  local settings_content='{"disabledClis":[]}'

  if [[ -f "$AMAZONQ_SETTINGS_FILE" ]]; then
    settings_content=$(cat "$AMAZONQ_SETTINGS_FILE")
  fi

  # Add disabled CLIs (simple append, would need jq for proper JSON manipulation)
  if [[ ${#disabled_clis[@]} -gt 0 ]]; then
    local disabled_list=$(printf ',"%s"' "${disabled_clis[@]}")
    disabled_list="[${disabled_list:1}]"  # Remove leading comma

    # Simple JSON update (for production, use jq)
    settings_content=$(echo "$settings_content" | sed "s/\"disabledClis\":\[.*\]/\"disabledClis\":${disabled_list}/")
  fi

  echo "$settings_content" > "$AMAZONQ_SETTINGS_FILE"

  _zsh_tool_log INFO "✓ Amazon Q settings configured"
  _zsh_tool_log DEBUG "Disabled CLIs: ${disabled_clis[*]}"

  return 0
}

# Configure Atuin compatibility
_amazonq_configure_atuin_compatibility() {
  _zsh_tool_log INFO "Configuring Amazon Q compatibility with Atuin..."

  # Add atuin to disabled CLIs list
  _amazonq_configure_settings "atuin"

  _zsh_tool_log INFO "✓ Atuin added to Amazon Q disabled CLIs"
  _zsh_tool_log INFO "Note: You may need to restart Amazon Q for changes to take effect"

  return 0
}

# Setup lazy loading for Amazon Q (performance optimization)
_amazonq_setup_lazy_loading() {
  _zsh_tool_log INFO "Setting up lazy loading for Amazon Q..."

  local zshrc="${HOME}/.zshrc"
  local lazy_load_marker="# Amazon Q lazy loading (zsh-tool)"

  # Check if already configured
  if grep -q "$lazy_load_marker" "$zshrc" 2>/dev/null; then
    _zsh_tool_log INFO "✓ Lazy loading already configured"
    return 0
  fi

  # Create lazy loading wrapper
  cat >> "$zshrc" << 'EOF'

# Amazon Q lazy loading (zsh-tool)
# Defers Amazon Q initialization until first use to improve shell startup time
_amazonq_lazy_init() {
  # Remove lazy loading hooks
  unfunction q 2>/dev/null

  # Source Amazon Q integration (typically added by installer)
  if [[ -f "${HOME}/.aws/amazonq/shell/zshrc" ]]; then
    source "${HOME}/.aws/amazonq/shell/zshrc"
  fi

  # Execute the original command
  q "$@"
}

# Alias q to lazy init function
alias q='_amazonq_lazy_init'

EOF

  _zsh_tool_log INFO "✓ Lazy loading configured"
  _zsh_tool_log INFO "Amazon Q will initialize on first 'q' command use"

  return 0
}

# Main installation flow for Amazon Q integration
amazonq_install_integration() {
  local enable_lazy_loading="${1:-false}"
  local configure_atuin="${2:-false}"

  _zsh_tool_log INFO "Starting Amazon Q CLI integration..."

  # Step 1: Detect or install
  if ! _amazonq_detect; then
    if ! _amazonq_install; then
      _zsh_tool_log ERROR "Amazon Q installation required but not completed"
      return 1
    fi
  fi

  # Step 2: Configure shell integration
  _amazonq_configure_shell_integration

  # Step 3: Configure Atuin compatibility if requested
  if [[ "$configure_atuin" == "true" ]]; then
    _amazonq_configure_atuin_compatibility
  fi

  # Step 4: Setup lazy loading if requested
  if [[ "$enable_lazy_loading" == "true" ]]; then
    _amazonq_setup_lazy_loading
  fi

  # Step 5: Health check
  _amazonq_health_check

  _zsh_tool_log INFO "✓ Amazon Q CLI integration complete"

  return 0
}

# Expose main function
_amazonq_install_integration() {
  amazonq_install_integration "$@"
}
