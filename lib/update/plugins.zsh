#!/usr/bin/env zsh
# Story 2.2: Plugin Updates
# Update all custom plugins

OMZ_CUSTOM_PLUGINS="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins"

# Get plugin version
_zsh_tool_get_plugin_version() {
  local plugin=$1
  local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"

  if [[ ! -d "$plugin_dir/.git" ]]; then
    echo "not-git"
    return 1
  fi

  cd "$plugin_dir"
  local version=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  cd - >/dev/null
  echo "$version"
}

# Check for plugin updates
_zsh_tool_check_plugin_updates() {
  local plugin=$1
  local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"

  if [[ ! -d "$plugin_dir/.git" ]]; then
    return 1  # Not a git repo, skip
  fi

  cd "$plugin_dir"

  # Fetch latest changes
  git fetch origin 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local fetch_status=${PIPESTATUS[1]}

  if [[ $fetch_status -ne 0 ]]; then
    cd - >/dev/null
    return 1
  fi

  # Check if updates available
  local current_sha=$(git rev-parse HEAD 2>/dev/null)
  local remote_sha=$(git rev-parse @{u} 2>/dev/null || git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null)

  cd - >/dev/null

  if [[ "$current_sha" == "$remote_sha" ]]; then
    return 1  # No updates
  else
    return 0  # Updates available
  fi
}

# Update single plugin
_zsh_tool_update_plugin() {
  local plugin=$1
  local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"

  if [[ ! -d "$plugin_dir/.git" ]]; then
    _zsh_tool_log DEBUG "Plugin $plugin is not a git repository, skipping"
    return 1
  fi

  _zsh_tool_log INFO "Updating plugin: $plugin"

  cd "$plugin_dir"

  local current_version=$(_zsh_tool_get_plugin_version "$plugin")

  # Pull latest changes
  git pull 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local pull_status=${PIPESTATUS[1]}

  if [[ $pull_status -ne 0 ]]; then
    _zsh_tool_log WARN "Failed to update plugin: $plugin"
    cd - >/dev/null
    return 1
  fi

  local new_version=$(_zsh_tool_get_plugin_version "$plugin")

  cd - >/dev/null

  if [[ "$current_version" == "$new_version" ]]; then
    _zsh_tool_log INFO "✓ Plugin $plugin (already up to date)"
  else
    _zsh_tool_log INFO "✓ Plugin $plugin updated ($current_version → $new_version)"
  fi

  # Update state
  _zsh_tool_update_state "plugins.${plugin}.version" "\"${new_version}\""
  _zsh_tool_update_state "plugins.${plugin}.last_update" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  return 0
}

# Update all custom plugins
_zsh_tool_update_all_plugins() {
  _zsh_tool_log INFO "Updating custom plugins..."

  if [[ ! -d "$OMZ_CUSTOM_PLUGINS" ]]; then
    _zsh_tool_log WARN "No custom plugins directory found"
    return 1
  fi

  local updated_count=0
  local failed_count=0
  local skipped_count=0

  for plugin_dir in ${OMZ_CUSTOM_PLUGINS}/*; do
    if [[ ! -d "$plugin_dir" ]]; then
      continue
    fi

    local plugin=$(basename "$plugin_dir")

    # Skip if not a git repo
    if [[ ! -d "$plugin_dir/.git" ]]; then
      _zsh_tool_log DEBUG "Plugin $plugin is not a git repository, skipping"
      ((skipped_count++))
      continue
    fi

    # Update plugin
    if _zsh_tool_update_plugin "$plugin"; then
      ((updated_count++))
    else
      ((failed_count++))
    fi
  done

  _zsh_tool_log INFO "✓ Plugins: $updated_count updated, $skipped_count skipped, $failed_count failed"

  return 0
}
