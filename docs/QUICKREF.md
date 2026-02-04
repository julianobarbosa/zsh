# ZSH Tool Quick Reference

> Command cheatsheet for daily use

---

## Installation

```bash
# Fresh install
curl -fsSL https://raw.githubusercontent.com/.../install.sh | zsh

# Or clone and run
git clone <repo> ~/.zsh-tool
cd ~/.zsh-tool && ./install.sh

# Minimal install (no plugins)
./install.sh --minimal
```

---

## Daily Commands

### Status & Info
```bash
zsh-tool status              # Show current configuration
zsh-tool verify              # Verify all components working
```

### Updates
```bash
zsh-tool update              # Update everything
zsh-tool update plugins      # Update plugins only
zsh-tool update themes       # Update themes only
zsh-tool self-update         # Update zsh-tool itself
```

### Backups
```bash
zsh-tool backup              # Create backup now
zsh-tool backup list         # List all backups
zsh-tool backup prune        # Keep last 10 backups
zsh-tool backup prune 5      # Keep last 5 backups
```

### Restore
```bash
zsh-tool restore list        # List available backups
zsh-tool restore apply 1     # Restore most recent
zsh-tool restore apply 3     # Restore 3rd most recent
zsh-tool restore apply 2026-02-04-120000  # By timestamp
zsh-tool restore apply 1 --force          # Skip confirmation
```

---

## Git Dotfiles

```bash
# Initialize (one-time)
zsh-tool-git init
zsh-tool-git remote git@github.com:user/dotfiles.git

# After shell reload
exec zsh

# Daily usage (use 'dotfiles' alias)
dotfiles status
dotfiles add .zshrc
dotfiles commit -m "Update zshrc"
dotfiles push
dotfiles pull
```

---

## Integrations

### Atuin (Shell History)
```bash
zsh-tool-atuin setup         # Install and configure
zsh-tool-atuin status        # Check health

# Usage
Ctrl+R                       # Search history (fuzzy)
atuin stats                  # View statistics
atuin sync                   # Sync to server
```

### Kiro CLI (AI Completions)
```bash
zsh-tool-kiro setup          # Install and configure
zsh-tool-kiro status         # Check health

# Usage
kiro "find large files"      # Get AI suggestion
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `~/.config/zsh-tool/config.yaml` | Main configuration |
| `~/.config/zsh-tool/state.json` | Tool state |
| `~/.config/zsh-tool/backups/` | Backup storage |
| `~/.config/zsh-tool/logs/zsh-tool.log` | Log file |
| `~/.zshrc` | Generated zsh config |
| `~/.zshrc.local` | User customizations |
| `~/.dotfiles/` | Bare git repo for dotfiles |

---

## Environment Variables

```bash
# Override defaults
export ZSH_TOOL_CONFIG_DIR="~/.config/zsh-tool"
export ZSH_TOOL_BACKUP_DIR="~/.config/zsh-tool/backups"
export ZSH_TOOL_DEBUG=1           # Enable debug logging
export DOTFILES_REPO="~/.dotfiles" # Git bare repo location
```

---

## Troubleshooting

### Check logs
```bash
tail -f ~/.config/zsh-tool/logs/zsh-tool.log
```

### Verify installation
```bash
zsh-tool verify
```

### Reset to clean state
```bash
# Create backup first!
zsh-tool backup

# Remove tool state
rm -rf ~/.config/zsh-tool/state.json

# Reinstall
./install.sh
```

### Rollback after bad restore
```bash
# Find pre-restore backup
zsh-tool backup list

# Restore to pre-restore state
zsh-tool restore apply <pre-restore-timestamp>
```

---

## Plugin Management

### Built-in Oh My Zsh plugins
Edit `~/.config/zsh-tool/config.yaml`:
```yaml
plugins:
  - git
  - docker
  - kubectl
  - brew
```

### Custom plugins (external)
```yaml
plugins:
  - git
  - zsh-autosuggestions      # Auto-installed
  - zsh-syntax-highlighting  # Auto-installed
```

### Manual plugin install
```bash
cd ~/.oh-my-zsh/custom/plugins
git clone https://github.com/user/plugin.git
# Then add to config.yaml
```

---

## Theme Management

### Set theme
```yaml
# In config.yaml
theme: powerlevel10k
# Or: robbyrussell, agnoster, etc.
```

### Custom theme
```bash
cd ~/.oh-my-zsh/custom/themes
git clone https://github.com/user/theme.git
# Then set: theme: theme-name
```

---

## Keyboard Shortcuts (with Atuin)

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Search history (Atuin fuzzy) |
| `↑` / `↓` | Navigate results |
| `Enter` | Execute selected |
| `Tab` | Edit before execute |
| `Esc` | Cancel search |

---

## Common Workflows

### New Machine Setup
```bash
# 1. Clone dotfiles
git clone --bare git@github.com:user/dotfiles.git ~/.dotfiles

# 2. Checkout
alias dotfiles='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'
dotfiles checkout

# 3. Install zsh-tool
./install.sh

# 4. Reload
exec zsh
```

### Before System Update
```bash
zsh-tool backup                  # Create backup
zsh-tool-git add .zshrc
zsh-tool-git commit -m "Pre-update snapshot"
```

### After Oh My Zsh Update Breaks Things
```bash
zsh-tool backup list             # Find pre-update backup
zsh-tool restore apply 1 --force # Restore immediately
exec zsh
```
