#!/usr/bin/env zsh
# Story 1.3: Install Team-Standard Configuration
# Generate and install .zshrc from team configuration

ZSH_TOOL_TEMPLATE_DIR="${ZSH_TOOL_CONFIG_DIR}/templates"
ZSH_TOOL_MANAGED_BEGIN="# ===== ZSH-TOOL MANAGED SECTION BEGIN ====="
ZSH_TOOL_MANAGED_END="# ===== ZSH-TOOL MANAGED SECTION END ====="

# Config cache (reduces I/O for multiple parse calls)
typeset -g _ZSH_TOOL_CONFIG_CACHE=""
typeset -g _ZSH_TOOL_CONFIG_CACHE_FILE=""
typeset -g _ZSH_TOOL_CONFIG_CACHE_MTIME=""

# Load configuration from YAML (simple parser with caching)
_zsh_tool_load_config() {
  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"

  # Validate file exists
  if [[ ! -f "$config_file" ]]; then
    _zsh_tool_log error "Configuration file not found: $config_file"
    return 1
  fi

  # Check file modification time for cache validation
  local current_mtime
  current_mtime=$(stat -f "%m" "$config_file" 2>/dev/null || stat -c "%Y" "$config_file" 2>/dev/null || echo "0")

  # Return cached config if same file AND same modification time
  if [[ -n "$_ZSH_TOOL_CONFIG_CACHE" && "$_ZSH_TOOL_CONFIG_CACHE_FILE" == "$config_file" && "$_ZSH_TOOL_CONFIG_CACHE_MTIME" == "$current_mtime" ]]; then
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

  # Cache for subsequent calls (includes mtime for invalidation)
  _ZSH_TOOL_CONFIG_CACHE="$config_content"
  _ZSH_TOOL_CONFIG_CACHE_FILE="$config_file"
  _ZSH_TOOL_CONFIG_CACHE_MTIME="$current_mtime"

  echo "$config_content"
  return 0
}

# Clear config cache (call after config changes)
_zsh_tool_clear_config_cache() {
  _ZSH_TOOL_CONFIG_CACHE=""
  _ZSH_TOOL_CONFIG_CACHE_FILE=""
  _ZSH_TOOL_CONFIG_CACHE_MTIME=""
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
# Handles nested structure: paths.prepend: [list of paths]
_zsh_tool_parse_paths() {
  local config=$(_zsh_tool_load_config) || return 1
  local in_paths=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^paths: ]]; then
      in_paths=true
      continue
    # Only break on non-indented top-level keys (not prepend/append which are nested)
    elif [[ "$line" =~ ^[a-z]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]] && [[ "$in_paths" == true ]]; then
      break
    fi

    if [[ "$in_paths" == true && "$line" =~ -\ \"(.+)\" ]]; then
      # Safely access match array
      if [[ -n "${match[1]:-}" ]]; then
        local pathval="${match[1]}"
        # Expand only safe shell variables ($HOME, $USER) - no arbitrary eval
        pathval="${pathval//\$HOME/$HOME}"
        pathval="${pathval//\$USER/$USER}"
        pathval="${pathval//\~/$HOME}"
        echo "export PATH=\"${pathval}:\$PATH\""
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

# Parse Kiro CLI configuration (formerly Amazon Q)
_zsh_tool_parse_kiro_enabled() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "kiro_cli" "$config")
  echo "$section" | grep '^\s*enabled:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_kiro_lazy_loading() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "kiro_cli" "$config")
  echo "$section" | grep '^\s*lazy_loading:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_kiro_atuin_compatibility() {
  local config=$(_zsh_tool_load_config)
  local section=$(_zsh_tool_extract_yaml_section "kiro_cli" "$config")
  echo "$section" | grep '^\s*atuin_compatibility:' | head -1 | awk '{print $2}' | tr -d ' '
}

_zsh_tool_parse_kiro_disabled_clis() {
  local config=$(_zsh_tool_load_config) || return 1
  local section=$(_zsh_tool_extract_yaml_section "kiro_cli" "$config")
  local in_disabled_clis=false

  while IFS= read -r line; do
    if [[ "$line" =~ disabled_clis: ]]; then
      in_disabled_clis=true
      continue
    elif [[ "$line" =~ ^[a-z_]+: ]] && [[ "$in_disabled_clis" == true ]]; then
      break
    fi

    if [[ "$in_disabled_clis" == true && "$line" =~ -\ ([a-z]+) ]]; then
      # Safely access match array
      [[ -n "${match[1]:-}" ]] && echo "${match[1]} "
    fi
  done <<< "$section"
}

# DEPRECATED: Amazon Q parsing functions (kept for backward compatibility during migration)
_zsh_tool_parse_amazon_q_enabled() {
  _zsh_tool_parse_kiro_enabled
}

_zsh_tool_parse_amazon_q_lazy_loading() {
  _zsh_tool_parse_kiro_lazy_loading
}

