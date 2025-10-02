# Lazy Completion Loading Fix

## Problem

If you encounter these errors in your shell:

```
(eval):1: command not found: _kubectl_lazy_completion
ERROR: The source file /dev/fd/25 doesn't exist.
```

This is caused by incorrect lazy loading of completion functions in your `~/.zshrc.local`.

## Root Cause

The `make_completion_lazy` function may be incorrectly using:

```zsh
zinit snippet <($cmd completion zsh)
```

Process substitutions like `<($cmd completion zsh)` create temporary file descriptors (e.g., `/dev/fd/25`) which cannot be used directly with `zinit snippet`.

## Solution

Update the `make_completion_lazy` function in your `~/.zshrc.local`:

### ❌ Incorrect (causes errors):

```zsh
make_completion_lazy() {
    local cmd=$1
    local completion_func="_${cmd}_lazy_completion"

    eval "
    ${completion_func}() {
        unfunction ${completion_func}
        zinit ice wait\"0\" lucid as\"completion\"
        zinit snippet <($cmd completion zsh)
        return 124
    }
    compdef ${completion_func} ${cmd}
    "
}
```

### ✅ Correct (fixed):

```zsh
make_completion_lazy() {
    local cmd=$1
    local completion_func="_${cmd}_lazy_completion"

    eval "
    ${completion_func}() {
        unfunction ${completion_func}
        source <($cmd completion zsh)
        compinit
    }
    compdef ${completion_func} ${cmd}
    "
}
```

## Key Changes

1. **Removed**: `zinit ice wait\"0\" lucid as\"completion\"`
2. **Removed**: `zinit snippet <($cmd completion zsh)`
3. **Added**: `source <($cmd completion zsh)` - directly source the completion output
4. **Added**: `compinit` - reinitialize completions
5. **Removed**: `return 124` - no longer needed

## Apply the Fix

1. Edit your `~/.zshrc.local`:
   ```bash
   vim ~/.zshrc.local
   ```

2. Find the `make_completion_lazy` function (usually around line 217-230)

3. Replace with the corrected version above

4. Reload your shell:
   ```bash
   exec zsh
   ```

## Verification

After applying the fix, you should no longer see:
- `_kubectl_lazy_completion` errors
- `/dev/fd/25` or similar file descriptor errors

Completions for `kubectl`, `docker`, `helm`, `argocd`, and `eksctl` should work normally.

## Alternative: Remove Lazy Loading

If you prefer, you can completely remove lazy loading and use standard completion:

```zsh
# Remove the make_completion_lazy function and for loop

# Add standard completions instead:
if command -v kubectl &>/dev/null; then
    source <(kubectl completion zsh)
fi

if command -v docker &>/dev/null; then
    source <(docker completion zsh)
fi

# ... repeat for other CLIs
```

Note: This loads completions immediately at startup, which may increase shell startup time slightly.
