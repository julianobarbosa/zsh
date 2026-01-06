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
  echo "  1. Homebrew (macOS/Linux - Recommended, most secure):"
  echo "     brew install atuin"
  echo ""
  echo "  2. Cargo (Rust - recommended if you have Rust toolchain):"
  echo "     cargo install atuin"
  echo ""
  echo "  3. Package managers:"
  echo "     • Arch: pacman -S atuin"
  echo "     • Nix: nix-env -iA nixpkgs.atuin"
  echo ""
  echo "  4. Installation script (requires manual review):"
  echo "     ⚠️  SECURITY: Never pipe curl directly to bash!"
  echo "     To use the script safely:"
  echo "       a) Download: curl -sSf https://setup.atuin.sh -o /tmp/atuin-install.sh"
  echo "       b) Review:   less /tmp/atuin-install.sh"
  echo "       c) Execute:  bash /tmp/atuin-install.sh"
  echo ""
  echo "For more info: https://github.com/atuinsh/atuin"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Try Homebrew installation first if available (most secure)
  if command -v brew >/dev/null 2>&1; then
    if _zsh_tool_prompt_confirm "Install Atuin via Homebrew? (recommended)"; then
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

  # Try Cargo if available (also secure - builds from source)
  if command -v cargo >/dev/null 2>&1; then
    if _zsh_tool_prompt_confirm "Install Atuin via Cargo (Rust)?"; then
      _zsh_tool_log INFO "Installing Atuin via Cargo..."
      if cargo install atuin; then
        _zsh_tool_log INFO "✓ Atuin installed successfully"
        return 0
      else
        _zsh_tool_log ERROR "Cargo installation failed"
        return 1
      fi
    fi
  fi

  # Offer secure script installation with verification
  if _zsh_tool_prompt_confirm "Download and review installation script?"; then
    local script_path="/tmp/atuin-install-$$.sh"
    _zsh_tool_log INFO "Downloading installation script to: $script_path"

    if curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh -o "$script_path" 2>/dev/null; then
      _zsh_tool_log INFO "✓ Script downloaded. Please review it."
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "  Script location: $script_path"
      echo "  To review: less $script_path"
      echo "  To execute: bash $script_path"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""

      if _zsh_tool_prompt_confirm "Open script for review now?"; then
        ${PAGER:-less} "$script_path"
      fi

      if _zsh_tool_prompt_confirm "Execute the installation script?"; then
        _zsh_tool_log INFO "Executing installation script..."
        if bash "$script_path"; then
          _zsh_tool_log INFO "✓ Atuin installed successfully"
          rm -f "$script_path"
          return 0
        else
          _zsh_tool_log ERROR "Script installation failed"
          rm -f "$script_path"
          return 1
        fi
      fi
      rm -f "$script_path"
    else
      _zsh_tool_log ERROR "Failed to download installation script"
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

# Sanitize TOML string value to prevent injection attacks
# Removes characters that could break TOML parsing or inject values
_atuin_sanitize_toml_string() {
  local value="$1"
  # Remove quotes, newlines, backslashes that could escape TOML structure
  # Also remove control characters
  echo "$value" | tr -d '"\n\r\\' | tr -d '\0-\037'
}

# Validate and sanitize TOML enum value against allowed list
# Returns the value if valid, or the default if invalid
_atuin_validate_enum() {
  local value="$1"
  local default="$2"
  shift 2
  local -a allowed=("$@")

  # Sanitize first
  value=$(_atuin_sanitize_toml_string "$value")

  # Check if value is in allowed list
  for opt in "${allowed[@]}"; do
    if [[ "$value" == "$opt" ]]; then
      echo "$value"
      return 0
    fi
  done

  # Return default if not in allowed list
  echo "$default"
}

# Validate numeric value
_atuin_validate_number() {
  local value="$1"
  local default="$2"
  local min="${3:-1}"
  local max="${4:-100}"

  # Check if it's a valid integer
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    if (( value >= min && value <= max )); then
      echo "$value"
      return 0
    fi
  fi

  echo "$default"
}

