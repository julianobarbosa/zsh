#!/usr/bin/env zsh
# Vi-Mode Integration
# Comprehensive vi-mode configuration for zsh with cursor shapes,
# mode indicators, timeout tuning, and enhanced keybindings

# Vi-mode configuration defaults
# Can be overridden by setting these variables before sourcing this file
VIMODE_CURSOR_INSERT="${VIMODE_CURSOR_INSERT:-beam}"      # beam, block, underline
VIMODE_CURSOR_NORMAL="${VIMODE_CURSOR_NORMAL:-block}"     # beam, block, underline
VIMODE_CURSOR_VISUAL="${VIMODE_CURSOR_VISUAL:-block}"     # beam, block, underline
VIMODE_ESCAPE_TIMEOUT="${VIMODE_ESCAPE_TIMEOUT:-10}"      # ms (lower = faster ESC response)
VIMODE_INDICATOR_INSERT="${VIMODE_INDICATOR_INSERT:-INS}"
VIMODE_INDICATOR_NORMAL="${VIMODE_INDICATOR_NORMAL:-NOR}"
VIMODE_INDICATOR_VISUAL="${VIMODE_INDICATOR_VISUAL:-VIS}"
VIMODE_INDICATOR_REPLACE="${VIMODE_INDICATOR_REPLACE:-REP}"

# Terminal cursor escape sequences
# These follow the DECSCUSR (DEC Set Cursor Style) standard
typeset -gA VIMODE_CURSOR_CODES
VIMODE_CURSOR_CODES=(
  block         '\e[2 q'    # Steady block
  block_blink   '\e[1 q'    # Blinking block
  underline     '\e[4 q'    # Steady underline
  underline_blink '\e[3 q'  # Blinking underline
  beam          '\e[6 q'    # Steady beam (line)
  beam_blink    '\e[5 q'    # Blinking beam
)

# Current mode tracking (exported for prompt integration)
typeset -g VIMODE_CURRENT_MODE="insert"
typeset -g VIMODE_INDICATOR=""

# ==============================================================================
# Detection and Prerequisites
# ==============================================================================

# Check if vi-mode is already enabled
_vimode_is_enabled() {
  [[ "$VIMODE_ENABLED" == "true" ]] || [[ -o vi ]]
}

# Detect terminal capabilities for cursor shapes
_vimode_detect_terminal() {
  local term="${TERM:-}"
  local term_program="${TERM_PROGRAM:-}"

  # Most modern terminals support DECSCUSR cursor styling
  case "$term_program" in
    iTerm.app|Apple_Terminal|vscode|Hyper|WezTerm|Alacritty)
      return 0
      ;;
  esac

  case "$term" in
    xterm*|rxvt*|screen*|tmux*|alacritty|wezterm|foot)
      return 0
      ;;
    linux|dumb)
      return 1
      ;;
  esac

  # Default: assume cursor styling is supported
  return 0
}

# Detect if running inside tmux
_vimode_in_tmux() {
  [[ -n "$TMUX" ]]
}

# Get the appropriate cursor escape sequence for tmux passthrough
_vimode_cursor_escape() {
  local cursor_code="$1"

  if _vimode_in_tmux; then
    # tmux requires passthrough escape sequences
    printf '\ePtmux;\e%s\e\\' "$cursor_code"
  else
    printf '%s' "$cursor_code"
  fi
}

# ==============================================================================
# Cursor Shape Management
# ==============================================================================

# Set cursor shape by name
# Usage: _vimode_set_cursor <shape>
# Shapes: block, block_blink, underline, underline_blink, beam, beam_blink
_vimode_set_cursor() {
  local shape="$1"
  local cursor_code="${VIMODE_CURSOR_CODES[$shape]:-}"

  if [[ -z "$cursor_code" ]]; then
    _zsh_tool_log DEBUG "Unknown cursor shape: $shape"
    return 1
  fi

  if _vimode_detect_terminal; then
    print -n "$(_vimode_cursor_escape "$cursor_code")"
  fi
}

# Set cursor for insert mode
_vimode_cursor_insert() {
  _vimode_set_cursor "$VIMODE_CURSOR_INSERT"
}

# Set cursor for normal/command mode
_vimode_cursor_normal() {
  _vimode_set_cursor "$VIMODE_CURSOR_NORMAL"
}

# Set cursor for visual mode
_vimode_cursor_visual() {
  _vimode_set_cursor "$VIMODE_CURSOR_VISUAL"
}

