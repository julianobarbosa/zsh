#!/usr/bin/env zsh
# Kiro CLI Integration
# Manages installation, configuration, and integration with zsh

# Kiro CLI configuration
# These paths match Kiro CLI's default installation locations on macOS
# Can be overridden by setting these variables before sourcing this file
KIRO_CONFIG_DIR="${KIRO_CONFIG_DIR:-${HOME}/.kiro}"
KIRO_SETTINGS_FILE="${KIRO_SETTINGS_FILE:-${KIRO_CONFIG_DIR}/settings/cli.json}"
KIRO_APP_PATH="${KIRO_APP_PATH:-/Applications/Kiro.app}"

# Check if Kiro CLI is installed
# Validates both command existence AND that it's actually Kiro CLI (not another 'kiro-cli' command)
_kiro_is_installed() {
  # First check if 'kiro-cli' command exists
  if _zsh_tool_is_installed "kiro-cli"; then
    return 0
  fi

  # Also check for 'q' command which is still supported
  if ! _zsh_tool_is_installed "q"; then
    return 1
  fi

  # Verify it's actually Kiro CLI by checking version output
  # Kiro CLI version format: "Kiro CLI vX.X.X" or similar
  local version_output
  version_output=$(q --version 2>/dev/null | head -n1)

  # Check for Kiro identifiers in version string
  # Also check for legacy Amazon Q branding for backwards compatibility
  if [[ "$version_output" =~ [Kk]iro ]] || \
     [[ "$version_output" =~ "kiro-cli" ]] || \
     [[ "$version_output" =~ [Aa]mazon.*[Qq] ]] || \
     [[ "$version_output" =~ "amazonq" ]]; then
    return 0
  fi

  # Also check if the q binary is from Kiro app bundle
  local q_path
  q_path=$(command -v q 2>/dev/null)
  if [[ "$q_path" =~ "Kiro" ]] || [[ "$q_path" =~ "kiro" ]]; then
    return 0
  fi

  # Not Kiro CLI - some other 'q' command
  return 1
}

# Detect Kiro CLI installation
_kiro_detect() {
  _zsh_tool_log INFO "Detecting Kiro CLI installation..."

  if _kiro_is_installed; then
    # Extract first line only as version output may include additional info
    local version_output
    if command -v kiro-cli >/dev/null 2>&1; then
      version_output=$(kiro-cli --version 2>/dev/null | head -n1)
    else
      version_output=$(q --version 2>/dev/null | head -n1)
    fi
    _zsh_tool_log INFO "Kiro CLI detected: $version_output"
    return 0
  else
    # Check if there's a different 'q' command that's not Kiro CLI
    if _zsh_tool_is_installed "q"; then
      local other_q
      other_q=$(q --version 2>/dev/null | head -n1)
      _zsh_tool_log WARN "Found 'q' command but it's not Kiro CLI: $other_q"
      _zsh_tool_log INFO "Kiro CLI needs to be installed separately"
    else
      _zsh_tool_log INFO "Kiro CLI not found"
    fi
    return 1
  fi
}

# Guide user through Kiro CLI installation
_kiro_install() {
  _zsh_tool_log INFO "Kiro CLI installation required"

  # Check if already installed
  if _kiro_is_installed; then
    _zsh_tool_log INFO "Kiro CLI already installed"
    return 0
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Kiro CLI Installation Guide"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Kiro CLI provides AI-powered command completions"
  echo "and inline suggestions for your terminal."
  echo ""
  echo "Installation options:"
  echo ""
  echo "  Option 1 - Homebrew (recommended):"
  echo "    brew install --cask kiro-cli"
  echo ""
  echo "  Option 2 - Direct install:"
  echo "    curl -fsSL https://cli.kiro.dev/install | bash"
  echo ""
  echo "  Option 3 - Manual download:"
  echo "    1. Visit: https://kiro.dev/docs/cli/"
  echo "    2. Download Kiro for macOS"
  echo "    3. Install the application"
  echo "    4. Launch Kiro and follow setup wizard"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if _zsh_tool_prompt_confirm "Have you installed Kiro CLI?"; then
    if _kiro_is_installed; then
      _zsh_tool_log INFO "Kiro CLI installation verified"
      return 0
    else
      _zsh_tool_log WARN "Kiro CLI command not found in PATH"
      _zsh_tool_log WARN "Try reloading your shell: exec zsh"
      return 1
    fi
  else
    _zsh_tool_log WARN "Kiro CLI installation skipped"
    return 1
  fi
}

