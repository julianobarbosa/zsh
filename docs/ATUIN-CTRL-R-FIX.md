# Fix: Atuin Ctrl+R Not Working with Amazon Q

**Issue**: When both Atuin and Amazon Q are installed, pressing Ctrl+R only redraws the prompt instead of opening Atuin's history search.

**Root Cause**: Amazon Q's shell integration loads after Atuin and overwrites the Ctrl+R keybinding.

---

## Solution

Add the following code to your `~/.zshrc.local` (or `~/.zshrc`) **after** the Amazon Q post block:

```zsh
# Restore Atuin keybindings after Amazon Q (Amazon Q overrides Ctrl+R)
# This ensures Ctrl+R opens Atuin search instead of just redisplaying the prompt
if command -v atuin &>/dev/null; then
    bindkey -M emacs '^r' atuin-search
    bindkey -M viins '^r' atuin-search-viins
fi
```

### Location in ~/.zshrc.local

The fix should be placed after the Amazon Q post block:

```zsh
# Amazon Q post block
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && \
    builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"

# Restore Atuin keybindings after Amazon Q (Amazon Q overrides Ctrl+R)
# This ensures Ctrl+R opens Atuin search instead of just redisplaying the prompt
if command -v atuin &>/dev/null; then
    bindkey -M emacs '^r' atuin-search
    bindkey -M viins '^r' atuin-search-viins
fi
```

---

## Verification

After adding the fix:

1. **Reload your shell**:
   ```bash
   exec zsh
   ```

2. **Check the keybinding**:
   ```bash
   bindkey | grep '^R'
   ```

   **Expected output**:
   ```
   "^R" atuin-search        # or atuin-search-viins in vi mode
   ```

3. **Test Ctrl+R**:
   - Press `Ctrl+R`
   - You should see Atuin's interactive history search interface
   - NOT just a prompt redraw

---

## Why This Happens

### Load Order Issue

In `~/.zshrc.local`, the load order is:

1. **Amazon Q pre block** (line ~14)
2. **Atuin initialization** (line ~427)
   - Sets: `bindkey '^r' atuin-search`
3. **Amazon Q post block** (line ~613)
   - Overwrites: `bindkey '^r' redisplay`

Amazon Q loads its autosuggestions and keybindings in the post block, which runs after Atuin has already configured Ctrl+R. This overwrites Atuin's binding.

### Why Not Reorder?

**Q: Can we just load Atuin after Amazon Q?**

**A: No**, because:
- Atuin needs to initialize early for proper shell history integration
- Amazon Q's pre/post blocks are designed to wrap around other tools
- Other plugins may depend on the current load order

**The safest solution** is to restore Atuin's keybinding after Amazon Q loads.

---

## Alternative Solutions

### Option 1: Disable Amazon Q Keybindings (Not Recommended)

You could disable Amazon Q entirely, but this defeats the purpose of having both tools.

### Option 2: Use Different Keybinding for Atuin

Configure Atuin to use a different key:

```zsh
# In ~/.zshrc.local, after Atuin init:
bindkey '^f' atuin-search  # Use Ctrl+F instead of Ctrl+R
```

### Option 3: Conditional Loading (Advanced)

Only load Amazon Q OR Atuin based on context:

```zsh
# Example: Load Amazon Q only in specific directories
if [[ "$PWD" == "$HOME/work"* ]]; then
    # Load Amazon Q
else
    # Use Atuin
fi
```

---

## Related Configuration

### Amazon Q Disabled CLIs

The zsh-tool configuration already adds Atuin to Amazon Q's disabled CLIs list:

```yaml
# templates/config.yaml
amazon_q:
  enabled: true
  atuin_compatibility: true
  disabled_clis:
    - atuin  # Prevents Amazon Q from intercepting atuin commands
```

**However**, this only prevents Amazon Q from providing autocomplete for the `atuin` command itself. It does NOT prevent Amazon Q from overriding keybindings.

### Known Issue

This is a known compatibility issue documented in:
- `docs/stories/story-amazon-q-integration.md` (line 96)
- GitHub Issue (Amazon Q): Intercepts arrow keys even with disabled CLIs

---

## Testing

To verify the fix is working:

```bash
# 1. Reload shell
exec zsh

# 2. Type a command
echo "test command"

# 3. Press Ctrl+R
# You should see Atuin's search interface, not a simple redraw

# 4. Search for "test"
# Atuin should find "echo 'test command'"
```

---

## Troubleshooting

### Ctrl+R still not working?

1. **Check if Atuin is installed**:
   ```bash
   command -v atuin
   # Should output: /Users/you/.cargo/bin/atuin
   ```

2. **Check if Atuin initialized**:
   ```bash
   type atuin-search
   # Should output: atuin-search is a shell function
   ```

3. **Check the keybinding**:
   ```bash
   bindkey | grep '^R'
   # Should output: "^R" atuin-search
   ```

4. **Check load order**:
   ```bash
   # Ensure Amazon Q post block loads BEFORE the Atuin restore
   grep -n "Amazon Q post\|Restore Atuin" ~/.zshrc.local
   ```

### Still having issues?

- Ensure the fix is placed **after** the Amazon Q post block
- Check for any other tools that might override Ctrl+R
- Try sourcing `~/.zshrc.local` directly: `source ~/.zshrc.local`
- Check for errors: `zsh -xv ~/.zshrc.local 2>&1 | less`

---

## References

- **Story**: ZSHTOOL-003 (Amazon Q Integration)
- **Known Issue**: Atuin Conflict with Amazon Q (line 96, story-amazon-q-integration.md)
- **Atuin Documentation**: https://github.com/atuinsh/atuin
- **Amazon Q Documentation**: https://docs.aws.amazon.com/amazonq/

---

**Fix Applied**: 2025-10-02
**Tested With**:
- Atuin v18.0.0+
- Amazon Q CLI 1.17.1+
- zsh 5.9+
