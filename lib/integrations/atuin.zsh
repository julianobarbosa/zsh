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
    _zsh_tool_log INFO "Running: atuin import auto"

    if atuin import auto; then
      _zsh_tool_log INFO "✓ History imported successfully"

      # Show stats after import
      echo ""
      atuin stats 2>/dev/null || true
      echo ""
    else
      _zsh_tool_log WARN "History import failed or had issues"
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
if command -v atuin &>/dev/null; then
    bindkey -M emacs '^r' atuin-search
    bindkey -M viins '^r' atuin-search-viins
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

  # Step 7: Health check
  if ! _atuin_health_check; then
    _zsh_tool_log WARN "Atuin health check had issues"
    _zsh_tool_log INFO "You may need to complete setup manually"
  fi

  # Step 8: Import existing history
  if [[ "$import_history" == "true" ]]; then
    _atuin_import_history
  fi

  # Step 9: Provide sync information
  if [[ "$sync_enabled" == "true" ]]; then
    _atuin_setup_sync
  fi

  _zsh_tool_log INFO "✓ Atuin shell history integration complete"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Atuin Integration Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  ✓ Atuin installed and configured"
  echo "  ✓ Shell integration added to .zshrc.local"
  echo "  ✓ Ctrl+R bound to Atuin search"
  echo ""
  echo "Next steps:"
  echo "  1. Reload shell: exec zsh"
  echo "  2. Press Ctrl+R to search history"
  echo "  3. View stats: atuin stats"
  echo "  4. (Optional) Setup sync: atuin register"
  echo ""
  echo "Documentation: https://docs.atuin.sh"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  return 0
}

# Alias for consistency with naming convention
alias _atuin_install_integration='atuin_install_integration'
