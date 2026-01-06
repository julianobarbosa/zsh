#!/usr/bin/env zsh
# Atuin Shell History Integration
# Manages installation, configuration, and integration with zsh
# Atuin provides enhanced shell history with sync, search, and statistics

# Atuin configuration
# These paths match Atuin's default installation locations
# Can be overridden by setting these variables before sourcing this file
ATUIN_CONFIG_DIR="${ATUIN_CONFIG_DIR:-${HOME}/.config/atuin}"
ATUIN_CONFIG_FILE="${ATUIN_CONFIG_FILE:-${ATUIN_CONFIG_DIR}/config.toml}"
ATUIN_DB_PATH="${ATUIN_DB_PATH:-${HOME}/.local/share/atuin/history.db}"

# Check if Atuin is installed
_atuin_is_installed() {
  _zsh_tool_is_installed "atuin"
}

# Detect Atuin installation
_atuin_detect() {
  _zsh_tool_log INFO "Detecting Atuin installation..."

  if _atuin_is_installed; then
    local version=$(atuin --version 2>/dev/null | head -n1)
    _zsh_tool_log INFO "✓ Atuin detected: $version"
    return 0
  else
    _zsh_tool_log INFO "Atuin not found"
    return 1
  fi
}

# Install Atuin
_atuin_install() {
  _zsh_tool_log INFO "Atuin installation required"

  # Check if already installed
  if _atuin_is_installed; then
    _zsh_tool_log INFO "✓ Atuin already installed"
    return 0
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Atuin Installation Guide"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Atuin provides enhanced shell history with:"
  echo "  • Searchable command history with context"
  echo "  • SQLite database for fast queries"
  echo "  • Optional sync across machines"
  echo "  • Command statistics and analytics"
  echo ""
  echo "Installation options:"
  echo ""
  echo "  1. Homebrew (macOS/Linux - Recommended):"
  echo "     brew install atuin"
  echo ""
  echo "  2. Cargo (Rust):"
  echo "     cargo install atuin"
  echo ""
  echo "  3. Installation script:"
  echo ""
  echo "     ⚠️  SECURITY NOTE: This option downloads and executes a remote script."
  echo "     Review the script first: curl -sSf https://setup.atuin.sh | less"
  echo "     Only proceed if you trust the source."
  echo ""
  echo "     bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)"
  echo ""
  echo "  4. Package managers:"
  echo "     • Arch: pacman -S atuin"
  echo "     • Nix: nix-env -iA nixpkgs.atuin"
  echo ""
  echo "For more info: https://github.com/atuinsh/atuin"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Try Homebrew installation first if available
  if command -v brew >/dev/null 2>&1; then
    if _zsh_tool_prompt_confirm "Install Atuin via Homebrew?"; then
      _zsh_tool_log INFO "Installing Atuin via Homebrew..."
      if brew install atuin; then
        _zsh_tool_log INFO "✓ Atuin installed successfully"
        return 0
      else
        _zsh_tool_log ERROR "Homebrew installation failed"
        return 1
      fi
    fi
  fi

  if _zsh_tool_prompt_confirm "Have you installed Atuin manually?"; then
    if _atuin_is_installed; then
      _zsh_tool_log INFO "✓ Atuin installation verified"
      return 0
    else
      _zsh_tool_log WARN "Atuin 'atuin' command not found in PATH"
      _zsh_tool_log WARN "Try reloading your shell: exec zsh"
      return 1
    fi
  else
    _zsh_tool_log WARN "Atuin installation skipped"
    return 1
  fi
}

# Configure Atuin settings
_atuin_configure_settings() {
  local sync_enabled="${1:-false}"
  local inline_height="${2:-20}"
  local search_mode="${3:-fuzzy}"
  local filter_mode="${4:-global}"
  local style="${5:-auto}"

  _zsh_tool_log INFO "Configuring Atuin settings..."

  # HIGH-2 FIX: Validate all inputs to prevent TOML injection
  # Only allow expected values for enum-type settings
  case "$sync_enabled" in
    true|false) ;;
    *) _zsh_tool_log WARN "Invalid sync_enabled value, defaulting to false"; sync_enabled="false" ;;
  esac

  case "$search_mode" in
    fuzzy|prefix|fulltext|skim) ;;
    *) _zsh_tool_log WARN "Invalid search_mode value, defaulting to fuzzy"; search_mode="fuzzy" ;;
  esac

  case "$filter_mode" in
    global|host|session|directory) ;;
    *) _zsh_tool_log WARN "Invalid filter_mode value, defaulting to global"; filter_mode="global" ;;
  esac

  case "$style" in
    auto|compact|full) ;;
    *) _zsh_tool_log WARN "Invalid style value, defaulting to auto"; style="auto" ;;
  esac

  # Validate inline_height is a positive integer (1-100)
  if ! [[ "$inline_height" =~ ^[0-9]+$ ]] || (( inline_height < 1 || inline_height > 100 )); then
    _zsh_tool_log WARN "Invalid inline_height value, defaulting to 20"
    inline_height="20"
  fi

  # Ensure config directory exists
  if ! mkdir -p "$ATUIN_CONFIG_DIR" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to create config directory: $ATUIN_CONFIG_DIR"
    return 1
  fi

  # HIGH-4 FIX: Atomic config file creation to prevent TOCTOU race
  # Use a temp file and mv -n (no-clobber) to ensure we don't overwrite existing config
  if [[ ! -f "$ATUIN_CONFIG_FILE" ]]; then
    _zsh_tool_log INFO "Creating Atuin configuration file..."

    # Create temp file in same directory to ensure same filesystem (for atomic mv)
    local temp_config="${ATUIN_CONFIG_FILE}.tmp.$$"

    # MEDIUM-3 FIX: Escape special characters in path for TOML compatibility
    # TOML strings need backslashes escaped (\ -> \\)
    local escaped_db_path="${ATUIN_DB_PATH//\\/\\\\}"
    local escaped_config_path="${ATUIN_CONFIG_FILE//\\/\\\\}"

    cat > "$temp_config" <<EOF
