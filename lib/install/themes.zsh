#!/usr/bin/env zsh
# Story 1.5: Theme Installation and Selection
# Install and apply Oh My Zsh themes

OMZ_CUSTOM_THEMES="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes"

# Theme URL registry (for custom themes)
typeset -A THEME_URLS
THEME_URLS=(
  "powerlevel10k" "https://github.com/romkatv/powerlevel10k.git"
)

# Check if theme is a built-in Oh My Zsh theme
_zsh_tool_is_builtin_theme() {
  local theme=$1
  [[ -f "${HOME}/.oh-my-zsh/themes/${theme}.zsh-theme" ]]
}

# Check if custom theme is installed
_zsh_tool_is_custom_theme_installed() {
  local theme=$1
  [[ -d "${OMZ_CUSTOM_THEMES}/${theme}" ]]
}

# Install custom theme
_zsh_tool_install_custom_theme() {
  local theme=$1
  local url="${THEME_URLS[$theme]}"

  if [[ -z "$url" ]]; then
    _zsh_tool_log WARN "No URL configured for theme: $theme"
    return 1
  fi

  _zsh_tool_log INFO "Installing theme: $theme"

  mkdir -p "$OMZ_CUSTOM_THEMES"

  git clone --depth=1 "$url" "${OMZ_CUSTOM_THEMES}/${theme}" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local exit_code=${PIPESTATUS[1]}

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Theme installed: $theme"
    return 0
  else
    _zsh_tool_log ERROR "Failed to install theme: $theme"
    return 1
  fi
}

# Apply theme (already handled in config.zsh via template)
_zsh_tool_apply_theme() {
  local theme=$(_zsh_tool_parse_theme)

  _zsh_tool_log INFO "Theme configured: $theme"

  # Check if theme exists
  if _zsh_tool_is_builtin_theme "$theme"; then
    _zsh_tool_log DEBUG "Using built-in theme: $theme"
    return 0
  elif _zsh_tool_is_custom_theme_installed "$theme"; then
    _zsh_tool_log DEBUG "Using custom theme: $theme"
    return 0
  elif [[ -n "${THEME_URLS[$theme]}" ]]; then
    # Install custom theme
    _zsh_tool_install_custom_theme "$theme"
    return $?
  else
    _zsh_tool_log WARN "Theme not found, falling back to robbyrussell"
    return 0
  fi
}
