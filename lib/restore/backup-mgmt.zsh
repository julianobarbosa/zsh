#!/usr/bin/env zsh
# Story 2.3: Configuration Backup Management
# Manage backups - create, list, prune, and remote sync

# Get current backup count
# Returns the number of backup directories
_zsh_tool_get_backup_count() {
  if [[ ! -d "$ZSH_TOOL_BACKUP_DIR" ]]; then
    echo "0"
    return 0
  fi

  setopt local_options null_glob
  local -a backup_dirs
  backup_dirs=("${ZSH_TOOL_BACKUP_DIR}"/*(N/))
  echo "${#backup_dirs[@]}"
}

# Get remote backup status
# Returns: "enabled", "disabled", or "not_configured"
_zsh_tool_get_remote_status() {
  local state=$(_zsh_tool_load_state)
  local remote_enabled=""
  local remote_url=""

  # Use jq if available for reliable JSON parsing
  if command -v jq &>/dev/null; then
    remote_enabled=$(echo "$state" | jq -r '.backups.remote_enabled // empty' 2>/dev/null)
    remote_url=$(echo "$state" | jq -r '.backups.remote_url // empty' 2>/dev/null)
  else
    # Fallback: More robust parsing using awk for nested JSON
    # This handles nested objects correctly by tracking brace depth
    remote_enabled=$(echo "$state" | awk -F'"remote_enabled"[[:space:]]*:[[:space:]]*' '
      NF > 1 {
        val = $2
        gsub(/^[[:space:]]*/, "", val)
        if (match(val, /^(true|false)/)) {
          print substr(val, RSTART, RLENGTH)
        }
      }
    ')
    remote_url=$(echo "$state" | awk -F'"remote_url"[[:space:]]*:[[:space:]]*"' '
      NF > 1 {
        val = $2
        if (match(val, /[^"]*/)) {
          print substr(val, RSTART, RLENGTH)
        }
      }
    ')
  fi

  if [[ -z "$remote_url" ]]; then
    echo "not_configured"
  elif [[ "$remote_enabled" == "true" ]]; then
    echo "enabled"
  else
    echo "disabled"
  fi
}

# Get backup size in human-readable format
# Usage: _zsh_tool_get_backup_size <backup_path>
_zsh_tool_get_backup_size() {
  local backup_path="$1"

  if [[ ! -d "$backup_path" ]]; then
    echo "0B"
    return
  fi

  # Use du to get size (macOS compatible)
  local size_kb=$(du -sk "$backup_path" 2>/dev/null | cut -f1)

  if [[ -z "$size_kb" || "$size_kb" -eq 0 ]]; then
    echo "0B"
  elif [[ "$size_kb" -lt 1024 ]]; then
    echo "${size_kb}KB"
  elif [[ "$size_kb" -lt 1048576 ]]; then
    local size_mb=$((size_kb / 1024))
    echo "${size_mb}MB"
  else
    local size_gb=$((size_kb / 1048576))
    echo "${size_gb}GB"
  fi
}

# Calculate relative time from backup timestamp
_zsh_tool_relative_time() {
  local backup_date=$1  # YYYY-MM-DD
  local backup_time=$2  # HHMMSS

  # Convert to timestamp (cross-platform: macOS and Linux)
  local backup_timestamp="0"

  if [[ "$OSTYPE" == darwin* ]]; then
    # macOS: use -j -f for custom format parsing
    backup_timestamp=$(date -j -f "%Y-%m-%d-%H%M%S" "${backup_date}-${backup_time}" +%s 2>/dev/null || echo "0")
  else
    # Linux: use -d with reformatted date string
    # Convert HHMMSS to HH:MM:SS for GNU date
    local formatted_time="${backup_time:0:2}:${backup_time:2:2}:${backup_time:4:2}"
    backup_timestamp=$(date -d "${backup_date} ${formatted_time}" +%s 2>/dev/null || echo "0")
  fi

  local current_timestamp=$(date +%s)

  if [[ "$backup_timestamp" == "0" ]]; then
    echo "unknown time"
    return
  fi

  local diff=$((current_timestamp - backup_timestamp))

  # Handle negative diff (future timestamp)
  if [[ $diff -lt 0 ]]; then
    echo "just now"
    return
  fi

  # Calculate time units
  local minutes=$((diff / 60))
  local hours=$((diff / 3600))
  local days=$((diff / 86400))

  if [[ $diff -lt 60 ]]; then
    echo "just now"
  elif [[ $minutes -lt 60 ]]; then
    if [[ $minutes -eq 1 ]]; then
      echo "1 minute ago"
    else
      echo "${minutes} minutes ago"
    fi
  elif [[ $hours -lt 24 ]]; then
    if [[ $hours -eq 1 ]]; then
      echo "1 hour ago"
    else
      echo "${hours} hours ago"
    fi
  else
    if [[ $days -eq 1 ]]; then
      echo "1 day ago"
    else
      echo "${days} days ago"
    fi
  fi
}

# List all available backups with enhanced metadata
_zsh_tool_list_backups() {
  if [[ ! -d "$ZSH_TOOL_BACKUP_DIR" ]]; then
    _zsh_tool_log WARN "No backup directory found"
    echo ""
    echo "No backups available."
    echo ""
    echo "Create a backup: zsh-tool-backup create"
    echo ""
    return 1
  fi

  # Get backups sorted by modification time (newest first)
  setopt local_options null_glob
  local -a backup_dirs
  backup_dirs=("${ZSH_TOOL_BACKUP_DIR}"/*(N/om))  # om = order by mtime, newest first

  if [[ ${#backup_dirs[@]} -eq 0 ]]; then
    echo ""
    echo "No backups available."
    echo ""
    echo "Create a backup: zsh-tool-backup create"
    echo ""
    return 1
  fi

  # Get remote status
  local remote_status=$(_zsh_tool_get_remote_status)

  echo ""
  echo "Available backups:"
  echo ""

  local index=1
  for backup_path in "${backup_dirs[@]}"; do
    local backup=$(basename "$backup_path")
    local manifest="${backup_path}/manifest.json"
    local trigger="unknown"
    local timestamp="unknown"

    if [[ -f "$manifest" ]]; then
      # Extract trigger - handle both quoted formats
      trigger=$(grep -o '"trigger"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" | sed 's/.*:.*"\([^"]*\)"/\1/')
      timestamp=$(grep -o '"timestamp"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" | sed 's/.*:.*"\([^"]*\)"/\1/')
    fi

    # Calculate relative time from backup directory name
    local backup_date=$(echo "$backup" | cut -d'-' -f1-3)
    local backup_time=$(echo "$backup" | cut -d'-' -f4)
    local relative_time=$(_zsh_tool_relative_time "$backup_date" "$backup_time")

    # Get backup size
    local size=$(_zsh_tool_get_backup_size "$backup_path")

    echo "${index}. ${backup} (${trigger}) - ${relative_time} [${size}]"
    ((index++))
  done

  echo ""
  echo "Total backups: ${#backup_dirs[@]} / ${ZSH_TOOL_BACKUP_RETENTION:-10} (retention limit)"

  # Show remote status
  case "$remote_status" in
    enabled)
      echo "Remote sync: Enabled"
      ;;
    disabled)
      echo "Remote sync: Disabled"
      ;;
    not_configured)
      echo "Remote sync: Not configured (use 'zsh-tool-backup remote-config <url>')"
      ;;
  esac

  echo ""
  echo "Commands:"
  echo "  zsh-tool-restore apply <number>  - Restore from backup"
  echo "  zsh-tool-backup create           - Create new backup"
  echo "  zsh-tool-backup remote           - Push to remote"
  echo ""
}

# Update backup state tracking
_zsh_tool_update_backup_state() {
  local backup_timestamp="$1"
  local count=$(_zsh_tool_get_backup_count)

  # Update state with backup information
  _zsh_tool_update_state "backups.last_backup" "\"${backup_timestamp}\""
  _zsh_tool_update_state "backups.count" "${count}"

  _zsh_tool_log DEBUG "Updated backup state: count=${count}, last=${backup_timestamp}"
}

# Create manual backup with state tracking
_zsh_tool_create_manual_backup() {
  local timestamp=$(date +%Y-%m-%d-%H%M%S)
  _zsh_tool_log INFO "Creating manual backup..."

  # Check disk space (warn if less than 100MB free)
  local free_space_kb=$(df -k "${ZSH_TOOL_BACKUP_DIR:-$HOME}" 2>/dev/null | tail -1 | awk '{print $4}')
  if [[ -n "$free_space_kb" && "$free_space_kb" -lt 102400 ]]; then
    _zsh_tool_log WARN "Low disk space detected (${free_space_kb}KB free). Backup may fail."
  fi

  if _zsh_tool_create_backup "manual"; then
    # Update state tracking
    _zsh_tool_update_backup_state "$timestamp"

    _zsh_tool_log INFO "Backup created: ${timestamp}"
    echo ""
    echo "Backup created successfully: ${timestamp}"
    echo "Total backups: $(_zsh_tool_get_backup_count)"
    echo ""
    return 0
  else
    _zsh_tool_log ERROR "Failed to create backup"
    return 1
  fi
}

# Backup to remote git repository
# Uses subshell for directory safety
_zsh_tool_backup_to_remote() {
  local remote_url=$(_zsh_tool_load_state | grep -o '"remote_url":"[^"]*"' | cut -d'"' -f4)

  if [[ -z "$remote_url" ]]; then
    _zsh_tool_log WARN "No remote backup URL configured"
    echo ""
    echo "Remote backups not configured."
    echo ""
    echo "To enable remote backups:"
    echo "  1. Configure remote: zsh-tool-backup remote-config <git-url>"
    echo "  2. Or manually:"
    echo "     cd ~/.config/zsh-tool/backups"
    echo "     git init"
    echo "     git remote add origin <your-remote-url>"
    echo ""
    return 1
  fi

  _zsh_tool_log INFO "Pushing backup to remote: $remote_url"

  # Use subshell for directory safety
  local push_result
  push_result=$(
    cd "$ZSH_TOOL_BACKUP_DIR" 2>/dev/null || {
      echo "ERROR:Cannot access backup directory"
      exit 1
    }

    # Check if git repo
    if [[ ! -d ".git" ]]; then
      git init 2>&1 || {
        echo "ERROR:Git init failed"
        exit 1
      }
      git remote add origin "$remote_url" 2>&1 || {
        echo "ERROR:Failed to add remote"
        exit 1
      }
    fi

    # Add and commit backups
    git add . 2>&1

    # Check if there are changes to commit
    if git diff --cached --quiet; then
      echo "INFO:No changes to commit"
      exit 0
    fi

    git commit -m "Backup: $(date +%Y-%m-%d\ %H:%M:%S)" 2>&1 || {
      echo "WARN:Nothing to commit"
    }

    # Get current branch name
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -z "$current_branch" ]]; then
      current_branch="main"  # Fallback for new repos
    fi

    # Push to remote using current branch
    if git push -u origin "$current_branch" 2>&1; then
      echo "SUCCESS:Pushed to $current_branch"
    else
      echo "ERROR:Push failed to branch $current_branch"
      exit 1
    fi
  ) 2>&1

  # Log the output
  echo "$push_result" >> "$ZSH_TOOL_LOG_FILE"

  # Check result
  if echo "$push_result" | grep -q "^ERROR:"; then
    local error_msg=$(echo "$push_result" | grep "^ERROR:" | head -1 | cut -d':' -f2-)
    _zsh_tool_log ERROR "Remote push failed: $error_msg"
    echo ""
    echo "Failed to push backup to remote."
    echo "Error: $error_msg"
    echo ""
    echo "Check your network connection and git configuration."
    echo ""
    return 1
  elif echo "$push_result" | grep -q "^SUCCESS:"; then
    _zsh_tool_log INFO "Backup pushed to remote"
    echo ""
    echo "Backup pushed to remote successfully."
    echo ""
    return 0
  else
    # No changes or other info
    _zsh_tool_log INFO "Remote sync complete (no new changes)"
    echo ""
    echo "Remote sync complete (no new changes to push)."
    echo ""
    return 0
  fi
}

# Fetch backups from remote
# Uses subshell for directory safety
_zsh_tool_fetch_remote_backups() {
  # Check if backup directory exists
  if [[ ! -d "$ZSH_TOOL_BACKUP_DIR" ]]; then
    _zsh_tool_log WARN "Backup directory does not exist"
    return 1
  fi

  # Use subshell for directory safety
  local pull_result
  pull_result=$(
    cd "$ZSH_TOOL_BACKUP_DIR" 2>/dev/null || {
      echo "ERROR:Cannot access backup directory"
      exit 1
    }

    if [[ ! -d ".git" ]]; then
      echo "ERROR:Backups directory is not a git repository"
      exit 1
    fi

    git pull origin main 2>&1 || git pull origin master 2>&1 || {
      echo "ERROR:Pull failed"
      exit 1
    }

    echo "SUCCESS:Fetched"
  ) 2>&1

  # Log the output
  echo "$pull_result" >> "$ZSH_TOOL_LOG_FILE"

  if echo "$pull_result" | grep -q "^ERROR:"; then
    local error_msg=$(echo "$pull_result" | grep "^ERROR:" | head -1 | cut -d':' -f2-)
    _zsh_tool_log WARN "Failed to fetch remote backups: $error_msg"
    echo ""
    echo "Failed to fetch remote backups."
    echo "Error: $error_msg"
    echo ""
    return 1
  else
    _zsh_tool_log INFO "Remote backups fetched"

    # Update state with new count
    local count=$(_zsh_tool_get_backup_count)
    _zsh_tool_update_state "backups.count" "${count}"

    echo ""
    echo "Remote backups fetched successfully."
    echo "Total backups: $count"
    echo ""
    return 0
  fi
}

# Configure remote backup URL
_zsh_tool_configure_remote_backup() {
  local remote_url=$1

  if [[ -z "$remote_url" ]]; then
    echo -n "Enter remote backup URL (e.g., git@github.com:user/zsh-backups.git): "
    read -r remote_url
  fi

  if [[ -z "$remote_url" ]]; then
    _zsh_tool_log ERROR "Remote URL cannot be empty"
    return 1
  fi

  # Validate URL format (basic check)
  if [[ ! "$remote_url" =~ ^(https?://|git@|ssh://) ]]; then
    _zsh_tool_log WARN "URL format may be invalid, but proceeding..."
  fi

  # Update state
  _zsh_tool_update_state "backups.remote_enabled" "true"
  _zsh_tool_update_state "backups.remote_url" "\"${remote_url}\""

  _zsh_tool_log INFO "Remote backup configured: $remote_url"

  echo ""
  echo "Remote backup configured successfully."
  echo "URL: $remote_url"
  echo ""
  echo "Next steps:"
  echo "  1. Create a backup: zsh-tool-backup create"
  echo "  2. Push to remote: zsh-tool-backup remote"
  echo ""

  return 0
}

# Disable remote backup
_zsh_tool_disable_remote_backup() {
  _zsh_tool_update_state "backups.remote_enabled" "false"
  _zsh_tool_log INFO "Remote backup disabled"

  echo ""
  echo "Remote backup disabled."
  echo "Local backups will continue to be created."
  echo ""

  return 0
}

# Show backup status summary
_zsh_tool_backup_status() {
  local count=$(_zsh_tool_get_backup_count)
  local remote_status=$(_zsh_tool_get_remote_status)
  local state=$(_zsh_tool_load_state)

  # Extract values using jq if available
  local last_backup=""
  local remote_url=""
  if command -v jq &>/dev/null; then
    last_backup=$(echo "$state" | jq -r '.backups.last_backup // empty' 2>/dev/null)
    remote_url=$(echo "$state" | jq -r '.backups.remote_url // empty' 2>/dev/null)
  else
    # Fallback: More robust parsing using awk for nested JSON
    last_backup=$(echo "$state" | awk -F'"last_backup"[[:space:]]*:[[:space:]]*"' '
      NF > 1 {
        val = $2
        if (match(val, /[^"]*/)) {
          print substr(val, RSTART, RLENGTH)
        }
      }
    ')
    remote_url=$(echo "$state" | awk -F'"remote_url"[[:space:]]*:[[:space:]]*"' '
      NF > 1 {
        val = $2
        if (match(val, /[^"]*/)) {
          print substr(val, RSTART, RLENGTH)
        }
      }
    ')
  fi

  echo ""
  echo "Backup Status"
  echo "============="
  echo ""
  echo "Local backups: $count / ${ZSH_TOOL_BACKUP_RETENTION:-10} (retention limit)"
  echo "Last backup: ${last_backup:-Never}"
  echo "Backup directory: $ZSH_TOOL_BACKUP_DIR"
  echo ""
  echo "Remote Configuration:"
  case "$remote_status" in
    enabled)
      echo "  Status: Enabled"
      echo "  URL: $remote_url"
      ;;
    disabled)
      echo "  Status: Disabled"
      echo "  URL: $remote_url"
      ;;
    not_configured)
      echo "  Status: Not configured"
      ;;
  esac
  echo ""
}
