#!/usr/bin/env zsh
# Amazon Q Developer CLI Integration
# Manages installation, configuration, and integration with zsh

# Amazon Q CLI configuration
# These paths match Amazon Q's default installation locations on macOS
# Can be overridden by setting these variables before sourcing this file
AMAZONQ_CONFIG_DIR="${AMAZONQ_CONFIG_DIR:-${HOME}/.aws/amazonq}"
AMAZONQ_SETTINGS_FILE="${AMAZONQ_SETTINGS_FILE:-${AMAZONQ_CONFIG_DIR}/settings.json}"
AMAZONQ_APP_PATH="${AMAZONQ_APP_PATH:-/Applications/Amazon Q.app}"

# Check if Amazon Q CLI is installed
# Validates both command existence AND that it's actually Amazon Q (not another 'q' command)
_amazonq_is_installed() {
  # First check if 'q' command exists
  if ! _zsh_tool_is_installed "q"; then
    return 1
  fi

  # Verify it's actually Amazon Q by checking version output
  # Amazon Q version format: "Amazon Q Developer CLI vX.X.X" or similar
  local version_output=$(q --version 2>/dev/null | head -n1)

  # Check for Amazon Q identifiers in version string
  if [[ "$version_output" =~ [Aa]mazon.*[Qq] ]] || \
     [[ "$version_output" =~ "AWS Q" ]] || \
     [[ "$version_output" =~ "q-cli" ]]; then
    return 0
  fi

  # Also check if the q binary is from Amazon Q app bundle
  local q_path=$(command -v q 2>/dev/null)
  if [[ "$q_path" =~ "Amazon Q" ]] || [[ "$q_path" =~ "amazonq" ]]; then
    return 0
  fi

  # Not Amazon Q - some other 'q' command
  return 1
}

# Detect Amazon Q installation
_amazonq_detect() {
  _zsh_tool_log INFO "Detecting Amazon Q CLI installation..."

  if _amazonq_is_installed; then
    # Extract first line only as version output may include additional info
    local version=$(q --version 2>/dev/null | head -n1)
    _zsh_tool_log INFO "✓ Amazon Q CLI detected: $version"
    return 0
  else
    # Check if there's a different 'q' command that's not Amazon Q
    if _zsh_tool_is_installed "q"; then
      local other_q=$(q --version 2>/dev/null | head -n1)
      _zsh_tool_log WARN "Found 'q' command but it's not Amazon Q: $other_q"
      _zsh_tool_log INFO "Amazon Q CLI needs to be installed separately"
    else
      _zsh_tool_log INFO "Amazon Q CLI not found"
    fi
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

  # Initial installation check
  if ! _amazonq_is_installed; then
    _zsh_tool_log ERROR "Amazon Q CLI not installed"
    return 1
  fi

  # Verify q command is available before execution
  if ! command -v q >/dev/null 2>&1; then
    _zsh_tool_log ERROR "Amazon Q command 'q' not found in PATH"
    _zsh_tool_log ERROR "Current PATH: $PATH"
    _zsh_tool_log ERROR "Try reloading your shell: exec zsh"
    _zsh_tool_log ERROR "Or reinstall Amazon Q"
    return 1
  fi

  # Verify q is executable
  local q_path=$(command -v q)
  if [[ ! -x "$q_path" ]]; then
    _zsh_tool_log ERROR "Amazon Q command is not executable: $q_path"
    _zsh_tool_log ERROR "Fix with: chmod +x $q_path"
    return 1
  fi

  echo ""
  echo "Running 'q doctor' to check Amazon Q configuration..."
  echo ""

  # Run q doctor with proper error handling
  if ! q doctor; then
    echo ""
    _zsh_tool_log WARN "Amazon Q health check reported issues"
    _zsh_tool_log INFO "Review output above and fix any reported problems"
    return 1
  fi

  echo ""
  _zsh_tool_log INFO "✓ Amazon Q health check passed"
  return 0
}

