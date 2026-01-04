#!/usr/bin/env zsh
# Story 1.7: Installation Verification and Summary
# Module: lib/install/verify.zsh
# Purpose: Verify installation and display summary

# ============================================================================
# SECURITY VALIDATION FUNCTIONS
# ============================================================================

# Validate a name (plugin, theme) against safe characters
# Only allows alphanumeric, hyphens, and underscores
# Returns: 0 if valid, 1 if invalid
# Note: Warnings sent to stderr to avoid polluting function output
_zsh_tool_validate_name() {
  local name="$1"
  local type="${2:-item}"

  # Check for empty name
  if [[ -z "$name" ]]; then
    echo "[WARN] Empty ${type} name detected" >&2
    return 1
  fi

  # CRITICAL: Validate name - only allow safe characters (alphanumeric, hyphens, underscores)
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "[WARN] Invalid ${type} name detected (unsafe characters): $name" >&2
    return 1
  fi

  # CRITICAL: Check for path traversal attempts
  if [[ "$name" == *".."* || "$name" == *"/"* || "$name" == *"\\"* ]]; then
    echo "[ERROR] Path traversal attempt detected in ${type} name: $name" >&2
    return 1
  fi

  return 0
}

# Safely parse YAML list items from config file
# Only returns items with valid names (alphanumeric, hyphens, underscores)
# Arguments: config_file section_name
# Returns: Prints valid items, one per line
_zsh_tool_parse_yaml_list() {
  local config_file="$1"
  local section="$2"
  local items=()

  if [[ ! -f "$config_file" ]]; then
    _zsh_tool_log ERROR "Config file not found: $config_file"
    return 1
  fi

  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Extract item name - remove leading "- " and any trailing whitespace
    local item="${line##*- }"
    item="${item%%[[:space:]]*}"  # Remove trailing whitespace
    item="${item//[[:space:]]/}"  # Remove any remaining whitespace

    # Skip empty items
    [[ -z "$item" ]] && continue

    # CRITICAL: Validate item name - only allow safe characters
    if ! _zsh_tool_validate_name "$item" "plugin/theme"; then
      echo "[WARN] Skipping invalid item name in config: $item" >&2
      continue
    fi

    items+=("$item")
  done < <(grep "^  - " "$config_file" 2>/dev/null | sed 's/^  - //' | grep -v "^#")

  # Output valid items
  printf '%s\n' "${items[@]}"
}

# Safely parse theme from config file
# Returns: Prints validated theme name or empty string
_zsh_tool_parse_theme() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    _zsh_tool_log ERROR "Config file not found: $config_file"
    return 1
  fi

  local theme=$(grep "^theme:" "$config_file" | sed 's/^theme: *//' | tr -d '"' | tr -d "'" | tr -d '[:space:]')

  # If no theme configured, return empty (valid case)
  if [[ -z "$theme" ]]; then
    return 0
  fi

  # CRITICAL: Validate theme name
  if ! _zsh_tool_validate_name "$theme" "theme"; then
    _zsh_tool_log ERROR "Invalid theme name in config: $theme"
    return 1
  fi

  echo "$theme"
}

# ============================================================================
# VERIFICATION FUNCTIONS
# ============================================================================

