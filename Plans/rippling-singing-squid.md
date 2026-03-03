# Fix `gc` function in functions.zsh

## Context

The `gc` function (AI-assisted git commit using kiro-cli) at `~/.zsh/functions.zsh:722-778` crashes when the user selects `[e]` to edit the suggested commit message. The root cause is `read -i` on line 768 — zsh's `read` builtin does not support the `-i` flag (that's a bash-only feature).

Confirmed: `zsh -c 'read "test?Prompt: " -i "default"'` produces `zsh:1: not an identifier: -i`.

The alias conflict with `alias gc="git commit"` (.zshrc line 27) is properly handled by `unalias gc` on line 718, so that's not an issue.

## Fix

**File:** `~/.zsh/functions.zsh` line 768

Replace:
```zsh
read "edited?Edit message: " -i "$msg"
# If read -i not supported, fallback
[[ -z "$edited" ]] && edited="$msg"
```

With:
```zsh
local edited="$msg"
vared -p "Edit message: " edited
```

`vared` is zsh's built-in variable editor — it pre-fills the variable content and lets the user edit inline, which is exactly what the `-i` flag was trying to do.

## Verification

- `zsh -n ~/.zsh/functions.zsh` — no syntax errors
- `source ~/.zsh/functions.zsh && type gc` — confirms function is loaded (not an alias)
