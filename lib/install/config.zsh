#!/usr/bin/env zsh
# Story 1.3: Install Team-Standard Configuration
# Generate and install .zshrc from team configuration

ZSH_TOOL_TEMPLATE_DIR="${ZSH_TOOL_CONFIG_DIR}/templates"
ZSH_TOOL_MANAGED_BEGIN="# ===== ZSH-TOOL MANAGED SECTION BEGIN ====="
ZSH_TOOL_MANAGED_END="# ===== ZSH-TOOL MANAGED SECTION END ====="

# Config cache (reduces I/O for multiple parse calls)
typeset -g _ZSH_TOOL_CONFIG_CACHE=""
typeset -g _ZSH_TOOL_CONFIG_CACHE_FILE=""

# Load configuration from YAML (simple parser with caching)
_zsh_tool_load_config() {
  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"

  # Validate file exists
  if [[ ! -f "$config_file" ]]; then
    _zsh_tool_log error "Configuration file not found: $config_file"
    return 1
  fi

  # Return cached config if same file
  if [[ -n "$_ZSH_TOOL_CONFIG_CACHE" && "$_ZSH_TOOL_CONFIG_CACHE_FILE" == "$config_file" ]]; then
    echo "$_ZSH_TOOL_CONFIG_CACHE"
    return 0
  fi

  # Load and validate file read
  local config_content
  if ! config_content=$(cat "$config_file" 2>/dev/null); then
    _zsh_tool_log error "Failed to read configuration file: $config_file"
    return 1
  fi

  # Basic structure validation
  if [[ -z "$config_content" ]]; then
    _zsh_tool_log error "Configuration file is empty: $config_file"
    return 1
  fi

  # Cache for subsequent calls
  _ZSH_TOOL_CONFIG_CACHE="$config_content"
  _ZSH_TOOL_CONFIG_CACHE_FILE="$config_file"

  echo "$config_content"
  return 0
}

# Clear config cache (call after config changes)
_zsh_tool_clear_config_cache() {
  _ZSH_TOOL_CONFIG_CACHE=""
  _ZSH_TOOL_CONFIG_CACHE_FILE=""
}

# Parse plugins from config
_zsh_tool_parse_plugins() {
  local config=$(_zsh_tool_load_config) || return 1
  local in_plugins=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^plugins: ]]; then
      in_plugins=true
      continue
    elif [[ "$line" =~ ^[a-z]+: ]] && [[ "$in_plugins" == true ]]; then
      break
    fi

    if [[ "$in_plugins" == true && "$line" =~ -\ ([a-zA-Z0-9_-]+) ]]; then
      # Safely access match array
      [[ -n "${match[1]:-}" ]] && echo -n "${match[1]} "
    fi
  done <<< "$config"
}

# Parse theme from config
_zsh_tool_parse_theme() {
  local config=$(_zsh_tool_load_config)
  # Extract theme section first, then get default
  local section=$(_zsh_tool_extract_yaml_section "themes" "$config")
  echo "$section" | grep '^\s*default:' | head -1 | awk '{print $2}' | tr -d '"'
}

