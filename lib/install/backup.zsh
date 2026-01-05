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

  _zsh_tool_log info "Creating backup (trigger: ${trigger})..."

  # Create backup directory with atomic secure permissions (fixes race condition)
  if ! mkdir -p -m 700 "$backup_dir"; then
    _zsh_tool_log error "Failed to create backup directory"
    return 1
  fi

  # Atomic backup: cleanup on failure
  local backup_failed=0

  # Backup .zshrc if exists
  if [[ -f "${HOME}/.zshrc" ]]; then
    if ! cp -p "${HOME}/.zshrc" "${backup_dir}/.zshrc"; then
      _zsh_tool_log error "Failed to backup .zshrc"
      backup_failed=1
    else
      _zsh_tool_log debug "Backed up .zshrc"
    fi
  fi

  # Backup .zsh_history if exists
  if [[ -f "${HOME}/.zsh_history" ]]; then
    if ! cp -p "${HOME}/.zsh_history" "${backup_dir}/.zsh_history"; then
      _zsh_tool_log error "Failed to backup .zsh_history"
      backup_failed=1
    else
      _zsh_tool_log debug "Backed up .zsh_history"
    fi
  fi

  # Backup Oh My Zsh custom directory if exists
  if [[ -d "${HOME}/.oh-my-zsh/custom" ]]; then
    if ! cp -Rp "${HOME}/.oh-my-zsh/custom" "${backup_dir}/oh-my-zsh-custom"; then
      _zsh_tool_log error "Failed to backup Oh My Zsh custom directory"
      backup_failed=1
    else
      _zsh_tool_log debug "Backed up Oh My Zsh custom directory"
    fi
  fi

  # Cleanup partial backup on failure
  if [[ $backup_failed -eq 1 ]]; then
    _zsh_tool_log warn "Backup partially failed - cleaning up incomplete backup"
    rm -rf "$backup_dir"
    return 1
  fi

  # Get Oh My Zsh version if installed (using subshell for safety)
  local omz_version="none"
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    if cd "${HOME}/.oh-my-zsh" 2>/dev/null; then
      omz_version=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
      cd - >/dev/null
    else
      _zsh_tool_log warn "Could not access Oh My Zsh directory for version detection"
      omz_version="unknown"
    fi
  fi

  # Generate manifest with validation
  if ! _zsh_tool_generate_manifest "$backup_dir" "$trigger" "$omz_version"; then
    _zsh_tool_log error "Failed to generate manifest - cleaning up backup"
    rm -rf "$backup_dir"
    return 1
  fi

  # Update state using jq-based approach
  local jq_installed=$(command -v jq >/dev/null 2>&1 && echo "true" || echo "false")
  if [[ "$jq_installed" == "true" ]]; then
    local state=$(_zsh_tool_load_state)
    local updated_state=$(echo "$state" | jq --arg backup "$timestamp" '. + {last_backup: $backup}')
    _zsh_tool_save_state "$updated_state"
  else
    # Fallback for systems without jq
    _zsh_tool_update_state "last_backup" "\"${timestamp}\""
  fi

  _zsh_tool_log info "✓ Backup created: ${timestamp}"

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

  # Validate backup directory exists
  if [[ ! -d "$backup_dir" ]]; then
    _zsh_tool_log error "Backup directory does not exist: $backup_dir"
    return 1
  fi

  # Read tool version from VERSION file or fallback
  # PROJECT_ROOT may not be set, so try script's parent directory
  local tool_version="1.0.0"
  local script_dir="${0:A:h}"
  local version_file="${script_dir}/../../VERSION"
  if [[ -n "${PROJECT_ROOT:-}" && -f "${PROJECT_ROOT}/VERSION" ]]; then
    tool_version=$(cat "${PROJECT_ROOT}/VERSION" 2>/dev/null | tr -d '\n' || echo "1.0.0")
  elif [[ -f "$version_file" ]]; then
    tool_version=$(cat "$version_file" 2>/dev/null | tr -d '\n' || echo "1.0.0")
  fi

  # Collect and sort files for deterministic output
  local -a files_array
  setopt local_options null_glob dot_glob
  for file in "$backup_dir"/*; do
    local fname=$(basename "$file")
    # Skip . and .. and manifest.json itself
    [[ "$fname" == "." || "$fname" == ".." || "$fname" == "manifest.json" ]] && continue
    [[ -f "$file" || -d "$file" ]] && files_array+=("$fname")
  done

  # Sort files for deterministic output
  files_array=("${(@o)files_array}")

  # Build JSON files array with proper escaping
  local files_list=""
  for fname in "${files_array[@]}"; do
    # Escape backslashes first, then double quotes for valid JSON
    local escaped_fname="${fname//\\/\\\\}"
    escaped_fname="${escaped_fname//\"/\\\"}"
    files_list="${files_list}\"${escaped_fname}\","
  done
  files_list=${files_list%,}  # Remove trailing comma

  # Write manifest and validate success
  if ! cat > "$manifest_file" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "trigger": "${trigger}",
  "files": [${files_list}],
  "omz_version": "${omz_version}",
  "tool_version": "${tool_version}"
}
EOF
  then
    _zsh_tool_log error "Failed to write manifest file: $manifest_file"
    return 1
  fi

  # Validate manifest was written successfully
  if [[ ! -f "$manifest_file" ]]; then
    _zsh_tool_log error "Manifest file not found after write: $manifest_file"
    return 1
  fi

  _zsh_tool_log debug "Generated manifest: $manifest_file"
  return 0
}

# Prune old backups (keep last N) - using zsh globs instead of ls
_zsh_tool_prune_old_backups() {
  setopt local_options null_glob
  local -a backup_dirs
  # Get directories sorted by modification time (Om = oldest first for correct pruning)
  # om sorts newest first, Om sorts oldest first
  backup_dirs=("${ZSH_TOOL_BACKUP_DIR}"/*(N/Om))

  local backup_count=${#backup_dirs[@]}

  if [[ $backup_count -gt $ZSH_TOOL_BACKUP_RETENTION ]]; then
    local to_delete=$((backup_count - ZSH_TOOL_BACKUP_RETENTION))
    _zsh_tool_log info "Pruning $to_delete old backup(s)..."

    # Delete oldest backups (first N in the sorted array)
    for ((i=1; i<=to_delete; i++)); do
      local dir="${backup_dirs[$i]}"
      rm -rf "$dir"
      _zsh_tool_log debug "Deleted old backup: $(basename "$dir")"
    done
  fi
}

# Backup single file
# Usage: _zsh_tool_backup_file <source> <dest>
_zsh_tool_backup_file() {
  local source="$1"
  local dest="$2"

  if [[ -f "$source" ]]; then
    if ! cp -p "$source" "$dest"; then
      _zsh_tool_log error "Failed to backup file: $source"
      return 1
    fi
    return 0
  else
    _zsh_tool_log warn "File not found: $source"
    return 1
  fi
}

# Backup directory
# Usage: _zsh_tool_backup_directory <source> <dest>
_zsh_tool_backup_directory() {
  local source="$1"
  local dest="$2"

  if [[ -d "$source" ]]; then
    if ! cp -Rp "$source" "$dest"; then
      _zsh_tool_log error "Failed to backup directory: $source"
      return 1
    fi
    return 0
  else
    _zsh_tool_log warn "Directory not found: $source"
    return 1
  fi
}