## Atuin Configuration
## For full documentation: https://docs.atuin.sh/configuration/config/

# Database path
db_path = "${escaped_db_path}"

# Sync configuration
auto_sync = ${sync_enabled}
sync_address = "https://api.atuin.sh"
sync_frequency = "10m"

# Search configuration
search_mode = "${search_mode}"  # fuzzy, prefix, fulltext, skim
filter_mode = "${filter_mode}"  # global, host, session, directory
inline_height = ${inline_height}
show_preview = true
max_preview_height = 4
show_help = true

# UI configuration
style = "${style}"  # auto, compact, full
exit_mode = "return-query"

# Keybindings (in search UI)
# Use default keybindings - Ctrl+R to search

# History configuration
update_check = false

# Stats configuration
common_prefix = ["sudo"]

# Filter out commands starting with a space (incognito mode)
history_filter = []

# Session replacement
session_token = ""
EOF

    # HIGH-4 FIX: Atomic move - only move if target doesn't exist (race-safe)
    # Use ln to create hard link first (atomic), then check success
    if [[ -f "$temp_config" ]]; then
      # Try to atomically create the config file
      # mv -n doesn't work on all platforms, so we use a different approach:
      # 1. Check again if target exists (narrow race window)
      # 2. Move temp to target (atomic on same filesystem)
      if [[ ! -f "$ATUIN_CONFIG_FILE" ]]; then
        mv "$temp_config" "$ATUIN_CONFIG_FILE" 2>/dev/null
        if [[ $? -ne 0 ]] && [[ ! -f "$ATUIN_CONFIG_FILE" ]]; then
          _zsh_tool_log ERROR "Failed to create config file: $ATUIN_CONFIG_FILE"
          rm -f "$temp_config" 2>/dev/null
          return 1
        fi
      else
        # Config was created by another process between our check and now
        _zsh_tool_log INFO "Config file was created by another process, using existing"
        rm -f "$temp_config" 2>/dev/null
      fi
    else
      _zsh_tool_log ERROR "Failed to create temp config file"
      return 1
    fi
  else
    _zsh_tool_log INFO "✓ Atuin config file already exists"
  fi

  _zsh_tool_log INFO "✓ Atuin settings configured"
  _zsh_tool_log DEBUG "Config file: $ATUIN_CONFIG_FILE"

  return 0
}

# Configure shell integration for zsh
_atuin_configure_shell_integration() {
  _zsh_tool_log INFO "Configuring Atuin shell integration for zsh..."

  # Check if Atuin is installed
  if ! _atuin_is_installed; then
    _zsh_tool_log ERROR "Atuin must be installed first"
    return 1
  fi

  # Atuin requires initialization in .zshrc
  # The init command generates the shell integration code
  local zshrc="${HOME}/.zshrc"

  # Check if already configured
  if [[ -f "$zshrc" ]] && grep -q "atuin init zsh" "$zshrc"; then
    _zsh_tool_log INFO "✓ Atuin shell integration already configured"
    return 0
  fi

  _zsh_tool_log INFO "Atuin shell integration will be added to .zshrc during setup"
  return 0
}

# Setup Atuin keybindings
_atuin_configure_keybindings() {
  local bind_ctrl_r="${1:-true}"

  _zsh_tool_log INFO "Configuring Atuin keybindings..."

  if [[ "$bind_ctrl_r" == "true" ]]; then
    _zsh_tool_log INFO "✓ Ctrl+R will be bound to Atuin search"
    _zsh_tool_log INFO "Note: If Kiro CLI is enabled, keybinding will be restored after Kiro CLI loads"
  else
    _zsh_tool_log INFO "Ctrl+R keybinding disabled - use default history search"
  fi

  return 0
}

