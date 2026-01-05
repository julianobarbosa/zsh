#!/usr/bin/env zsh
# Story 1.4: Plugin Management System - Update Module
# Update all custom plugins (AC9: plugin update command)

# Source shared component manager
# Calculate lib directory if not set
: ${ZSH_TOOL_LIB_DIR:="${0:A:h:h}"}
source "${ZSH_TOOL_LIB_DIR}/core/component-manager.zsh"

OMZ_CUSTOM_PLUGINS="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins"

# Get plugin version (wrapper for component-manager's generic function)
# Usage: _zsh_tool_get_plugin_version <plugin_name>
_zsh_tool_get_plugin_version() {
  local plugin="$1"
  local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"
  _zsh_tool_get_component_version "$plugin_dir"
}

# Check single plugin for updates (wrapper for component-manager's generic function)
# Usage: _zsh_tool_check_plugin_updates <plugin_name>
_zsh_tool_check_plugin_updates() {
  local plugin="$1"
  local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"
  _zsh_tool_check_component_updates "$plugin_dir"
}

# Update single plugin (thin wrapper around component-manager)
_zsh_tool_update_plugin() {
  local plugin=$1
  local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"

  if [[ ! -d "$plugin_dir/.git" ]]; then
    _zsh_tool_log DEBUG "Plugin $plugin is not a git repository, skipping"
    return 1
  fi

  _zsh_tool_update_component "plugin" "$plugin" "$plugin_dir"
}

# Update all custom plugins (parallel execution using component-manager)
_zsh_tool_update_all_plugins() {
  _zsh_tool_update_components_parallel "plugin" "$OMZ_CUSTOM_PLUGINS" "_zsh_tool_update_plugin"
}

# Check all plugins for updates (without applying)
_zsh_tool_check_all_plugins() {
  if [[ ! -d "$OMZ_CUSTOM_PLUGINS" ]]; then
    _zsh_tool_log DEBUG "No custom plugins directory found"
    return 1
  fi

  local updates_available=0

  for plugin_dir in ${OMZ_CUSTOM_PLUGINS}/*; do
    if [[ ! -d "$plugin_dir" ]]; then
      continue
    fi

    local plugin=$(basename "$plugin_dir")

    # Skip if not a git repo
    if [[ ! -d "$plugin_dir/.git" ]]; then
      continue
    fi

    # Check for updates using component-manager
    if _zsh_tool_check_component_updates "$plugin_dir"; then
      _zsh_tool_log INFO "  Plugin $plugin has updates available"
      ((updates_available++))
    fi
  done

  if [[ $updates_available -gt 0 ]]; then
    _zsh_tool_log INFO "✓ $updates_available custom plugin(s) have updates available"
    return 0
  else
    _zsh_tool_log INFO "✓ All custom plugins are up to date"
    return 1
  fi
}
