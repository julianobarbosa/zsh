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

  if [[ -z "$section" ]]; then
    _zsh_tool_log ERROR "Section parameter required"
    return 1
  fi

  # Extract items only from the specified section
  # Uses awk to find the section header and extract list items until the next top-level section
  local in_section=0
  while IFS= read -r line; do
    # Check if we've hit the target section header (e.g., "plugins:")
    if [[ "$line" =~ ^${section}:[[:space:]]*$ ]]; then
      in_section=1
      continue
    fi

    # Check if we've hit a new top-level section (non-indented line ending with :)
    # This means we've left our target section
    if [[ $in_section -eq 1 && "$line" =~ ^[^[:space:]] ]]; then
      break
    fi

    # Skip if not in our section
    [[ $in_section -eq 0 ]] && continue

    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Only process simple list items (lines starting with "  - " followed by a simple value)
    # Skip complex items like "  - name: value" (these have a colon after the item)
    if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]+([^:[:space:]]+)[[:space:]]*$ ]]; then
      local item="${match[1]}"

      # Skip empty items
      [[ -z "$item" ]] && continue

      # CRITICAL: Validate item name - only allow safe characters
      if ! _zsh_tool_validate_name "$item" "plugin/theme"; then
        echo "[WARN] Skipping invalid item name in config: $item" >&2
        continue
      fi

      items+=("$item")
    fi
  done < "$config_file"

  # Output valid items
  printf '%s\n' "${items[@]}"
}