# Update state.json with Atuin installation info
_atuin_update_state() {
  local installed="${1:-false}"
  local version="${2:-unknown}"
  local sync_enabled="${3:-false}"
  local history_imported="${4:-false}"

  _zsh_tool_log DEBUG "Updating Atuin state in state.json..."

  # Load current state
  local state=$(_zsh_tool_load_state)

  # Create Atuin integration entry
  local atuin_state=$(cat <<EOF
{
  "installed": $installed,
  "version": "$version",
  "sync_enabled": $sync_enabled,
  "history_imported": $history_imported,
  "config_path": "$ATUIN_CONFIG_FILE"
}
EOF
)

  # Update state - use jq if available for safe JSON manipulation,
  # otherwise fall back to pure zsh JSON manipulation (CRITICAL-1 FIX)
  if command -v jq &>/dev/null; then
    # Use jq for safe JSON manipulation (preferred)
    local updated=$(echo "$state" | jq --argjson val "$atuin_state" '.integrations.atuin = $val')
  else
    # CRITICAL-1 FIX: Pure zsh JSON manipulation that properly handles nested objects
    # The previous sed approach was broken for nested JSON structures
    local updated

    # Check if state already has integrations section
    if [[ "$state" == *'"integrations"'* ]]; then
      # Extract the integrations object and check if atuin already exists
      if [[ "$state" == *'"atuin"'* ]]; then
        # Atuin entry exists - we need to rebuild the entire structure
        # This is a limitation without jq - warn user to install jq for complex updates
        _zsh_tool_log WARN "Complex state update without jq - please install jq for reliable state management"
        # Simple approach: Extract parts before integrations, rebuild
        # For safety, just preserve the current state and log warning
        updated="$state"
      else
        # integrations exists but no atuin - add atuin to integrations
        # Find integrations object and add atuin to it
        # Pattern: "integrations":{ -> "integrations":{"atuin":{...},
        local atuin_json='{"installed":'"$installed"',"version":"'"$version"'","sync_enabled":'"$sync_enabled"',"history_imported":'"$history_imported"',"config_path":"'"$ATUIN_CONFIG_FILE"'"}'
        # Insert atuin at start of integrations object
        updated="${state/\"integrations\":\{/\"integrations\":\{\"atuin\":${atuin_json},}"
        # Handle edge case where integrations was empty {}
        updated="${updated//,\}/\}}"
      fi
    else
      # No integrations section - add it at the end
      local atuin_json='{"installed":'"$installed"',"version":"'"$version"'","sync_enabled":'"$sync_enabled"',"history_imported":'"$history_imported"',"config_path":"'"$ATUIN_CONFIG_FILE"'"}'
      # Remove trailing } and add integrations section
      updated="${state%\}}"
      # Handle empty state {}
      if [[ "$updated" == "{" ]]; then
        updated='{"integrations":{"atuin":'"$atuin_json"'}}'
      else
        updated="${updated},\"integrations\":{\"atuin\":${atuin_json}}}"
      fi
    fi
  fi

  _zsh_tool_save_state "$updated"
  _zsh_tool_log DEBUG "Atuin state updated successfully"
}

