# Atuin Tab Completion Integration

Enables TAB completion from Atuin's history database using fzf.

## Overview

This integration allows you to use TAB to autocomplete commands from your Atuin shell history. When you type a partial command and press TAB, it queries Atuin's database and presents matches via fzf for selection.

## Requirements

- [Atuin](https://github.com/atuinsh/atuin) - Shell history manager
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder

## Usage

```bash
export ELE<TAB>
```

Opens fzf with matching history entries:

```
┌─ Atuin > ─────────────────────────────────────────────┐
│ export ELEVENLABS_API_KEY=$(op read op://...)         │
│ export EDITOR=vim                                      │
│ export PATH=...                                        │
└────────────────────────────────────────────────────────┘
```

- **Single match**: Auto-selects immediately (`--select-1`)
- **Multiple matches**: Opens fzf for selection
- **No matches**: Falls back to standard completion

## Configuration

Add to `~/.zshrc.local` or source after Atuin initialization:

```zsh
# Minimum characters before triggering Atuin completion (default: 2)
ATUIN_COMPLETE_MIN_CHARS=2
```

## How It Works

1. Widget `_atuin_fzf_complete` is bound to TAB (`^I`)
2. When triggered, queries Atuin: `atuin search --cmd-only --limit 50 --search-mode prefix`
3. Pipes results to fzf for selection
4. Selected command replaces the entire command line

## Integration with Other Tools

### Kiro CLI / Amazon Q Compatibility

If you use Kiro CLI (formerly Amazon Q), the TAB binding may be overridden. The integration uses `zle-line-init` to restore the binding after each prompt:

```zsh
_restore_tab_zle_line_init() {
    if (( $+widgets[_atuin_fzf_complete] )); then
        bindkey '^I' _atuin_fzf_complete
    elif (( $+widgets[fzf-tab-complete] )); then
        bindkey '^I' fzf-tab-complete
    fi
}
```

Priority: `_atuin_fzf_complete` > `fzf-tab-complete` > default

### fzf-tab

This integration takes priority over fzf-tab. If you prefer fzf-tab for certain completions, you can modify the priority in `_restore_tab_zle_line_init`.

## Troubleshooting

### TAB not triggering Atuin completion

1. Check binding: `bindkey '^I'`
2. Verify widget exists: `type _atuin_fzf_complete`
3. Ensure atuin and fzf are in PATH: `command -v atuin fzf`

### No results from Atuin

1. Test directly: `atuin search --cmd-only --limit 5 -- "your query"`
2. Check Atuin database: `atuin stats`

## See Also

- [ATUIN-CTRL-R-FIX.md](./ATUIN-CTRL-R-FIX.md) - Fixing Ctrl+R binding conflicts
- [Atuin Documentation](https://docs.atuin.sh)
