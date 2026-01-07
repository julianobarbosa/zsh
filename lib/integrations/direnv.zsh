#!/usr/bin/env zsh
# direnv + 1Password Integration
# Manages secure environment variable loading with biometric authentication
# Credentials are fetched from 1Password vault, never stored on disk

# direnv configuration paths
DIRENV_LIB_DIR="${DIRENV_LIB_DIR:-${HOME}/.direnv/lib}"
DIRENV_TEMPLATE_DIR="${DIRENV_TEMPLATE_DIR:-${HOME}/.direnv/templates}"
DIRENV_AI_KEYS_HELPER="${DIRENV_AI_KEYS_HELPER:-${DIRENV_LIB_DIR}/ai-keys.sh}"
DIRENV_AI_KEYS_TEMPLATE="${DIRENV_AI_KEYS_TEMPLATE:-${DIRENV_TEMPLATE_DIR}/ai-keys.env.tpl}"

# Check if direnv is installed
_direnv_is_installed() {
  command -v direnv &>/dev/null
}

# Check if 1Password CLI is installed
_direnv_op_is_installed() {
  command -v op &>/dev/null
}

# Detect direnv installation
_direnv_detect() {
  _zsh_tool_log INFO "Detecting direnv installation..."

  if _direnv_is_installed; then
    local version=$(direnv version 2>/dev/null)
    _zsh_tool_log INFO "direnv detected: $version"
    return 0
  else
    _zsh_tool_log INFO "direnv not found"
    return 1
  fi
}

# Detect 1Password CLI installation
_direnv_op_detect() {
  _zsh_tool_log INFO "Detecting 1Password CLI installation..."

  if _direnv_op_is_installed; then
    local version=$(op --version 2>/dev/null)
    _zsh_tool_log INFO "1Password CLI detected: $version"
    return 0
  else
    _zsh_tool_log INFO "1Password CLI not found"
    return 1
  fi
}

# Verify 1Password desktop app integration
_direnv_op_has_desktop_integration() {
  # Check macOS 1Password app integration config locations
  [[ -f "$HOME/.config/op/config" ]] || \
  [[ -f "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/Library/Application Support/1Password/config/settings.json" ]]
}

# Install direnv if missing
_direnv_install() {
  _zsh_tool_log INFO "direnv installation required"

  if _direnv_is_installed; then
    _zsh_tool_log INFO "direnv already installed"
    return 0
  fi

  echo ""
  echo "direnv Installation Guide"
  echo "========================="
  echo ""
  echo "direnv is a shell extension that loads/unloads environment"
  echo "variables when you enter/exit directories."
  echo ""
  echo "Installation options:"
  echo ""
  echo "  1. Homebrew (macOS/Linux - Recommended):"
  echo "     brew install direnv"
  echo ""
  echo "  2. Package managers:"
  echo "     Arch: pacman -S direnv"
  echo "     Ubuntu: apt install direnv"
  echo "     Nix: nix-env -iA nixpkgs.direnv"
  echo ""
  echo "For more info: https://direnv.net"
  echo ""

  # Try Homebrew installation first if available
  if command -v brew >/dev/null 2>&1; then
    if _zsh_tool_prompt_confirm "Install direnv via Homebrew? (recommended)"; then
      _zsh_tool_log INFO "Installing direnv via Homebrew..."
      if brew install direnv; then
        _zsh_tool_log INFO "direnv installed successfully"
        return 0
      else
        _zsh_tool_log ERROR "Homebrew installation failed"
        return 1
      fi
    fi
  fi

  if _zsh_tool_prompt_confirm "Have you installed direnv manually?"; then
    if _direnv_is_installed; then
      _zsh_tool_log INFO "direnv installation verified"
      return 0
    else
      _zsh_tool_log WARN "direnv command not found in PATH"
      _zsh_tool_log WARN "Try reloading your shell: exec zsh"
      return 1
    fi
  else
    _zsh_tool_log WARN "direnv installation skipped"
    return 1
  fi
}

