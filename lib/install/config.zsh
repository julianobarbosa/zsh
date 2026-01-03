#!/usr/bin/env zsh
# Story 1.3: Install Team-Standard Configuration
# Generate and install .zshrc from team configuration

ZSH_TOOL_TEMPLATE_DIR="${ZSH_TOOL_CONFIG_DIR}/templates"
ZSH_TOOL_MANAGED_BEGIN="# ===== ZSH-TOOL MANAGED SECTION BEGIN ====="
ZSH_TOOL_MANAGED_END="# ===== ZSH-TOOL MANAGED SECTION END ====="

# Load configuration from YAML (simple parser for our needs)
_zsh_tool_load_config() {
  local config_file="${ZSH_TOOL_CONFIG_DIR}/config.yaml"

  if [[ ! -f "$config_file" ]]; then
    _zsh_tool_log ERROR "Configuration file not found: $config_file"
    return 1
  fi

  cat "$config_file"
}

# Parse plugins from config
_zsh_tool_parse_plugins() {
  local config=$(_zsh_tool_load_config)
  local in_plugins=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^plugins: ]]; then
      in_plugins=true
      continue
    elif [[ "$line" =~ ^[a-z]+: ]] && [[ "$in_plugins" == true ]]; then
      break
    fi

    if [[ "$in_plugins" == true && "$line" =~ -\ ([a-zA-Z0-9_-]+) ]]; then
      echo -n "${match[1]} "
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
  local config=$(_zsh_tool_load_config)
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
        name="${match[1]}"
      elif [[ "$line" =~ command:\ \"(.+)\" ]]; then
        echo "alias ${name}=\"${match[1]}\""
      fi
    fi
  done <<< "$config"
}

# Parse exports from config
_zsh_tool_parse_exports() {
  local config=$(_zsh_tool_load_config)
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
        name="${match[1]}"
      elif [[ "$line" =~ value:\ \"(.+)\" ]]; then
        echo "export ${name}=\"${match[1]}\""
      fi
    fi
  done <<< "$config"
}

# Parse PATH modifications from config
_zsh_tool_parse_paths() {
  local config=$(_zsh_tool_load_config)
  local in_paths=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^paths: ]]; then
      in_paths=true
      continue
    elif [[ "$line" =~ ^[a-z]+: ]] && [[ "$in_paths" == true ]]; then
      break
    fi

    if [[ "$in_paths" == true && "$line" =~ -\ \"(.+)\" ]]; then
      local path="${match[1]}"
      # Expand only safe shell variables ($HOME, $USER) - no arbitrary eval
      path="${path//\$HOME/$HOME}"
      path="${path//\$USER/$USER}"
      path="${path//\~/$HOME}"
      echo "export PATH=\"${path}:\$PATH\""
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
    _zsh_tool_log ERROR "Template file not found: $template_file"
    return 1
  fi

  # Parse configuration
  local plugins=$(_zsh_tool_parse_plugins)
  local theme=$(_zsh_tool_parse_theme)
  local aliases=$(_zsh_tool_parse_aliases)
  local exports=$(_zsh_tool_parse_exports)
  local paths=$(_zsh_tool_parse_paths)
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Read template and replace placeholders
  local content=$(cat "$template_file")
  content="${content//\{\{timestamp\}\}/$timestamp}"
  content="${content//\{\{theme\}\}/$theme}"
  content="${content//\{\{plugins\}\}/$plugins}"
  content="${content//\{\{aliases\}\}/$aliases}"
  content="${content//\{\{exports\}\}/$exports}"
  content="${content//\{\{paths\}\}/$paths}"

  echo "$content"
}

# Install team configuration
_zsh_tool_install_config() {
  _zsh_tool_log INFO "Installing team configuration..."

  # Generate new .zshrc content
  local new_content=$(_zsh_tool_generate_zshrc)
  if [[ -z "$new_content" ]]; then
    _zsh_tool_log ERROR "Failed to generate .zshrc content"
    return 1
  fi

  local zshrc="${HOME}/.zshrc"
  local temp_zshrc="${zshrc}.tmp"

  # If .zshrc exists, preserve non-managed sections
  if [[ -f "$zshrc" ]]; then
    # Extract user content (everything outside managed section)
    local user_content=$(sed -n "/${ZSH_TOOL_MANAGED_BEGIN}/,/${ZSH_TOOL_MANAGED_END}/!p" "$zshrc" 2>/dev/null || echo "")

    # If user content exists and .zshrc.local doesn't exist, save it
    if [[ -n "$user_content" && ! -f "${HOME}/.zshrc.local" ]]; then
      _zsh_tool_log INFO "Migrating existing configuration to .zshrc.local"
      echo "$user_content" > "${HOME}/.zshrc.local"
    fi
  fi

  # Write new .zshrc
  echo "$new_content" > "$temp_zshrc"
  mv "$temp_zshrc" "$zshrc"

  _zsh_tool_log INFO "✓ Team configuration installed"

  # Update state
  _zsh_tool_update_state "config_installed" "true"

  return 0
}

# Create .zshrc.local template if doesn't exist
_zsh_tool_setup_custom_layer() {
  local zshrc_local="${HOME}/.zshrc.local"

  if [[ ! -f "$zshrc_local" ]]; then
    cat > "$zshrc_local" <<'EOF'
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
    _zsh_tool_log INFO "Created .zshrc.local template for personal customizations"
  fi
}
