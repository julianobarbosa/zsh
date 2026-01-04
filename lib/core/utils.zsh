#!/usr/bin/env zsh
# Core utilities for zsh-tool
# Logging, prompts, error handling, idempotency checks

# Configuration
ZSH_TOOL_CONFIG_DIR="${HOME}/.config/zsh-tool"
ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/zsh-tool.log"
ZSH_TOOL_STATE_FILE="${ZSH_TOOL_CONFIG_DIR}/state.json"
ZSH_TOOL_LOG_LEVEL="${ZSH_TOOL_LOG_LEVEL:-INFO}"

# Logging levels
typeset -A ZSH_TOOL_LOG_LEVELS
ZSH_TOOL_LOG_LEVELS=(
  DEBUG 0
  INFO 1
  WARN 2
  ERROR 3
)

# Initialize logging directory
_zsh_tool_init_logging() {
  mkdir -p "$(dirname "$ZSH_TOOL_LOG_FILE")" 2>/dev/null
}

# Log message
# Usage: _zsh_tool_log <level> <message>
# Levels: info, warn, error, debug (case-insensitive)
_zsh_tool_log() {
  local level="${1:u}"  # Convert to uppercase for consistent matching
  shift
  local message="$*"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Initialize logging if needed
  [[ ! -d "$(dirname "$ZSH_TOOL_LOG_FILE")" ]] && _zsh_tool_init_logging

  # Check log level
  local current_level=${ZSH_TOOL_LOG_LEVELS[$ZSH_TOOL_LOG_LEVEL]:-1}
  local msg_level=${ZSH_TOOL_LOG_LEVELS[$level]:-1}

  if [[ $msg_level -ge $current_level ]]; then
    # Console output with colors
    case $level in
      ERROR)
        echo "[${timestamp}] [${level}] ${message}" | tee -a "$ZSH_TOOL_LOG_FILE" >&2
        ;;
      WARN)
        echo "[${timestamp}] [${level}] ${message}" | tee -a "$ZSH_TOOL_LOG_FILE"
        ;;
      *)
        echo "[${timestamp}] [${level}] ${message}" >> "$ZSH_TOOL_LOG_FILE"
        [[ $level == "INFO" ]] && echo "${message}"
        ;;
    esac
  fi
}

# Prompt user for confirmation
# Usage: _zsh_tool_prompt_confirm <message>
# Returns: 0 if yes, 1 if no
_zsh_tool_prompt_confirm() {
  local message="$1"
  local response

  echo -n "${message} (y/n): "
  read response

  case "$response" in
    [Yy]|[Yy][Ee][Ss])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Check if command exists
# Usage: _zsh_tool_is_installed <command>
_zsh_tool_is_installed() {
  command -v "$1" >/dev/null 2>&1
}

# Load state file
# Usage: _zsh_tool_load_state
_zsh_tool_load_state() {
  if [[ -f "$ZSH_TOOL_STATE_FILE" ]]; then
    cat "$ZSH_TOOL_STATE_FILE"
  else
    echo "{}"
  fi
}

# Save state file atomically
# Usage: _zsh_tool_save_state <json_content>
_zsh_tool_save_state() {
  local content="$1"
  mkdir -p "$(dirname "$ZSH_TOOL_STATE_FILE")" 2>/dev/null
  # Atomic write: write to temp file then rename (prevents race conditions)
  local temp_file="${ZSH_TOOL_STATE_FILE}.tmp.$$"
  echo "$content" > "$temp_file" && mv "$temp_file" "$ZSH_TOOL_STATE_FILE"
}

# Update state field
# Usage: _zsh_tool_update_state <key> <value>
_zsh_tool_update_state() {
  local key="$1"
  local value="$2"
  local state=$(_zsh_tool_load_state)

  # Simple JSON update (works for top-level keys)
  # For complex JSON, would use jq, but keeping dependencies minimal
  local updated
  if echo "$state" | grep -q "\"${key}\""; then
    # Update existing key
    updated=$(echo "$state" | sed "s/\"${key}\":[^,}]*/\"${key}\":${value}/")
  else
    # Add new key
    updated=$(echo "$state" | sed "s/}/,\"${key}\":${value}}/")
  fi

  _zsh_tool_save_state "$updated"
}

# Check if operation is safe (idempotency check)
# Usage: _zsh_tool_is_idempotent_safe <operation>
_zsh_tool_is_idempotent_safe() {
  local operation="$1"
  local state=$(_zsh_tool_load_state)

  # Check if operation already completed in state
  echo "$state" | grep -q "\"${operation}\":true"
  return $?
}

# Error handler
_zsh_tool_error_handler() {
  local exit_code=$?
  local line_number=${1:-"unknown"}

  if [[ $exit_code -ne 0 ]]; then
    _zsh_tool_log ERROR "Operation failed at line $line_number with exit code $exit_code"
    _zsh_tool_log ERROR "Run 'zsh-tool-restore list' to recover if needed"
  fi

  return $exit_code
}

# Set up error trap (disabled - too aggressive for global use)
# Use 'trap _zsh_tool_error_handler ERR' in specific functions if needed
# trap '_zsh_tool_error_handler $LINENO' ERR

# Progress spinner
# Usage: _zsh_tool_with_spinner <message> <command...>
_zsh_tool_with_spinner() {
  local message="$1"
  shift
  local cmd="$*"

  echo -n "${message}... "

  # Run command in background
  eval "$cmd" >/dev/null 2>&1 &
  local pid=$!

  # Spinner
  local spin='-\|/'
  local i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r${message}... ${spin:$i:1}"
    sleep 0.1
  done

  wait $pid
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    echo "\r${message}... ✓"
  else
    echo "\r${message}... ✗"
  fi

  return $exit_code
}

# Initialize configuration directory
_zsh_tool_init_config() {
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}"/{logs,backups} 2>/dev/null

  # Create default state if not exists
  if [[ ! -f "$ZSH_TOOL_STATE_FILE" ]]; then
    _zsh_tool_save_state '{"version":"1.0.0","installed":false}'
  fi
}

# Auto-initialize on load
_zsh_tool_init_config
