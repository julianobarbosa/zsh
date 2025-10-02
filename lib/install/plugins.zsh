#!/usr/bin/env zsh
# Story 1.4: Plugin Management System
# Install and manage Oh My Zsh plugins

OMZ_CUSTOM_PLUGINS="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins"

# Plugin URL registry (for custom plugins)
typeset -A PLUGIN_URLS
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

# Install single custom plugin
_zsh_tool_install_custom_plugin() {
  local plugin=$1
  local url="${PLUGIN_URLS[$plugin]}"

  if [[ -z "$url" ]]; then
    _zsh_tool_log WARN "No URL configured for plugin: $plugin"
    return 1
  fi

  _zsh_tool_log INFO "Installing plugin: $plugin"

  mkdir -p "$OMZ_CUSTOM_PLUGINS"

  git clone --depth=1 "$url" "${OMZ_CUSTOM_PLUGINS}/${plugin}" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local exit_code=${PIPESTATUS[1]}

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Plugin installed: $plugin"
    return 0
  else
    _zsh_tool_log ERROR "Failed to install plugin: $plugin"
    return 1
  fi
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
  local plugins_json=$(echo "$plugins" | sed 's/ /","/g')
  _zsh_tool_update_state "plugins" "[\"${plugins_json}\"]"

  return 0
}

# Update single plugin
_zsh_tool_update_plugin() {
  local plugin=$1

  if ! _zsh_tool_is_custom_plugin_installed "$plugin"; then
    _zsh_tool_log WARN "Plugin not installed: $plugin"
    return 1
  fi

  _zsh_tool_log INFO "Updating plugin: $plugin"

  cd "${OMZ_CUSTOM_PLUGINS}/${plugin}"
  git pull 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local exit_code=${PIPESTATUS[1]}
  cd - >/dev/null

  if [[ $exit_code -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Plugin updated: $plugin"
    return 0
  else
    _zsh_tool_log ERROR "Failed to update plugin: $plugin"
    return 1
  fi
}