# Configure Atuin settings
_atuin_configure_settings() {
  local sync_enabled="${1:-false}"
  local inline_height="${2:-20}"
  local search_mode="${3:-fuzzy}"
  local filter_mode="${4:-global}"
  local style="${5:-auto}"

  _zsh_tool_log INFO "Configuring Atuin settings..."

  # SECURITY: Validate and sanitize all inputs to prevent TOML injection
  # Validate boolean - only allow "true" or "false"
  if [[ "$sync_enabled" != "true" ]]; then
    sync_enabled="false"
  fi

  # Validate numeric value (1-50 range for inline_height)
  inline_height=$(_atuin_validate_number "$inline_height" "20" 1 50)

  # Validate enum values against allowed options
  search_mode=$(_atuin_validate_enum "$search_mode" "fuzzy" "fuzzy" "prefix" "fulltext" "skim")
  filter_mode=$(_atuin_validate_enum "$filter_mode" "global" "global" "host" "session" "directory")
  style=$(_atuin_validate_enum "$style" "auto" "auto" "compact" "full")

  # Sanitize database path (remove potentially dangerous characters)
  local safe_db_path=$(_atuin_sanitize_toml_string "$ATUIN_DB_PATH")

  _zsh_tool_log DEBUG "Validated settings: sync=$sync_enabled, height=$inline_height, search=$search_mode, filter=$filter_mode, style=$style"

  # Ensure config directory exists
  if ! mkdir -p "$ATUIN_CONFIG_DIR" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to create config directory: $ATUIN_CONFIG_DIR"
    return 1
  fi

  # Initialize config file if it doesn't exist
  if [[ ! -f "$ATUIN_CONFIG_FILE" ]]; then
    _zsh_tool_log INFO "Creating Atuin configuration file..."

    # Generate config using validated/sanitized values only
    cat > "$ATUIN_CONFIG_FILE" <<EOF
## Atuin Configuration
## For full documentation: https://docs.atuin.sh/configuration/config/

# Database path
db_path = "${safe_db_path}"

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

    if [[ ! -f "$ATUIN_CONFIG_FILE" ]]; then
      _zsh_tool_log ERROR "Failed to create config file: $ATUIN_CONFIG_FILE"
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
  # otherwise fall back to sed with comprehensive escaping
  if command -v jq &>/dev/null; then
    # Use jq for safe JSON manipulation (preferred)
    local updated=$(echo "$state" | jq --argjson val "$atuin_state" '.integrations.atuin = $val')
  else
    # Fallback: Escape ALL sed special characters in the replacement string
    # Characters to escape: \ & / [ ] . * ^ $
    local escaped_state="$atuin_state"
    escaped_state="${escaped_state//\\/\\\\}"  # Escape backslashes first
    escaped_state="${escaped_state//&/\\&}"     # Escape ampersand
    escaped_state="${escaped_state//\//\\/}"    # Escape forward slashes
    escaped_state="${escaped_state//\[/\\[}"    # Escape open bracket
    escaped_state="${escaped_state//\]/\\]}"    # Escape close bracket
    escaped_state="${escaped_state//./\\.}"     # Escape dots
    escaped_state="${escaped_state//\*/\\*}"    # Escape asterisks
    escaped_state="${escaped_state//^/\\^}"     # Escape caret
    escaped_state="${escaped_state//\$/\\$}"    # Escape dollar sign

    if echo "$state" | grep -q '"integrations"'; then
      # integrations section exists, update it
      local updated=$(echo "$state" | sed 's/"integrations":[^}]*}/"integrations":{"atuin":'"${escaped_state}"'}/')
    else
      # Add integrations section
      local updated=$(echo "$state" | sed 's/}$/,"integrations":{"atuin":'"${escaped_state}"'}}/')
    fi
  fi

  _zsh_tool_save_state "$updated"
  _zsh_tool_log DEBUG "Atuin state updated successfully"
}