# Validate backup location path for safety
# Only allows paths under expected directories (HOME, /tmp, or system temp directories)
# Returns: 0 if valid, 1 if invalid
_zsh_tool_validate_backup_location() {
  local backup_location="$1"

  # Check for empty path
  if [[ -z "$backup_location" ]]; then
    _zsh_tool_log DEBUG "Empty backup location"
    return 1
  fi

  # CRITICAL: Normalize the path to resolve any symlinks and relative components
  local resolved_path
  resolved_path=$(cd "$backup_location" 2>/dev/null && pwd -P) || {
    _zsh_tool_log DEBUG "Cannot resolve backup location: $backup_location"
    return 1
  }

  # CRITICAL: Check for path traversal attempts in the original path
  if [[ "$backup_location" == *".."* ]]; then
    _zsh_tool_log ERROR "Path traversal attempt detected in backup location: $backup_location"
    return 1
  fi

  # CRITICAL: Validate the resolved path is under allowed directories
  # Allow paths under:
  # - HOME directory
  # - /tmp or /private/tmp (common temp locations)
  # - /var/folders or /private/var/folders (macOS temp directories from mktemp)
  local home_real
  home_real=$(cd "$HOME" 2>/dev/null && pwd -P)

  local allowed=false
  if [[ "$resolved_path" == "${home_real}"* ]]; then
    allowed=true
  elif [[ "$resolved_path" == "/tmp"* || "$resolved_path" == "/private/tmp"* ]]; then
    allowed=true
  elif [[ "$resolved_path" == "/var/folders"* || "$resolved_path" == "/private/var/folders"* ]]; then
    # macOS mktemp creates dirs under /var/folders (symlinked to /private/var/folders)
    allowed=true
  fi

  if [[ "$allowed" != "true" ]]; then
    _zsh_tool_log ERROR "Backup location outside allowed directories: $resolved_path"
    return 1
  fi

  # CRITICAL: Check for shell metacharacters that could cause command injection
  if [[ "$backup_location" =~ [\;\|\&\$\`\<\>\(\)\{\}\[\]\'\"] ]]; then
    _zsh_tool_log ERROR "Invalid characters in backup location: $backup_location"
    return 1
  fi

  return 0
}

# Verify installation in a subshell (as specified in story requirements)
# This tests that ~/.zshrc can be sourced correctly in a fresh shell
# Returns: 0 if subshell verification passes, 1 otherwise
_zsh_tool_verify_in_subshell() {
  _zsh_tool_log DEBUG "Running subshell verification"

  local zshrc="${HOME}/.zshrc"

  # Check if .zshrc exists
  if [[ ! -f "$zshrc" ]]; then
    _zsh_tool_log ERROR "~/.zshrc does not exist"
    return 1
  fi

  # Run verification in a subshell as specified in the story:
  # zsh -c 'source ~/.zshrc && typeset -f omz'
  local subshell_output
  local subshell_result

  # Use timeout to prevent hanging if there are issues
  if command -v timeout >/dev/null 2>&1; then
    subshell_output=$(timeout 30 zsh -c 'source ~/.zshrc && typeset -f omz' 2>&1)
    subshell_result=$?
  else
    # Fallback without timeout (macOS may not have timeout by default)
    subshell_output=$(zsh -c 'source ~/.zshrc && typeset -f omz' 2>&1)
    subshell_result=$?
  fi

  if [[ $subshell_result -ne 0 ]]; then
    _zsh_tool_log ERROR "Subshell verification failed: $subshell_output"
    return 1
  fi

  # Verify the output contains the omz function definition
  if [[ "$subshell_output" != *"omz"* ]]; then
    _zsh_tool_log ERROR "omz function not found in subshell"
    return 1
  fi

  _zsh_tool_log DEBUG "Subshell verification passed"
  return 0
}

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

  # SECURITY FIX: Use safe YAML parser with validation
  local plugins=()
  while IFS= read -r plugin; do
    [[ -n "$plugin" ]] && plugins+=("$plugin")
  done < <(_zsh_tool_parse_yaml_list "$config_file" "plugins")

  if [[ ${#plugins[@]} -eq 0 ]]; then
    _zsh_tool_log DEBUG "No plugins configured"
    return 0
  fi

  local failed_plugins=()

  for plugin in "${plugins[@]}"; do
    _zsh_tool_log DEBUG "Checking plugin: $plugin"

    # SECURITY: Plugin name already validated by _zsh_tool_parse_yaml_list
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

  # SECURITY FIX: Use safe theme parser with validation
  local configured_theme
  configured_theme=$(_zsh_tool_parse_theme "$config_file")
  local parse_result=$?

  # Check if parsing failed (invalid theme name detected)
  if [[ $parse_result -ne 0 ]]; then
    _zsh_tool_log ERROR "Failed to parse theme from config (possible security issue)"
    return 1
  fi

  if [[ -z "$configured_theme" ]]; then
    _zsh_tool_log DEBUG "No theme configured"
    return 0
  fi

  # SECURITY FIX: Additional validation - theme name already validated by _zsh_tool_parse_theme
  # but double-check for path traversal before file operations
  if [[ ! "$configured_theme" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    _zsh_tool_log ERROR "Invalid theme name detected: $configured_theme"
    return 1
  fi

  if [[ "$configured_theme" == *".."* || "$configured_theme" == *"/"* ]]; then
    _zsh_tool_log ERROR "Path traversal attempt detected in theme name"
    return 1
  fi

  # Check $ZSH_THEME matches config
  if [[ "$ZSH_THEME" != "$configured_theme" ]]; then
    _zsh_tool_log ERROR "Theme mismatch: configured=$configured_theme, actual=$ZSH_THEME"
    return 1
  fi

  # Check theme file exists (now safe after validation)
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
    # SECURITY FIX: Use safe YAML parser with validation for plugins
    local plugins=()
    while IFS= read -r plugin; do
      [[ -n "$plugin" ]] && plugins+=("$plugin")
    done < <(_zsh_tool_parse_yaml_list "$config_file" "plugins")

    if [[ ${#plugins[@]} -gt 0 ]]; then
      echo "  Plugins:"
      for plugin in "${plugins[@]}"; do
        echo "    ✓ $plugin"
      done
    fi

    # SECURITY FIX: Use safe theme parser with validation
    local theme
    theme=$(_zsh_tool_parse_theme "$config_file")
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
      # SECURITY FIX (HIGH-6): Validate backup_location before using with find
      if _zsh_tool_validate_backup_location "$backup_location"; then
        echo "Backup:"
        echo "  ✓ Location: $backup_location"
        echo "  ✓ Timestamp: $backup_timestamp"
        # Safe to use find now that backup_location is validated
        local backup_count=$(find "$backup_location" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo "  ✓ Files backed up: $backup_count"
        echo ""
      else
        _zsh_tool_log WARN "Skipping backup display: invalid backup location"
      fi
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

  # HIGH-3 FIX: Run subshell verification as specified in story requirements
  # This verifies that ~/.zshrc can be sourced in a fresh shell
  # Skip subshell verification if ZSH_TOOL_SKIP_SUBSHELL_VERIFY is set (for testing)
  if [[ -z "$ZSH_TOOL_SKIP_SUBSHELL_VERIFY" ]]; then
    if ! _zsh_tool_verify_in_subshell; then
      failed_checks+=("Subshell verification failed")
    fi
  else
    _zsh_tool_log DEBUG "Skipping subshell verification (ZSH_TOOL_SKIP_SUBSHELL_VERIFY set)"
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