# Install 1Password CLI if missing
_direnv_op_install() {
  _zsh_tool_log INFO "1Password CLI installation required"

  if _direnv_op_is_installed; then
    _zsh_tool_log INFO "1Password CLI already installed"
    return 0
  fi

  echo ""
  echo "1Password CLI Installation Guide"
  echo "================================="
  echo ""
  echo "The 1Password CLI (op) enables secure credential access"
  echo "with biometric authentication (Touch ID on macOS)."
  echo ""
  echo "Installation options:"
  echo ""
  echo "  1. Homebrew (macOS - Recommended):"
  echo "     brew install --cask 1password-cli"
  echo ""
  echo "  2. Download from 1Password:"
  echo "     https://developer.1password.com/docs/cli/get-started/"
  echo ""
  echo "After installation, enable CLI integration in 1Password:"
  echo "  1Password > Settings > Developer > Command-Line Interface"
  echo ""

  # Try Homebrew installation first if available
  if command -v brew >/dev/null 2>&1; then
    if _zsh_tool_prompt_confirm "Install 1Password CLI via Homebrew? (recommended)"; then
      _zsh_tool_log INFO "Installing 1Password CLI via Homebrew..."
      if brew install --cask 1password-cli; then
        _zsh_tool_log INFO "1Password CLI installed successfully"
        return 0
      else
        _zsh_tool_log ERROR "Homebrew installation failed"
        return 1
      fi
    fi
  fi

  if _zsh_tool_prompt_confirm "Have you installed 1Password CLI manually?"; then
    if _direnv_op_is_installed; then
      _zsh_tool_log INFO "1Password CLI installation verified"
      return 0
    else
      _zsh_tool_log WARN "1Password CLI (op) not found in PATH"
      return 1
    fi
  else
    _zsh_tool_log WARN "1Password CLI installation skipped"
    return 1
  fi
}

# Setup direnv shell hook in .zshrc
_direnv_setup_shell_hook() {
  local zshrc="$HOME/.zshrc"
  local hook_line='eval "$(direnv hook zsh)"'

  if grep -qF "$hook_line" "$zshrc" 2>/dev/null; then
    _zsh_tool_log INFO "direnv hook already in .zshrc"
    return 0
  fi

  _zsh_tool_log INFO "Adding direnv hook to .zshrc..."

  echo "" >> "$zshrc"
  echo "# direnv shell hook (added by zsh-tool)" >> "$zshrc"
  echo "$hook_line" >> "$zshrc"

  _zsh_tool_log INFO "direnv hook added to .zshrc"
  return 0
}

# Create direnv directory structure
_direnv_create_structure() {
  _zsh_tool_log INFO "Creating direnv directory structure..."

  mkdir -p "$DIRENV_LIB_DIR" || {
    _zsh_tool_log ERROR "Failed to create $DIRENV_LIB_DIR"
    return 1
  }

  mkdir -p "$DIRENV_TEMPLATE_DIR" || {
    _zsh_tool_log ERROR "Failed to create $DIRENV_TEMPLATE_DIR"
    return 1
  }

  _zsh_tool_log INFO "direnv directories created"
  return 0
}

# Install AI keys helper function
_direnv_install_ai_keys_helper() {
  _zsh_tool_log INFO "Installing AI keys helper function..."

  # Ensure directory exists
  mkdir -p "$(dirname "$DIRENV_AI_KEYS_HELPER")" 2>/dev/null

  cat > "$DIRENV_AI_KEYS_HELPER" << 'HELPER_EOF'
#!/usr/bin/env bash
# AI API Keys loader - fetches credentials from 1Password
# Usage: source ~/.direnv/lib/ai-keys.sh && load_ai_keys
#
# This helper fetches AI API keys from 1Password using biometric auth.
# Credentials are never stored on disk - they exist only in memory.

load_ai_keys() {
  # Check if op is available
  if ! command -v op &>/dev/null; then
    echo "1Password CLI (op) not found - AI keys not loaded"
    return 1
  fi

  # Enable session caching (5 minutes) to reduce Touch ID prompts
  export OP_CACHE_EXPIRES_IN=300

  # Check for template file
  local template="${DIRENV_AI_KEYS_TEMPLATE:-$HOME/.direnv/templates/ai-keys.env.tpl}"
  if [[ ! -f "$template" ]]; then
    echo "Template not found: $template"
    echo "Create it with your 1Password secret references"
    return 1
  fi

  # Inject secrets from 1Password
  # op inject reads the template and replaces {{ op://... }} references
  # with actual values fetched from 1Password vault
  local injected
  if injected=$(op inject -i "$template" 2>/dev/null); then
    eval "$injected"
    echo "AI keys loaded ($(date +%H:%M))"
    return 0
  else
    echo "AI keys not loaded - check 1Password authentication"
    return 1
  fi
}

# Optional: Unload AI keys (called automatically by direnv on exit)
unload_ai_keys() {
  unset OPENAI_API_KEY
  unset ANTHROPIC_API_KEY
  unset GOOGLE_AI_API_KEY
  unset GITHUB_TOKEN
  # Add more as needed
}
HELPER_EOF

  chmod +x "$DIRENV_AI_KEYS_HELPER"
  _zsh_tool_log INFO "AI keys helper installed: $DIRENV_AI_KEYS_HELPER"
  return 0
}

