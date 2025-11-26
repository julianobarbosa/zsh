# Enable Touch ID for sudo in Terminal with tmux

This guide explains how to configure Touch ID authentication for `sudo` commands in macOS Terminal, including support for tmux sessions.

## Prerequisites

- macOS with Touch ID (MacBook Pro/Air with Touch Bar or M1+ Mac)
- Homebrew installed
- tmux (if using tmux sessions)

## Quick Setup

### Step 1: Enable Touch ID for sudo

macOS provides a template file for local sudo configuration that survives system updates.

```bash
# Copy the template
sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local

# Edit the file
sudo nano /etc/pam.d/sudo_local
```

Uncomment the Touch ID line by removing the `#`:

**Before:**
```
#auth       sufficient     pam_tid.so
```

**After:**
```
auth       sufficient     pam_tid.so
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

### Step 2: Test Touch ID (outside tmux)

```bash
sudo -k && sudo echo "Touch ID works!"
```

You should see a Touch ID prompt instead of a password prompt.

## Enable Touch ID in tmux

By default, Touch ID doesn't work inside tmux sessions because tmux doesn't have access to the local session's PAM authentication context. The `pam-reattach` module fixes this.

### Step 1: Install pam-reattach

```bash
brew install pam-reattach
```

### Step 2: Update sudo_local configuration

```bash
sudo nano /etc/pam.d/sudo_local
```

Add the `pam_reattach.so` line **before** the Touch ID line:

**For Apple Silicon Macs (M1/M2/M3):**
```
# sudo_local: local config file which survives system update and is included for sudo
# uncomment following line to enable Touch ID for sudo
auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
auth       sufficient     pam_tid.so
```

**For Intel Macs:**
```
# sudo_local: local config file which survives system update and is included for sudo
# uncomment following line to enable Touch ID for sudo
auth       optional       /usr/local/lib/pam/pam_reattach.so
auth       sufficient     pam_tid.so
```

### Step 3: Test in tmux

```bash
tmux
sudo -k && sudo echo "Touch ID in tmux works!"
```

## Configuration Reference

### File Locations

| File | Purpose |
|------|---------|
| `/etc/pam.d/sudo_local.template` | macOS template (read-only reference) |
| `/etc/pam.d/sudo_local` | Your custom config (survives updates) |
| `/etc/pam.d/sudo` | System sudo config (don't edit) |

### pam_reattach.so Locations

| Architecture | Path |
|--------------|------|
| Apple Silicon | `/opt/homebrew/lib/pam/pam_reattach.so` |
| Intel | `/usr/local/lib/pam/pam_reattach.so` |

### PAM Directives Explained

| Directive | Meaning |
|-----------|---------|
| `auth` | Authentication module |
| `optional` | Failure doesn't block authentication |
| `sufficient` | Success grants access immediately |
| `pam_reattach.so` | Re-attaches to user session (for tmux) |
| `pam_tid.so` | Touch ID authentication module |

## Troubleshooting

### Touch ID prompt doesn't appear

1. **Check the configuration:**
   ```bash
   sudo cat /etc/pam.d/sudo_local
   ```
   Ensure lines are not commented (no `#` at the start).

2. **Verify pam_reattach.so exists:**
   ```bash
   ls -la /opt/homebrew/lib/pam/pam_reattach.so  # Apple Silicon
   ls -la /usr/local/lib/pam/pam_reattach.so     # Intel
   ```

3. **Check if in tmux/screen/SSH:**
   ```bash
   echo $TERM_PROGRAM
   ```
   - If `tmux`: ensure pam-reattach is configured
   - If SSH: Touch ID won't work (use password or SSH keys)

### Password prompt instead of Touch ID in tmux

Ensure the order in `sudo_local` is correct:
1. `pam_reattach.so` must come **first**
2. `pam_tid.so` must come **second**

### After macOS update, Touch ID stops working

Your `/etc/pam.d/sudo_local` should survive updates. If it doesn't:

```bash
# Check if file still exists
ls -la /etc/pam.d/sudo_local

# If missing, recreate it
sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
sudo nano /etc/pam.d/sudo_local
# Add the pam_reattach and pam_tid lines
```

### Touch ID works outside tmux but not inside

Reinstall pam-reattach:
```bash
brew reinstall pam-reattach
```

Verify the library path matches your architecture in `sudo_local`.

## Validation Commands

```bash
# Check pam-reattach installation
brew list pam-reattach

# Check library exists
ls -la /opt/homebrew/lib/pam/pam_reattach.so

# View current sudo_local config
sudo cat /etc/pam.d/sudo_local

# Test sudo (clears cached credentials first)
sudo -k && sudo whoami
```

## Security Considerations

- Touch ID provides convenient authentication without reducing security
- `pam_reattach.so` is marked as `optional` - if it fails, authentication continues
- `pam_tid.so` is marked as `sufficient` - Touch ID alone grants access
- If Touch ID fails 3 times, fallback to password is available
- Touch ID doesn't work over SSH (by design - no local biometric access)

## References

- [pam-reattach GitHub](https://github.com/fabianishere/pam_reattach)
- [Apple PAM documentation](https://developer.apple.com/documentation/security/password_autofill/)
