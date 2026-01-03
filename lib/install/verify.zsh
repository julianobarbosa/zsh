#!/usr/bin/env zsh
# Story 1.7: Installation Verification and Summary
# Module: lib/install/verify.zsh
# Purpose: Verify installation and display summary

# ============================================================================
# VERIFICATION FUNCTIONS
# ============================================================================

# Check if Oh My Zsh is loaded
# Returns: 0 if OMZ is loaded, 1 otherwise
_zsh_tool_check_omz_loaded() {
  _zsh_tool_log DEBUG "Checking if Oh My Zsh is loaded"

  # Check $ZSH variable exists
  if [[ -z "$ZSH" ]]; then
    _zsh_tool_log DEBUG "ZSH variable not set"
    return 1
  fi

  # Check oh-my-zsh.sh exists
  if [[ ! -f "$ZSH/oh-my-zsh.sh" ]]; then
    _zsh_tool_log DEBUG "oh-my-zsh.sh not found at $ZSH"
    return 1
  fi

  # Check OMZ functions are defined
  if ! typeset -f omz >/dev/null 2>&1; then
    _zsh_tool_log DEBUG "omz function not defined"
    return 1
  fi

  _zsh_tool_log DEBUG "Oh My Zsh is loaded successfully"
  return 0
}

# Check if configured plugins are loaded
# Returns: 0 if all plugins are loaded, 1 otherwise
_zsh_tool_check_plugins_loaded() {
  _zsh_tool_log DEBUG "Checking if plugins are loaded"

  # Read plugins from config
  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  if [[ ! -f "$config_file" ]]; then
    _zsh_tool_log ERROR "Config file not found: $config_file"
    return 1
  fi

  local plugins=($(grep "^  - " "$config_file" | sed 's/^  - //' | grep -v "^#"))

  if [[ ${#plugins[@]} -eq 0 ]]; then
    _zsh_tool_log DEBUG "No plugins configured"
    return 0
  fi

  local failed_plugins=()

  for plugin in "${plugins[@]}"; do
    _zsh_tool_log DEBUG "Checking plugin: $plugin"

    # Plugin-specific checks
    case "$plugin" in
      zsh-syntax-highlighting)
        if [[ -z "$ZSH_HIGHLIGHT_VERSION" ]]; then
          failed_plugins+=("$plugin")
          _zsh_tool_log DEBUG "Plugin check failed: $plugin (ZSH_HIGHLIGHT_VERSION not set)"
        fi
        ;;
      zsh-autosuggestions)
        if [[ -z "$ZSH_AUTOSUGGEST_VERSION" ]]; then
          failed_plugins+=("$plugin")
          _zsh_tool_log DEBUG "Plugin check failed: $plugin (ZSH_AUTOSUGGEST_VERSION not set)"
        fi
        ;;
      *)
        # Generic check: plugin dir exists
        if [[ ! -d "$ZSH/plugins/$plugin" ]] && [[ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
          failed_plugins+=("$plugin")
          _zsh_tool_log DEBUG "Plugin check failed: $plugin (directory not found)"
        fi
        ;;
    esac
  done

  if [[ ${#failed_plugins[@]} -gt 0 ]]; then
    _zsh_tool_log ERROR "Failed to load plugins: ${failed_plugins[*]}"
    return 1
  fi

  _zsh_tool_log DEBUG "All plugins loaded successfully"
  return 0
}

# Check if theme is applied
# Returns: 0 if theme is applied, 1 otherwise
_zsh_tool_check_theme_applied() {
  _zsh_tool_log DEBUG "Checking if theme is applied"

  # Read theme from config
  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  if [[ ! -f "$config_file" ]]; then
    _zsh_tool_log ERROR "Config file not found: $config_file"
    return 1
  fi

  local configured_theme=$(grep "^theme:" "$config_file" | sed 's/^theme: *//' | tr -d '"' | tr -d "'")

  if [[ -z "$configured_theme" ]]; then
    _zsh_tool_log DEBUG "No theme configured"
    return 0
  fi

  # Check $ZSH_THEME matches config
  if [[ "$ZSH_THEME" != "$configured_theme" ]]; then
    _zsh_tool_log ERROR "Theme mismatch: configured=$configured_theme, actual=$ZSH_THEME"
    return 1
  fi

  # Check theme file exists
  if [[ ! -f "$ZSH/themes/${configured_theme}.zsh-theme" ]] && \
     [[ ! -f "$ZSH_CUSTOM/themes/${configured_theme}.zsh-theme" ]]; then
    _zsh_tool_log ERROR "Theme file not found: $configured_theme"
    return 1
  fi

  _zsh_tool_log DEBUG "Theme applied successfully: $configured_theme"
  return 0
}

# Display installation summary
# Returns: 0 on success
_zsh_tool_display_summary() {
  _zsh_tool_log DEBUG "Displaying installation summary"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ZSH-TOOL INSTALLATION SUMMARY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Prerequisites Section
  echo "Prerequisites:"

  if command -v brew >/dev/null 2>&1; then
    local brew_version=$(brew --version 2>/dev/null | head -1)
    echo "  ✓ Homebrew: $brew_version"
  fi

  if command -v git >/dev/null 2>&1; then
    local git_version=$(git --version 2>/dev/null)
    echo "  ✓ Git: $git_version"
  fi

  if [[ -n "$ZSH" ]] && [[ -d "$ZSH/.git" ]]; then
    local omz_hash=$(cd "$ZSH" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo "  ✓ Oh My Zsh: commit $omz_hash"
  fi

  local zsh_version=$(zsh --version 2>/dev/null)
  echo "  ✓ Zsh: $zsh_version"

  echo ""

  # Configuration Section
  echo "Configuration:"

  # Read config
  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  if [[ -f "$config_file" ]]; then
    # Plugins
    local plugins=($(grep "^  - " "$config_file" | sed 's/^  - //' | grep -v "^#"))
    if [[ ${#plugins[@]} -gt 0 ]]; then
      echo "  Plugins:"
      for plugin in "${plugins[@]}"; do
        echo "    ✓ $plugin"
      done
    fi

    # Theme
    local theme=$(grep "^theme:" "$config_file" | sed 's/^theme: *//' | tr -d '"' | tr -d "'")
    if [[ -n "$theme" ]]; then
      echo "  ✓ Theme: $theme"
    fi
  fi

  # Custom layer
  if [[ -f "${HOME}/.zshrc.local" ]]; then
    echo "  ✓ Custom layer: ~/.zshrc.local"
  fi

  # Team config
  echo "  ✓ Team config: ${config_file}"

  echo ""

  # Backup Section
  local state_file="${ZSH_TOOL_STATE_FILE:-${HOME}/.local/share/zsh-tool/state.json}"
  if [[ -f "$state_file" ]]; then
    local backup_location=$(grep '"backup_location"' "$state_file" 2>/dev/null | sed 's/.*: *"\(.*\)".*/\1/')
    local backup_timestamp=$(grep '"backup_timestamp"' "$state_file" 2>/dev/null | sed 's/.*: *"\(.*\)".*/\1/')

    if [[ -n "$backup_location" ]] && [[ -d "$backup_location" ]]; then
      echo "Backup:"
      echo "  ✓ Location: $backup_location"
      echo "  ✓ Timestamp: $backup_timestamp"
      local backup_count=$(find "$backup_location" -type f 2>/dev/null | wc -l | tr -d ' ')
      echo "  ✓ Files backed up: $backup_count"
      echo ""
    fi

    # Timing Section
    local install_start=$(grep '"installation_start"' "$state_file" 2>/dev/null | sed 's/.*: *"\(.*\)".*/\1/')
    local install_end=$(grep '"installation_end"' "$state_file" 2>/dev/null | sed 's/.*: *"\(.*\)".*/\1/')

    if [[ -n "$install_start" ]] && [[ -n "$install_end" ]]; then
      echo "Installation Timing:"
      echo "  ✓ Started: $install_start"
      echo "  ✓ Completed: $install_end"

      # Calculate duration (simplified - just show timestamps)
      local duration_seconds=$(grep '"installation_duration_seconds"' "$state_file" 2>/dev/null | sed 's/.*: *\([0-9]*\).*/\1/')
      if [[ -n "$duration_seconds" ]]; then
        echo "  ✓ Duration: ${duration_seconds}s"
      fi
      echo ""
    fi
  fi

  # Next Steps Section
  echo "Next Steps:"
  echo "  • Customize: Edit ~/.zshrc.local for personal settings"
  echo "  • Verify: Run 'zsh-tool-verify' to check installation"
  echo "  • Docs: See ${ZSH_TOOL_CONFIG_DIR}/README.md"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  return 0
}

# Verify installation
# Returns: 0 if all checks pass, 1 if any fail
_zsh_tool_verify_installation() {
  _zsh_tool_log INFO "Verifying installation"

  local failed_checks=()

  # Check Oh My Zsh
  if ! _zsh_tool_check_omz_loaded; then
    failed_checks+=("Oh My Zsh not loaded")
  fi

  # Check plugins
  if ! _zsh_tool_check_plugins_loaded; then
    failed_checks+=("Plugins not loaded")
  fi

  # Check theme
  if ! _zsh_tool_check_theme_applied; then
    failed_checks+=("Theme not applied")
  fi

  # Report results
  if [[ ${#failed_checks[@]} -gt 0 ]]; then
    _zsh_tool_log ERROR "Installation verification failed"

    echo ""
    echo "⚠️  Installation verification failed!"
    echo ""
    echo "Failed checks:"
    for check in "${failed_checks[@]}"; do
      echo "  ✗ $check"
    done
    echo ""
    echo "Remediation options:"
    echo "  1. Re-run installation: ./install.sh"
    echo "  2. Restore from backup: (check ${ZSH_TOOL_STATE_FILE} for backup location)"
    echo "  3. Check logs: cat ${ZSH_TOOL_LOG_FILE}"
    echo ""

    return 1
  fi

  _zsh_tool_log INFO "Installation verification passed"

  echo ""
  echo "✓ Installation verification passed!"
  echo ""

  return 0
}

# ============================================================================
# PUBLIC INTERFACE
# ============================================================================

# Public command: zsh-tool-verify
# Runs verification and displays summary
zsh-tool-verify() {
  _zsh_tool_log INFO "Running installation verification"

  # Run verification
  if ! _zsh_tool_verify_installation; then
    return 1
  fi

  # Display summary
  _zsh_tool_display_summary

  return 0
}