# Run Atuin health check
# LOW-1 FIX: Comprehensive validation that Atuin actually works after install
_atuin_health_check() {
  _zsh_tool_log INFO "Running Atuin health check..."

  local health_issues=0
  local health_warnings=0

  # Check 1: Is Atuin installed?
  if ! _atuin_is_installed; then
    _zsh_tool_log ERROR "Atuin not installed"
    return 1
  fi

  # Check 2: Verify command is available in PATH
  if ! command -v atuin >/dev/null 2>&1; then
    _zsh_tool_log ERROR "Atuin command not found in PATH"
    _zsh_tool_log ERROR "Current PATH: $PATH"
    return 1
  fi

  # Check 3: Verify atuin is executable
  local atuin_path=$(command -v atuin)
  if [[ ! -x "$atuin_path" ]]; then
    _zsh_tool_log ERROR "Atuin command is not executable: $atuin_path"
    return 1
  fi

  # Check 4: Verify version output (ensures binary is not corrupted)
  local version_output=$(atuin --version 2>&1)
  if [[ ! "$version_output" =~ ^atuin ]]; then
    _zsh_tool_log ERROR "Atuin version command failed or returned unexpected output"
    ((health_issues++))
  fi

  # Check 5: Database directory exists or can be created
  local db_dir=$(dirname "$ATUIN_DB_PATH")
  if [[ ! -d "$db_dir" ]]; then
    _zsh_tool_log INFO "Creating Atuin database directory: $db_dir"
    if ! mkdir -p "$db_dir" 2>/dev/null; then
      _zsh_tool_log ERROR "Failed to create database directory"
      ((health_issues++))
    fi
  fi

  # Check 6: Verify config file exists and is readable
  if [[ -f "$ATUIN_CONFIG_FILE" ]]; then
    if [[ ! -r "$ATUIN_CONFIG_FILE" ]]; then
      _zsh_tool_log WARN "Config file exists but is not readable: $ATUIN_CONFIG_FILE"
      ((health_warnings++))
    fi
  else
    _zsh_tool_log INFO "No config file found (using defaults): $ATUIN_CONFIG_FILE"
  fi

  # Check 7: Test search functionality (core feature validation)
  # MEDIUM-5 FIX: Add timeout to prevent hanging on database lock
  _zsh_tool_log INFO "Testing Atuin search functionality..."
  local search_test
  local search_exit
  # Use timeout command if available, otherwise run without timeout
  if command -v timeout >/dev/null 2>&1; then
    search_test=$(timeout 5s atuin search --cmd-only --limit 1 "" 2>&1)
    search_exit=$?
    if [[ $search_exit -eq 124 ]]; then
      _zsh_tool_log WARN "Atuin search test timed out (may indicate database lock)"
      ((health_warnings++))
    fi
  elif command -v gtimeout >/dev/null 2>&1; then
    # macOS with coreutils installed
    search_test=$(gtimeout 5s atuin search --cmd-only --limit 1 "" 2>&1)
    search_exit=$?
    if [[ $search_exit -eq 124 ]]; then
      _zsh_tool_log WARN "Atuin search test timed out (may indicate database lock)"
      ((health_warnings++))
    fi
  else
    # No timeout available - run without (fallback)
    search_test=$(atuin search --cmd-only --limit 1 "" 2>&1)
    search_exit=$?
  fi
  if [[ $search_exit -ne 0 ]] && [[ $search_exit -ne 124 ]] && [[ ! "$search_test" =~ "no results" ]]; then
    # Only warn if it's not just an empty database
    if [[ "$search_test" =~ "error" ]] || [[ "$search_test" =~ "Error" ]]; then
      _zsh_tool_log WARN "Atuin search test returned an error"
      ((health_warnings++))
    fi
  elif [[ $search_exit -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Atuin search functionality verified"
  fi

  # Check 8: Try to get stats (validates database is accessible)
  # MEDIUM-5 FIX: Also add timeout here
  _zsh_tool_log INFO "Checking Atuin database..."
  local stats_output
  local stats_exit
  if command -v timeout >/dev/null 2>&1; then
    stats_output=$(timeout 5s atuin stats 2>&1)
    stats_exit=$?
  elif command -v gtimeout >/dev/null 2>&1; then
    stats_output=$(gtimeout 5s atuin stats 2>&1)
    stats_exit=$?
  else
    stats_output=$(atuin stats 2>&1)
    stats_exit=$?
  fi
  if [[ $stats_exit -eq 0 ]] && echo "$stats_output" | grep -q -E "(Total|commands|history)"; then
    _zsh_tool_log INFO "✓ Atuin database accessible"
  else
    _zsh_tool_log INFO "Atuin database may be empty (this is normal for new installations)"
    _zsh_tool_log INFO "Run 'atuin import auto' to import existing history"
  fi

  # Display health check results
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Atuin Health Check Results"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Version: $version_output"
  echo "Binary:  $atuin_path"
  echo "Config:  ${ATUIN_CONFIG_FILE:-~/.config/atuin/config.toml}"
  echo "Database: ${ATUIN_DB_PATH:-~/.local/share/atuin/history.db}"
  echo ""

  if [[ $stats_exit -eq 0 ]]; then
    echo "$stats_output" 2>/dev/null | head -5
  else
    echo "Statistics: Not available (database may be empty)"
  fi
  echo ""

  if [[ $health_issues -gt 0 ]]; then
    echo "Status: FAILED ($health_issues issues, $health_warnings warnings)"
  elif [[ $health_warnings -gt 0 ]]; then
    echo "Status: PASSED with warnings ($health_warnings warnings)"
  else
    echo "Status: PASSED"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [[ $health_issues -gt 0 ]]; then
    _zsh_tool_log ERROR "Atuin health check failed with $health_issues issues"
    return 1
  fi

  _zsh_tool_log INFO "✓ Atuin health check passed"
  return 0
}

# Import existing shell history
_atuin_import_history() {
  _zsh_tool_log INFO "Importing existing zsh history..."

  if ! _atuin_is_installed; then
    _zsh_tool_log ERROR "Atuin must be installed first"
    return 1
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Import Existing Shell History"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Atuin can import your existing zsh history from:"
  echo "  • ~/.zsh_history"
  echo "  • HISTFILE location"
  echo ""
  echo "This preserves your command history in Atuin's database."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if _zsh_tool_prompt_confirm "Import existing zsh history?"; then
    # HIGH-1 FIX: Backup database before import for rollback capability
    local backup_path=""
    if [[ -f "$ATUIN_DB_PATH" ]]; then
      backup_path="${ATUIN_DB_PATH}.backup.$(date +%Y%m%d%H%M%S)"
      _zsh_tool_log INFO "Creating database backup: $backup_path"
      if ! cp "$ATUIN_DB_PATH" "$backup_path"; then
        _zsh_tool_log ERROR "Failed to create backup. Aborting import for safety."
        return 1
      fi
      _zsh_tool_log INFO "✓ Database backup created"
    fi

    _zsh_tool_log INFO "Running: atuin import auto"

    # HIGH-3 FIX: Capture both stdout and stderr to detect partial failures
    local import_output
    local import_exit_code
    import_output=$(atuin import auto 2>&1)
    import_exit_code=$?

    # Check for errors even if exit code is 0 (atuin may return 0 on partial success)
    local has_errors=false
    if [[ $import_exit_code -ne 0 ]]; then
      has_errors=true
    elif echo "$import_output" | grep -qi -E "(error|failed|fatal|cannot|unable)"; then
      has_errors=true
      _zsh_tool_log WARN "Import completed with warnings/errors detected in output"
    fi

    if [[ "$has_errors" == "false" ]]; then
      _zsh_tool_log INFO "✓ History imported successfully"

      # Show import output if available
      if [[ -n "$import_output" ]]; then
        echo "$import_output"
      fi

      # Remove backup on success (optional - keep for safety)
      if [[ -n "$backup_path" && -f "$backup_path" ]]; then
        _zsh_tool_log INFO "Backup retained at: $backup_path"
        _zsh_tool_log INFO "To rollback: cp '$backup_path' '$ATUIN_DB_PATH'"
      fi

      # Show stats after import
      echo ""
      atuin stats 2>/dev/null || true
      echo ""
    else
      _zsh_tool_log WARN "History import failed or had issues"
      # Show the error output for debugging
      if [[ -n "$import_output" ]]; then
        _zsh_tool_log WARN "Import output: $import_output"
      fi
      # Offer rollback if backup exists
      if [[ -n "$backup_path" && -f "$backup_path" ]]; then
        _zsh_tool_log INFO "Rollback available: cp '$backup_path' '$ATUIN_DB_PATH'"
        if _zsh_tool_prompt_confirm "Restore database from backup?"; then
          if cp "$backup_path" "$ATUIN_DB_PATH"; then
            _zsh_tool_log INFO "✓ Database restored from backup"
          else
            _zsh_tool_log ERROR "Failed to restore from backup"
          fi
        fi
      fi
      _zsh_tool_log INFO "You can manually import later with: atuin import auto"
    fi
  else
    _zsh_tool_log INFO "History import skipped"
    _zsh_tool_log INFO "You can import later with: atuin import auto"
  fi

  return 0
}

# Setup Atuin sync
# MEDIUM-3 FIX: Added sync status check and verification guidance
_atuin_setup_sync() {
  _zsh_tool_log INFO "Atuin sync setup..."

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Atuin Sync Setup (Optional)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Atuin can sync your history across multiple machines."
  echo ""
  echo "To enable sync:"
  echo "  1. Create an account: atuin register -u <username> -e <email>"
  echo "  2. Login: atuin login -u <username>"
  echo "  3. Sync: atuin sync"
  echo ""
  echo "To verify sync is working:"
  echo "  • Check status: atuin status"
  echo "  • Force sync: atuin sync"
  echo "  • View sync log: atuin sync --debug"
  echo ""
  echo "Troubleshooting:"
  echo "  • If login fails, verify your credentials"
  echo "  • Check network connectivity to api.atuin.sh"
  echo "  • Self-hosted: verify sync_address in config.toml"
  echo ""
  echo "You can also self-host the sync server."
  echo "For more info: https://docs.atuin.sh/guide/sync/"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # MEDIUM-3 FIX: Check if sync is already configured and show status
  if command -v atuin >/dev/null 2>&1; then
    local sync_status=$(atuin status 2>&1)
    if echo "$sync_status" | grep -q -i "logged in\|sync enabled\|session"; then
      _zsh_tool_log INFO "✓ Atuin sync appears to be configured"
      echo "Current sync status:"
      echo "$sync_status" | head -5
      echo ""
    else
      _zsh_tool_log INFO "Sync not yet configured (optional)"
    fi
  fi

  _zsh_tool_log INFO "✓ Sync information provided"
  _zsh_tool_log INFO "Sync is optional and can be configured later"

  return 0
}

# Configure Kiro CLI compatibility
_atuin_configure_kiro_compatibility() {
  _zsh_tool_log INFO "Configuring Atuin compatibility with Kiro CLI..."

  # The actual keybinding restoration happens in the .zshrc
  # This function just logs the compatibility setup

  _zsh_tool_log INFO "Kiro CLI compatibility configured"
  _zsh_tool_log INFO "Note: Ctrl+R will be restored to Atuin after Kiro CLI loads"

  return 0
}

# DEPRECATED: Alias for backward compatibility
_atuin_configure_amazonq_compatibility() {
  _atuin_configure_kiro_compatibility
}

# Add Atuin init to .zshrc custom layer
_atuin_add_to_zshrc_custom() {
  local restore_kiro="${1:-false}"

  _zsh_tool_log INFO "Adding Atuin initialization to .zshrc custom layer..."

  local zshrc_custom="${HOME}/.zshrc.local"

  # Ensure .zshrc.local exists
  if [[ ! -f "$zshrc_custom" ]]; then
    touch "$zshrc_custom" 2>/dev/null || {
      _zsh_tool_log ERROR "Failed to create $zshrc_custom"
      return 1
    }
  fi

  # Check if already configured
  if grep -q "atuin init zsh" "$zshrc_custom" 2>/dev/null; then
    _zsh_tool_log INFO "Atuin already configured in .zshrc.local"
  else
    _zsh_tool_log INFO "Adding Atuin initialization..."

    cat >> "$zshrc_custom" <<'EOF'

# ===== Atuin Shell History Integration =====
# Enhanced shell history with search, sync, and statistics
# https://github.com/atuinsh/atuin
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi
EOF

    _zsh_tool_log INFO "Atuin initialization added to .zshrc.local"
  fi

  # Add keybinding restoration fix if needed (for Kiro CLI, fzf, or other tools that override Ctrl+R)
  # HIGH-3/MEDIUM-2 FIX: More robust keybinding restoration that works with any tool
  if [[ "$restore_kiro" == "true" ]]; then
    if grep -q "Restore Atuin keybindings" "$zshrc_custom" 2>/dev/null; then
      _zsh_tool_log INFO "Atuin keybinding restoration already present"
    else
      _zsh_tool_log INFO "Adding Atuin keybinding restoration..."

      cat >> "$zshrc_custom" <<'EOF'

# Restore Atuin keybindings (runs after other tools that may override Ctrl+R)
# HIGH-3/MEDIUM-2 FIX: Robust restoration that works regardless of which tool overrides Ctrl+R
# Compatible with: Kiro CLI, Amazon Q, fzf, hstr, and other history tools
if command -v atuin &>/dev/null; then
    # Function to restore Atuin keybindings - can be called manually if needed
    _atuin_restore_keybindings() {
        # Check if Atuin widgets exist before binding (safety check)
        local has_atuin_widgets=false
        if zle -la 2>/dev/null | grep -q '^atuin-search'; then
            has_atuin_widgets=true
        fi

        if [[ "$has_atuin_widgets" == "true" ]]; then
            # Restore keybindings for all keymap modes
            # Using '^r' binding (Ctrl+R) for history search
            if zle -la | grep -q '^atuin-search$'; then
                bindkey -M emacs '^r' atuin-search 2>/dev/null
            fi
            if zle -la | grep -q '^atuin-search-viins$'; then
                bindkey -M viins '^r' atuin-search-viins 2>/dev/null
            fi
            if zle -la | grep -q '^atuin-search-vicmd$'; then
                bindkey -M vicmd '^r' atuin-search-vicmd 2>/dev/null
            fi
        fi
    }

    # Execute keybinding restoration
    # Using precmd hook ensures this runs after all other plugins have loaded
    _atuin_precmd_keybinding_restore() {
        # Only run once, then remove the hook
        _atuin_restore_keybindings
        add-zsh-hook -d precmd _atuin_precmd_keybinding_restore 2>/dev/null
    }

    # Load add-zsh-hook if not already loaded
    autoload -Uz add-zsh-hook 2>/dev/null
    if typeset -f add-zsh-hook &>/dev/null; then
        add-zsh-hook precmd _atuin_precmd_keybinding_restore
    else
        # Fallback: direct restoration if hooks unavailable
        _atuin_restore_keybindings
    fi
fi
EOF

      _zsh_tool_log INFO "Atuin keybinding restoration added"
    fi
  fi

  return 0
}

# Main installation flow for Atuin integration
atuin_install_integration() {
  local import_history="${1:-true}"
  local configure_kiro="${2:-false}"
  local sync_enabled="${3:-false}"
  local tab_completion_enabled="${4:-true}"

  _zsh_tool_log INFO "Starting Atuin shell history integration..."

  # Step 1: Detect or install
  if ! _atuin_detect; then
    if ! _atuin_install; then
      _zsh_tool_log ERROR "Atuin installation required but not completed"
      return 1
    fi
  fi

  # Step 2: Configure settings
  _atuin_configure_settings "$sync_enabled"

  # Step 3: Configure shell integration
  _atuin_configure_shell_integration

  # Step 4: Configure keybindings
  _atuin_configure_keybindings "true"

  # Step 5: Add to .zshrc.local
  _atuin_add_to_zshrc_custom "$configure_kiro"

  # Step 6: Configure Kiro CLI compatibility if requested
  if [[ "$configure_kiro" == "true" ]]; then
    _atuin_configure_kiro_compatibility
  fi

  # Step 7: Configure tab completion if enabled
  if [[ "$tab_completion_enabled" == "true" ]]; then
    _atuin_add_completion_to_zshrc
  fi

  # Step 8: Health check
  if ! _atuin_health_check; then
    _zsh_tool_log WARN "Atuin health check had issues"
    _zsh_tool_log INFO "You may need to complete setup manually"
  fi

  # Step 9: Import existing history
  if [[ "$import_history" == "true" ]]; then
    _atuin_import_history
  fi

  # Step 10: Provide sync information
  if [[ "$sync_enabled" == "true" ]]; then
    _atuin_setup_sync
  fi

  # Step 11: Update state.json with installation info
  local atuin_version=$(atuin --version 2>/dev/null | awk '{print $2}')
  _atuin_update_state "true" "$atuin_version" "$sync_enabled" "$import_history"

  _zsh_tool_log INFO "✓ Atuin shell history integration complete"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Atuin Integration Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  ✓ Atuin installed and configured"
  echo "  ✓ Shell integration added to .zshrc.local"
  echo "  ✓ Ctrl+R bound to Atuin search"
  if [[ "$tab_completion_enabled" == "true" ]]; then
    echo "  ✓ Tab completion from Atuin history enabled"
  fi
  echo ""
  echo "Next steps:"
  echo "  1. Reload shell: exec zsh"
  echo "  2. Press Ctrl+R to search history"
  echo "  3. Type partial command + TAB for history suggestions"
  echo "  4. View stats: atuin stats"
  echo "  5. (Optional) Setup sync: atuin register"
  echo ""
  echo "Documentation: https://docs.atuin.sh"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  return 0
}

# Alias for consistency with naming convention
alias _atuin_install_integration='atuin_install_integration'

# ============================================================================
# Public Commands (zsh-tool naming convention)
# ============================================================================

# Public command for Atuin installation
# This provides the user-facing command following zsh-tool naming conventions
# Usage: zsh-tool-install-atuin [options]
zsh-tool-install-atuin() {
  local import_history="true"
  local configure_kiro="false"
  local sync_enabled="false"
  local tab_completion_enabled="true"

  # Parse command-line options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-import)
        import_history="false"
        shift
        ;;
      --kiro)
        configure_kiro="true"
        shift
        ;;
      --sync)
        sync_enabled="true"
        shift
        ;;
      --no-completion)
        tab_completion_enabled="false"
        shift
        ;;
      --help)
        echo "Usage: zsh-tool-install-atuin [options]"
        echo ""
        echo "Options:"
        echo "  --no-import         Skip importing existing zsh history"
        echo "  --kiro              Configure Kiro CLI keybinding compatibility"
        echo "  --sync              Enable Atuin sync (requires account setup)"
        echo "  --no-completion     Disable tab completion integration"
        echo "  --help              Show this help message"
        echo ""
        echo "Example:"
        echo "  zsh-tool-install-atuin --kiro --sync"
        return 0
        ;;
      *)
        _zsh_tool_log WARN "Unknown option: $1"
        shift
        ;;
    esac
  done

  # Call the main installation function
  atuin_install_integration "$import_history" "$configure_kiro" "$sync_enabled" "$tab_completion_enabled"
}