# Run Atuin health check with comprehensive validation
_atuin_health_check() {
  _zsh_tool_log INFO "Running Atuin health check..."

  local health_issues=0
  local -a health_warnings=()
  local -a health_errors=()

  # Check 1: Installation
  if ! _atuin_is_installed; then
    health_errors+=("Atuin not installed")
    _zsh_tool_log ERROR "Atuin not installed"
    return 1
  fi

  # Check 2: Command availability
  if ! command -v atuin >/dev/null 2>&1; then
    health_errors+=("Atuin command not found in PATH")
    _zsh_tool_log ERROR "Atuin command not found in PATH"
    _zsh_tool_log ERROR "Current PATH: $PATH"
    return 1
  fi

  # Check 3: Executable permissions
  local atuin_path=$(command -v atuin)
  if [[ ! -x "$atuin_path" ]]; then
    health_errors+=("Atuin command is not executable: $atuin_path")
    _zsh_tool_log ERROR "Atuin command is not executable: $atuin_path"
    return 1
  fi

  # Check 4: Version verification (validates binary runs correctly)
  local version_output
  version_output=$(atuin --version 2>&1)
  if [[ $? -ne 0 ]] || [[ ! "$version_output" =~ "atuin" ]]; then
    health_errors+=("Atuin binary appears corrupted or incompatible")
    _zsh_tool_log ERROR "Atuin binary appears corrupted or incompatible"
    return 1
  fi

  # Check 5: Database directory
  local db_dir=$(dirname "$ATUIN_DB_PATH")
  if [[ ! -d "$db_dir" ]]; then
    _zsh_tool_log INFO "Creating Atuin database directory: $db_dir"
    mkdir -p "$db_dir" 2>/dev/null || {
      health_errors+=("Failed to create database directory")
      _zsh_tool_log ERROR "Failed to create database directory"
      return 1
    }
  fi

  # Check 6: Database accessibility
  _zsh_tool_log INFO "Verifying Atuin database..."
  local stats_output
  stats_output=$(atuin stats 2>&1)
  local stats_exit=$?

  if [[ $stats_exit -eq 0 ]] && echo "$stats_output" | grep -q "Total commands"; then
    _zsh_tool_log INFO "✓ Atuin database accessible"
  else
    health_warnings+=("Database may need initialization (run: atuin import auto)")
    _zsh_tool_log WARN "Atuin database may need manual initialization"
  fi

  # Check 7: Config file validity
  if [[ -f "$ATUIN_CONFIG_FILE" ]]; then
    # Try to parse the TOML config (basic validation)
    if ! grep -q "search_mode\|filter_mode\|sync" "$ATUIN_CONFIG_FILE" 2>/dev/null; then
      health_warnings+=("Config file may be incomplete or corrupted")
      _zsh_tool_log WARN "Config file may be incomplete: $ATUIN_CONFIG_FILE"
    else
      _zsh_tool_log INFO "✓ Config file exists and appears valid"
    fi
  else
    health_warnings+=("No config file found (using defaults)")
    _zsh_tool_log INFO "No config file found (using defaults)"
  fi

  # Check 8: Shell integration validation (verify init works)
  _zsh_tool_log INFO "Verifying shell integration..."
  local init_output
  init_output=$(atuin init zsh 2>&1)
  if [[ $? -eq 0 ]] && [[ -n "$init_output" ]]; then
    _zsh_tool_log INFO "✓ Shell integration generates correctly"
  else
    health_warnings+=("Shell integration may have issues")
    _zsh_tool_log WARN "Shell integration may have issues"
  fi

  # Check 9: Functional test - can we search history?
  _zsh_tool_log INFO "Verifying search functionality..."
  local search_test
  search_test=$(atuin search --limit 1 --cmd-only "" 2>&1)
  if [[ $? -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Search functionality works"
  else
    health_warnings+=("Search may not work until history is imported")
    _zsh_tool_log INFO "Search requires history data (run: atuin import auto)"
  fi

  # Display comprehensive health report
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Atuin Health Check Results"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Version: $version_output"
  echo "Binary:  $atuin_path"
  echo "Config:  $ATUIN_CONFIG_FILE"
  echo "Database: $ATUIN_DB_PATH"
  echo ""

  # Show stats if available
  if [[ $stats_exit -eq 0 ]]; then
    echo "--- Statistics ---"
    echo "$stats_output" | head -10
    echo ""
  fi

  # Show any warnings
  if [[ ${#health_warnings[@]} -gt 0 ]]; then
    echo "--- Warnings ---"
    for warn in "${health_warnings[@]}"; do
      echo "  ⚠️  $warn"
    done
    echo ""
  fi

  # Final status
  if [[ ${#health_errors[@]} -gt 0 ]]; then
    echo "Status: FAILED"
    for err in "${health_errors[@]}"; do
      echo "  ❌ $err"
    done
  elif [[ ${#health_warnings[@]} -gt 0 ]]; then
    echo "Status: PASSED with warnings"
  else
    echo "Status: PASSED ✓"
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [[ ${#health_errors[@]} -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Atuin health check passed"
    return 0
  else
    _zsh_tool_log ERROR "Atuin health check failed"
    return 1
  fi
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

    if atuin import auto; then
      _zsh_tool_log INFO "✓ History imported successfully"

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

# Verify Atuin sync credentials and connectivity
# Returns 0 if sync is working, 1 if not configured, 2 if connection failed
_atuin_verify_sync() {
  if ! _atuin_is_installed; then
    return 1
  fi

  # Check if sync status command works (indicates logged in)
  local sync_status
  sync_status=$(atuin status 2>&1)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    _zsh_tool_log DEBUG "Sync not configured or not logged in"
    return 1
  fi

  # Check if we can reach the sync server
  if echo "$sync_status" | grep -qi "logged in\|username\|sync"; then
    # Try a sync to verify connectivity
    _zsh_tool_log INFO "Verifying sync connectivity..."
    if atuin sync --force 2>&1 | grep -qi "error\|failed\|unauthorized"; then
      _zsh_tool_log WARN "Sync credentials may be invalid or server unreachable"
      return 2
    fi
    _zsh_tool_log INFO "✓ Sync verification successful"
    return 0
  fi

  return 1
}

# Setup Atuin sync
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
  echo "You can also self-host the sync server."
  echo "For more info: https://docs.atuin.sh/guide/sync/"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Check if user wants to configure sync now
  if _zsh_tool_prompt_confirm "Configure sync now?"; then
    echo ""
    echo "You can either:"
    echo "  [1] Register a new account"
    echo "  [2] Login with existing account"
    echo "  [3] Skip for now"
    echo ""
    echo -n "Choice [1/2/3]: "
    read choice

    case "$choice" in
      1)
        echo ""
        echo "To register, run:"
        echo "  atuin register -u YOUR_USERNAME -e YOUR_EMAIL"
        echo ""
        echo "Then login with:"
        echo "  atuin login -u YOUR_USERNAME"
        echo ""
        _zsh_tool_log INFO "After registering and logging in, run: atuin sync"
        ;;
      2)
        echo ""
        echo "To login, run:"
        echo "  atuin login -u YOUR_USERNAME"
        echo ""
        if _zsh_tool_prompt_confirm "Have you already logged in?"; then
          # Verify the credentials work
          local verify_result
          _atuin_verify_sync
          verify_result=$?

          case $verify_result in
            0)
              _zsh_tool_log INFO "✓ Sync credentials verified successfully"
              ;;
            1)
              _zsh_tool_log WARN "Sync not configured. Please login first: atuin login -u YOUR_USERNAME"
              ;;
            2)
              _zsh_tool_log ERROR "Sync verification failed. Check credentials or network connection."
              _zsh_tool_log INFO "Try: atuin status"
              ;;
          esac
        fi
        ;;
      *)
        _zsh_tool_log INFO "Sync setup skipped. You can configure it later."
        ;;
    esac
  fi

  _zsh_tool_log INFO "✓ Sync information provided"
  _zsh_tool_log INFO "Sync is optional and can be configured later"

  return 0
}

# Detect tools that might override Ctrl+R keybinding
# Returns list of detected tools that commonly override history search
_atuin_detect_keybinding_conflicts() {
  local -a conflicts=()

  # Kiro CLI / Amazon Q - checks multiple possible config locations
  if [[ -f "${HOME}/.config/amazonq/shell/zshrc" ]] || \
     [[ -f "${HOME}/.local/share/amazonq/shell/zshrc" ]] || \
     command -v q &>/dev/null || \
     command -v amazon-q &>/dev/null; then
    conflicts+=("kiro-cli")
  fi

  # FZF - commonly binds Ctrl+R
  if command -v fzf &>/dev/null && [[ -f "${HOME}/.fzf.zsh" ]]; then
    conflicts+=("fzf")
  fi

  # McFly - another history search tool
  if command -v mcfly &>/dev/null; then
    conflicts+=("mcfly")
  fi

  # Hstr - bash/zsh history suggest box
  if command -v hstr &>/dev/null; then
    conflicts+=("hstr")
  fi

  # Return space-separated list
  echo "${conflicts[*]}"
}

# Configure Kiro CLI compatibility
_atuin_configure_kiro_compatibility() {
  _zsh_tool_log INFO "Configuring Atuin compatibility with other tools..."

  # Detect potential conflicts
  local conflicts=$(_atuin_detect_keybinding_conflicts)

  if [[ -n "$conflicts" ]]; then
    _zsh_tool_log INFO "Detected tools that may override Ctrl+R: $conflicts"
    _zsh_tool_log INFO "Keybinding restoration will be configured"
  fi

  # The actual keybinding restoration happens in the .zshrc
  # This function just logs the compatibility setup

  _zsh_tool_log INFO "Keybinding compatibility configured"
  _zsh_tool_log INFO "Note: Ctrl+R will be restored to Atuin after other tools load"

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

  # Add keybinding restoration fix if needed (for Kiro CLI, FZF, McFly, etc.)
  if [[ "$restore_kiro" == "true" ]]; then
    if grep -q "Restore Atuin keybindings" "$zshrc_custom" 2>/dev/null; then
      _zsh_tool_log INFO "Keybinding restoration fix already present"
    else
      _zsh_tool_log INFO "Adding keybinding restoration fix..."

      cat >> "$zshrc_custom" <<'EOF'

# ===== Restore Atuin Keybindings =====
# Some tools (Kiro CLI, FZF, McFly, etc.) override Ctrl+R for their own history search.
# This restores Atuin's keybindings after other tools have loaded.
# The detection is widget-based (not tool-specific) for maximum compatibility.
if command -v atuin &>/dev/null; then
    # Function to restore Atuin keybindings - can be called after any tool loads
    _restore_atuin_keybindings() {
        # Only proceed if Atuin widgets are registered
        local widgets_available=0

        # Check and bind emacs mode
        if zle -la 2>/dev/null | grep -q '^atuin-search$'; then
            bindkey -M emacs '^r' atuin-search
            widgets_available=1
        fi

        # Check and bind vi insert mode
        if zle -la 2>/dev/null | grep -q '^atuin-search-viins$'; then
            bindkey -M viins '^r' atuin-search-viins
            widgets_available=1
        fi

        # Check and bind vi command mode
        if zle -la 2>/dev/null | grep -q '^atuin-search-vicmd$'; then
            bindkey -M vicmd '^r' atuin-search-vicmd
            widgets_available=1
        fi

        # Fallback: If specific widgets not found but atuin-search exists, use it
        if [[ $widgets_available -eq 0 ]]; then
            if zle -la 2>/dev/null | grep -q 'atuin'; then
                # Use the first available atuin widget
                local widget=$(zle -la 2>/dev/null | grep 'atuin' | head -1)
                if [[ -n "$widget" ]]; then
                    bindkey '^r' "$widget"
                fi
            fi
        fi
    }

    # Restore keybindings immediately (runs after all rc files loaded)
    _restore_atuin_keybindings

    # Also register for precmd to handle tools that load lazily
    # This ensures Atuin keybindings are restored even if a tool
    # overrides them after initial shell setup
    if [[ -z "$_ATUIN_KEYBIND_RESTORED" ]]; then
        _atuin_precmd_keybind_restore() {
            _restore_atuin_keybindings
            # Only need to run once, then remove from precmd
            precmd_functions=(${precmd_functions:#_atuin_precmd_keybind_restore})
            export _ATUIN_KEYBIND_RESTORED=1
        }
        precmd_functions+=(_atuin_precmd_keybind_restore)
    fi
fi
EOF

      _zsh_tool_log INFO "Keybinding restoration fix added"
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

  # Add matches using compadd
  # -U: Don't require match with current prefix
  # -V: Named group for completion display
  # -Q: Don't quote special characters (preserve as-is)
  local expl
  _description -V history-atuin expl "Atuin history"
  compadd "${expl[@]}" -U -Q -- "${matches[@]}"

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
  # Register the completer function
  # Add to the completer list - runs after _expand but before _complete
  local current_completers
  zstyle -g current_completers ':completion:*' completer

  # Only add if not already present
  if [[ ! " ${current_completers[*]} " =~ " _atuin_history_completer " ]]; then
    # Insert after _expand (if present) or at the beginning
    local -a new_completers
    local found=0
    for c in "${current_completers[@]}"; do
      new_completers+=("$c")
      if [[ "$c" == "_expand" ]]; then
        new_completers+=("_atuin_history_completer")
        found=1
      fi
    done

    # If _expand wasn't found, prepend
    if (( ! found )); then
      new_completers=("_atuin_history_completer" "${current_completers[@]}")
    fi

    zstyle ':completion:*' completer "${new_completers[@]}"
  fi

  # Configure Atuin completion display
  zstyle ':completion:*:history-atuin:*' format '%F{yellow}── Atuin History ──%f'
  zstyle ':completion:*:history-atuin:*' group-name 'history-atuin'

  # Create ZLE widgets
  zle -N _atuin_complete_line
  zle -N _atuin_hybrid_complete

  # Optional: Bind to a key (uncomment to enable)
  # bindkey '^X^H' _atuin_complete_line  # Ctrl+X Ctrl+H for Atuin line completion
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

# ===== Atuin Tab Completion Integration =====
# Enables TAB completion from Atuin's history database
# Usage: type partial command and press TAB to get suggestions from history
# Configuration:
#   ATUIN_COMPLETE_LIMIT=20        # Max suggestions
#   ATUIN_COMPLETE_MIN_CHARS=2     # Min chars before suggesting
#   ATUIN_COMPLETE_SEARCH_MODE=prefix  # prefix, fuzzy, full-text

if command -v atuin >/dev/null 2>&1; then
  # Source the Atuin completion functions
  source "${ZSH_TOOL_DIR:-$HOME/Repos/github/zsh}/lib/integrations/atuin.zsh" 2>/dev/null

  # Initialize Atuin completion
  _atuin_setup_completion

  # Optional: Replace default TAB with hybrid completion
  # Uncomment the next line to try Atuin first, then fallback to standard completion
  # bindkey '^I' _atuin_hybrid_complete
fi
EOF

  _zsh_tool_log INFO "✓ Atuin completion integration added"
  return 0
}