# Reset cursor to default on shell exit
_vimode_cursor_reset() {
  _vimode_set_cursor "block"
}

# ==============================================================================
# Mode Change Handlers
# ==============================================================================

# Update mode indicator variable (for prompt integration)
_vimode_update_indicator() {
  case "$VIMODE_CURRENT_MODE" in
    insert)
      VIMODE_INDICATOR="$VIMODE_INDICATOR_INSERT"
      ;;
    normal)
      VIMODE_INDICATOR="$VIMODE_INDICATOR_NORMAL"
      ;;
    visual)
      VIMODE_INDICATOR="$VIMODE_INDICATOR_VISUAL"
      ;;
    replace)
      VIMODE_INDICATOR="$VIMODE_INDICATOR_REPLACE"
      ;;
  esac
}

# ZLE hook: Called when entering insert mode
_vimode_line_init() {
  VIMODE_CURRENT_MODE="insert"
  _vimode_cursor_insert
  _vimode_update_indicator
  zle reset-prompt 2>/dev/null || true
  # Chain to original widget if it existed
  [[ "$_VIMODE_HAS_ORIG_LINE_INIT" == "true" ]] && _vimode_orig_line_init "$@"
}

# ZLE hook: Called when keymap changes
_vimode_keymap_select() {
  case "${KEYMAP}" in
    vicmd|command)
      VIMODE_CURRENT_MODE="normal"
      _vimode_cursor_normal
      ;;
    viins|main)
      VIMODE_CURRENT_MODE="insert"
      _vimode_cursor_insert
      ;;
    visual|viopp)
      VIMODE_CURRENT_MODE="visual"
      _vimode_cursor_visual
      ;;
    *)
      VIMODE_CURRENT_MODE="insert"
      _vimode_cursor_insert
      ;;
  esac

  _vimode_update_indicator
  zle reset-prompt 2>/dev/null || true
  # Chain to original widget if it existed
  [[ "$_VIMODE_HAS_ORIG_KEYMAP_SELECT" == "true" ]] && _vimode_orig_keymap_select "$@"
}

# ZLE hook: Called when line is finished (Enter pressed)
_vimode_line_finish() {
  # Reset to insert mode cursor for command output
  _vimode_cursor_insert
  # Chain to original widget if it existed
  [[ "$_VIMODE_HAS_ORIG_LINE_FINISH" == "true" ]] && _vimode_orig_line_finish "$@"
}

# ==============================================================================
# Enhanced Vi Keybindings
# ==============================================================================

# Setup enhanced vi keybindings
_vimode_setup_keybindings() {
  _zsh_tool_log DEBUG "Setting up vi-mode keybindings..."

  # Ensure vi mode is enabled
  bindkey -v

  # --- Insert Mode Keybindings ---

  # Use Ctrl+A and Ctrl+E for line navigation (like emacs, useful in insert mode)
  bindkey -M viins '^A' beginning-of-line
  bindkey -M viins '^E' end-of-line

  # Ctrl+K to kill to end of line
  bindkey -M viins '^K' kill-line

  # Ctrl+U to kill whole line
  bindkey -M viins '^U' backward-kill-line

  # Ctrl+W to delete word backward
  bindkey -M viins '^W' backward-kill-word

  # Ctrl+Y to yank (paste)
  bindkey -M viins '^Y' yank

  # Ctrl+P/N for history navigation
  bindkey -M viins '^P' up-line-or-history
  bindkey -M viins '^N' down-line-or-history

  # Backspace and Delete keys
  bindkey -M viins '^?' backward-delete-char  # Backspace
  bindkey -M viins '^H' backward-delete-char  # Ctrl+H
  bindkey -M viins '^[[3~' delete-char        # Delete key

  # Home and End keys
  bindkey -M viins '^[[H' beginning-of-line   # Home
  bindkey -M viins '^[[F' end-of-line         # End
  bindkey -M viins '^[[1~' beginning-of-line  # Home (alternate)
  bindkey -M viins '^[[4~' end-of-line        # End (alternate)

  # Arrow keys in insert mode
  bindkey -M viins '^[[A' up-line-or-history
  bindkey -M viins '^[[B' down-line-or-history
  bindkey -M viins '^[[C' forward-char
  bindkey -M viins '^[[D' backward-char

  # --- Normal/Command Mode Keybindings ---

  # H and L for beginning/end of line (like vim with remaps)
  bindkey -M vicmd 'H' beginning-of-line
  bindkey -M vicmd 'L' end-of-line

  # Ctrl+A/E in command mode too
  bindkey -M vicmd '^A' beginning-of-line
  bindkey -M vicmd '^E' end-of-line

  # j and k for history with prefix search
  autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey -M vicmd 'k' up-line-or-beginning-search
  bindkey -M vicmd 'j' down-line-or-beginning-search

  # Arrow keys in command mode
  bindkey -M vicmd '^[[A' up-line-or-beginning-search
  bindkey -M vicmd '^[[B' down-line-or-beginning-search

  # Undo/Redo
  bindkey -M vicmd 'u' undo
  bindkey -M vicmd '^R' redo

  # Search history with / and ?
  bindkey -M vicmd '/' history-incremental-search-backward
  bindkey -M vicmd '?' history-incremental-search-forward

  # Visual mode 'v' to edit command in $EDITOR
  autoload -Uz edit-command-line
  zle -N edit-command-line
  bindkey -M vicmd 'v' edit-command-line

  # Y to yank whole line (like vim)
  bindkey -M vicmd 'Y' vi-yank-eol

  # --- Surround Plugin (text objects) ---
  # If zsh-vi-more/vi-motions is available, additional text objects work
  # Basic text objects are built-in: iw, aw, i", a", etc.

  _zsh_tool_log DEBUG "Vi-mode keybindings configured"
}