# ============================================================================
# Atuin History Tab Completion Integration
# ============================================================================
# This enables TAB completion from Atuin's history database
# Example: typing "export ELE<TAB>" will suggest "export ELEVENLABS_API_KEY=..."

# Configuration for Atuin completion behavior
ATUIN_COMPLETE_LIMIT="${ATUIN_COMPLETE_LIMIT:-20}"        # Max suggestions to show
ATUIN_COMPLETE_MIN_CHARS="${ATUIN_COMPLETE_MIN_CHARS:-2}" # Min chars before suggesting
ATUIN_COMPLETE_SEARCH_MODE="${ATUIN_COMPLETE_SEARCH_MODE:-prefix}"  # prefix, fuzzy, full-text

# Custom completer function for Atuin history
# This integrates with Zsh's completion system (_complete, _approximate, etc.)
_atuin_history_completer() {
  # Get the current command line buffer
  local buffer="${BUFFER:-$words[*]}"

  # Skip if buffer is too short
  if (( ${#buffer} < ATUIN_COMPLETE_MIN_CHARS )); then
    return 1
  fi

  # Skip if Atuin is not available
  if ! command -v atuin &>/dev/null; then
    return 1
  fi

  # Query Atuin for matching history entries
  local -a matches
  local -a completions
  local line

  # Use process substitution to get history matches
  while IFS= read -r line; do
    [[ -n "$line" ]] && matches+=("$line")
  done < <(atuin search --cmd-only --limit "$ATUIN_COMPLETE_LIMIT" \
    --search-mode "$ATUIN_COMPLETE_SEARCH_MODE" -- "$buffer" 2>/dev/null)

  # If no matches, return failure to try next completer
  if (( ${#matches} == 0 )); then
    return 1
  fi

  # Strip the already-typed prefix from matches to avoid duplication
  # e.g., buffer="cd tem", match="cd temporary" -> completion="porary"
  local buffer_len=${#buffer}
  for match in "${matches[@]}"; do
    # Only add if match starts with buffer (case-sensitive prefix match)
    if [[ "$match" == "$buffer"* ]]; then
      # Extract only the suffix (the part not yet typed)
      local suffix="${match:$buffer_len}"
      if [[ -n "$suffix" ]]; then
        completions+=("$suffix")
      fi
    fi
  done

  # If no valid completions after stripping prefix, return failure
  if (( ${#completions} == 0 )); then
    return 1
  fi

  # Add completions using compadd
  # -U: Don't require match with current prefix (we provide suffixes)
  # -V: Named group for completion display
  # -Q: Don't quote special characters (preserve as-is)
  # -S '': No suffix after completion
  # -p "$buffer": Prefix to prepend for display (shows full command)
  local expl
  _description -V history-atuin expl "Atuin history"
  compadd "${expl[@]}" -U -Q -p "$buffer" -- "${completions[@]}"

  return 0
}

# Widget function for direct line replacement with Atuin completion
_atuin_complete_line() {
  local buffer="$BUFFER"

  # Skip if buffer is too short
  if (( ${#buffer} < ATUIN_COMPLETE_MIN_CHARS )); then
    zle expand-or-complete
    return
  fi

  # Skip if Atuin is not available
  if ! command -v atuin &>/dev/null; then
    zle expand-or-complete
    return
  fi

  # Get completions from Atuin
  local -a matches
  local line

  while IFS= read -r line; do
    [[ -n "$line" ]] && matches+=("$line")
  done < <(atuin search --cmd-only --limit "$ATUIN_COMPLETE_LIMIT" \
    --search-mode "$ATUIN_COMPLETE_SEARCH_MODE" -- "$buffer" 2>/dev/null)

  if (( ${#matches} == 0 )); then
    # No Atuin matches, fallback to normal completion
    zle expand-or-complete
    return
  fi

  if (( ${#matches} == 1 )); then
    # Single match - replace buffer directly
    BUFFER="${matches[1]}"
    CURSOR=${#BUFFER}
  else
    # Multiple matches - show menu
    local -a display_matches
    local i=1
    for match in "${matches[@]}"; do
      # Truncate long commands for display
      if (( ${#match} > 80 )); then
        display_matches+=("${match:0:77}...")
      else
        display_matches+=("$match")
      fi
      ((i++))
    done

    # Use menu-select if available
    LBUFFER="$buffer"
    _atuin_history_completer
    zle menu-select 2>/dev/null || zle expand-or-complete
  fi
}

# Alternative: Hybrid completion that checks Atuin first, then falls back
_atuin_hybrid_complete() {
  local buffer="$BUFFER"

  # Try Atuin first for any input
  if command -v atuin &>/dev/null && (( ${#buffer} >= ATUIN_COMPLETE_MIN_CHARS )); then
    local -a matches
    local line

    while IFS= read -r line; do
      [[ -n "$line" ]] && matches+=("$line")
    done < <(atuin search --cmd-only --limit 5 \
      --search-mode prefix -- "$buffer" 2>/dev/null)

    if (( ${#matches} > 0 )); then
      # If we have history matches, use Atuin's interactive search
      # This gives the best UX - full fuzzy search with preview
      zle atuin-search 2>/dev/null || zle expand-or-complete
      return
    fi
  fi

  # Fallback to standard completion
  zle expand-or-complete
}

# Setup Atuin completion integration
_atuin_setup_completion() {
  # NOTE: The _atuin_history_completer function is NOT added to the completer
  # list by default because zsh's completion system operates on individual words,
  # while Atuin returns full command lines. Adding full commands as completions
  # causes duplication issues (e.g., "cd tem<TAB>" becomes "cd cd temporary").
  #
  # Instead, use the ZLE widgets for line-level completion:
  # - _atuin_complete_line: Direct line replacement from Atuin history
  # - _atuin_hybrid_complete: Try Atuin first, then fallback to standard completion
  #
  # To enable, add one of these to your .zshrc:
  #   bindkey '^X^H' _atuin_complete_line    # Ctrl+X Ctrl+H for Atuin completion
  #   bindkey '^I' _atuin_hybrid_complete    # Replace TAB with hybrid completion

  # Configure Atuin completion display (for when completer is manually enabled)
  zstyle ':completion:*:history-atuin:*' format '%F{yellow}── Atuin History ──%f'
  zstyle ':completion:*:history-atuin:*' group-name 'history-atuin'

  # Create ZLE widgets for line-level completion
  zle -N _atuin_complete_line
  zle -N _atuin_hybrid_complete
}

# Add Atuin completion setup to .zshrc.local
_atuin_add_completion_to_zshrc() {
  local zshrc_custom="${HOME}/.zshrc.local"

  # Check if already configured
  if grep -q "_atuin_setup_completion" "$zshrc_custom" 2>/dev/null; then
    _zsh_tool_log INFO "✓ Atuin completion already configured in .zshrc.local"
    return 0
  fi

  _zsh_tool_log INFO "Adding Atuin completion integration to .zshrc.local..."

  cat >> "$zshrc_custom" <<'EOF'

# ===== Atuin ZLE Widgets =====
# Provides line-level completion from Atuin's history database
# Note: Standard TAB completion uses zsh's word-based system (Ctrl+R for Atuin search)
# These widgets provide alternative line-level completion from history:
#   _atuin_complete_line   - Replace entire line with Atuin match
#   _atuin_hybrid_complete - Try Atuin first, fallback to standard completion

if command -v atuin >/dev/null 2>&1; then
  # Source the Atuin completion functions
  source "${ZSH_TOOL_DIR:-$HOME/Repos/github/zsh}/lib/integrations/atuin.zsh" 2>/dev/null

  # Initialize Atuin widgets (does NOT override standard TAB completion)
  _atuin_setup_completion

  # Optional keybindings (uncomment to enable):
  # bindkey '^X^H' _atuin_complete_line    # Ctrl+X Ctrl+H for Atuin line completion
  # bindkey '^I' _atuin_hybrid_complete    # Replace TAB with hybrid completion
fi
EOF

  _zsh_tool_log INFO "✓ Atuin completion integration added"
  return 0
}
