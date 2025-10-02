#!/usr/bin/env zsh
# Story 2.3: Configuration Backup Management
# Manage backups - create, list, prune, and remote sync

# List all available backups
_zsh_tool_list_backups() {
  if [[ ! -d "$ZSH_TOOL_BACKUP_DIR" ]]; then
    _zsh_tool_log WARN "No backups found"
    return 1
  fi

  local backups=($(ls -1t "$ZSH_TOOL_BACKUP_DIR" 2>/dev/null))

  if [[ ${#backups[@]} -eq 0 ]]; then
    echo "No backups available"
    return 1
  fi

  echo ""
  echo "Available backups:"
  echo ""

  local index=1
  for backup in "${backups[@]}"; do
    local manifest="${ZSH_TOOL_BACKUP_DIR}/${backup}/manifest.json"
    local trigger="unknown"
    local timestamp="unknown"

    if [[ -f "$manifest" ]]; then
      trigger=$(grep -o '"trigger":"[^"]*"' "$manifest" | cut -d'"' -f4)
      timestamp=$(grep -o '"timestamp":"[^"]*"' "$manifest" | cut -d'"' -f4)
    fi

    # Calculate relative time
    local backup_date=$(echo "$backup" | cut -d'-' -f1-3)
    local backup_time=$(echo "$backup" | cut -d'-' -f4)
    local relative_time=$(_zsh_tool_relative_time "$backup_date" "$backup_time")

    echo "${index}. ${backup} (${trigger}) - ${relative_time}"
    ((index++))
  done

  echo ""
  echo "Use 'zsh-tool-restore apply <number>' to restore"
  echo ""
}

# Calculate relative time from backup timestamp
_zsh_tool_relative_time() {
  local backup_date=$1  # YYYY-MM-DD
  local backup_time=$2  # HHMMSS

  # Convert to timestamp (macOS compatible)
  local backup_timestamp=$(date -j -f "%Y-%m-%d-%H%M%S" "${backup_date}-${backup_time}" +%s 2>/dev/null || echo "0")
  local current_timestamp=$(date +%s)

  if [[ "$backup_timestamp" == "0" ]]; then
    echo "unknown time"
    return
  fi

  local diff=$((current_timestamp - backup_timestamp))

  # Calculate time units
  local minutes=$((diff / 60))
  local hours=$((diff / 3600))
  local days=$((diff / 86400))

  if [[ $minutes -lt 60 ]]; then
    echo "${minutes} minutes ago"
  elif [[ $hours -lt 24 ]]; then
    echo "${hours} hours ago"
  else
    echo "${days} days ago"
  fi
}

# Create manual backup
_zsh_tool_create_manual_backup() {
  local timestamp=$(date +%Y-%m-%d-%H%M%S)
  _zsh_tool_log INFO "Creating manual backup..."

  if _zsh_tool_create_backup "manual-${timestamp}"; then
    _zsh_tool_log INFO "✓ Backup created: ${timestamp}"
    return 0
  else
    _zsh_tool_log ERROR "Failed to create backup"
    return 1
  fi
}

# Backup to remote git repository
_zsh_tool_backup_to_remote() {
  local remote_url=$(_zsh_tool_load_state | grep -o '"remote_url":"[^"]*"' | cut -d'"' -f4)

  if [[ -z "$remote_url" ]]; then
    _zsh_tool_log WARN "No remote backup URL configured"
    echo ""
    echo "To enable remote backups, configure a git remote:"
    echo "  cd ~/.config/zsh-tool/backups"
    echo "  git init"
    echo "  git remote add origin <your-remote-url>"
    echo "  git push -u origin main"
    echo ""
    return 1
  fi

  _zsh_tool_log INFO "Pushing backup to remote: $remote_url"

  cd "$ZSH_TOOL_BACKUP_DIR"

  # Check if git repo
  if [[ ! -d ".git" ]]; then
    git init 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    git remote add origin "$remote_url" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  fi

  # Add and commit backups
  git add . 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  git commit -m "Backup: $(date +%Y-%m-%d\ %H:%M:%S)" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null

  # Push to remote
  git push origin main 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local push_status=${PIPESTATUS[1]}

  cd - >/dev/null

  if [[ $push_status -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Backup pushed to remote"
    return 0
  else
    _zsh_tool_log WARN "Failed to push backup to remote"
    return 1
  fi
}

# Fetch backups from remote
_zsh_tool_fetch_remote_backups() {
  cd "$ZSH_TOOL_BACKUP_DIR"

  if [[ ! -d ".git" ]]; then
    _zsh_tool_log WARN "Backups directory is not a git repository"
    cd - >/dev/null
    return 1
  fi

  _zsh_tool_log INFO "Fetching backups from remote..."

  git pull origin main 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  local pull_status=${PIPESTATUS[1]}

  cd - >/dev/null

  if [[ $pull_status -eq 0 ]]; then
    _zsh_tool_log INFO "✓ Remote backups fetched"
    return 0
  else
    _zsh_tool_log WARN "Failed to fetch remote backups"
    return 1
  fi
}

# Configure remote backup URL
_zsh_tool_configure_remote_backup() {
  local remote_url=$1

  if [[ -z "$remote_url" ]]; then
    echo -n "Enter remote backup URL: "
    read remote_url
  fi

  if [[ -z "$remote_url" ]]; then
    _zsh_tool_log ERROR "Remote URL cannot be empty"
    return 1
  fi

  # Update state
  _zsh_tool_update_state "backups.remote_enabled" "true"
  _zsh_tool_update_state "backups.remote_url" "\"${remote_url}\""

  _zsh_tool_log INFO "✓ Remote backup configured: $remote_url"
  return 0
}
