# Vi-Mode Integration

Enhanced vi-mode for zsh with cursor shape changes, mode indicators, fast ESC timeout, and comprehensive keybindings.

## Features

- **Cursor Shape Changes**: Different cursor shapes for insert vs normal mode
- **Mode Indicators**: Visual indicator showing current mode (INS/NOR/VIS/REP)
- **Fast ESC Response**: Configurable timeout for responsive mode switching
- **Enhanced Keybindings**: Vim-style navigation with shell conveniences
- **Atuin Compatibility**: Ctrl+R history search works in vi-mode
- **tmux Support**: Cursor shapes work inside tmux sessions

## Quick Start

Enable vi-mode in your `config.yaml`:

```yaml
vimode:
  enabled: true
```

Reload your shell:

```bash
exec zsh
```

## Configuration

Full configuration options in `config.yaml`:

```yaml
vimode:
  enabled: true
  cursor:
    insert: "beam"     # beam, block, underline
    normal: "block"    # beam, block, underline
    visual: "block"    # beam, block, underline
  escape_timeout: 10   # ms (1-100, lower = faster ESC)
  indicators:
    insert: "INS"
    normal: "NOR"
    visual: "VIS"
    replace: "REP"
  atuin_compatibility: true
```

### Cursor Shapes

| Shape | Description | Best For |
|-------|-------------|----------|
| `beam` | Thin vertical line | Insert mode (like most editors) |
| `block` | Solid rectangle | Normal mode (vim-like) |
| `underline` | Horizontal line at bottom | Alternative preference |
| `*_blink` | Blinking variants | `beam_blink`, `block_blink`, `underline_blink` |

### Escape Timeout

The `escape_timeout` setting controls how quickly ESC registers:

- **10ms** (default): Very responsive, good for fast typists
- **20-50ms**: Balance between responsiveness and key sequence detection
- **100ms**: More tolerant of key sequences (e.g., arrow keys)

If you experience issues with escape sequences (like arrow keys not working), try increasing this value.

## Keybindings Reference

### Insert Mode

| Key | Action |
|-----|--------|
| `ESC` | Enter normal mode |
| `Ctrl+A` | Beginning of line |
| `Ctrl+E` | End of line |
| `Ctrl+K` | Kill to end of line |
| `Ctrl+U` | Kill whole line |
| `Ctrl+W` | Delete word backward |
| `Ctrl+Y` | Yank (paste) |
| `Ctrl+P` | Previous history |
| `Ctrl+N` | Next history |
| `Ctrl+R` | Search history (Atuin if available) |

### Normal Mode

| Key | Action |
|-----|--------|
| `i` | Insert before cursor |
| `a` | Insert after cursor |
| `I` | Insert at line beginning |
| `A` | Insert at line end |
| `h/l` | Move left/right |
| `j/k` | Next/previous history (with prefix search) |
| `w/b` | Forward/backward word |
| `0` | Beginning of line |
| `$` | End of line |
| `H` | Beginning of line (alternate) |
| `L` | End of line (alternate) |
| `x` | Delete character |
| `dd` | Delete line |
| `dw` | Delete word |
| `d$` | Delete to end |
| `cc` | Change line |
| `cw` | Change word |
| `yy` | Yank line |
| `Y` | Yank to end of line |
| `p` | Paste after |
| `P` | Paste before |
| `u` | Undo |
| `Ctrl+R` | Redo |
| `/` | Search history backward |
| `?` | Search history forward |
| `v` | Edit command in $EDITOR |

## Prompt Integration

### Adding Mode Indicator to Prompt

Use the provided helper functions in your prompt:

```zsh
# Simple indicator
RPROMPT='$(vimode_indicator)'

# Colored indicator
RPROMPT='$(vimode_indicator_colored)'
```

### Custom Prompt Example

```zsh
# Custom prompt with mode indicator
PROMPT='%F{blue}%~%f $(vimode_indicator_colored) %# '

# Or use the VIMODE_INDICATOR variable directly
PROMPT='%F{blue}%~%f [${VIMODE_INDICATOR}] %# '
```

### Oh My Zsh Theme Integration

If using Oh My Zsh, add to your theme or `.zshrc`:

```zsh
# After Oh My Zsh loads
RPROMPT='$(vimode_indicator_colored) '$RPROMPT
```

## Atuin Integration

When both vi-mode and Atuin are enabled, Ctrl+R automatically works in both insert and normal modes:

- **Insert mode**: `Ctrl+R` opens Atuin search
- **Normal mode**: `Ctrl+R` opens Atuin search

If Atuin is not detected, standard zsh history search is used.

## Troubleshooting

### ESC Key Delay

If pressing ESC feels slow:

1. Decrease `escape_timeout` in config:
   ```yaml
   vimode:
     escape_timeout: 5
   ```

2. Check if other plugins set KEYTIMEOUT:
   ```bash
   echo $KEYTIMEOUT
   ```

### Cursor Not Changing

1. Check terminal support:
   ```bash
   # Should change cursor to block then beam
   echo -e '\e[2 q'  # block
   echo -e '\e[6 q'  # beam
   ```

2. If using tmux, ensure `set -g default-terminal "tmux-256color"` in `.tmux.conf`

3. For iTerm2, enable "Cursor" settings in Preferences > Profiles > Text

### Mode Indicator Not Updating

Ensure your prompt uses single quotes to delay evaluation:

```zsh
# Correct - evaluated each time
RPROMPT='$(vimode_indicator)'

# Wrong - evaluated once at shell start
RPROMPT="$(vimode_indicator)"
```

### Ctrl+R Not Working

1. Check if Atuin is installed: `atuin --version`
2. Ensure atuin shell integration is loaded before vimode
3. Run health check: `vimode_health_check` (if available)

## Health Check

Run the built-in health check:

```zsh
# From zsh-tool
zsh-tool vimode health

# Or directly
_vimode_health_check
```

## Technical Details

### Terminal Support

Vi-mode uses DECSCUSR escape sequences for cursor styling. Supported terminals:
- iTerm2
- Apple Terminal
- VS Code Terminal
- Alacritty
- WezTerm
- Hyper
- Most xterm-compatible terminals
- tmux (via passthrough sequences)

### ZLE Widgets

The integration registers these ZLE widgets:
- `zle-line-init`: Called when starting new command line
- `zle-keymap-select`: Called when keymap changes
- `zle-line-finish`: Called when command is executed

### Environment Variables

| Variable | Description |
|----------|-------------|
| `VIMODE_ENABLED` | Set to "true" when vi-mode is active |
| `VIMODE_CURRENT_MODE` | Current mode: insert, normal, visual, replace |
| `VIMODE_INDICATOR` | Current mode indicator text |
| `KEYTIMEOUT` | ESC timeout in centiseconds |

## See Also

- [Atuin Integration](./ATUIN-CTRL-R-FIX.md) - Atuin shell history
- [Kiro CLI Integration](./KIRO-CLI.md) - AI command completions
- [Configuration Guide](./README.md) - General configuration
