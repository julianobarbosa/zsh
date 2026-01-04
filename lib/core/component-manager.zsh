#!/usr/bin/env zsh
# Shared Component Management Module
# Extracted from plugins.zsh and themes.zsh to eliminate 95% code duplication
# Handles git-based installation and updates for plugins, themes, and future integrations

# Generic component version detection
# Usage: _zsh_tool_get_component_version <component_dir>
_zsh_tool_get_component_version() {
  local component_dir=$1

  if [[ ! -d "$component_dir/.git" ]]; then
    echo "not-git"
    return 1
  fi

  (
    cd "$component_dir" || return 1
    git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown"
  )
}

# Generic component update check
# Usage: _zsh_tool_check_component_updates <component_dir>
# Returns: 0 if updates available, 1 otherwise
_zsh_tool_check_component_updates() {
  local component_dir=$1

  if [[ ! -d "$component_dir/.git" ]]; then
    return 1  # Not a git repo, skip
  fi

  (
    cd "$component_dir" || return 1

    # Fetch latest changes
    git fetch origin 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    local fetch_status=${pipestatus[1]}

    if [[ $fetch_status -ne 0 ]]; then
      return 1
    fi

    # Check if updates available
    local current_sha=$(git rev-parse HEAD 2>/dev/null)
    local remote_sha=$(git rev-parse @{u} 2>/dev/null || git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null)

    if [[ "$current_sha" == "$remote_sha" ]]; then
      return 1  # No updates
    else
      return 0  # Updates available
    fi
  )
}

# Generic component update
# Usage: _zsh_tool_update_component <component_type> <component_name> <component_dir>
# Returns: 0 on success, 1 on failure
_zsh_tool_update_component() {
  local component_type=$1  # "plugin" or "theme"
  local component_name=$2
  local component_dir=$3

  if [[ ! -d "$component_dir/.git" ]]; then
    _zsh_tool_log DEBUG "${(C)component_type} $component_name is not a git repository, skipping"
    return 1
  fi

  _zsh_tool_log INFO "Updating ${component_type}: $component_name"

  local current_version=$(_zsh_tool_get_component_version "$component_dir")

  (
    cd "$component_dir" || {
      _zsh_tool_log WARN "Failed to change to ${component_type} directory: $component_name"
      return 1
    }

    # Pull latest changes
    git pull 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    local pull_status=${pipestatus[1]}

    if [[ $pull_status -ne 0 ]]; then
      _zsh_tool_log WARN "Failed to update ${component_type}: $component_name"
      return 1
    fi
  )

  local new_version=$(_zsh_tool_get_component_version "$component_dir")

  if [[ "$current_version" == "$new_version" ]]; then
    _zsh_tool_log INFO "✓ ${(C)component_type} $component_name (already up to date)"
  else
    _zsh_tool_log INFO "✓ ${(C)component_type} $component_name updated ($current_version → $new_version)"
  fi

  # Update state
  _zsh_tool_update_state "${component_type}s.${component_name}.version" "\"${new_version}\""
  _zsh_tool_update_state "${component_type}s.${component_name}.last_update" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  return 0
}

# Generic component installation
# Usage: _zsh_tool_install_git_component <component_type> <component_name> <git_url> <target_dir>
# Returns: 0 on success, 1 on failure
_zsh_tool_install_git_component() {
  local component_type=$1  # "plugin" or "theme"
  local component_name=$2
  local git_url=$3
  local target_dir=$4

  # Validate inputs
  if [[ -z "$git_url" ]]; then
    _zsh_tool_log ERROR "${(C)component_type} $component_name not found in registry"
    return 1
  fi

  # Check if already installed
  if [[ -d "$target_dir" ]]; then
    _zsh_tool_log INFO "${(C)component_type} $component_name already installed"
    return 0
  fi

  _zsh_tool_log INFO "Installing ${component_type}: $component_name from $git_url"

  # Clone repository
  git clone --depth 1 "$git_url" "$target_dir" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local clone_status=${pipestatus[1]}

  if [[ $clone_status -eq 0 ]]; then
    _zsh_tool_log INFO "✓ ${(C)component_type} $component_name installed"

    # Update state
    local version=$(_zsh_tool_get_component_version "$target_dir")
    _zsh_tool_update_state "${component_type}s.${component_name}.installed" "true"
    _zsh_tool_update_state "${component_type}s.${component_name}.version" "\"${version}\""

    return 0
  else
    _zsh_tool_log ERROR "Failed to install ${component_type}: $component_name"
    return 1
  fi
}

# Generic built-in component detection
# Usage: _zsh_tool_is_builtin_component <component_name> <builtin_array_name>
# Returns: 0 if builtin, 1 otherwise
_zsh_tool_is_builtin_component() {
  local component_name=$1
  local -n builtin_array=$2  # Name reference to array

  # Check if component is in builtin array
  for builtin in "${builtin_array[@]}"; do
    if [[ "$builtin" == "$component_name" ]]; then
      return 0
    fi
  done

  return 1
}

# Parallel component update
# Usage: _zsh_tool_update_components_parallel <component_type> <components_dir> <update_func>
# Returns: 0 on success
_zsh_tool_update_components_parallel() {
  local component_type=$1  # "plugin" or "theme"
  local components_dir=$2
  local update_func=$3     # Function to call for each component

  _zsh_tool_log INFO "Updating ${component_type}s in parallel..."

  if [[ ! -d "$components_dir" ]]; then
    _zsh_tool_log DEBUG "No custom ${component_type}s directory found"
    return 0
  fi

  local updated_count=0
  local failed_count=0
  local skipped_count=0
  local -a component_pids=()
  local -a component_names=()

  # Temp dir for parallel results
  local temp_dir=$(mktemp -d)

  # Launch updates in parallel (background jobs)
  for component_dir in ${components_dir}/*(N); do
    if [[ ! -d "$component_dir" ]]; then
      continue
    fi

    local component=$(basename "$component_dir")

    # Skip if not a git repo
    if [[ ! -d "$component_dir/.git" ]]; then
      _zsh_tool_log DEBUG "${(C)component_type} $component is not a git repository, skipping"
      ((skipped_count++))
      continue
    fi

    # Update component in background
    (
      if $update_func "$component"; then
        echo "success" > "${temp_dir}/${component}.status"
      else
        echo "failed" > "${temp_dir}/${component}.status"
      fi
    ) &

    component_pids+=($!)
    component_names+=("$component")
  done

  # Wait for all parallel updates to complete
  for pid in ${component_pids[@]}; do
    wait $pid
  done

  # Collect results
  for component in ${component_names[@]}; do
    if [[ -f "${temp_dir}/${component}.status" ]]; then
      local component_status=$(cat "${temp_dir}/${component}.status")
      if [[ "$component_status" == "success" ]]; then
        ((updated_count++))
      else
        ((failed_count++))
      fi
    fi
  done

  # Cleanup
  rm -rf "$temp_dir"

  _zsh_tool_log INFO "✓ ${(C)component_type}s: $updated_count updated, $skipped_count skipped, $failed_count failed (parallel execution)"

  return 0
}