# Parse aliases from config
_zsh_tool_parse_aliases() {
  local config=$(_zsh_tool_load_config) || return 1
  local in_aliases=false
  local name=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^aliases: ]]; then
      in_aliases=true
      continue
    elif [[ "$line" =~ ^[a-z]+: ]] && [[ "$in_aliases" == true ]]; then
      break
    fi

    if [[ "$in_aliases" == true ]]; then
      if [[ "$line" =~ name:\ \"(.+)\" ]]; then
        # Safely access match array
        [[ -n "${match[1]:-}" ]] && name="${match[1]}"
      elif [[ "$line" =~ command:\ \"(.+)\" ]]; then
        # Safely access match array
        if [[ -n "${match[1]:-}" && -n "$name" ]]; then
          echo "alias ${name}=\"${match[1]}\""
        fi
      fi
    fi
  done <<< "$config"
}

# Parse exports from config
_zsh_tool_parse_exports() {
  local config=$(_zsh_tool_load_config) || return 1
  local in_exports=false
  local name=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^exports: ]]; then
      in_exports=true
      continue
    elif [[ "$line" =~ ^[a-z]+: ]] && [[ "$in_exports" == true ]]; then
      break
    fi

    if [[ "$in_exports" == true ]]; then
      if [[ "$line" =~ name:\ \"(.+)\" ]]; then
        # Safely access match array
        [[ -n "${match[1]:-}" ]] && name="${match[1]}"
      elif [[ "$line" =~ value:\ \"(.+)\" ]]; then
        # Safely access match array and escape special characters
        if [[ -n "${match[1]:-}" && -n "$name" ]]; then
          local value="${match[1]}"
          # Escape double quotes and backslashes in export value
          value="${value//\\/\\\\}"
          value="${value//\"/\\\"}"
          echo "export ${name}=\"${value}\""
        fi
      fi
    fi
  done <<< "$config"
}

# Parse PATH modifications from config
_zsh_tool_parse_paths() {
  local config=$(_zsh_tool_load_config) || return 1
  local in_paths=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^paths: ]]; then
      in_paths=true
      continue
    elif [[ "$line" =~ ^[a-z]+: ]] && [[ "$in_paths" == true ]]; then
      break
    fi

    if [[ "$in_paths" == true && "$line" =~ -\ \"(.+)\" ]]; then
      # Safely access match array
      if [[ -n "${match[1]:-}" ]]; then
        local path="${match[1]}"
        # Expand only safe shell variables ($HOME, $USER) - no arbitrary eval
        path="${path//\$HOME/$HOME}"
        path="${path//\$USER/$USER}"
        path="${path//\~/$HOME}"
        echo "export PATH=\"${path}:\$PATH\""
      fi
    fi
  done <<< "$config"
}

# Helper: Extract a YAML section by name (handles sections up to 50 lines)
# Returns all lines from section start until next top-level key or EOF
_zsh_tool_extract_yaml_section() {
  local section_name="$1"
  local config="$2"
  local in_section=false

  while IFS= read -r line; do
    # Check if we hit the target section
    if [[ "$line" =~ ^${section_name}: ]]; then
      in_section=true
      echo "$line"
      continue
    fi

    # If we're in the section, check if we've hit a new top-level key
    if [[ "$in_section" == true ]]; then
      # New top-level key starts at column 0 with no leading space
      if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
        break
      fi
      echo "$line"
    fi
  done <<< "$config"
}

# Parse Amazon Q configuration
_zsh_tool_parse_amazon_q_enabled() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "amazon_q" "$config")
  echo "$section" | grep '^\s*enabled:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_amazon_q_lazy_loading() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "amazon_q" "$config")
  echo "$section" | grep '^\s*lazy_loading:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_amazon_q_atuin_compatibility() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "amazon_q" "$config")
  echo "$section" | grep '^\s*atuin_compatibility:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_amazon_q_disabled_clis() {
  local config=$(_zsh_tool_load_config)
  local in_disabled_clis=false

  while IFS= read -r line; do
    if [[ "$line" =~ disabled_clis: ]]; then
      in_disabled_clis=true
      continue
    elif [[ "$line" =~ ^[a-z_]+: ]] && [[ "$in_disabled_clis" == true ]]; then
      break
    fi

    if [[ "$in_disabled_clis" == true && "$line" =~ -\ ([a-z]+) ]]; then
      echo "${match[1]} "
    fi
  done <<< "$config"
}

# Parse Atuin configuration
_zsh_tool_parse_atuin_enabled() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "atuin" "$config")
  echo "$section" | grep '^\s*enabled:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_atuin_import_history() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "atuin" "$config")
  echo "$section" | grep '^\s*import_history:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_atuin_sync_enabled() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "atuin" "$config")
  echo "$section" | grep '^\s*sync_enabled:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_atuin_search_mode() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "atuin" "$config")
  echo "$section" | grep '^\s*search_mode:' | head -1 | awk '{print $2}' | tr -d ' "'
}

_zsh_tool_parse_atuin_filter_mode() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "atuin" "$config")
  echo "$section" | grep '^\s*filter_mode:' | head -1 | awk '{print $2}' | tr -d ' "'
}

