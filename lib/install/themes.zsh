#!/usr/bin/env zsh
# Story 1.5: Theme Installation and Selection
# Install and apply Oh My Zsh themes

OMZ_CUSTOM_THEMES="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes"

# Theme URL registry (for custom themes)
# Use -g for global scope when sourced from within a function
typeset -gA THEME_URLS
THEME_URLS=(
  "powerlevel10k" "https://github.com/romkatv/powerlevel10k.git"
)

# Default fallback theme
ZSH_TOOL_DEFAULT_THEME="robbyrussell"

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

  # Use progress spinner for git clone (AC10 - progress indicators)
  local exit_code
  if typeset -f _zsh_tool_with_spinner >/dev/null 2>&1; then
    _zsh_tool_with_spinner "Cloning $theme" "git clone --depth=1 '$url' '${OMZ_CUSTOM_THEMES}/${theme}' >> '$ZSH_TOOL_LOG_FILE' 2>&1"
    exit_code=$?
  else
    # Fallback if spinner not available
    git clone --depth=1 "$url" "${OMZ_CUSTOM_THEMES}/${theme}" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    exit_code=${pipestatus[1]}  # zsh uses lowercase pipestatus
  fi

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

  # Handle empty theme from config - fallback to default
  if [[ -z "$theme" ]]; then
    theme="$ZSH_TOOL_DEFAULT_THEME"
    _zsh_tool_log INFO "No theme in config, using default: $theme"
  else
    _zsh_tool_log INFO "Theme configured: $theme"
  fi

  local result=0

  # Check if theme exists
  if _zsh_tool_is_builtin_theme "$theme"; then
    _zsh_tool_log DEBUG "Using built-in theme: $theme"
  elif _zsh_tool_is_custom_theme_installed "$theme"; then
    _zsh_tool_log DEBUG "Using custom theme: $theme"
  elif [[ -n "${THEME_URLS[$theme]}" ]]; then
    # Install custom theme
    _zsh_tool_install_custom_theme "$theme"
    result=$?
  else
    _zsh_tool_log WARN "Theme not found, falling back to $ZSH_TOOL_DEFAULT_THEME"
    theme="$ZSH_TOOL_DEFAULT_THEME"
  fi

  # Update state with applied theme (AC9 compliance)
  _zsh_tool_update_state "theme" "\"$theme\""

  return $result
}

# Validate theme name (security check)
_zsh_tool_validate_theme_name() {
  local theme=$1

  # Reject empty names
  [[ -z "$theme" ]] && return 1

  # Reject path traversal attempts
  [[ "$theme" == *".."* ]] && return 1

  # Reject absolute paths or slashes
  [[ "$theme" == *"/"* ]] && return 1

  # Only allow alphanumeric, hyphens, underscores (use parameter expansion)
  local sanitized="${theme//[a-zA-Z0-9_-]/}"
  [[ -z "$sanitized" ]]
}