# Safely parse theme from config file (for verification)
# Note: Named differently from _zsh_tool_parse_theme in config.zsh to avoid collision
# Returns: Prints validated theme name or empty string
_zsh_tool_verify_parse_theme() {
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

# Check if Oh My Zsh is installed
# Returns: 0 if OMZ is installed, 1 otherwise
# Note: During installation, .zshrc hasn't been sourced so we check files exist, not functions loaded
_zsh_tool_check_omz_loaded() {
  _zsh_tool_log DEBUG "Checking if Oh My Zsh is installed"

  # Set default OMZ path if not already set (during install, .zshrc hasn't been sourced)
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"

  # Check oh-my-zsh.sh exists
  if [[ ! -f "$zsh_dir/oh-my-zsh.sh" ]]; then
    _zsh_tool_log DEBUG "oh-my-zsh.sh not found at $zsh_dir"
    return 1
  fi

  # Check essential OMZ directories exist
  if [[ ! -d "$zsh_dir/plugins" ]] || [[ ! -d "$zsh_dir/themes" ]]; then
    _zsh_tool_log DEBUG "OMZ plugins or themes directory not found at $zsh_dir"
    return 1
  fi

  _zsh_tool_log DEBUG "Oh My Zsh is installed successfully"
  return 0
}

# Check if configured plugins are installed
# Returns: 0 if all plugins are installed, 1 otherwise
# Note: This checks installation (files exist), not loading (which requires sourcing .zshrc)
_zsh_tool_check_plugins_loaded() {
  _zsh_tool_log DEBUG "Checking if plugins are installed"

  # Set default OMZ paths if not already set (during install, .zshrc hasn't been sourced)
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local zsh_custom="${ZSH_CUSTOM:-$zsh_dir/custom}"

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
    # Check if plugin is installed (directory exists in OMZ plugins or custom plugins)
    # External plugins (zsh-syntax-highlighting, zsh-autosuggestions) are installed to $ZSH_CUSTOM/plugins/
    if [[ -d "$zsh_dir/plugins/$plugin" ]] || [[ -d "$zsh_custom/plugins/$plugin" ]]; then
      _zsh_tool_log DEBUG "Plugin found: $plugin"
    else
      failed_plugins+=("$plugin")
      _zsh_tool_log DEBUG "Plugin check failed: $plugin (directory not found in $zsh_dir/plugins or $zsh_custom/plugins)"
    fi
  done

  if [[ ${#failed_plugins[@]} -gt 0 ]]; then
    _zsh_tool_log ERROR "Failed to find plugins: ${failed_plugins[*]}"
    return 1
  fi

  _zsh_tool_log DEBUG "All plugins installed successfully"
  return 0
}

# Check if theme is installed
# Returns: 0 if theme is installed, 1 otherwise
# Note: During installation, .zshrc hasn't been sourced so we check files exist, not ZSH_THEME var
_zsh_tool_check_theme_applied() {
  _zsh_tool_log DEBUG "Checking if theme is installed"

  # Set default OMZ paths if not already set (during install, .zshrc hasn't been sourced)
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local zsh_custom="${ZSH_CUSTOM:-$zsh_dir/custom}"

  # Read theme from config
  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  if [[ ! -f "$config_file" ]]; then
    _zsh_tool_log ERROR "Config file not found: $config_file"
    return 1
  fi

  # SECURITY FIX: Use safe theme parser with validation
  local configured_theme
  configured_theme=$(_zsh_tool_verify_parse_theme "$config_file")
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

  # Check theme file exists (now safe after validation)
  if [[ ! -f "$zsh_dir/themes/${configured_theme}.zsh-theme" ]] && \
     [[ ! -f "$zsh_custom/themes/${configured_theme}.zsh-theme" ]]; then
    _zsh_tool_log ERROR "Theme file not found: $configured_theme"
    return 1
  fi

  _zsh_tool_log DEBUG "Theme installed successfully: $configured_theme"
  return 0
}

# MEDIUM FIX: Detect if running in a TTY for colored output
# Returns: 0 if TTY available, 1 otherwise
_zsh_tool_is_tty() {
  [[ -t 1 ]] && [[ -t 2 ]]
}

# Safe echo with emoji support
# Usage: _zsh_tool_echo_status <status_type> <message> [is_tty]
# status_type: "success", "failure", "warning", "info", "tip", "cmd"
# is_tty: "true" or "false" (optional, auto-detects if not provided)
_zsh_tool_echo_status() {
  local status_type="$1"
  local message="$2"
  local is_tty="${3:-}"

  # Auto-detect TTY if not provided (check directly, not in subshell)
  if [[ -z "$is_tty" ]]; then
    if [[ -t 1 ]]; then
      is_tty="true"
    else
      is_tty="false"
    fi
  fi

  local prefix=""

  # Use beautiful emojis for TTY
  if [[ "$is_tty" == "true" ]]; then
    case "$status_type" in
      success) prefix="✅" ;;
      failure) prefix="❌" ;;
      warning) prefix="⚠️ " ;;
      info)    prefix="📌" ;;
      tip)     prefix="💡" ;;
      cmd)     prefix="👉" ;;
      *)       prefix="  " ;;
    esac
  else
    # ASCII fallbacks for non-TTY environments (CI/pipes)
    case "$status_type" in
      success) prefix="[OK]" ;;
      failure) prefix="[FAIL]" ;;
      warning) prefix="[WARN]" ;;
      info)    prefix="[i]" ;;
      tip)     prefix="[*]" ;;
      cmd)     prefix="[>]" ;;
      *)       prefix="   " ;;
    esac
  fi

  echo "   ${prefix} ${message}"
}