# Install AI keys template
_direnv_install_ai_keys_template() {
  _zsh_tool_log INFO "Installing AI keys template..."

  # Ensure directory exists
  mkdir -p "$(dirname "$DIRENV_AI_KEYS_TEMPLATE")" 2>/dev/null

  # Only create if doesn't exist (preserve user customizations)
  if [[ -f "$DIRENV_AI_KEYS_TEMPLATE" ]]; then
    _zsh_tool_log INFO "Template already exists (preserved): $DIRENV_AI_KEYS_TEMPLATE"
    return 0
  fi

  cat > "$DIRENV_AI_KEYS_TEMPLATE" << 'TEMPLATE_EOF'
# AI API Keys - fetched from 1Password
# Customize vault/item names to match your 1Password setup
# Format: VARIABLE_NAME={{ op://Vault/Item/field }}
#
# Example vault structure:
#   AI Keys (vault)
#   - OpenAI (item)
#      - credential (field containing API key)
#   - Anthropic (item)
#      - credential (field containing API key)
#
# Uncomment and customize the lines below:

# OPENAI_API_KEY={{ op://AI Keys/OpenAI/credential }}
# ANTHROPIC_API_KEY={{ op://AI Keys/Anthropic/credential }}
# GOOGLE_AI_API_KEY={{ op://AI Keys/Google AI/credential }}
# GITHUB_TOKEN={{ op://Development/GitHub/token }}

# Add more keys as needed...
TEMPLATE_EOF

  _zsh_tool_log INFO "AI keys template installed: $DIRENV_AI_KEYS_TEMPLATE"
  _zsh_tool_log INFO "Edit the template to match your 1Password vault structure"
  return 0
}

# Update state.json with direnv installation info
_direnv_update_state() {
  local installed="${1:-false}"
  local direnv_version="${2:-unknown}"
  local op_version="${3:-unknown}"
  local onepassword_integration="${4:-false}"

  _zsh_tool_log DEBUG "Updating direnv state in state.json..."

  # Load current state
  local state=$(_zsh_tool_load_state)

  # Create direnv integration entry
  local direnv_state=$(cat <<EOF
{
  "installed": $installed,
  "direnv_version": "$direnv_version",
  "op_version": "$op_version",
  "onepassword_integration": $onepassword_integration,
  "helper_path": "$DIRENV_AI_KEYS_HELPER",
  "template_path": "$DIRENV_AI_KEYS_TEMPLATE"
}
EOF
)

  # Update state using jq if available
  if command -v jq &>/dev/null; then
    local updated=$(echo "$state" | jq --argjson val "$direnv_state" '.integrations.direnv = $val')
  else
    # Fallback: Escape sed special characters
    local escaped_state="$direnv_state"
    escaped_state="${escaped_state//\\/\\\\}"
    escaped_state="${escaped_state//&/\\&}"
    escaped_state="${escaped_state//\//\\/}"

    if echo "$state" | grep -q '"integrations"'; then
      local updated=$(echo "$state" | sed 's/"integrations":[^}]*}/"integrations":{"direnv":'"${escaped_state}"'}/')
    else
      local updated=$(echo "$state" | sed 's/}$/,"integrations":{"direnv":'"${escaped_state}"'}}/')
    fi
  fi

  _zsh_tool_save_state "$updated"
  _zsh_tool_log DEBUG "direnv state updated successfully"
}