# ==============================================================================
# Escape Key Timeout
# ==============================================================================

# Configure escape key timeout for responsive mode switching
_vimode_setup_escape_timeout() {
  # KEYTIMEOUT is in centiseconds (1/100 of a second)
  # Convert milliseconds to centiseconds, minimum 1
  local timeout_cs=$(( (VIMODE_ESCAPE_TIMEOUT + 9) / 10 ))
  (( timeout_cs < 1 )) && timeout_cs=1

  export KEYTIMEOUT=$timeout_cs

  _zsh_tool_log DEBUG "Escape timeout set to ${KEYTIMEOUT}cs (${VIMODE_ESCAPE_TIMEOUT}ms)"
}

# ==============================================================================
# ZLE Widget Registration
# ==============================================================================

# Register ZLE widgets for mode change detection
# Chains to existing widgets to avoid conflicts with other plugins
_vimode_register_widgets() {
  # Save existing zle-line-init if present
  if zle -la | grep -q '^zle-line-init$'; then
    local existing_init=$(zle -lL zle-line-init 2>/dev/null | awk '{print $NF}')
    if [[ -n "$existing_init" && "$existing_init" != "_vimode_line_init" ]]; then
      eval "_vimode_orig_line_init() { $existing_init \"\$@\"; }"
      typeset -g _VIMODE_HAS_ORIG_LINE_INIT=true
    fi
  fi

  # Save existing zle-keymap-select if present
  if zle -la | grep -q '^zle-keymap-select$'; then
    local existing_keymap=$(zle -lL zle-keymap-select 2>/dev/null | awk '{print $NF}')
    if [[ -n "$existing_keymap" && "$existing_keymap" != "_vimode_keymap_select" ]]; then
      eval "_vimode_orig_keymap_select() { $existing_keymap \"\$@\"; }"
      typeset -g _VIMODE_HAS_ORIG_KEYMAP_SELECT=true
    fi
  fi

  # Save existing zle-line-finish if present
  if zle -la | grep -q '^zle-line-finish$'; then
    local existing_finish=$(zle -lL zle-line-finish 2>/dev/null | awk '{print $NF}')
    if [[ -n "$existing_finish" && "$existing_finish" != "_vimode_line_finish" ]]; then
      eval "_vimode_orig_line_finish() { $existing_finish \"\$@\"; }"
      typeset -g _VIMODE_HAS_ORIG_LINE_FINISH=true
    fi
  fi

  # Create ZLE widgets
  zle -N zle-line-init _vimode_line_init
  zle -N zle-keymap-select _vimode_keymap_select
  zle -N zle-line-finish _vimode_line_finish

  _zsh_tool_log DEBUG "Vi-mode ZLE widgets registered"
}

# ==============================================================================
# Prompt Integration Helpers
# ==============================================================================

# Get current mode indicator (for use in prompts)
# Usage: $(vimode_indicator)
vimode_indicator() {
  echo -n "$VIMODE_INDICATOR"
}