_zsh_tool_parse_atuin_inline_height() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "atuin" "$config")
  echo "$section" | grep '^\s*inline_height:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_atuin_style() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "atuin" "$config")
  echo "$section" | grep '^\s*style:' | head -1 | awk '{print $2}' | tr -d ' "'
}

# Generate .zshrc content from template
_zsh_tool_generate_zshrc() {
  local template_file="${ZSH_TOOL_TEMPLATE_DIR}/zshrc.template"

  if [[ ! -f "$template_file" ]]; then
    _zsh_tool_log error "Template file not found: $template_file"
    return 1
  fi

  # Parse configuration
  local plugins=$(_zsh_tool_parse_plugins) || { _zsh_tool_log error "Failed to parse plugins"; return 1; }
  local theme=$(_zsh_tool_parse_theme) || { _zsh_tool_log error "Failed to parse theme"; return 1; }
  local aliases=$(_zsh_tool_parse_aliases) || { _zsh_tool_log error "Failed to parse aliases"; return 1; }
  local exports=$(_zsh_tool_parse_exports) || { _zsh_tool_log error "Failed to parse exports"; return 1; }
  local paths=$(_zsh_tool_parse_paths) || { _zsh_tool_log error "Failed to parse paths"; return 1; }
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Read template and validate
  local content
  if ! content=$(cat "$template_file" 2>/dev/null); then
    _zsh_tool_log error "Failed to read template file: $template_file"
    return 1
  fi

  # Sanitize values to prevent injection (escape special sed characters)
  local safe_timestamp="${timestamp//\//\\/}"
  local safe_theme="${theme//\//\\/}"
  local safe_theme="${safe_theme//&/\\&}"
  local safe_plugins="${plugins//\//\\/}"
  local safe_plugins="${safe_plugins//&/\\&}"

  # Replace placeholders safely using sed with escaped values
  # Note: aliases, exports, paths contain newlines and special chars - use cautiously
  content="${content//\{\{timestamp\}\}/$safe_timestamp}"
  content="${content//\{\{theme\}\}/$safe_theme}"
  content="${content//\{\{plugins\}\}/$safe_plugins}"
  # These are already escaped in parse functions, but multiline-safe
  content="${content//\{\{aliases\}\}/$aliases}"
  content="${content//\{\{exports\}\}/$exports}"
  content="${content//\{\{paths\}\}/$paths}"

  echo "$content"
}

# Install team configuration
_zsh_tool_install_config() {
  _zsh_tool_log info "Installing team configuration..."

  # Generate new .zshrc content
  local new_content=$(_zsh_tool_generate_zshrc)
  if [[ -z "$new_content" ]]; then
    _zsh_tool_log error "Failed to generate .zshrc content"
    return 1
  fi

  local zshrc="${HOME}/.zshrc"
  local temp_zshrc=$(mktemp "${zshrc}.tmp.XXXXXX" 2>/dev/null || echo "${zshrc}.tmp.$$")

  # Preserve existing user configuration if .zshrc exists
  if [[ -f "$zshrc" ]]; then
    _zsh_tool_with_spinner "Preserving user customizations" _zsh_tool_preserve_user_config "$zshrc" || {
      _zsh_tool_log warn "Failed to preserve user config, continuing anyway"
    }
  fi

  # Write new .zshrc with atomic operation and validation
  if ! echo "$new_content" > "$temp_zshrc" 2>/dev/null; then
    _zsh_tool_log error "Failed to write temporary .zshrc file"
    rm -f "$temp_zshrc"
    return 1
  fi

  # Preserve permissions if .zshrc exists
  if [[ -f "$zshrc" ]]; then
    # macOS and Linux compatible permission preservation
    local perms=$(stat -f "%OLp" "$zshrc" 2>/dev/null || stat -c "%a" "$zshrc" 2>/dev/null || echo "644")
    chmod "$perms" "$temp_zshrc" 2>/dev/null || chmod 644 "$temp_zshrc"
  else
    chmod 644 "$temp_zshrc"
  fi

  if ! mv "$temp_zshrc" "$zshrc"; then
    _zsh_tool_log error "Failed to install .zshrc"
    rm -f "$temp_zshrc"
    return 1
  fi

  _zsh_tool_log info "✓ Team configuration installed"

  # Setup custom layer (creates .zshrc.local if doesn't exist)
  _zsh_tool_with_spinner "Setting up personal customization layer" _zsh_tool_setup_custom_layer

  # Update state
  _zsh_tool_update_state "config_installed" "true"

  return 0
}