# Run direnv + 1Password health check
_direnv_health_check() {
  _zsh_tool_log INFO "Running direnv + 1Password health check..."

  local health_issues=0
  local -a health_warnings=()
  local -a health_errors=()

  echo ""
  echo "direnv + 1Password Health Check"
  echo "================================"
  echo ""

  # Check 1: direnv installation
  if _direnv_is_installed; then
    local direnv_version=$(direnv version 2>/dev/null)
    echo "direnv: $direnv_version"
  else
    echo "direnv: not installed"
    health_errors+=("direnv not installed")
  fi

  # Check 2: 1Password CLI installation
  if _direnv_op_is_installed; then
    local op_version=$(op --version 2>/dev/null)
    echo "1Password CLI: $op_version"
  else
    echo "1Password CLI: not installed"
    health_errors+=("1Password CLI not installed")
  fi

  # Check 3: 1Password desktop integration
  if _direnv_op_has_desktop_integration; then
    echo "1Password desktop integration: configured"
  else
    echo "1Password desktop integration: not detected"
    health_warnings+=("1Password desktop app integration not detected - enable in Settings > Developer > CLI")
  fi

  # Check 4: Helper file
  if [[ -f "$DIRENV_AI_KEYS_HELPER" ]]; then
    echo "AI keys helper: installed"
  else
    echo "AI keys helper: not found"
    health_errors+=("AI keys helper not installed")
  fi

  # Check 5: Template file
  if [[ -f "$DIRENV_AI_KEYS_TEMPLATE" ]]; then
    echo "AI keys template: installed"
    # Check if template has been customized (not just comments)
    if grep -q "^[^#]*op://" "$DIRENV_AI_KEYS_TEMPLATE" 2>/dev/null; then
      echo "AI keys template: configured"
    else
      echo "AI keys template: not configured (all lines commented)"
      health_warnings+=("AI keys template exists but no secrets configured")
    fi
  else
    echo "AI keys template: not found"
    health_errors+=("AI keys template not installed")
  fi

  # Check 6: Shell hook in .zshrc
  if grep -q 'direnv hook zsh' "$HOME/.zshrc" 2>/dev/null; then
    echo "Shell hook: configured"
  else
    echo "Shell hook: not configured"
    health_warnings+=("direnv shell hook not in .zshrc")
  fi

  echo ""

  # Show warnings
  if [[ ${#health_warnings[@]} -gt 0 ]]; then
    echo "--- Warnings ---"
    for warn in "${health_warnings[@]}"; do
      echo "  $warn"
    done
    echo ""
  fi

  # Final status
  if [[ ${#health_errors[@]} -gt 0 ]]; then
    echo "Status: FAILED"
    for err in "${health_errors[@]}"; do
      echo "  $err"
    done
    echo ""
    return 1
  elif [[ ${#health_warnings[@]} -gt 0 ]]; then
    echo "Status: PASSED with warnings"
  else
    echo "Status: PASSED"
  fi

  echo ""
  return 0
}

# Add direnv initialization to .zshrc.local
_direnv_add_to_zshrc_custom() {
  _zsh_tool_log INFO "Adding direnv initialization to .zshrc.local..."

  local zshrc_custom="${HOME}/.zshrc.local"

  # Ensure .zshrc.local exists
  if [[ ! -f "$zshrc_custom" ]]; then
    touch "$zshrc_custom" 2>/dev/null || {
      _zsh_tool_log ERROR "Failed to create $zshrc_custom"
      return 1
    }
  fi

  # Check if already configured
  if grep -q "direnv hook zsh" "$zshrc_custom" 2>/dev/null; then
    _zsh_tool_log INFO "direnv already configured in .zshrc.local"
    return 0
  fi

  _zsh_tool_log INFO "Adding direnv initialization..."

  cat >> "$zshrc_custom" << 'EOF'

# ===== direnv + 1Password Integration =====
# Automatic environment variable loading with secure credential management
# https://direnv.net | https://developer.1password.com/docs/cli/
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi
EOF

  _zsh_tool_log INFO "direnv initialization added to .zshrc.local"
  return 0
}

# Main installation function
direnv_install_integration() {
  _zsh_tool_log INFO "Setting up direnv + 1Password integration..."

  echo ""
  echo "direnv + 1Password Integration Setup"
  echo "====================================="
  echo ""
  echo "This integration provides:"
  echo "  - Automatic environment variable loading per directory"
  echo "  - Secure credential fetching from 1Password vault"
  echo "  - Biometric authentication (Touch ID on macOS)"
  echo "  - Credentials never stored on disk"
  echo ""

  # Step 1: Install direnv
  if ! _direnv_detect; then
    if ! _direnv_install; then
      _zsh_tool_log ERROR "direnv installation required but not completed"
      return 1
    fi
  fi

  # Step 2: Install 1Password CLI
  if ! _direnv_op_detect; then
    if ! _direnv_op_install; then
      _zsh_tool_log WARN "1Password CLI not installed - continuing without it"
      _zsh_tool_log WARN "You can install it later for secure credential management"
    fi
  fi

  # Step 3: Verify 1Password desktop app integration
  if _direnv_op_is_installed && ! _direnv_op_has_desktop_integration; then
    _zsh_tool_log WARN "1Password desktop app integration not detected"
    echo ""
    echo "To enable Touch ID authentication:"
    echo "  1. Open 1Password desktop app"
    echo "  2. Go to Settings > Developer"
    echo "  3. Enable 'Integrate with 1Password CLI'"
    echo ""
  fi

  # Step 4: Create directory structure
  _direnv_create_structure || return 1

  # Step 5: Install helper and template
  _direnv_install_ai_keys_helper || return 1
  _direnv_install_ai_keys_template || return 1

  # Step 6: Add to .zshrc.local
  _direnv_add_to_zshrc_custom || return 1

  # Step 7: Health check
  _direnv_health_check

  # Step 8: Update state
  local direnv_version=$(direnv version 2>/dev/null || echo "unknown")
  local op_version=$(op --version 2>/dev/null || echo "not installed")
  local has_op=$(_direnv_op_is_installed && echo "true" || echo "false")
  _direnv_update_state "true" "$direnv_version" "$op_version" "$has_op"

  _zsh_tool_log INFO "direnv + 1Password integration complete!"

  echo ""
  echo "direnv + 1Password Integration Summary"
  echo "======================================="
  echo ""
  echo "  direnv installed and configured"
  if _direnv_op_is_installed; then
    echo "  1Password CLI installed"
  else
    echo "  1Password CLI: not installed (optional)"
  fi
  echo "  Helper installed: $DIRENV_AI_KEYS_HELPER"
  echo "  Template installed: $DIRENV_AI_KEYS_TEMPLATE"
  echo ""
  echo "Next steps:"
  echo "  1. Edit ~/.direnv/templates/ai-keys.env.tpl to match your 1Password vault"
  echo "  2. Create .envrc in your project directory:"
  echo "     source ~/.direnv/lib/ai-keys.sh"
  echo "     load_ai_keys"
  echo "  3. Run: direnv allow"
  echo "  4. Reload shell: exec zsh"
  echo ""
  echo "Documentation:"
  echo "  - direnv: https://direnv.net"
  echo "  - 1Password CLI: https://developer.1password.com/docs/cli/"
  echo ""

  return 0
}

# Alias for consistency with naming convention
alias _direnv_install_integration='direnv_install_integration'

# ============================================================================
# Public Commands (zsh-tool naming convention)
# ============================================================================

# Public command for direnv installation
zsh-tool-direnv() {
  local subcommand="${1:-status}"

  case "$subcommand" in
    install)
      direnv_install_integration
      ;;
    status|health)
      _direnv_health_check
      ;;
    *)
      cat <<DIRENV_HELP
Usage: zsh-tool-direnv [command]

Commands:
  install     Install direnv + 1Password integration
  status      Check integration health

Example project setup:
  1. Create .envrc in your project:
     source ~/.direnv/lib/ai-keys.sh
     load_ai_keys

  2. Allow direnv:
     direnv allow

For more info:
  - direnv: https://direnv.net
  - 1Password CLI: https://developer.1password.com/docs/cli/
DIRENV_HELP
      ;;
  esac
}