# Get mode indicator with color formatting
# Usage: $(vimode_indicator_colored)
vimode_indicator_colored() {
  local color
  case "$VIMODE_CURRENT_MODE" in
    insert)
      color="%F{green}"
      ;;
    normal)
      color="%F{yellow}"
      ;;
    visual)
      color="%F{magenta}"
      ;;
    replace)
      color="%F{red}"
      ;;
    *)
      color="%F{white}"
      ;;
  esac

  echo -n "${color}${VIMODE_INDICATOR}%f"
}

# Example: Add to your prompt
# PROMPT='$(vimode_indicator_colored) %~ $ '
# Or for RPROMPT:
# RPROMPT='$(vimode_indicator)'

# ==============================================================================
# Atuin Integration
# ==============================================================================

# Ensure Ctrl+R works in vi-mode when Atuin is installed
_vimode_setup_atuin_compatibility() {
  # Check if Atuin is installed and initialized
  if ! command -v atuin >/dev/null 2>&1; then
    return 0
  fi

  # Check if atuin-search widget exists
  if ! zle -la | grep -q '^atuin-search$'; then
    _zsh_tool_log DEBUG "Atuin widgets not loaded, skipping compatibility setup"
    return 0
  fi

  _zsh_tool_log DEBUG "Configuring Atuin compatibility for vi-mode..."

  # Bind Ctrl+R in both vi insert and command modes
  bindkey -M viins '^R' atuin-search-viins 2>/dev/null || bindkey -M viins '^R' atuin-search 2>/dev/null
  bindkey -M vicmd '^R' atuin-search-vicmd 2>/dev/null || bindkey -M vicmd '^R' atuin-search 2>/dev/null

  # Also bind Up arrow to atuin if available
  if zle -la | grep -q '^atuin-up-search$'; then
    bindkey -M viins '^[[A' atuin-up-search
    bindkey -M vicmd '^[[A' atuin-up-search
  fi

  _zsh_tool_log DEBUG "Atuin compatibility configured for vi-mode"
}

# ==============================================================================
# Health Check
# ==============================================================================

# Run vi-mode health check
_vimode_health_check() {
  _zsh_tool_log INFO "Running vi-mode health check..."

  local issues=0

  # Check if vi mode is enabled
  if [[ -o vi ]]; then
    _zsh_tool_log INFO "  Vi mode is enabled"
  else
    _zsh_tool_log WARN "  Vi mode is NOT enabled"
    ((issues++))
  fi

  # Check KEYTIMEOUT
  if [[ -n "$KEYTIMEOUT" ]] && (( KEYTIMEOUT <= 20 )); then
    _zsh_tool_log INFO "  KEYTIMEOUT is set to ${KEYTIMEOUT}cs (good)"
  else
    _zsh_tool_log WARN "  KEYTIMEOUT is ${KEYTIMEOUT:-not set}cs (may cause ESC delay)"
    ((issues++))
  fi

  # Check terminal cursor support
  if _vimode_detect_terminal; then
    _zsh_tool_log INFO "  Terminal supports cursor shape changes"
  else
    _zsh_tool_log WARN "  Terminal may not support cursor shape changes"
    ((issues++))
  fi

  # Check ZLE widgets
  if zle -la | grep -q '^zle-keymap-select$'; then
    _zsh_tool_log INFO "  ZLE keymap-select widget is registered"
  else
    _zsh_tool_log WARN "  ZLE keymap-select widget not found"
    ((issues++))
  fi

  # Check mode indicator
  _zsh_tool_log INFO "  Current mode: $VIMODE_CURRENT_MODE"
  _zsh_tool_log INFO "  Mode indicator: $VIMODE_INDICATOR"

  if (( issues > 0 )); then
    _zsh_tool_log WARN "Vi-mode health check found $issues issue(s)"
    return 1
  else
    _zsh_tool_log INFO "Vi-mode health check passed"
    return 0
  fi
}

# ==============================================================================
# Configuration from YAML
# ==============================================================================

