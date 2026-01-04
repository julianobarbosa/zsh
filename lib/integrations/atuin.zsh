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

  # Ensure config directory exists
  if ! mkdir -p "$ATUIN_CONFIG_DIR" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to create config directory: $ATUIN_CONFIG_DIR"
    return 1
  fi

  # Initialize config file if it doesn't exist
  if [[ ! -f "$ATUIN_CONFIG_FILE" ]]; then
    _zsh_tool_log INFO "Creating Atuin configuration file..."

    cat > "$ATUIN_CONFIG_FILE" <<EOF
## Atuin Configuration
## For full documentation: https://docs.atuin.sh/configuration/config/

# Database path
db_path = "${ATUIN_DB_PATH}"

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
    _zsh_tool_log INFO "Note: If Amazon Q is enabled, keybinding will be restored after Amazon Q loads"
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

# Run Atuin health check
_atuin_health_check() {
  _zsh_tool_log INFO "Running Atuin health check..."

  # Check if installed
  if ! _atuin_is_installed; then
    _zsh_tool_log ERROR "Atuin not installed"
    return 1
  fi

  # Verify command is available
  if ! command -v atuin >/dev/null 2>&1; then
    _zsh_tool_log ERROR "Atuin command not found in PATH"
    _zsh_tool_log ERROR "Current PATH: $PATH"
    return 1
  fi

  # Verify atuin is executable
  local atuin_path=$(command -v atuin)
  if [[ ! -x "$atuin_path" ]]; then
    _zsh_tool_log ERROR "Atuin command is not executable: $atuin_path"
    return 1
  fi

  # Check database directory
  local db_dir=$(dirname "$ATUIN_DB_PATH")
  if [[ ! -d "$db_dir" ]]; then
    _zsh_tool_log INFO "Creating Atuin database directory: $db_dir"
    mkdir -p "$db_dir" 2>/dev/null || {
      _zsh_tool_log ERROR "Failed to create database directory"
      return 1
    }
  fi

  # Try to get stats (this will create DB if it doesn't exist)
  _zsh_tool_log INFO "Initializing Atuin database..."
  if atuin stats 2>&1 | grep -q "Total commands"; then
    _zsh_tool_log INFO "✓ Atuin database initialized successfully"
  else
    _zsh_tool_log WARN "Atuin database may need manual initialization"
    _zsh_tool_log INFO "Run: atuin import auto"
  fi

  # Display version and basic info
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Atuin Health Check Results"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  atuin --version
  echo ""
  atuin stats 2>/dev/null || echo "Statistics not available yet (database empty)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

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

  _zsh_tool_log INFO "✓ Sync information provided"
  _zsh_tool_log INFO "Sync is optional and can be configured later"

  return 0
}

# Configure Amazon Q compatibility
_atuin_configure_amazonq_compatibility() {
  _zsh_tool_log INFO "Configuring Atuin compatibility with Amazon Q..."

  # The actual keybinding restoration happens in the .zshrc
  # This function just logs the compatibility setup

  _zsh_tool_log INFO "✓ Amazon Q compatibility configured"
  _zsh_tool_log INFO "Note: Ctrl+R will be restored to Atuin after Amazon Q loads"

  return 0
}

# Add Atuin init to .zshrc custom layer
_atuin_add_to_zshrc_custom() {
  local restore_amazonq="${1:-false}"

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
    _zsh_tool_log INFO "✓ Atuin already configured in .zshrc.local"
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

    _zsh_tool_log INFO "✓ Atuin initialization added to .zshrc.local"
  fi

  # Add Amazon Q compatibility fix if needed
  if [[ "$restore_amazonq" == "true" ]]; then
    if grep -q "Restore Atuin keybindings after Amazon Q" "$zshrc_custom" 2>/dev/null; then
      _zsh_tool_log INFO "✓ Amazon Q compatibility fix already present"
    else
      _zsh_tool_log INFO "Adding Amazon Q compatibility fix..."

      cat >> "$zshrc_custom" <<'EOF'

# Restore Atuin keybindings after Amazon Q (Amazon Q overrides Ctrl+R)
# This ensures Ctrl+R opens Atuin search instead of just redisplaying the prompt
# HIGH-2 FIX: Check if widgets exist before binding, add vicmd mode handling
if command -v atuin &>/dev/null; then
    # Check if atuin-search widget exists before binding (emacs mode)
    if zle -la | grep -q '^atuin-search$'; then
        bindkey -M emacs '^r' atuin-search
    fi
    # Check if atuin-search-viins widget exists before binding (vi insert mode)
    if zle -la | grep -q '^atuin-search-viins$'; then
        bindkey -M viins '^r' atuin-search-viins
    fi
    # Check if atuin-search-vicmd widget exists before binding (vi command mode)
    if zle -la | grep -q '^atuin-search-vicmd$'; then
        bindkey -M vicmd '^r' atuin-search-vicmd
    fi
fi
EOF

      _zsh_tool_log INFO "✓ Amazon Q compatibility fix added"
    fi
  fi

  return 0
}

# Main installation flow for Atuin integration
atuin_install_integration() {
  local import_history="${1:-true}"
  local configure_amazonq="${2:-false}"
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
  _atuin_add_to_zshrc_custom "$configure_amazonq"

  # Step 6: Configure Amazon Q compatibility if requested
  if [[ "$configure_amazonq" == "true" ]]; then
    _atuin_configure_amazonq_compatibility
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
  local configure_amazonq="false"
  local sync_enabled="false"
  local tab_completion_enabled="true"

  # Parse command-line options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-import)
        import_history="false"
        shift
        ;;
      --amazonq)
        configure_amazonq="true"
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
        echo "  --amazonq           Configure Amazon Q keybinding compatibility"
        echo "  --sync              Enable Atuin sync (requires account setup)"
        echo "  --no-completion     Disable tab completion integration"
        echo "  --help              Show this help message"
        echo ""
        echo "Example:"
        echo "  zsh-tool-install-atuin --amazonq --sync"
        return 0
        ;;
      *)
        _zsh_tool_log WARN "Unknown option: $1"
        shift
        ;;
    esac
  done

  # Call the main installation function
  atuin_install_integration "$import_history" "$configure_amazonq" "$sync_enabled" "$tab_completion_enabled"
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
