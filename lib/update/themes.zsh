#!/usr/bin/env zsh
# Story 2.2: Theme Updates
# Update all custom themes (git-based)

# Source shared component manager
# Calculate lib directory if not set
: ${ZSH_TOOL_LIB_DIR:="${0:A:h:h}"}
source "${ZSH_TOOL_LIB_DIR}/core/component-manager.zsh"

OMZ_CUSTOM_THEMES="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes"

# Get theme version (wrapper for component-manager's generic function)
# Usage: _zsh_tool_get_theme_version <theme_name>
_zsh_tool_get_theme_version() {
  local theme="$1"
  local theme_dir="${OMZ_CUSTOM_THEMES}/${theme}"
  _zsh_tool_get_component_version "$theme_dir"
}

# Check single theme for updates (wrapper for component-manager's generic function)
# Usage: _zsh_tool_check_theme_updates <theme_name>
_zsh_tool_check_theme_updates() {
  local theme="$1"
  local theme_dir="${OMZ_CUSTOM_THEMES}/${theme}"
  _zsh_tool_check_component_updates "$theme_dir"
}

# Update single theme (thin wrapper around component-manager)
_zsh_tool_update_theme() {
  local theme=$1
  local theme_dir="${OMZ_CUSTOM_THEMES}/${theme}"

  if [[ ! -d "$theme_dir/.git" ]]; then
    _zsh_tool_log DEBUG "Theme $theme is not a git repository, skipping"
    return 1
  fi

  _zsh_tool_update_component "theme" "$theme" "$theme_dir"
}

# Update all custom themes (parallel execution using component-manager)
_zsh_tool_update_all_themes() {
  _zsh_tool_update_components_parallel "theme" "$OMZ_CUSTOM_THEMES" "_zsh_tool_update_theme"
}

# Check all themes for updates (without applying)
_zsh_tool_check_all_themes() {
  if [[ ! -d "$OMZ_CUSTOM_THEMES" ]]; then
    _zsh_tool_log DEBUG "No custom themes directory found"
    return 1
  fi

  local updates_available=0

  for theme_dir in ${OMZ_CUSTOM_THEMES}/*; do
    if [[ ! -d "$theme_dir" ]]; then
      continue
    fi

    local theme=$(basename "$theme_dir")

    # Skip if not a git repo
    if [[ ! -d "$theme_dir/.git" ]]; then
      continue
    fi

    # Check for updates using component-manager
    if _zsh_tool_check_component_updates "$theme_dir"; then
      _zsh_tool_log INFO "  Theme $theme has updates available"
      ((updates_available++))
    fi
  done

  if [[ $updates_available -gt 0 ]]; then
    _zsh_tool_log INFO "✓ $updates_available custom theme(s) have updates available"
    return 0
  else
    _zsh_tool_log INFO "✓ All custom themes are up to date"
    return 1
  fi
}
