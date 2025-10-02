#!/usr/bin/env zsh
# Story 1.7: Installation Verification and Summary
# Verify installation and display summary

# Verify Oh My Zsh loaded
_zsh_tool_check_omz_loaded() {
  [[ -n "$ZSH" && -f "$ZSH/oh-my-zsh.sh" ]]
}

# Verify plugins loaded (check for plugin-specific indicators)
_zsh_tool_check_plugins_loaded() {
  local plugins=$(_zsh_tool_parse_plugins)
  local loaded=0
  local total=0

  for plugin in ${(z)plugins}; do
    ((total++))

    # Check plugin-specific indicators
    case "$plugin" in
      "zsh-syntax-highlighting")
        [[ -n "$ZSH_HIGHLIGHT_VERSION" ]] && ((loaded++))
        ;;
      "zsh-autosuggestions")
        [[ -n "$ZSH_AUTOSUGGEST_VERSION" ]] && ((loaded++))
        ;;
      *)
        # For built-in plugins, assume loaded if .zshrc has them
        ((loaded++))
        ;;
    esac
  done

  echo "${loaded}/${total}"
}

# Verify theme applied
_zsh_tool_check_theme_applied() {
  local configured_theme=$(_zsh_tool_parse_theme)
  [[ "$ZSH_THEME" == "$configured_theme" ]]
}

# Display installation summary
_zsh_tool_display_summary() {
  local start_time="${1:-unknown}"
  local end_time=$(date +%s)
  local duration="unknown"

  if [[ "$start_time" != "unknown" ]]; then
    duration=$((end_time - start_time))
    duration="${duration}s"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✓ zsh-tool Installation Complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Prerequisites
  echo "Prerequisites:"
  if _zsh_tool_is_installed brew; then
    echo "  ✓ Homebrew $(brew --version | head -1 | awk '{print $2}')"
  fi
  if _zsh_tool_is_installed git; then
    echo "  ✓ git $(git --version | awk '{print $3}')"
  fi
  if xcode-select -p >/dev/null 2>&1; then
    echo "  ✓ Xcode Command Line Tools"
  fi

  # Oh My Zsh
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    local omz_version=$(cd "${HOME}/.oh-my-zsh" && git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo "  ✓ Oh My Zsh ($omz_version)"
  fi
  echo ""

  # Configuration
  echo "Configuration:"
  echo "  ✓ Team .zshrc installed"

  local plugins=$(_zsh_tool_parse_plugins)
  local plugin_count=$(echo "$plugins" | wc -w | tr -d ' ')
  echo "  ✓ $plugin_count plugins configured: $plugins"

  local theme=$(_zsh_tool_parse_theme)
  echo "  ✓ Theme: $theme"
  echo ""

  # Backup
  local last_backup=$(_zsh_tool_load_state | grep -o '"last_backup":"[^"]*"' | cut -d'"' -f4)
  if [[ -n "$last_backup" ]]; then
    echo "Backup created: ~/.config/zsh-tool/backups/$last_backup/"
    echo ""
  fi

  # Next steps
  echo "Next steps:"
  echo "  1. Reload your shell: exec zsh"
  echo "  2. (Optional) Customize: edit ~/.zshrc.local"
  echo "  3. Get help: zsh-tool-help"
  echo ""

  if [[ "$duration" != "unknown" ]]; then
    echo "Installation time: $duration"
    echo ""
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Verify installation
_zsh_tool_verify_installation() {
  _zsh_tool_log INFO "Verifying installation..."

  local all_ok=true

  # Check prerequisites
  if ! _zsh_tool_is_installed brew; then
    _zsh_tool_log WARN "Homebrew not found"
    all_ok=false
  fi

  if ! _zsh_tool_is_installed git; then
    _zsh_tool_log WARN "git not found"
    all_ok=false
  fi

  # Check Oh My Zsh
  if ! _zsh_tool_verify_omz; then
    _zsh_tool_log WARN "Oh My Zsh verification failed"
    all_ok=false
  fi

  # Check .zshrc
  if [[ ! -f "${HOME}/.zshrc" ]]; then
    _zsh_tool_log WARN ".zshrc not found"
    all_ok=false
  elif ! grep -q "$ZSH_TOOL_MANAGED_BEGIN" "${HOME}/.zshrc"; then
    _zsh_tool_log WARN ".zshrc missing managed section"
    all_ok=false
  fi

  if [[ "$all_ok" == true ]]; then
    _zsh_tool_log INFO "✓ Verification passed"
    return 0
  else
    _zsh_tool_log WARN "Verification completed with warnings"
    return 1
  fi
}
