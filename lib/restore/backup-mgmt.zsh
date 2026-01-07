#!/usr/bin/env zsh
# Story 2.3: Configuration Backup Management
# Manage backups - create, list, prune, and remote sync

# Get default git branch dynamically
# Returns: branch name (main or master, defaults to main)
_zsh_tool_get_backup_branch() {
  local branch=""

  # Try upstream tracking first
  branch=$(git rev-parse --abbrev-ref @{u} 2>/dev/null | cut -d'/' -f2)

  if [[ -z "$branch" ]]; then
    # Try common branch names
    for try_branch in main master; do
      if git show-ref --verify --quiet "refs/remotes/origin/${try_branch}" 2>/dev/null; then
        branch="$try_branch"
        break
      fi
    done
  fi

  # Default to main if nothing found
  echo "${branch:-main}"
}

# List all available backups with enhanced display
# AC3: Displays available backups with timestamps, triggers, and relative time
_zsh_tool_list_backups() {
  if [[ ! -d "$ZSH_TOOL_BACKUP_DIR" ]]; then
    _zsh_tool_log WARN "No backup directory found"
    echo "No backup directory exists yet."
    echo "Run 'zsh-tool-backup create' to create your first backup."
    return 1
  fi

  # Use zsh glob for portable, sorted listing (newest first)
  setopt local_options null_glob
  local -a backup_dirs
  backup_dirs=("${ZSH_TOOL_BACKUP_DIR}"/*(N/om))

  if [[ ${#backup_dirs[@]} -eq 0 ]]; then
    echo "No backups available"
    echo "Run 'zsh-tool-backup create' to create your first backup."
    return 1
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Available Backups (newest first)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local index=1
  for backup_path in "${backup_dirs[@]}"; do
    local backup=$(basename "$backup_path")
    local manifest="${backup_path}/manifest.json"
    local trigger="unknown"
    local files_count=0
    local size="?"

    if [[ -f "$manifest" ]]; then
      # Use jq if available, fallback to grep
      if command -v jq >/dev/null 2>&1; then
        trigger=$(jq -r '.trigger // "unknown"' "$manifest" 2>/dev/null)
      else
        trigger=$(grep -o '"trigger":"[^"]*"' "$manifest" 2>/dev/null | cut -d'"' -f4)
        [[ -z "$trigger" ]] && trigger="unknown"
      fi
    fi

    # Count files using zsh glob (consistent with rest of codebase)
    local -a backup_files
    backup_files=("$backup_path"/*(N))
    files_count=${#backup_files[@]}

    # Calculate size (du -sh for human readable)
    size=$(du -sh "$backup_path" 2>/dev/null | cut -f1 || echo "?")

    # Calculate relative time
    local backup_date=$(echo "$backup" | cut -d'-' -f1-3)
    local backup_time=$(echo "$backup" | cut -d'-' -f4)
    local relative_time=$(_zsh_tool_relative_time "$backup_date" "$backup_time")

    printf "  %2d. %-20s  %-15s  %-15s  %s\n" \
      "$index" "$backup" "$trigger" "$relative_time" "($size)"
    ((index++))
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Commands:"
  echo "  zsh-tool-restore apply <number>  - Restore from backup"
  echo "  zsh-tool-backup remote           - Push to remote"
  echo "  zsh-tool-backup fetch            - Pull from remote"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  return 0
}

# Calculate relative time from backup timestamp
# Args: backup_date (YYYY-MM-DD), backup_time (HHMMSS)
_zsh_tool_relative_time() {
  local backup_date=$1  # YYYY-MM-DD
  local backup_time=$2  # HHMMSS

  # Handle missing time component
  [[ -z "$backup_time" ]] && backup_time="000000"

  # Convert to timestamp (cross-platform: macOS and Linux)
  local backup_timestamp
  if [[ "$OSTYPE" == darwin* ]]; then
    # macOS/BSD date
    backup_timestamp=$(date -j -f "%Y-%m-%d-%H%M%S" "${backup_date}-${backup_time}" +%s 2>/dev/null || echo "0")
  else
    # Linux/GNU date
    local formatted_date="${backup_date} ${backup_time:0:2}:${backup_time:2:2}:${backup_time:4:2}"
    backup_timestamp=$(date -d "$formatted_date" +%s 2>/dev/null || echo "0")
  fi
  local current_timestamp=$(date +%s)

  if [[ "$backup_timestamp" == "0" ]]; then
    echo "unknown"
    return 0
  fi

  local diff=$((current_timestamp - backup_timestamp))

  # Handle negative diff (future dates - shouldn't happen but be safe)
  if [[ $diff -lt 0 ]]; then
    echo "just now"
    return 0
  fi

  # Calculate time units
  local minutes=$((diff / 60))
  local hours=$((diff / 3600))
  local days=$((diff / 86400))

  if [[ $diff -lt 60 ]]; then
    echo "just now"
  elif [[ $minutes -lt 60 ]]; then
    echo "${minutes}m ago"
  elif [[ $hours -lt 24 ]]; then
    echo "${hours}h ago"
  elif [[ $days -eq 1 ]]; then
    echo "1 day ago"
  else
    echo "${days} days ago"
  fi
}

# Create manual backup
# AC1: Command creates timestamped backup to local storage
_zsh_tool_create_manual_backup() {
  local timestamp=$(date +%Y-%m-%d-%H%M%S)
  _zsh_tool_log INFO "Creating manual backup..."

  if _zsh_tool_create_backup "manual"; then
    _zsh_tool_log INFO "Backup created successfully"

    # Update state with backup info (AC8)
    _zsh_tool_update_state "last_backup" "\"${timestamp}\""
    _zsh_tool_update_state "backups.last_local" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

    # Update backup count
    local count=$(_zsh_tool_count_backups)
    _zsh_tool_update_state "backups.count" "$count"

    return 0
  else
    _zsh_tool_log ERROR "Failed to create backup"
    return 1
  fi
}

# Count existing backups
_zsh_tool_count_backups() {
  setopt local_options null_glob
  local -a backup_dirs
  backup_dirs=("${ZSH_TOOL_BACKUP_DIR}"/*(N/))
  echo "${#backup_dirs[@]}"
}

# Backup to remote git repository
# AC2: Command pushes backup to configured git repository
# AC6: Command handles network failures gracefully
_zsh_tool_backup_to_remote() {
  # Get remote URL from state
  local remote_url
  local state=$(_zsh_tool_load_state)

  if command -v jq >/dev/null 2>&1; then
    remote_url=$(echo "$state" | jq -r '.backups.remote_url // empty' 2>/dev/null)
  else
    remote_url=$(echo "$state" | grep -o '"remote_url":"[^"]*"' | cut -d'"' -f4)
  fi

  if [[ -z "$remote_url" ]]; then
    _zsh_tool_log WARN "No remote backup URL configured"
    echo ""
    echo "To enable remote backups, run:"
    echo "  zsh-tool-backup config <your-git-remote-url>"
    echo ""
    echo "Example:"
    echo "  zsh-tool-backup config git@github.com:username/zsh-backups.git"
    echo ""
    return 1
  fi

  _zsh_tool_log INFO "Pushing backup to remote: $remote_url"

  # Use subshell to avoid polluting calling shell's directory (AC6)
  local push_result
  push_result=$(
    cd "$ZSH_TOOL_BACKUP_DIR" 2>/dev/null || {
      echo "ERROR:Cannot access backup directory"
      exit 1
    }

    # Initialize git if needed
    if [[ ! -d ".git" ]]; then
      _zsh_tool_log DEBUG "Initializing git repository in backup directory"
      # Try --initial-branch first (git 2.28+), fallback for older versions
      if ! git init --initial-branch=main 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null; then
        # Fallback for older git versions
        git init 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null || {
          echo "ERROR:Failed to initialize git repository"
          exit 1
        }
        git checkout -b main 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null || true
      fi
      git remote add origin "$remote_url" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null || {
        echo "ERROR:Failed to add remote"
        exit 1
      }
    fi

    # Get default branch dynamically
    local branch=$(_zsh_tool_get_backup_branch)
    _zsh_tool_log DEBUG "Using branch: $branch"

    # Add all backup files
    git add . 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null

    # Commit (may fail if nothing to commit - that's OK)
    local commit_msg="Backup: $(date +%Y-%m-%d\ %H:%M:%S)"
    git commit -m "$commit_msg" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null || true

    # Push to remote with error capture
    local push_output
    push_output=$(git push -u origin "$branch" 2>&1)
    local push_status=$?

    echo "$push_output" >> "$ZSH_TOOL_LOG_FILE"

    if [[ $push_status -eq 0 ]]; then
      echo "SUCCESS"
    else
      # Check for common errors
      if echo "$push_output" | grep -q "Permission denied"; then
        echo "ERROR:Permission denied - check SSH keys or credentials"
      elif echo "$push_output" | grep -q "Could not resolve host"; then
        echo "ERROR:Network error - could not resolve host"
      elif echo "$push_output" | grep -q "Connection refused"; then
        echo "ERROR:Connection refused - check remote URL"
      elif echo "$push_output" | grep -q "rejected"; then
        echo "ERROR:Push rejected - try 'zsh-tool-backup fetch' first"
      else
        echo "ERROR:Push failed - check logs for details"
      fi
    fi
  )

  # Process result
  if [[ "$push_result" == "SUCCESS" ]]; then
    _zsh_tool_log INFO "Backup pushed to remote successfully"

    # Update state (AC8)
    _zsh_tool_update_state "backups.last_remote_sync" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    _zsh_tool_update_state "backups.remote_enabled" "true"

    return 0
  else
    local error_msg="${push_result#ERROR:}"
    _zsh_tool_log ERROR "Failed to push backup: $error_msg"
    return 1
  fi
}

# Fetch backups from remote
# AC5: Command retrieves backups from remote repository
# AC6: Command handles network failures gracefully
_zsh_tool_fetch_remote_backups() {
  _zsh_tool_log INFO "Fetching backups from remote..."

  # Use subshell to avoid polluting calling shell's directory (AC6)
  local fetch_result
  fetch_result=$(
    cd "$ZSH_TOOL_BACKUP_DIR" 2>/dev/null || {
      echo "ERROR:Cannot access backup directory"
      exit 1
    }

    if [[ ! -d ".git" ]]; then
      echo "ERROR:Backup directory is not a git repository. Run 'zsh-tool-backup remote' first."
      exit 1
    fi

    # Get default branch dynamically
    local branch=$(_zsh_tool_get_backup_branch)
    _zsh_tool_log DEBUG "Fetching from branch: $branch"

    # Fetch and merge with error capture
    local pull_output
    pull_output=$(git pull origin "$branch" 2>&1)
    local pull_status=$?

    echo "$pull_output" >> "$ZSH_TOOL_LOG_FILE"

    if [[ $pull_status -eq 0 ]]; then
      echo "SUCCESS"
    else
      # Check for common errors
      if echo "$pull_output" | grep -q "CONFLICT"; then
        echo "ERROR:Merge conflict detected - resolve manually in $ZSH_TOOL_BACKUP_DIR"
      elif echo "$pull_output" | grep -q "Could not resolve host"; then
        echo "ERROR:Network error - could not resolve host"
      elif echo "$pull_output" | grep -q "Permission denied"; then
        echo "ERROR:Permission denied - check SSH keys or credentials"
      else
        echo "ERROR:Fetch failed - check logs for details"
      fi
    fi
  )

  # Process result
  if [[ "$fetch_result" == "SUCCESS" ]]; then
    _zsh_tool_log INFO "Remote backups fetched successfully"

    # Update state (AC8)
    _zsh_tool_update_state "backups.last_fetch" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

    return 0
  else
    local error_msg="${fetch_result#ERROR:}"
    _zsh_tool_log ERROR "Failed to fetch backups: $error_msg"
    echo ""
    echo "Error: $error_msg"
    echo ""
    return 1
  fi
}

# Configure remote backup URL
# AC4: Command supports configuring remote backup URL via state file
_zsh_tool_configure_remote_backup() {
  local remote_url="$1"

  # If no URL provided, prompt for it
  if [[ -z "$remote_url" ]]; then
    echo -n "Enter remote backup URL (e.g., git@github.com:user/backups.git): "
    read -r remote_url
  fi

  # Validate URL is not empty
  if [[ -z "$remote_url" ]]; then
    _zsh_tool_log ERROR "Remote URL cannot be empty"
    return 1
  fi

  # Basic URL validation
  if [[ ! "$remote_url" =~ ^(git@|https://|ssh://|git://) ]]; then
    _zsh_tool_log WARN "URL doesn't look like a valid git remote. Proceeding anyway..."
  fi

  # Escape special JSON characters in URL (L1 fix)
  local escaped_url="${remote_url//\\/\\\\}"  # Escape backslashes
  escaped_url="${escaped_url//\"/\\\"}"        # Escape quotes

  # Update state (AC8)
  _zsh_tool_update_state "backups.remote_enabled" "true"
  _zsh_tool_update_state "backups.remote_url" "\"${escaped_url}\""
  _zsh_tool_update_state "backups.configured_at" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  _zsh_tool_log INFO "Remote backup configured: $remote_url"

  echo ""
  echo "Remote backup configured successfully!"
  echo ""
  echo "Next steps:"
  echo "  1. Create a backup:     zsh-tool-backup create"
  echo "  2. Push to remote:      zsh-tool-backup remote"
  echo "  3. Fetch from remote:   zsh-tool-backup fetch"
  echo ""

  return 0
}

# Get backup statistics
# AC8: Track backup statistics
_zsh_tool_backup_stats() {
  setopt local_options null_glob
  local -a backup_dirs
  backup_dirs=("${ZSH_TOOL_BACKUP_DIR}"/*(N/))

  local count=${#backup_dirs[@]}
  local total_size="0"

  if [[ $count -gt 0 ]]; then
    total_size=$(du -sh "$ZSH_TOOL_BACKUP_DIR" 2>/dev/null | cut -f1 || echo "unknown")
  fi

  echo "Backup Statistics:"
  echo "  Total backups: $count"
  echo "  Total size: $total_size"
  echo "  Retention limit: ${ZSH_TOOL_BACKUP_RETENTION:-10}"
  echo "  Location: $ZSH_TOOL_BACKUP_DIR"

  # Check remote status
  local state=$(_zsh_tool_load_state)
  local remote_enabled="false"
  if command -v jq >/dev/null 2>&1; then
    remote_enabled=$(echo "$state" | jq -r '.backups.remote_enabled // "false"' 2>/dev/null)
  fi

  if [[ "$remote_enabled" == "true" ]]; then
    echo "  Remote sync: enabled"
  else
    echo "  Remote sync: not configured"
  fi
}