# List available themes with status
_zsh_tool_theme_list() {
  local current_theme=$(_zsh_tool_parse_theme 2>/dev/null)
  [[ -z "$current_theme" ]] && current_theme="$ZSH_TOOL_DEFAULT_THEME"

  echo "Available themes:"
  echo "================"

  # List built-in themes (common ones)
  local builtin_themes=("robbyrussell" "agnoster" "af-magic" "bira" "candy" "clean" "cloud" "dallas" "dst" "eastwood" "fino" "gnzh" "jnrowe" "mh" "minimal" "ys")

  for theme in "${builtin_themes[@]}"; do
    local theme_status=""
    if [[ "$theme" == "$current_theme" ]]; then
      theme_status="📍 current"
    elif _zsh_tool_is_builtin_theme "$theme"; then
      theme_status="📦 built-in"
    fi
    [[ -n "$theme_status" ]] && printf "  %-25s %s\n" "$theme" "$theme_status"
  done

  # List custom themes from registry
  echo ""
  echo "Custom themes (require download):"
  echo "================================="

  for theme url in "${(@kv)THEME_URLS}"; do
    local theme_status=""
    if [[ "$theme" == "$current_theme" ]]; then
      theme_status="📍 current"
    elif _zsh_tool_is_custom_theme_installed "$theme"; then
      theme_status="✅ installed"
    else
      theme_status="⬇️  available"
    fi
    printf "  %-25s %s\n" "$theme" "$theme_status"
  done

  # Show any installed custom themes not in registry
  if [[ -d "$OMZ_CUSTOM_THEMES" ]]; then
    local extra_found=false
    for theme_dir in "${OMZ_CUSTOM_THEMES}"/*(/N); do
      local theme="${theme_dir:t}"
      if [[ -z "${THEME_URLS[$theme]}" ]]; then
        if [[ "$extra_found" == "false" ]]; then
          echo ""
          echo "Extra custom themes:"
          echo "==================="
          extra_found=true
        fi
        local theme_status=""
        if [[ "$theme" == "$current_theme" ]]; then
          theme_status="📍 current"
        else
          theme_status="✅ installed"
        fi
        printf "  %-25s %s\n" "$theme" "$theme_status"
      fi
    done
  fi

  echo ""
  echo "Current theme: $current_theme"
}

# Update the ZSH_THEME line in .zshrc within the managed section
_zsh_tool_update_zshrc_theme() {
  local new_theme=$1
  local zshrc="${HOME}/.zshrc"

  # Validate theme name
  if ! _zsh_tool_validate_theme_name "$new_theme"; then
    _zsh_tool_log ERROR "Invalid theme name: $new_theme"
    return 1
  fi

  # Check if .zshrc exists
  if [[ ! -f "$zshrc" ]]; then
    _zsh_tool_log WARN ".zshrc not found, cannot update theme"
    return 1
  fi

  # Check if managed section exists
  if ! grep -q "ZSH-TOOL MANAGED SECTION BEGIN" "$zshrc" 2>/dev/null; then
    _zsh_tool_log WARN ".zshrc has no managed section, run zsh-tool install first"
    return 1
  fi

  # Update the ZSH_THEME line
  local temp_zshrc="${zshrc}.tmp.$$"

  # Preserve original file permissions (handle both BSD and GNU stat)
  local orig_perms=$(stat -f "%OLp" "$zshrc" 2>/dev/null || stat -c "%a" "$zshrc" 2>/dev/null)
  if [[ -z "$orig_perms" ]]; then
    _zsh_tool_log WARN "Could not read file permissions, using default 644"
    orig_perms="644"
  fi

  # Escape theme name for sed to prevent injection (escape &, \, /)
  local escaped_theme="${new_theme//\\/\\\\}"  # Escape backslashes first
  escaped_theme="${escaped_theme//&/\\&}"       # Escape ampersand
  escaped_theme="${escaped_theme//\//\\/}"      # Escape forward slashes

  if sed "s/^ZSH_THEME=.*/ZSH_THEME=\"${escaped_theme}\"/" "$zshrc" > "$temp_zshrc" 2>/dev/null; then
    # Restore original permissions before moving
    if ! chmod "$orig_perms" "$temp_zshrc" 2>/dev/null; then
      _zsh_tool_log WARN "Could not restore file permissions"
    fi
    mv "$temp_zshrc" "$zshrc"
    _zsh_tool_log INFO "✓ Updated ZSH_THEME to: $new_theme"
    return 0
  else
    [[ -f "$temp_zshrc" ]] && rm -f "$temp_zshrc"
    _zsh_tool_log ERROR "Failed to update ZSH_THEME"
    return 1
  fi
}

# Set theme - install if needed, then update .zshrc
_zsh_tool_theme_set() {
  local theme=$1

  if [[ -z "$theme" ]]; then
    _zsh_tool_log ERROR "Theme name required"
    return 1
  fi

  # Validate theme name
  if ! _zsh_tool_validate_theme_name "$theme"; then
    _zsh_tool_log ERROR "Invalid theme name: $theme (must be alphanumeric with hyphens/underscores only)"
    return 1
  fi

  _zsh_tool_log INFO "Setting theme: $theme"

  # Check if built-in
  if _zsh_tool_is_builtin_theme "$theme"; then
    _zsh_tool_log DEBUG "Using built-in theme: $theme"
  elif _zsh_tool_is_custom_theme_installed "$theme"; then
    _zsh_tool_log DEBUG "Using installed custom theme: $theme"
  elif [[ -n "${THEME_URLS[$theme]}" ]]; then
    # Need to install custom theme first
    if ! _zsh_tool_install_custom_theme "$theme"; then
      _zsh_tool_log WARN "Failed to install theme, falling back to $ZSH_TOOL_DEFAULT_THEME"
      theme="$ZSH_TOOL_DEFAULT_THEME"
    fi
  else
    _zsh_tool_log WARN "Theme '$theme' not found, falling back to $ZSH_TOOL_DEFAULT_THEME"
    theme="$ZSH_TOOL_DEFAULT_THEME"
  fi

  # Update .zshrc
  if _zsh_tool_update_zshrc_theme "$theme"; then
    # Update state
    _zsh_tool_update_state "theme" "\"$theme\""
    _zsh_tool_log INFO "✓ Theme set to: $theme"
    _zsh_tool_log INFO "  Restart your shell or run 'source ~/.zshrc' to apply"
    return 0
  else
    return 1
  fi
}

# Public dispatcher function
# Usage: zsh-tool-theme [list|set] [theme-name]
zsh-tool-theme() {
  local action="${1:-list}"
  local theme="$2"

  case "$action" in
    list)
      _zsh_tool_theme_list
      ;;
    set)
      if [[ -z "$theme" ]]; then
        _zsh_tool_log ERROR "Usage: zsh-tool-theme set <theme-name>"
        return 1
      fi
      _zsh_tool_theme_set "$theme"
      ;;
    current)
      local current=$(_zsh_tool_parse_theme 2>/dev/null)
      [[ -z "$current" ]] && current="$ZSH_TOOL_DEFAULT_THEME"
      echo "Current theme: $current"
      ;;
    *)
      echo "Usage: zsh-tool-theme [list|set|current] [theme-name]"
      echo ""
      echo "Commands:"
      echo "  list              Show available themes"
      echo "  set <theme>       Set and apply a theme"
      echo "  current           Show current theme"
      return 1
      ;;
  esac
}