# Validate CLI name for security
_amazonq_validate_cli_name() {
  local cli_name="$1"

  # Check for empty
  if [[ -z "$cli_name" ]]; then
    _zsh_tool_log ERROR "CLI name cannot be empty"
    return 1
  fi

  # Check length (max 64 characters)
  if [[ ${#cli_name} -gt 64 ]]; then
    _zsh_tool_log ERROR "CLI name too long: '$cli_name' (max 64 characters)"
    return 1
  fi

  # Check pattern: only alphanumeric, hyphen, and underscore allowed
  if [[ ! "$cli_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    _zsh_tool_log ERROR "Invalid CLI name: '$cli_name'"
    _zsh_tool_log ERROR "Only alphanumeric characters, hyphens, and underscores are allowed"
    return 1
  fi

  return 0
}

# Configure Amazon Q settings file
_amazonq_configure_settings() {
  local disabled_clis=("$@")
  local temp_file=""
  local _cleanup_temp() {
    [[ -n "$temp_file" && -f "$temp_file" ]] && rm -f "$temp_file" 2>/dev/null
  }

  _zsh_tool_log INFO "Configuring Amazon Q settings..."

  # Validate all CLI names first
  for cli in "${disabled_clis[@]}"; do
    if ! _amazonq_validate_cli_name "$cli"; then
      return 1
    fi
  done

  # Check if jq is available for safe JSON manipulation
  if ! command -v jq >/dev/null 2>&1; then
    _zsh_tool_log ERROR "jq is required for safe JSON manipulation"
    _zsh_tool_log ERROR "Install with: brew install jq"
    return 1
  fi

  # Ensure config directory exists with error checking
  if ! mkdir -p "$AMAZONQ_CONFIG_DIR" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to create config directory: $AMAZONQ_CONFIG_DIR"
    _zsh_tool_log ERROR "Check parent directory permissions and disk space"
    return 1
  fi

  # Verify directory was created and is writable
  if [[ ! -d "$AMAZONQ_CONFIG_DIR" ]]; then
    _zsh_tool_log ERROR "Config directory not found after creation: $AMAZONQ_CONFIG_DIR"
    return 1
  fi

  if [[ ! -w "$AMAZONQ_CONFIG_DIR" ]]; then
    _zsh_tool_log ERROR "Config directory not writable: $AMAZONQ_CONFIG_DIR"
    _zsh_tool_log ERROR "Check directory permissions"
    return 1
  fi

  # Clean up any orphaned temp files from previous failed runs
  # Use setopt nullglob to avoid "no matches found" error if no temp files exist
  setopt local_options nullglob
  rm -f "${AMAZONQ_SETTINGS_FILE}".tmp.* 2>/dev/null

  # Initialize settings file if it doesn't exist or has invalid JSON
  if [[ ! -f "$AMAZONQ_SETTINGS_FILE" ]]; then
    # Use umask 077 to ensure settings file is not world-readable (security best practice)
    if ! (umask 077; echo '{"disabledClis":[]}' > "$AMAZONQ_SETTINGS_FILE") 2>/dev/null; then
      _zsh_tool_log ERROR "Failed to create settings file: $AMAZONQ_SETTINGS_FILE"
      return 1
    fi
  else
    # Validate existing JSON file
    if ! jq empty "$AMAZONQ_SETTINGS_FILE" 2>/dev/null; then
      _zsh_tool_log WARN "Settings file contains invalid JSON, recreating..."
      # Use umask 077 to ensure settings file is not world-readable (security best practice)
      if ! (umask 077; echo '{"disabledClis":[]}' > "$AMAZONQ_SETTINGS_FILE") 2>/dev/null; then
        _zsh_tool_log ERROR "Failed to recreate settings file: $AMAZONQ_SETTINGS_FILE"
        return 1
      fi
    fi
  fi

  # Build jq array from disabled_clis using safe method
  local jq_array="[]"
  if [[ ${#disabled_clis[@]} -gt 0 ]]; then
    jq_array=$(printf '%s\n' "${disabled_clis[@]}" | jq -R . | jq -s .)
  fi

  # Update settings file using jq (safe JSON manipulation)
  # Use PID + RANDOM + timestamp for unique temp file (handles concurrent subshells)
  temp_file="${AMAZONQ_SETTINGS_FILE}.tmp.$$.$RANDOM.$(date +%s%N 2>/dev/null || date +%s)"

  # Set up trap for cleanup on interrupt/error
  trap '_cleanup_temp' INT TERM

  if ! jq ".disabledClis = $jq_array" "$AMAZONQ_SETTINGS_FILE" > "$temp_file" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to update settings with jq"
    _cleanup_temp
    trap - INT TERM
    return 1
  fi

  # Verify temp file was created and has content
  if [[ ! -f "$temp_file" ]] || [[ ! -s "$temp_file" ]]; then
    _zsh_tool_log ERROR "Temporary settings file creation failed"
    _cleanup_temp
    trap - INT TERM
    return 1
  fi

  # Atomic move
  if ! mv "$temp_file" "$AMAZONQ_SETTINGS_FILE" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to move settings file into place"
    _cleanup_temp
    trap - INT TERM
    return 1
  fi

  # Clear trap after successful completion
  trap - INT TERM

  _zsh_tool_log INFO "✓ Amazon Q settings configured"
  _zsh_tool_log DEBUG "Settings file: $AMAZONQ_SETTINGS_FILE"
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

  # Verify .zshrc exists
  if [[ ! -f "$zshrc" ]]; then
    _zsh_tool_log ERROR ".zshrc not found: $zshrc"
    return 1
  fi

  # Check if .zshrc is a symlink and warn user
  if [[ -L "$zshrc" ]]; then
    local link_target=$(readlink "$zshrc")
    _zsh_tool_log WARN ".zshrc is a symlink: $zshrc -> $link_target"
    _zsh_tool_log WARN "Modifying symlinked configuration may affect other systems"

    # In non-interactive mode or if prompt function doesn't exist, continue anyway
    if type _zsh_tool_prompt_confirm >/dev/null 2>&1; then
      if ! _zsh_tool_prompt_confirm "Continue anyway?"; then
        _zsh_tool_log INFO "Lazy loading setup skipped"
        return 1
      fi
    else
      _zsh_tool_log WARN "Continuing with symlinked .zshrc (non-interactive mode)"
    fi
  fi

  # Check if already configured
  if grep -q "$lazy_load_marker" "$zshrc" 2>/dev/null; then
    _zsh_tool_log INFO "✓ Lazy loading already configured"
    return 0
  fi

  # Create backup with timestamp
  local backup="${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"
  if ! cp "$zshrc" "$backup" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to create backup: $backup"
    _zsh_tool_log ERROR "Aborting to avoid data loss"
    return 1
  fi
  _zsh_tool_log INFO "Created backup: $backup"

  # Append lazy loading code with error checking
  if ! cat >> "$zshrc" << 'EOF'

# Amazon Q lazy loading (zsh-tool)
# Defers Amazon Q initialization until first use to improve shell startup time
_amazonq_lazy_init() {
  # Remove the alias to prevent recursion
  unalias q 2>/dev/null

  # Remove this lazy init function
  unfunction _amazonq_lazy_init 2>/dev/null

  # Source Amazon Q integration (typically added by installer)
  # This will define the real 'q' function
  if [[ -f "${HOME}/.aws/amazonq/shell/zshrc" ]]; then
    source "${HOME}/.aws/amazonq/shell/zshrc"
  fi

  # Execute the command with the real q function (now defined by Amazon Q)
  # Use 'command' to ensure we bypass any remaining aliases
  if type q &>/dev/null; then
    q "$@"
  else
    echo "Amazon Q integration not found or failed to load" >&2
    return 1
  fi
}

# Create alias that will be replaced after first use
alias q='_amazonq_lazy_init'

EOF
  then
    _zsh_tool_log ERROR "Failed to append lazy loading code to .zshrc"
    _zsh_tool_log INFO "Restoring from backup..."
    if mv "$backup" "$zshrc" 2>/dev/null; then
      _zsh_tool_log INFO "✓ Restored from backup"
    else
      _zsh_tool_log ERROR "Failed to restore backup - manual recovery may be needed"
      _zsh_tool_log ERROR "Backup location: $backup"
    fi
    return 1
  fi

  # Verify the marker was added
  if ! grep -q "$lazy_load_marker" "$zshrc" 2>/dev/null; then
    _zsh_tool_log ERROR "Lazy loading marker not found after append"
    _zsh_tool_log INFO "Restoring from backup..."
    mv "$backup" "$zshrc" 2>/dev/null
    return 1
  fi

  _zsh_tool_log INFO "✓ Lazy loading configured"
  _zsh_tool_log INFO "Amazon Q will initialize on first 'q' command use"
  _zsh_tool_log DEBUG "Backup saved at: $backup"

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
  if ! _amazonq_health_check; then
    _zsh_tool_log ERROR "Amazon Q health check failed"
    _zsh_tool_log ERROR "Installation incomplete - please address issues and retry"
    _zsh_tool_log INFO "Run 'zsh-tool-amazonq health' to diagnose issues"
    return 1
  fi

  _zsh_tool_log INFO "✓ Amazon Q CLI integration complete"

  return 0
}

# Alias for consistency with naming convention
# Both amazonq_install_integration and _amazonq_install_integration are available
alias _amazonq_install_integration='amazonq_install_integration'