# Apply configuration from parsed YAML settings
_vimode_apply_config() {
  local cursor_insert="${1:-beam}"
  local cursor_normal="${2:-block}"
  local escape_timeout="${3:-10}"
  local indicator_insert="${4:-INS}"
  local indicator_normal="${5:-NOR}"

  # Validate cursor shapes
  case "$cursor_insert" in
    beam|block|underline|beam_blink|block_blink|underline_blink) ;;
    *) cursor_insert="beam" ;;
  esac

  case "$cursor_normal" in
    beam|block|underline|beam_blink|block_blink|underline_blink) ;;
    *) cursor_normal="block" ;;
  esac

  # Validate escape timeout (1-100ms)
  if ! [[ "$escape_timeout" =~ ^[0-9]+$ ]] || (( escape_timeout < 1 || escape_timeout > 100 )); then
    escape_timeout=10
  fi

  # Apply configuration
  VIMODE_CURSOR_INSERT="$cursor_insert"
  VIMODE_CURSOR_NORMAL="$cursor_normal"
  VIMODE_ESCAPE_TIMEOUT="$escape_timeout"
  VIMODE_INDICATOR_INSERT="$indicator_insert"
  VIMODE_INDICATOR_NORMAL="$indicator_normal"

  _zsh_tool_log DEBUG "Vi-mode config applied: cursor_insert=$cursor_insert, cursor_normal=$cursor_normal, escape_timeout=${escape_timeout}ms"
}

# ==============================================================================
# Main Installation Flow
# ==============================================================================

# Initialize vi-mode with all features
# Usage: vimode_init [options...]
# Options are parsed from config or can be passed directly
vimode_init() {
  # Guard against double-initialization
  if _vimode_is_enabled; then
    _zsh_tool_log DEBUG "Vi-mode already enabled, skipping initialization"
    return 0
  fi

  _zsh_tool_log INFO "Initializing vi-mode integration..."

  # Enable vi mode
  bindkey -v

  # Set up escape timeout first (affects all key sequences)
  _vimode_setup_escape_timeout

  # Register ZLE widgets for mode detection
  _vimode_register_widgets

  # Set up enhanced keybindings
  _vimode_setup_keybindings

  # Set initial cursor
  _vimode_cursor_insert

  # Set initial mode indicator
  VIMODE_CURRENT_MODE="insert"
  _vimode_update_indicator

  # Set up cursor reset on shell exit (chain to existing trap)
  typeset -g _vimode_orig_exit_trap="$(trap -p EXIT 2>/dev/null | sed "s/trap -- '\\(.*\\)' EXIT/\\1/" | sed "s/trap -- \"\\(.*\\)\" EXIT/\\1/")"
  if [[ -n "$_vimode_orig_exit_trap" ]]; then
    trap '_vimode_cursor_reset; eval "$_vimode_orig_exit_trap"' EXIT
  else
    trap '_vimode_cursor_reset' EXIT
  fi

  # Mark as enabled
  export VIMODE_ENABLED="true"

  _zsh_tool_log INFO "Vi-mode initialization complete"
}

# Main installation flow for vi-mode integration (called by zsh-tool)
vimode_install_integration() {
  local cursor_insert="${1:-beam}"
  local cursor_normal="${2:-block}"
  local escape_timeout="${3:-10}"
  local enable_atuin_compat="${4:-true}"

  _zsh_tool_log INFO "Starting vi-mode integration..."

  # Apply configuration
  _vimode_apply_config "$cursor_insert" "$cursor_normal" "$escape_timeout"

  # Initialize vi-mode
  vimode_init

  # Set up Atuin compatibility if requested and available
  if [[ "$enable_atuin_compat" == "true" ]]; then
    # Defer Atuin compatibility setup to allow Atuin to initialize first
    if type add-zsh-hook >/dev/null 2>&1; then
      _vimode_setup_atuin_compat_deferred() {
        _vimode_setup_atuin_compatibility
        add-zsh-hook -d precmd _vimode_setup_atuin_compat_deferred
      }
      add-zsh-hook precmd _vimode_setup_atuin_compat_deferred
    else
      # Fallback: try immediately
      _vimode_setup_atuin_compatibility
    fi
  fi

  # Update state
  _zsh_tool_update_state "vimode.enabled" "true"
  _zsh_tool_update_state "vimode.cursor_insert" "\"${cursor_insert}\""
  _zsh_tool_update_state "vimode.cursor_normal" "\"${cursor_normal}\""
  _zsh_tool_update_state "vimode.escape_timeout" "${escape_timeout}"

  _zsh_tool_log INFO "Vi-mode integration complete"
  return 0
}

# Alias for consistency with naming convention
alias _vimode_install_integration='vimode_install_integration'
