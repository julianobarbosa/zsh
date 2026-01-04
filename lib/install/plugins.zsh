#!/usr/bin/env zsh
# Story 1.4: Plugin Management System
# Install and manage Oh My Zsh plugins

# Source shared component manager
# Calculate lib directory if not set
: ${ZSH_TOOL_LIB_DIR:="${0:A:h:h}"}
source "${ZSH_TOOL_LIB_DIR}/core/component-manager.zsh"

OMZ_CUSTOM_PLUGINS="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins"

# Plugin URL registry (for custom plugins)
# Use -g for global scope when sourced from within a function
typeset -gA PLUGIN_URLS
PLUGIN_URLS=(
  "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
  "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
)

# Check if plugin is a built-in Oh My Zsh plugin
_zsh_tool_is_builtin_plugin() {
  local plugin=$1
  [[ -d "${HOME}/.oh-my-zsh/plugins/${plugin}" ]]
}

# Check if custom plugin is installed
_zsh_tool_is_custom_plugin_installed() {
  local plugin=$1
  [[ -d "${OMZ_CUSTOM_PLUGINS}/${plugin}" ]]
}

# Install single custom plugin (thin wrapper around component-manager)
_zsh_tool_install_custom_plugin() {
  local plugin=$1
  local url="${PLUGIN_URLS[$plugin]}"
  local target_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"

  if [[ -z "$url" ]]; then
    _zsh_tool_log WARN "No URL configured for plugin: $plugin"
    return 1
  fi

  mkdir -p "$OMZ_CUSTOM_PLUGINS"

  _zsh_tool_install_git_component "plugin" "$plugin" "$url" "$target_dir"
}

# Install all plugins from configuration
_zsh_tool_install_plugins() {
  _zsh_tool_log INFO "Installing plugins..."

  local plugins=$(_zsh_tool_parse_plugins)
  local installed_count=0
  local skipped_count=0
  local failed_count=0

  for plugin in ${(z)plugins}; do
    # Check if built-in (already available with Oh My Zsh)
    if _zsh_tool_is_builtin_plugin "$plugin"; then
      _zsh_tool_log DEBUG "Plugin $plugin is built-in, skipping"
      ((skipped_count++))
      continue
    fi

    # Check if already installed
    if _zsh_tool_is_custom_plugin_installed "$plugin"; then
      _zsh_tool_log DEBUG "Plugin $plugin already installed, skipping"
      ((skipped_count++))
      continue
    fi

    # Install custom plugin
    if _zsh_tool_install_custom_plugin "$plugin"; then
      ((installed_count++))
    else
      ((failed_count++))
    fi
  done

  _zsh_tool_log INFO "✓ Plugins: $installed_count installed, $skipped_count skipped, $failed_count failed"

  # Update state with installed plugins
  # Build proper JSON array from space-separated list
  local plugins_json=""
  local first=true
  for p in ${(z)plugins}; do
    if [[ "$first" == "true" ]]; then
      plugins_json="\"$p\""
      first=false
    else
      plugins_json="${plugins_json},\"$p\""
    fi
  done
  _zsh_tool_update_state "plugins" "[${plugins_json}]"

  # Update .zshrc plugins array (AC5)
  _zsh_tool_update_zshrc_plugins

  return 0
}