# Validate file path (prevent path traversal and symlink attacks)
# Usage: _zsh_tool_validate_path <path>
_zsh_tool_validate_path() {
  local path="$1"

  # Check for path traversal attempts
  if [[ "$path" == *".."* ]] || [[ "$path" == *"~"* ]]; then
    _zsh_tool_log ERROR "Invalid path detected: $path"
    return 1
  fi

  # Resolve symlinks and validate real path
  if [[ -e "$path" ]] || [[ -L "$path" ]]; then
    local real_path=$(readlink -f "$path" 2>/dev/null || realpath "$path" 2>/dev/null || echo "$path")
    # Check if resolved path contains traversal patterns
    if [[ "$real_path" == *".."* ]]; then
      _zsh_tool_log ERROR "Symlink resolves to invalid path: $real_path"
      return 1
    fi
    # Validate resolved path is under HOME
    if [[ "$real_path" == /* ]] && [[ "$real_path" != "${HOME}"* ]]; then
      _zsh_tool_log ERROR "Symlink points outside HOME directory: $real_path"
      return 1
    fi
  fi

  # Check for absolute paths outside HOME
  if [[ "$path" == /* ]] && [[ "$path" != "${HOME}"* ]]; then
    _zsh_tool_log WARN "Path outside HOME directory: $path"
  fi

  return 0
}

# Preserve user configuration from existing .zshrc
# Extracts content outside managed markers and merges into .zshrc.local
# Usage: _zsh_tool_preserve_user_config <zshrc_path>
_zsh_tool_preserve_user_config() {
  local zshrc="$1"
  local zshrc_local="${HOME}/.zshrc.local"

  # Validate paths
  _zsh_tool_validate_path "$zshrc" || return 1
  _zsh_tool_validate_path "$zshrc_local" || return 1

  # Check if source file exists
  if [[ ! -f "$zshrc" ]]; then
    _zsh_tool_log DEBUG "No existing .zshrc to preserve"
    return 0
  fi

  # Escape markers for sed (prevent injection)
  local begin_marker=$(printf '%s\n' "$ZSH_TOOL_MANAGED_BEGIN" | sed 's/[[\.*^$()+?{|]/\\&/g')
  local end_marker=$(printf '%s\n' "$ZSH_TOOL_MANAGED_END" | sed 's/[[\.*^$()+?{|]/\\&/g')

  # Extract user content (everything outside managed section)
  local user_content=$(sed -n "/${begin_marker}/,/${end_marker}/!p" "$zshrc" 2>/dev/null || echo "")

  # Skip if no user content
  if [[ -z "$user_content" ]] || [[ "$user_content" =~ ^[[:space:]]*$ ]]; then
    _zsh_tool_log DEBUG "No user content to preserve"
    return 0
  fi

  # Filter out template-generated content (optimized single grep with extended regex)
  # Remove lines that are part of the zsh-tool template
  user_content=$(echo "$user_content" | grep -vE "^(\[\[ -f ~/.zshrc.local \]\] && source|# User customizations|# Load zsh-tool functions|# zsh-tool managed .zshrc template|\[\[ -f ~/.local/bin/zsh-tool/zsh-tool.zsh \]\] && source)")

  # Check again after filtering
  if [[ -z "$user_content" ]] || [[ "$user_content" =~ ^[[:space:]]*$ ]]; then
    _zsh_tool_log DEBUG "No user content to preserve after filtering template lines"
    return 0
  fi

  # If .zshrc.local exists, append to it; otherwise create it
  local temp_local=$(mktemp "${zshrc_local}.tmp.XXXXXX" 2>/dev/null || echo "${zshrc_local}.tmp.$$")

  if [[ -f "$zshrc_local" ]]; then
    _zsh_tool_log INFO "Merging preserved content into existing .zshrc.local"
    {
      cat "$zshrc_local"
      echo ""
      echo "# ===== Migrated from .zshrc on $(date '+%Y-%m-%d %H:%M:%S') ====="
      echo "$user_content"
    } > "$temp_local"
  else
    _zsh_tool_log INFO "Creating .zshrc.local with preserved content"
    echo "$user_content" > "$temp_local"
  fi

  # Atomic write with permission preservation
  if [[ -f "$zshrc_local" ]]; then
    # macOS and Linux compatible permission preservation
    local perms=$(stat -f "%OLp" "$zshrc_local" 2>/dev/null || stat -c "%a" "$zshrc_local" 2>/dev/null || echo "644")
    chmod "$perms" "$temp_local" 2>/dev/null || chmod 644 "$temp_local"
  else
    chmod 644 "$temp_local"
  fi

  if ! mv "$temp_local" "$zshrc_local"; then
    _zsh_tool_log ERROR "Failed to create .zshrc.local during preservation"
    rm -f "$temp_local"
    return 1
  fi

  _zsh_tool_log INFO "User configuration preserved to .zshrc.local"

  # Update state
  _zsh_tool_update_state "custom_layer_migrated" "true"
  _zsh_tool_update_state "migration_timestamp" "\"$(date '+%Y-%m-%d %H:%M:%S')\""

  return 0
}

# Create .zshrc.local template if doesn't exist
_zsh_tool_setup_custom_layer() {
  local zshrc_local="${HOME}/.zshrc.local"

  # Validate path
  _zsh_tool_validate_path "$zshrc_local" || return 1

  if [[ -f "$zshrc_local" ]]; then
    _zsh_tool_log DEBUG ".zshrc.local already exists, skipping creation"
    return 0
  fi

  # Use temp file for atomic write
  local temp_local=$(mktemp "${zshrc_local}.tmp.XXXXXX" 2>/dev/null || echo "${zshrc_local}.tmp.$$")

  cat > "$temp_local" <<'EOF'
# Personal zsh customizations
# This file is NOT managed by zsh-tool

# Your custom aliases
# alias ll='ls -lah'

# Your custom exports
# export MY_VAR="value"

# Your custom functions
# my_function() {
#   echo "custom"
# }
EOF

  # Atomic write
  chmod 644 "$temp_local"
  if ! mv "$temp_local" "$zshrc_local"; then
    _zsh_tool_log ERROR "Failed to create .zshrc.local template"
    rm -f "$temp_local"
    return 1
  fi

  _zsh_tool_log INFO "Created .zshrc.local template for personal customizations"

  # Update state
  _zsh_tool_update_state "custom_layer_setup" "true"

  return 0
}

# Public: Manage customization layer
# Usage: _zsh_tool_config_custom
_zsh_tool_config_custom() {
  local zshrc_local="${HOME}/.zshrc.local"

  echo "Custom Layer Status:"
  echo "===================="

  # Check if .zshrc.local exists
  if [[ -f "$zshrc_local" ]]; then
    echo "✓ Custom layer active: $zshrc_local"

    # Check state
    local state=$(_zsh_tool_load_state)
    if echo "$state" | grep -q '"custom_layer_setup":true'; then
      echo "✓ Setup complete (tracked in state)"
    fi

    if echo "$state" | grep -q '"custom_layer_migrated":true'; then
      local migration_time=$(echo "$state" | sed -n 's/.*"migration_timestamp":"\([^"]*\)".*/\1/p')
      echo "✓ Content migrated from .zshrc on: $migration_time"
    fi

    # Show file size and line count
    local lines=$(wc -l < "$zshrc_local" | tr -d ' ')
    local size=$(du -h "$zshrc_local" | awk '{print $1}')
    echo "  Lines: $lines | Size: $size"
  else
    echo "✗ No custom layer found"
    echo "  Run 'zsh-tool-config edit' to create and edit it"
    return 1
  fi

  return 0
}

# Public: Display configuration sources
# Usage: _zsh_tool_config_show
_zsh_tool_config_show() {
  echo "Zsh Configuration Sources:"
  echo "=========================="

  # Check .zshrc
  local zshrc="${HOME}/.zshrc"
  if [[ -f "$zshrc" ]]; then
    echo "✓ Main config: $zshrc"
    if grep -q "$ZSH_TOOL_MANAGED_BEGIN" "$zshrc"; then
      echo "  └─ Contains zsh-tool managed section"
    fi
  else
    echo "✗ Main config: $zshrc (missing)"
  fi

  # Check .zshrc.local
  local zshrc_local="${HOME}/.zshrc.local"
  if [[ -f "$zshrc_local" ]]; then
    echo "✓ Custom config: $zshrc_local"
  else
    echo "○ Custom config: $zshrc_local (not created yet)"
  fi

  # Check config.yaml
  local config_yaml="${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  if [[ -f "$config_yaml" ]]; then
    echo "✓ Team config: $config_yaml"
  else
    echo "✗ Team config: $config_yaml (missing)"
  fi

  # Check state
  echo ""
  echo "State Information:"
  local state=$(_zsh_tool_load_state)
  if echo "$state" | grep -q '"config_installed":true'; then
    echo "✓ Team configuration installed"
  else
    echo "✗ Team configuration not installed"
  fi

  if echo "$state" | grep -q '"custom_layer_setup":true'; then
    echo "✓ Custom layer initialized"
  fi

  return 0
}

# Public: Open .zshrc.local in editor
# Usage: _zsh_tool_config_edit
_zsh_tool_config_edit() {
  local zshrc_local="${HOME}/.zshrc.local"
  local editor="${EDITOR:-vi}"

  # Validate editor exists and is executable
  if ! command -v "$editor" >/dev/null 2>&1; then
    _zsh_tool_log ERROR "Editor not found: $editor"
    echo "Error: Editor '$editor' not found or not executable"
    echo "Set EDITOR environment variable to a valid editor (e.g., vi, vim, nano)"
    return 1
  fi

  # Create .zshrc.local if doesn't exist
  if [[ ! -f "$zshrc_local" ]]; then
    _zsh_tool_log INFO "Creating .zshrc.local before editing"
    _zsh_tool_setup_custom_layer || return 1
  fi

  _zsh_tool_log INFO "Opening .zshrc.local in $editor"
  $editor "$zshrc_local"

  return 0
}

# Public: Dispatcher for zsh-tool-config commands
# Usage: zsh-tool-config [custom|show|edit]
zsh-tool-config() {
  local subcommand="${1:-show}"

  case "$subcommand" in
    custom)
      _zsh_tool_config_custom
      ;;
    show)
      _zsh_tool_config_show
      ;;
    edit)
      _zsh_tool_config_edit
      ;;
    *)
      echo "Usage: zsh-tool-config [custom|show|edit]"
      echo ""
      echo "Commands:"
      echo "  custom    Show customization layer status"
      echo "  show      Display all configuration sources"
      echo "  edit      Open .zshrc.local in \$EDITOR"
      return 1
      ;;
  esac

  return $?
}