_zsh_tool_parse_amazon_q_atuin_compatibility() {
  _zsh_tool_parse_kiro_atuin_compatibility
}

_zsh_tool_parse_amazon_q_disabled_clis() {
  _zsh_tool_parse_kiro_disabled_clis
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

# HIGH-4: Remove duplicate source lines from content
# Ensures only one instance of each source line exists
# Usage: _zsh_tool_dedupe_source_lines <content>
_zsh_tool_dedupe_source_lines() {
  local content="$1"
  local seen_sources=""
  local result=""
  local line=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if this is a source line for .zshrc.local (various formats)
    # Use simple string matching for reliability across zsh versions
    local is_source_local=false
    if [[ "$line" == *"source"*".zshrc.local"* ]] || \
       [[ "$line" == *"[["*".zshrc.local"*"]]"*"source"* ]]; then
      is_source_local=true
    fi

    if [[ "$is_source_local" == true ]]; then
      # Check if we've seen a source for .zshrc.local before
      if [[ "$seen_sources" == *"zshrc.local"* ]]; then
        # Skip duplicate source line
        continue
      fi
      seen_sources="${seen_sources}zshrc.local:"
    fi

    # Build result with preserved newlines
    if [[ -n "$result" ]]; then
      result="${result}
${line}"
    else
      result="$line"
    fi
  done <<< "$content"

  echo "$result"
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

  # HIGH-4: Remove any duplicate source lines for .zshrc.local
  content=$(_zsh_tool_dedupe_source_lines "$content")

  echo "$content"
}

# Install team configuration
_zsh_tool_install_config() {
  _zsh_tool_log info "Installing team configuration..."

  # Clear config cache to ensure fresh data is used
  _zsh_tool_clear_config_cache

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
  # MEDIUM-4: Enhanced permission handling with explicit fallback logging
  if [[ -f "$zshrc" ]]; then
    # macOS and Linux compatible permission preservation
    local perms=$(stat -f "%OLp" "$zshrc" 2>/dev/null || stat -c "%a" "$zshrc" 2>/dev/null || echo "")
    if [[ -n "$perms" ]]; then
      if ! chmod "$perms" "$temp_zshrc" 2>/dev/null; then
        _zsh_tool_log DEBUG "Could not preserve .zshrc permissions ($perms), using default 644"
        chmod 644 "$temp_zshrc"
      fi
    else
      _zsh_tool_log DEBUG "Could not read .zshrc permissions, using default 644"
      chmod 644 "$temp_zshrc"
    fi
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
    _zsh_tool_log error "Invalid path detected: $path"
    return 1
  fi

  # Resolve symlinks and validate real path
  if [[ -e "$path" ]] || [[ -L "$path" ]]; then
    # HIGH-5: Improved symlink resolution with proper macOS support
    # Try multiple methods: readlink -f (Linux), greadlink -f (macOS with coreutils),
    # realpath, or manual resolution as last resort
    local real_path=""
    if real_path=$(readlink -f "$path" 2>/dev/null); then
      : # success
    elif real_path=$(greadlink -f "$path" 2>/dev/null); then
      : # success with GNU coreutils on macOS
    elif real_path=$(realpath "$path" 2>/dev/null); then
      : # success with realpath
    else
      # Manual resolution: follow symlink chain (up to 10 levels to prevent infinite loops)
      real_path="$path"
      local count=0
      while [[ -L "$real_path" && $count -lt 10 ]]; do
        local link_target=$(readlink "$real_path" 2>/dev/null)
        if [[ -z "$link_target" ]]; then
          break
        fi
        # Handle relative symlinks
        if [[ "$link_target" != /* ]]; then
          link_target="$(dirname "$real_path")/$link_target"
        fi
        real_path="$link_target"
        ((count++))
      done
      # If we hit the limit, treat as suspicious
      if [[ $count -ge 10 ]]; then
        _zsh_tool_log error "Symlink chain too deep (possible loop): $path"
        return 1
      fi
    fi

    # Check if resolved path contains traversal patterns
    if [[ "$real_path" == *".."* ]]; then
      _zsh_tool_log error "Symlink resolves to invalid path: $real_path"
      return 1
    fi
    # Validate resolved path is under HOME
    if [[ "$real_path" == /* ]] && [[ "$real_path" != "${HOME}"* ]]; then
      _zsh_tool_log error "Symlink points outside HOME directory: $real_path"
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

  # HIGH-3: Create backup of .zshrc.local before any modification (rollback mechanism)
  local backup_file=""
  if [[ -f "$zshrc_local" ]]; then
    backup_file="${zshrc_local}.backup.$(date '+%Y%m%d_%H%M%S')"
    if ! cp -p "$zshrc_local" "$backup_file" 2>/dev/null; then
      _zsh_tool_log WARN "Failed to create backup of .zshrc.local, proceeding anyway"
      backup_file=""
    else
      _zsh_tool_log DEBUG "Created backup: $backup_file"
    fi
  fi

  # Escape markers for sed (prevent injection)
  # HIGH-6: Complete sed pattern escaping - escape [], /, and & characters
  local begin_marker=$(printf '%s\n' "$ZSH_TOOL_MANAGED_BEGIN" | sed 's/[][\\.*^$()+?{|/&]/\\&/g')
  local end_marker=$(printf '%s\n' "$ZSH_TOOL_MANAGED_END" | sed 's/[][\\.*^$()+?{|/&]/\\&/g')

  # MEDIUM-3: Validate markers exist and are properly paired before extraction
  # This prevents brittle behavior with malformed markers
  local has_begin has_end
  has_begin=$(grep -cF "$ZSH_TOOL_MANAGED_BEGIN" "$zshrc" 2>/dev/null) || has_begin=0
  has_end=$(grep -cF "$ZSH_TOOL_MANAGED_END" "$zshrc" 2>/dev/null) || has_end=0

  local user_content=""
  if [[ "$has_begin" -eq 1 && "$has_end" -eq 1 ]]; then
    # Both markers found exactly once - safe to extract
    user_content=$(sed -n "/${begin_marker}/,/${end_marker}/!p" "$zshrc" 2>/dev/null || echo "")
  elif [[ "$has_begin" -eq 0 && "$has_end" -eq 0 ]]; then
    # No markers - entire file is user content
    user_content=$(cat "$zshrc" 2>/dev/null || echo "")
    _zsh_tool_log DEBUG "No managed markers found - treating entire file as user content"
  else
    # Malformed markers (missing one, or duplicates)
    _zsh_tool_log WARN "Malformed managed section markers (begin=$has_begin, end=$has_end) - skipping extraction to avoid data loss"
    return 0
  fi

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
  # MEDIUM-4: Enhanced permission handling with explicit fallback logging
  if [[ -f "$zshrc_local" ]]; then
    # macOS and Linux compatible permission preservation
    local perms=$(stat -f "%OLp" "$zshrc_local" 2>/dev/null || stat -c "%a" "$zshrc_local" 2>/dev/null || echo "")
    if [[ -n "$perms" ]]; then
      if ! chmod "$perms" "$temp_local" 2>/dev/null; then
        _zsh_tool_log DEBUG "Could not preserve permissions ($perms), using default 644"
        chmod 644 "$temp_local"
      fi
    else
      _zsh_tool_log DEBUG "Could not read original permissions, using default 644"
      chmod 644 "$temp_local"
    fi
  else
    chmod 644 "$temp_local"
  fi

  if ! mv "$temp_local" "$zshrc_local"; then
    _zsh_tool_log error "Failed to create .zshrc.local during preservation"
    rm -f "$temp_local"
    # HIGH-3: Rollback - restore backup on failure
    if [[ -n "$backup_file" && -f "$backup_file" ]]; then
      if mv "$backup_file" "$zshrc_local" 2>/dev/null; then
        _zsh_tool_log INFO "Rolled back to backup: $backup_file"
      else
        _zsh_tool_log WARN "Failed to rollback, backup remains at: $backup_file"
      fi
    fi
    return 1
  fi

  _zsh_tool_log INFO "User configuration preserved to .zshrc.local"
  # HIGH-3: On success, keep backup for safety but log its location
  if [[ -n "$backup_file" && -f "$backup_file" ]]; then
    _zsh_tool_log INFO "Backup preserved at: $backup_file"
  fi

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
    _zsh_tool_log error "Failed to create .zshrc.local template"
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

  # Sanitize editor: only allow alphanumeric, hyphens, underscores, forward slashes, and dots
  # This prevents command injection via shell metacharacters in EDITOR
  if [[ ! "$editor" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
    _zsh_tool_log WARN "EDITOR contains invalid characters ('$editor'), falling back to vi"
    editor="vi"
  fi

  # Validate editor exists and is executable
  if ! command -v "$editor" >/dev/null 2>&1; then
    _zsh_tool_log WARN "Editor '$editor' not found, falling back to vi"
    editor="vi"
    # Final check for vi
    if ! command -v "$editor" >/dev/null 2>&1; then
      _zsh_tool_log error "No valid editor found (tried '$EDITOR' and 'vi')"
      echo "Error: No valid editor found"
      echo "Set EDITOR environment variable to a valid editor (e.g., vi, vim, nano)"
      return 1
    fi
  fi

  # Create .zshrc.local if doesn't exist
  if [[ ! -f "$zshrc_local" ]]; then
    _zsh_tool_log INFO "Creating .zshrc.local before editing"
    _zsh_tool_setup_custom_layer || return 1
  fi

  _zsh_tool_log INFO "Opening .zshrc.local in $editor"
  "$editor" "$zshrc_local"

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
