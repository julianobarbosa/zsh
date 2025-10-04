# iTerm2 XPC Connection Interruption Fix

## Problem
Terminal windows close unexpectedly when idle in iTerm2, with macOS Console showing:
```
XPC_ERROR_CONNECTION_INTERRUPTED
```

## Root Cause
Conflicting SSH socket configurations and GPG agent causing XPC connection failures between iTerm2 and shell processes.

## Diagnosis
Check macOS Console logs for XPC errors:
```bash
log show --predicate 'process == "iTerm2"' --last 1h | grep -i "error\|crash\|exit"
```

Look for:
- `XPC_ERROR_CONNECTION_INTERRUPTED`
- `nw_connection_copy_protocol_metadata_internal on unconnected nw_connection`

## Solution

### 1. Fix SSH Socket Configuration

**Problem:** Invalid SSH_AUTH_SOCK path causing XPC errors
```bash
# REMOVE THIS:
export SSH_AUTH_SOCK=/System/Library/Services/ssh-keychain.xpc/Contents/MacOS/ssh-keychain.sock
```

**Solution:** Remove the invalid SSH socket configuration from `~/.zshrc.local`

### 2. Disable GPG Agent XPC Integration

**Problem:** GPG agent launching interferes with XPC connections
```bash
# DISABLE THIS:
if command -v gpgconf &>/dev/null; then
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
    gpgconf --launch gpg-agent &>/dev/null
fi
```

**Solution:** Comment out GPG agent configuration:
```bash
# GPG Configuration
export GPG_TTY=$(tty)
# Disabled GPG agent to prevent XPC connection interruptions
# if command -v gpgconf &>/dev/null; then
#     export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
#     gpgconf --launch gpg-agent &>/dev/null
# fi
```

### 3. Disable Shell-GPT Integration (if applicable)

**Problem:** Shell-GPT ZLE integration conflicts with XPC
```bash
# DISABLE THIS:
if command -v sgpt &>/dev/null; then
    _sgpt_zsh() {
        if [[ -n "$BUFFER" ]]; then
            _sgpt_prev_cmd=$BUFFER
            BUFFER+="⌛"
            zle -I && zle redisplay
            BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd")
            zle end-of-line
        fi
    }
    zle -N _sgpt_zsh
    bindkey ^l _sgpt_zsh
fi
```

**Solution:** Comment out Shell-GPT integration:
```bash
# Shell-GPT Integration (disabled to prevent XPC connection issues and keybinding conflicts)
# if command -v sgpt &>/dev/null; then
#     _sgpt_zsh() {
#         if [[ -n "$BUFFER" ]]; then
#             _sgpt_prev_cmd=$BUFFER
#             BUFFER+="⌛"
#             zle -I && zle redisplay
#             BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd")
#             zle end-of-line
#         fi
#     }
#     zle -N _sgpt_zsh
#     bindkey ^l _sgpt_zsh
# fi
```

### 4. Configure iTerm2 Settings

**Preferences → Profiles → Session:**
- Set **"After a session ends"** → **"No action"**
- Set **"Undo can revive a session"** → Increase timeout (e.g., 300 seconds)

**Preferences → General → Closing:**
- Enable **"Confirm 'Quit iTerm2' command"**
- Enable **"Restore windows at startup"**

## Testing
1. Apply the fixes to `~/.zshrc.local`
2. Restart shell: `exec zsh`
3. Leave terminal idle for 10-15 minutes
4. Verify terminal stays open

## Re-enabling Features
After confirming the fix works, re-enable features one at a time:
1. Uncomment one configuration block
2. Test for 10-15 minutes
3. If stable, move to the next feature
4. If terminal closes, that feature is the culprit

## Date
2025-10-04