# Configure shell integration for zsh
_kiro_configure_shell_integration() {
  _zsh_tool_log INFO "Configuring Kiro CLI shell integration for zsh..."

  # Check if Kiro CLI is installed
  if ! _kiro_is_installed; then
    _zsh_tool_log ERROR "Kiro CLI must be installed first"
    return 1
  fi

  # Check if shell integration is already configured
  if [[ -f "${HOME}/.zshrc" ]] && grep -q "Kiro.*block\|kiro.*block" "${HOME}/.zshrc"; then
    _zsh_tool_log INFO "Kiro CLI shell integration already configured"
    return 0
  fi

  # Kiro CLI typically adds integration automatically during installation
  # If not present, guide user to run initialization
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Kiro CLI Shell Integration Setup"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Shell integration may need manual setup."
  echo ""
  echo "To initialize Kiro CLI shell integration:"
  echo "  1. Open Kiro application"
  echo "  2. Go to Settings/Preferences"
  echo "  3. Enable 'Shell Integration' for zsh"
  echo "  4. Reload your shell: exec zsh"
  echo ""
  echo "Or run the shell integration command manually:"
  echo "  kiro-cli init zsh >> ~/.zshrc"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  _zsh_tool_log INFO "Shell integration guidance provided"
  return 0
}

# Run Kiro CLI health check
_kiro_health_check() {
  _zsh_tool_log INFO "Running Kiro CLI health check..."

  # Initial installation check
  if ! _kiro_is_installed; then
    _zsh_tool_log ERROR "Kiro CLI not installed"
    return 1
  fi

  # Determine which command to use
  local kiro_cmd="q"
  if command -v kiro-cli >/dev/null 2>&1; then
    kiro_cmd="kiro-cli"
  fi

  # Verify command is available before execution
  if ! command -v "$kiro_cmd" >/dev/null 2>&1; then
    _zsh_tool_log ERROR "Kiro CLI command '$kiro_cmd' not found in PATH"
    _zsh_tool_log ERROR "Current PATH: $PATH"
    _zsh_tool_log ERROR "Try reloading your shell: exec zsh"
    _zsh_tool_log ERROR "Or reinstall Kiro CLI"
    return 1
  fi

  # Verify command is executable
  local cmd_path
  cmd_path=$(command -v "$kiro_cmd")
  if [[ ! -x "$cmd_path" ]]; then
    _zsh_tool_log ERROR "Kiro CLI command is not executable: $cmd_path"
    _zsh_tool_log ERROR "Fix with: chmod +x $cmd_path"
    return 1
  fi

  echo ""
  echo "Running '$kiro_cmd doctor' to check Kiro CLI configuration..."
  echo ""

  # Run doctor with proper error handling
  if ! "$kiro_cmd" doctor; then
    echo ""
    _zsh_tool_log WARN "Kiro CLI health check reported issues"
    _zsh_tool_log INFO "Review output above and fix any reported problems"
    return 1
  fi

  echo ""
  _zsh_tool_log INFO "Kiro CLI health check passed"
  return 0
}

