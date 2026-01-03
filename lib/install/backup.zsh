#!/usr/bin/env zsh
# Story 1.2: Backup Existing Configuration
# Create timestamped backups before making changes

ZSH_TOOL_BACKUP_DIR="${ZSH_TOOL_CONFIG_DIR}/backups"
ZSH_TOOL_BACKUP_RETENTION=10

# Create timestamped backup
# Usage: _zsh_tool_create_backup [trigger]
_zsh_tool_create_backup() {
  local trigger="${1:-manual}"
  local timestamp=$(date +%Y-%m-%d-%H%M%S)
  local backup_dir="${ZSH_TOOL_BACKUP_DIR}/${timestamp}"

  _zsh_tool_log INFO "Creating backup (trigger: ${trigger})..."

  # Create backup directory with secure permissions (0700)
  mkdir -p "$backup_dir" && chmod 700 "$backup_dir" || {
    _zsh_tool_log ERROR "Failed to create backup directory"
    return 1
  }

  # Backup .zshrc if exists
  if [[ -f "${HOME}/.zshrc" ]]; then
    cp "${HOME}/.zshrc" "${backup_dir}/.zshrc"
    _zsh_tool_log DEBUG "Backed up .zshrc"
  fi

  # Backup .zsh_history if exists
  if [[ -f "${HOME}/.zsh_history" ]]; then
    cp "${HOME}/.zsh_history" "${backup_dir}/.zsh_history"
    _zsh_tool_log DEBUG "Backed up .zsh_history"
  fi

  # Backup Oh My Zsh custom directory if exists
  if [[ -d "${HOME}/.oh-my-zsh/custom" ]]; then
    cp -R "${HOME}/.oh-my-zsh/custom" "${backup_dir}/oh-my-zsh-custom"
    _zsh_tool_log DEBUG "Backed up Oh My Zsh custom directory"
  fi

  # Get Oh My Zsh version if installed (using subshell for safety)
  local omz_version="none"
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    omz_version=$(cd "${HOME}/.oh-my-zsh" 2>/dev/null && git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  fi

  # Generate manifest
  _zsh_tool_generate_manifest "$backup_dir" "$trigger" "$omz_version"

  # Update state
  _zsh_tool_update_state "last_backup" "\"${timestamp}\""

  _zsh_tool_log INFO "✓ Backup created: ${timestamp}"

  # Prune old backups
  _zsh_tool_prune_old_backups

  return 0
}

# Generate backup manifest
_zsh_tool_generate_manifest() {
  local backup_dir="$1"
  local trigger="$2"
  local omz_version="$3"
  local manifest_file="${backup_dir}/manifest.json"

  local files_list=""
  # Use nullglob and dotglob to handle empty directories and hidden files
  setopt local_options null_glob dot_glob
  for file in "$backup_dir"/*; do
    local fname=$(basename "$file")
    # Skip . and ..
    [[ "$fname" == "." || "$fname" == ".." ]] && continue
    [[ -f "$file" || -d "$file" ]] && files_list="${files_list}\"${fname}\","
  done
  files_list=${files_list%,}  # Remove trailing comma

  cat > "$manifest_file" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "trigger": "${trigger}",
  "files": [${files_list}],
  "omz_version": "${omz_version}",
  "tool_version": "1.0.0"
}
EOF

  _zsh_tool_log DEBUG "Generated manifest: $manifest_file"
}

# Prune old backups (keep last N)
_zsh_tool_prune_old_backups() {
  local backup_count=$(ls -1d "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | wc -l | tr -d ' ')

  if [[ $backup_count -gt $ZSH_TOOL_BACKUP_RETENTION ]]; then
    local to_delete=$((backup_count - ZSH_TOOL_BACKUP_RETENTION))
    _zsh_tool_log INFO "Pruning $to_delete old backup(s)..."

    ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ | tail -n "$to_delete" | while IFS= read -r dir; do
      rm -rf "$dir"
      _zsh_tool_log DEBUG "Deleted old backup: $(basename "$dir")"
    done
  fi
}

# Backup single file
# Usage: _zsh_tool_backup_file <source> <dest>
_zsh_tool_backup_file() {
  local source="$1"
  local dest="$2"

  if [[ -f "$source" ]]; then
    cp "$source" "$dest"
    return 0
  else
    _zsh_tool_log WARN "File not found: $source"
    return 1
  fi
}

# Backup directory
# Usage: _zsh_tool_backup_directory <source> <dest>
_zsh_tool_backup_directory() {
  local source="$1"
  local dest="$2"

  if [[ -d "$source" ]]; then
    cp -R "$source" "$dest"
    return 0
  else
    _zsh_tool_log WARN "Directory not found: $source"
    return 1
  fi
}