# Display installation summary
# Returns: 0 on success
_zsh_tool_display_summary() {
  _zsh_tool_log DEBUG "Displaying installation summary"

  # Check TTY directly (don't use subshell - breaks -t test)
  local is_tty=false
  if [[ -t 1 ]]; then
    is_tty=true
  fi

  local line=""

  # Build separator line
  if [[ "$is_tty" == "true" ]]; then
    line="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    line="=============================================="
  fi

  echo ""
  echo "$line"
  if [[ "$is_tty" == "true" ]]; then
    echo "   ✅ ZSH-TOOL VERIFIED"
  else
    echo "   [OK] ZSH-TOOL VERIFIED"
  fi
  echo "$line"
  echo ""

  # ─────────────────────────────────────────────────
  # 📦 Prerequisites Section
  # ─────────────────────────────────────────────────
  if [[ "$is_tty" == "true" ]]; then
    echo "📦 Prerequisites"
  else
    echo "[Prerequisites]"
  fi

  # Collect prerequisite info with aligned columns
  # Suppress any noise from external tools (direnv, etc.)
  local brew_ver="" git_ver="" omz_ver="" zsh_ver=""

  if command -v brew >/dev/null 2>&1; then
    brew_ver=$(DIRENV_DIR= brew --version 2>/dev/null | head -1 | sed 's/Homebrew //')
  fi

  if command -v git >/dev/null 2>&1; then
    git_ver=$(DIRENV_DIR= git --version 2>/dev/null | sed 's/git version //')
  fi

  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  if [[ -d "$zsh_dir/.git" ]]; then
    omz_ver=$(cd "$zsh_dir" && DIRENV_DIR= git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  fi

  zsh_ver=$(zsh --version 2>/dev/null | sed 's/zsh //' | cut -d' ' -f1)

  # Display in clean columns
  [[ -n "$brew_ver" ]] && _zsh_tool_echo_status "success" "Homebrew      $brew_ver" "$is_tty"
  [[ -n "$git_ver" ]]  && _zsh_tool_echo_status "success" "Git           $git_ver" "$is_tty"
  [[ -n "$omz_ver" ]]  && _zsh_tool_echo_status "success" "Oh My Zsh     $omz_ver" "$is_tty"
  [[ -n "$zsh_ver" ]]  && _zsh_tool_echo_status "success" "Zsh           $zsh_ver" "$is_tty"

  echo ""

  # ─────────────────────────────────────────────────
  # 🔌 Plugins Section
  # ─────────────────────────────────────────────────
  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  if [[ -f "$config_file" ]]; then
    local plugins=()
    while IFS= read -r plugin; do
      [[ -n "$plugin" ]] && plugins+=("$plugin")
    done < <(_zsh_tool_parse_yaml_list "$config_file" "plugins")

    if [[ ${#plugins[@]} -gt 0 ]]; then
      if [[ "$is_tty" == "true" ]]; then
        echo "🔌 Plugins (${#plugins[@]} active)"
      else
        echo "[Plugins] (${#plugins[@]} active)"
      fi

      # Display plugins in a compact row format
      local plugin_line="  "
      for plugin in "${plugins[@]}"; do
        plugin_line+=" $plugin "
      done
      _zsh_tool_echo_status "success" "${plugin_line}" "$is_tty"
      echo ""
    fi
  fi

  # ─────────────────────────────────────────────────
  # ⚙️  Config Layers Section
  # ─────────────────────────────────────────────────
  if [[ "$is_tty" == "true" ]]; then
    echo "⚙️  Config Layers"
  else
    echo "[Config Layers]"
  fi

  # Team config
  if [[ -f "$config_file" ]]; then
    _zsh_tool_echo_status "success" "Team:       $config_file" "$is_tty"
  fi

  # Custom layer
  if [[ -f "${HOME}/.zshrc.local" ]]; then
    _zsh_tool_echo_status "success" "Personal:   ~/.zshrc.local" "$is_tty"
  fi

  echo ""

  # ─────────────────────────────────────────────────
  # 🎉 Success Footer
  # ─────────────────────────────────────────────────
  echo "$line"
  if [[ "$is_tty" == "true" ]]; then
    echo "   🎉 You're all set!"
  else
    echo "   You're all set!"
  fi
  echo "$line"
  echo ""

  # ─────────────────────────────────────────────────
  # Available Commands (not homework!)
  # ─────────────────────────────────────────────────
  _zsh_tool_echo_status "tip" "zsh-tool help        Show all commands" "$is_tty"
  _zsh_tool_echo_status "cmd" "zsh-tool customize   Edit personal settings" "$is_tty"
  _zsh_tool_echo_status "cmd" "zsh-tool update      Check for updates" "$is_tty"
  echo ""

  return 0
}

# Verify installation
# Returns: 0 if all checks pass, 1 if any fail
_zsh_tool_verify_installation() {
  _zsh_tool_log DEBUG "Verifying installation"

  # Check TTY directly (don't use subshell - breaks -t test)
  local is_tty=false
  if [[ -t 1 ]]; then
    is_tty=true
  fi

  local line=""

  if [[ "$is_tty" == "true" ]]; then
    line="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    line="=============================================="
  fi

  local failed_checks=()
  local failed_remediation=()

  # Check Oh My Zsh
  if ! _zsh_tool_check_omz_loaded; then
    failed_checks+=("Oh My Zsh not installed")
    failed_remediation+=('sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"')
  fi

  # Check plugins
  if ! _zsh_tool_check_plugins_loaded; then
    failed_checks+=("Some plugins not found")
    failed_remediation+=("Check plugin names in config.yaml or run: zsh-tool install")
  fi

  # Check theme
  if ! _zsh_tool_check_theme_applied; then
    failed_checks+=("Theme not installed")
    failed_remediation+=("Verify theme name in config.yaml exists in ~/.oh-my-zsh/themes/")
  fi

  # HIGH-3 FIX: Run subshell verification as specified in story requirements
  if [[ -z "$ZSH_TOOL_SKIP_SUBSHELL_VERIFY" ]]; then
    if ! _zsh_tool_verify_in_subshell; then
      failed_checks+=("Shell configuration error")
      failed_remediation+=("Check ~/.zshrc for syntax errors: zsh -n ~/.zshrc")
    fi
  else
    _zsh_tool_log DEBUG "Skipping subshell verification (ZSH_TOOL_SKIP_SUBSHELL_VERIFY set)"
  fi

  # Report results - FAILURE STATE
  if [[ ${#failed_checks[@]} -gt 0 ]]; then
    _zsh_tool_log ERROR "Installation verification failed"

    echo ""
    echo "$line"
    if [[ "$is_tty" == "true" ]]; then
      echo "   ❌ ZSH-TOOL VERIFICATION FAILED"
    else
      echo "   [FAIL] ZSH-TOOL VERIFICATION FAILED"
    fi
    echo "$line"
    echo ""

    if [[ "$is_tty" == "true" ]]; then
      echo "🚨 ${#failed_checks[@]} issue(s) blocking your setup"
    else
      echo "[!] ${#failed_checks[@]} issue(s) blocking your setup"
    fi
    echo ""

    # Show numbered issues with remediation
    local i=1
    for idx in {1..${#failed_checks[@]}}; do
      local check="${failed_checks[$idx]}"
      local fix="${failed_remediation[$idx]}"

      if [[ "$is_tty" == "true" ]]; then
        echo "   ${idx}️⃣  ${check}"
      else
        echo "   [$idx] ${check}"
      fi
      echo ""
      echo "      ${fix}"
      echo ""
    done

    echo "$line"
    if [[ "$is_tty" == "true" ]]; then
      echo "   👉 Fix in order, then: zsh-tool-verify"
    else
      echo "   [>] Fix in order, then: zsh-tool-verify"
    fi
    echo "$line"
    echo ""

    return 1
  fi

  _zsh_tool_log DEBUG "Installation verification passed"

  # Success is shown in _zsh_tool_display_summary
  return 0
}

# ============================================================================
# PUBLIC INTERFACE
# ============================================================================

# Public command: zsh-tool-verify
# Runs verification and displays summary
zsh-tool-verify() {
  # Temporarily suppress direnv and other noisy tools
  local _old_direnv_dir="${DIRENV_DIR:-}"
  unset DIRENV_DIR 2>/dev/null

  _zsh_tool_log DEBUG "Running installation verification"

  local result=0

  # Run verification first
  if ! _zsh_tool_verify_installation; then
    result=1
  fi

  # Display summary (success or failure already shown by verify_installation)
  if [[ $result -eq 0 ]]; then
    _zsh_tool_display_summary | grep -v -E "^(direnv:|\\[0m)"
  fi

  # Restore direnv if it was set
  [[ -n "$_old_direnv_dir" ]] && export DIRENV_DIR="$_old_direnv_dir"

  return $result
}