# Validate CLI name for security
_kiro_validate_cli_name() {
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

  # Check pattern: only ASCII alphanumeric, hyphen, and underscore allowed
  # First check for any non-ASCII characters (bytes > 127)
  if [[ "$cli_name" =~ [^[:ascii:]] ]] || [[ ! "$cli_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    _zsh_tool_log ERROR "Invalid CLI name: '$cli_name'"
    _zsh_tool_log ERROR "Only alphanumeric characters, hyphens, and underscores are allowed"
    return 1
  fi

  return 0
}

# Helper function for temp file cleanup (defined at module level for proper scoping)
_kiro_cleanup_temp_file() {
  local file="$1"
  [[ -n "$file" && -f "$file" ]] && rm -f "$file" 2>/dev/null
}

# Configure Kiro CLI settings file
_kiro_configure_settings() {
  local disabled_clis=("$@")
  local temp_file=""

  _zsh_tool_log INFO "Configuring Kiro CLI settings..."

  # Validate all CLI names first
  for cli in "${disabled_clis[@]}"; do
    if ! _kiro_validate_cli_name "$cli"; then
      return 1
    fi
  done

  # Check if jq is available for safe JSON manipulation
  if ! command -v jq >/dev/null 2>&1; then
    _zsh_tool_log ERROR "jq is required for safe JSON manipulation"
    _zsh_tool_log ERROR "Install with: brew install jq"
    return 1
  fi

  # Ensure settings directory exists with error checking
  local settings_dir="${KIRO_CONFIG_DIR}/settings"
  if ! (umask 077; mkdir -p "$settings_dir") 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to create settings directory: $settings_dir"
    _zsh_tool_log ERROR "Check parent directory permissions and disk space"
    return 1
  fi

  # Verify directory was created and is writable
  if [[ ! -d "$settings_dir" ]]; then
    _zsh_tool_log ERROR "Settings directory not found after creation: $settings_dir"
    return 1
  fi

  if [[ ! -w "$settings_dir" ]]; then
    _zsh_tool_log ERROR "Settings directory not writable: $settings_dir"
    _zsh_tool_log ERROR "Check directory permissions"
    return 1
  fi

  # Clean up any orphaned temp files from previous failed runs
  setopt local_options nullglob
  rm -f "${KIRO_SETTINGS_FILE}".tmp.* 2>/dev/null

  # Initialize settings file if it doesn't exist or has invalid JSON
  if [[ ! -f "$KIRO_SETTINGS_FILE" ]]; then
    if ! (umask 077; echo '{"disabledClis":[]}' > "$KIRO_SETTINGS_FILE") 2>/dev/null; then
      _zsh_tool_log ERROR "Failed to create settings file: $KIRO_SETTINGS_FILE"
      return 1
    fi
  else
    # Validate existing JSON file
    if ! jq empty "$KIRO_SETTINGS_FILE" 2>/dev/null; then
      _zsh_tool_log WARN "Settings file contains invalid JSON, recreating..."
      if ! (umask 077; echo '{"disabledClis":[]}' > "$KIRO_SETTINGS_FILE") 2>/dev/null; then
        _zsh_tool_log ERROR "Failed to recreate settings file: $KIRO_SETTINGS_FILE"
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
  temp_file="${KIRO_SETTINGS_FILE}.tmp.$$.$RANDOM.$(date +%s%N 2>/dev/null || date +%s)"

  # Set up trap for cleanup on interrupt/error/exit
  trap '_kiro_cleanup_temp_file "$temp_file"' INT TERM EXIT

  if ! (umask 077; jq ".disabledClis = $jq_array" "$KIRO_SETTINGS_FILE" > "$temp_file") 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to update settings with jq"
    _kiro_cleanup_temp_file "$temp_file"
    trap - INT TERM EXIT
    return 1
  fi

  # Verify temp file was created and has content
  if [[ ! -f "$temp_file" ]] || [[ ! -s "$temp_file" ]]; then
    _zsh_tool_log ERROR "Temporary settings file creation failed"
    _kiro_cleanup_temp_file "$temp_file"
    trap - INT TERM EXIT
    return 1
  fi

  # Atomic move
  if ! mv "$temp_file" "$KIRO_SETTINGS_FILE" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to move settings file into place"
    _kiro_cleanup_temp_file "$temp_file"
    trap - INT TERM EXIT
    return 1
  fi

  # Clear trap after successful completion (temp_file no longer exists after mv)
  trap - INT TERM EXIT

  _zsh_tool_log INFO "Kiro CLI settings configured"
  _zsh_tool_log DEBUG "Settings file: $KIRO_SETTINGS_FILE"
  _zsh_tool_log DEBUG "Disabled CLIs: ${disabled_clis[*]}"

  return 0
}

# Configure Atuin compatibility
_kiro_configure_atuin_compatibility() {
  _zsh_tool_log INFO "Configuring Kiro CLI compatibility with Atuin..."

  # Add atuin to disabled CLIs list
  _kiro_configure_settings "atuin"

  _zsh_tool_log INFO "Atuin added to Kiro CLI disabled CLIs"
  _zsh_tool_log INFO "Note: You may need to restart Kiro for changes to take effect"

  return 0
}

# Setup lazy loading for Kiro CLI (performance optimization)
_kiro_setup_lazy_loading() {
  _zsh_tool_log INFO "Setting up lazy loading for Kiro CLI..."

  local zshrc="${HOME}/.zshrc"
  local lazy_load_marker="# Kiro CLI lazy loading (zsh-tool)"

  # Verify .zshrc exists
  if [[ ! -f "$zshrc" ]]; then
    _zsh_tool_log ERROR ".zshrc not found: $zshrc"
    return 1
  fi

  # Check if .zshrc is a symlink and warn user
  if [[ -L "$zshrc" ]]; then
    local link_target
    link_target=$(readlink "$zshrc")
    _zsh_tool_log WARN ".zshrc is a symlink: $zshrc -> $link_target"
    _zsh_tool_log WARN "Modifying symlinked configuration may affect other systems"

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
    _zsh_tool_log INFO "Lazy loading already configured"
    return 0
  fi

  # Create backup with timestamp
  local backup
  backup="${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"
  if ! cp "$zshrc" "$backup" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to create backup: $backup"
    _zsh_tool_log ERROR "Aborting to avoid data loss"
    return 1
  fi
  _zsh_tool_log INFO "Created backup: $backup"

  # Append lazy loading code with error checking
  if ! cat >> "$zshrc" << 'EOF'

# Kiro CLI lazy loading (zsh-tool)
# Defers Kiro CLI initialization until first use to improve shell startup time
_kiro_lazy_init() {
  # Remove the aliases to prevent recursion
  unalias kiro-cli 2>/dev/null
  unalias q 2>/dev/null

  # Remove this lazy init function
  unfunction _kiro_lazy_init 2>/dev/null

  # Source Kiro CLI integration (typically added by installer)
  # Use KIRO_CONFIG_DIR if set, otherwise default to ~/.kiro
  local kiro_shell_rc="${KIRO_CONFIG_DIR:-${HOME}/.kiro}/shell/zshrc"
  if [[ -f "$kiro_shell_rc" ]]; then
    source "$kiro_shell_rc"
  fi

  # Execute the command with the real function (now defined by Kiro CLI)
  if type kiro-cli &>/dev/null; then
    kiro-cli "$@"
  elif type q &>/dev/null; then
    q "$@"
  else
    echo "Kiro CLI integration not found or failed to load" >&2
    return 1
  fi
}

# Create aliases that will be replaced after first use
alias kiro-cli='_kiro_lazy_init'
alias q='_kiro_lazy_init'

EOF
  then
    _zsh_tool_log ERROR "Failed to append lazy loading code to .zshrc"
    _zsh_tool_log INFO "Restoring from backup..."
    if mv "$backup" "$zshrc" 2>/dev/null; then
      _zsh_tool_log INFO "Restored from backup"
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

  _zsh_tool_log INFO "Lazy loading configured"
  _zsh_tool_log INFO "Kiro CLI will initialize on first 'kiro-cli' or 'q' command use"
  _zsh_tool_log DEBUG "Backup saved at: $backup"

  return 0
}

# Main installation flow for Kiro CLI integration
kiro_install_integration() {
  local enable_lazy_loading="${1:-false}"
  local configure_atuin="${2:-false}"

  _zsh_tool_log INFO "Starting Kiro CLI integration..."

  # Step 1: Detect or install
  if ! _kiro_detect; then
    if ! _kiro_install; then
      _zsh_tool_log ERROR "Kiro CLI installation required but not completed"
      return 1
    fi
  fi

  # Step 2: Configure shell integration
  _kiro_configure_shell_integration

  # Step 3: Configure Atuin compatibility if requested
  if [[ "$configure_atuin" == "true" ]]; then
    _kiro_configure_atuin_compatibility
  fi

  # Step 4: Setup lazy loading if requested
  if [[ "$enable_lazy_loading" == "true" ]]; then
    _kiro_setup_lazy_loading
  fi

  # Step 5: Health check
  if ! _kiro_health_check; then
    _zsh_tool_log ERROR "Kiro CLI health check failed"
    _zsh_tool_log ERROR "Installation incomplete - please address issues and retry"
    _zsh_tool_log INFO "Run 'zsh-tool-kiro health' to diagnose issues"
    return 1
  fi

  # Step 6: Update state.json with installation info
  local version_info="unknown"
  if command -v kiro-cli >/dev/null 2>&1; then
    version_info=$(kiro-cli --version 2>/dev/null | head -n1)
  elif command -v q >/dev/null 2>&1; then
    version_info=$(q --version 2>/dev/null | head -n1)
  fi
  _kiro_update_state "true" "$version_info" "$enable_lazy_loading" "$configure_atuin"

  _zsh_tool_log INFO "Kiro CLI integration complete"

  return 0
}

# Update state.json with Kiro CLI installation info
_kiro_update_state() {
  local installed="${1:-true}"
  local version="${2:-unknown}"
  local lazy_loading="${3:-false}"
  local atuin_compat="${4:-false}"

  _zsh_tool_log DEBUG "Updating Kiro CLI state in state.json..."

  # Load current state
  local state
  state=$(_zsh_tool_load_state)

  # Build Kiro CLI state object
  local kiro_state
  kiro_state=$(cat <<EOF
{
  "installed": $installed,
  "version": "$version",
  "lazy_loading": $lazy_loading,
  "atuin_compatibility": $atuin_compat,
  "last_configured": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

  # Update state - use jq if available for safe JSON manipulation
  local updated
  if command -v jq >/dev/null 2>&1; then
    # Ensure integrations object exists, then set kiro_cli
    updated=$(echo "$state" | jq --argjson val "$kiro_state" '
      if .integrations == null then .integrations = {} else . end |
      .integrations.kiro_cli = $val
    ')
  else
    # Fallback without jq - basic string manipulation
    local kiro_json
    kiro_json=$(echo "$kiro_state" | tr -d '\n' | sed 's/  */ /g')

    if [[ "$state" == *'"integrations"'* ]]; then
      if [[ "$state" == *'"kiro_cli"'* ]]; then
        _zsh_tool_log WARN "Complex state update without jq - please install jq for reliable state management"
        updated="$state"
      else
        updated="${state/\"integrations\":\{/\"integrations\":\{\"kiro_cli\":${kiro_json},}"
      fi
    else
      updated="${state%\}}"
      if [[ "$updated" == "{" ]]; then
        updated="{\"integrations\":{\"kiro_cli\":${kiro_json}}}"
      else
        updated="${updated},\"integrations\":{\"kiro_cli\":${kiro_json}}}"
      fi
    fi
  fi

  _zsh_tool_save_state "$updated"
  _zsh_tool_log DEBUG "Kiro CLI state updated successfully"
}

# Remove lazy loading configuration from .zshrc
_kiro_remove_lazy_loading() {
  _zsh_tool_log INFO "Removing Kiro CLI lazy loading configuration..."

  local zshrc="${HOME}/.zshrc"
  local lazy_load_marker="# Kiro CLI lazy loading (zsh-tool)"
  local lazy_load_end_marker="alias q='_kiro_lazy_init'"

  # Check if lazy loading is configured
  if ! grep -q "$lazy_load_marker" "$zshrc" 2>/dev/null; then
    _zsh_tool_log INFO "Lazy loading not configured - nothing to remove"
    return 0
  fi

  # Create backup before modification
  local backup
  backup="${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"
  if ! cp "$zshrc" "$backup" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to create backup: $backup"
    return 1
  fi
  _zsh_tool_log INFO "Created backup: $backup"

  # Remove the lazy loading block using sed
  # The block starts with the marker comment and ends with the q alias
  local temp_file="${zshrc}.tmp.$$"
  if command -v sed >/dev/null 2>&1; then
    # Remove from marker to end marker (inclusive), plus trailing blank line
    sed "/${lazy_load_marker}/,/${lazy_load_end_marker}/d" "$zshrc" > "$temp_file"

    if [[ -s "$temp_file" ]] || [[ ! -s "$zshrc" ]]; then
      mv "$temp_file" "$zshrc"
      _zsh_tool_log INFO "Lazy loading configuration removed"
    else
      rm -f "$temp_file"
      _zsh_tool_log ERROR "Failed to remove lazy loading - restoring backup"
      mv "$backup" "$zshrc"
      return 1
    fi
  else
    _zsh_tool_log ERROR "sed not available - cannot remove lazy loading"
    return 1
  fi

  return 0
}