# List installed plugins with status
_zsh_tool_plugin_list() {
  local config_plugins=$(_zsh_tool_parse_plugins 2>/dev/null)

  echo "Configured plugins:"
  echo "==================="

  for plugin in ${(z)config_plugins}; do
    local plugin_status="❓ unknown"

    if _zsh_tool_is_builtin_plugin "$plugin"; then
      plugin_status="📦 built-in"
    elif _zsh_tool_is_custom_plugin_installed "$plugin"; then
      plugin_status="✅ installed"
    else
      plugin_status="❌ not installed"
    fi

    printf "  %-30s %s\n" "$plugin" "$plugin_status"
  done

  # List any extra custom plugins not in config
  if [[ -d "$OMZ_CUSTOM_PLUGINS" ]]; then
    local extra_found=false
    for plugin_dir in "${OMZ_CUSTOM_PLUGINS}"/*(/N); do
      local plugin="${plugin_dir:t}"
      if ! echo "$config_plugins" | grep -qw "$plugin"; then
        if [[ "$extra_found" == "false" ]]; then
          echo ""
          echo "Extra plugins (not in config):"
          echo "=============================="
          extra_found=true
        fi
        printf "  %-30s %s\n" "$plugin" "⚠️  not in config"
      fi
    done
  fi
}

# Validate plugin name (security check)
_zsh_tool_validate_plugin_name() {
  local plugin=$1

  # Reject empty names
  [[ -z "$plugin" ]] && return 1

  # Reject path traversal attempts
  [[ "$plugin" == *".."* ]] && return 1

  # Reject absolute paths or slashes
  [[ "$plugin" == *"/"* ]] && return 1

  # Only allow alphanumeric, hyphens, underscores (use parameter expansion to strip valid chars)
  # If anything remains after stripping valid chars, the name is invalid
  local sanitized="${plugin//[a-zA-Z0-9_-]/}"
  [[ -z "$sanitized" ]]
}

# Add plugin to config and install
_zsh_tool_plugin_add() {
  local plugin=$1

  if [[ -z "$plugin" ]]; then
    _zsh_tool_log ERROR "Plugin name required"
    return 1
  fi

  # Validate plugin name for security
  if ! _zsh_tool_validate_plugin_name "$plugin"; then
    _zsh_tool_log ERROR "Invalid plugin name: $plugin (must be alphanumeric with hyphens/underscores only)"
    return 1
  fi

  _zsh_tool_log INFO "Adding plugin: $plugin"

  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  local config_plugins=$(_zsh_tool_parse_plugins 2>/dev/null)
  local already_in_config=false

  # Check if already in config
  if echo "$config_plugins" | grep -qw "$plugin"; then
    _zsh_tool_log WARN "Plugin already in config: $plugin"
    already_in_config=true
  fi

  # Helper to add plugin to config.yaml
  _add_to_config() {
    if [[ "$already_in_config" == "false" ]] && [[ -f "$config_file" ]]; then
      sed -i '' "/^plugins:/a\\
\\  - $plugin
" "$config_file" 2>/dev/null || {
        sed -i "/^plugins:/a\\  - $plugin" "$config_file"
      }
      _zsh_tool_log INFO "Added $plugin to config.yaml"
    fi
  }

  # Check if built-in (no installation needed)
  if _zsh_tool_is_builtin_plugin "$plugin"; then
    _add_to_config
    _zsh_tool_log INFO "✓ Plugin $plugin is built-in (no installation needed)"
    _zsh_tool_update_zshrc_plugins
    return 0
  fi

  # Check if already installed
  if _zsh_tool_is_custom_plugin_installed "$plugin"; then
    _add_to_config
    _zsh_tool_log INFO "✓ Plugin $plugin already installed"
    _zsh_tool_update_zshrc_plugins
    return 0
  fi

  # Install custom plugin FIRST, then update config on success
  if _zsh_tool_install_custom_plugin "$plugin"; then
    _add_to_config
    _zsh_tool_log INFO "✓ Plugin $plugin added and installed"
    _zsh_tool_update_zshrc_plugins
    return 0
  else
    _zsh_tool_log ERROR "Failed to install plugin: $plugin (not added to config)"
    return 1
  fi
}

# Remove plugin from config and filesystem
_zsh_tool_plugin_remove() {
  local plugin=$1

  if [[ -z "$plugin" ]]; then
    _zsh_tool_log ERROR "Plugin name required"
    return 1
  fi

  # Validate plugin name for security
  if ! _zsh_tool_validate_plugin_name "$plugin"; then
    _zsh_tool_log ERROR "Invalid plugin name: $plugin (must be alphanumeric with hyphens/underscores only)"
    return 1
  fi

  _zsh_tool_log INFO "Removing plugin: $plugin"

  # Check if built-in (can't remove)
  if _zsh_tool_is_builtin_plugin "$plugin"; then
    _zsh_tool_log WARN "Cannot remove built-in plugin: $plugin (remove from config only)"
  fi

  # Remove from config.yaml
  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  if [[ -f "$config_file" ]]; then
    # Remove plugin line from config
    sed -i '' "/^  - ${plugin}$/d" "$config_file" 2>/dev/null || {
      # GNU sed fallback
      sed -i "/^  - ${plugin}$/d" "$config_file"
    }
    _zsh_tool_log INFO "Removed $plugin from config.yaml"
  fi

  # Remove custom plugin directory if exists
  if _zsh_tool_is_custom_plugin_installed "$plugin"; then
    local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"

    # Safety checks - verify it's actually a plugin directory
    [[ -z "$plugin_dir" ]] && return 1
    [[ -z "$OMZ_CUSTOM_PLUGINS" ]] && return 1
    if [[ -d "$plugin_dir" ]] && [[ "$plugin_dir" == "${OMZ_CUSTOM_PLUGINS}/"* ]]; then
      rm -rf "$plugin_dir"
      _zsh_tool_log INFO "Removed plugin directory: $plugin_dir"
    fi
  fi

  _zsh_tool_log INFO "✓ Plugin $plugin removed"

  # Update .zshrc plugins array (AC5)
  _zsh_tool_update_zshrc_plugins

  return 0
}

# Update the plugins=(...) line in .zshrc within the managed section (AC5)
_zsh_tool_update_zshrc_plugins() {
  local zshrc="${HOME}/.zshrc"

  # Get current configured plugins
  local plugins=$(_zsh_tool_parse_plugins 2>/dev/null)
  if [[ -z "$plugins" ]]; then
    _zsh_tool_log DEBUG "No plugins configured, skipping .zshrc update"
    return 0
  fi

  # Check if .zshrc exists
  if [[ ! -f "$zshrc" ]]; then
    _zsh_tool_log WARN ".zshrc not found, cannot update plugins array"
    return 1
  fi

  # Check if managed section exists
  if ! grep -q "ZSH-TOOL MANAGED SECTION BEGIN" "$zshrc" 2>/dev/null; then
    _zsh_tool_log WARN ".zshrc has no managed section, run zsh-tool install first"
    return 1
  fi

  # Escape special sed characters in plugins string to prevent injection
  local escaped_plugins="${plugins//\\/\\\\}"  # Escape backslashes first
  escaped_plugins="${escaped_plugins//\//\\/}"  # Escape forward slashes
  escaped_plugins="${escaped_plugins//&/\\&}"   # Escape ampersands

  # Update the plugins=(...) line within .zshrc
  # Use sed to replace the line that starts with "plugins=("
  local temp_zshrc="${zshrc}.tmp.$$"

  # Preserve original file permissions
  local orig_perms=$(stat -f "%OLp" "$zshrc" 2>/dev/null || stat -c "%a" "$zshrc" 2>/dev/null)

  if sed "s/^plugins=(.*)/plugins=(${escaped_plugins})/" "$zshrc" > "$temp_zshrc" 2>/dev/null; then
    # Restore original permissions before moving
    [[ -n "$orig_perms" ]] && chmod "$orig_perms" "$temp_zshrc" 2>/dev/null
    mv "$temp_zshrc" "$zshrc"
    _zsh_tool_log INFO "✓ Updated .zshrc plugins array"
    return 0
  else
    [[ -f "$temp_zshrc" ]] && rm -f "$temp_zshrc"
    _zsh_tool_log ERROR "Failed to update .zshrc plugins array"
    return 1
  fi
}

# Public dispatcher function
# Usage: zsh-tool-plugin [list|add|remove|update] [plugin-name]
zsh-tool-plugin() {
  local action="${1:-list}"
  local plugin="$2"

  case "$action" in
    list)
      _zsh_tool_plugin_list
      ;;
    add)
      if [[ -z "$plugin" ]]; then
        _zsh_tool_log ERROR "Usage: zsh-tool-plugin add <plugin-name>"
        return 1
      fi
      _zsh_tool_plugin_add "$plugin"
      ;;
    remove)
      if [[ -z "$plugin" ]]; then
        _zsh_tool_log ERROR "Usage: zsh-tool-plugin remove <plugin-name>"
        return 1
      fi
      _zsh_tool_plugin_remove "$plugin"
      ;;
    update)
      # Delegate to update module
      if [[ -z "$plugin" ]] || [[ "$plugin" == "all" ]]; then
        _zsh_tool_update_all_plugins
      else
        _zsh_tool_update_plugin "$plugin"
      fi
      ;;
    *)
      echo "Usage: zsh-tool-plugin [list|add|remove|update] [plugin-name]"
      echo ""
      echo "Commands:"
      echo "  list              Show installed plugins"
      echo "  add <plugin>      Add and install a plugin"
      echo "  remove <plugin>   Remove a plugin"
      echo "  update [plugin]   Update plugin(s) (default: all)"
      return 1
      ;;
  esac
}
