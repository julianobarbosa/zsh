---
name: zsh-theme
description: Complete Oh My Zsh theme guide covering theme selection, installation, customization, and troubleshooting. Use when choosing themes, comparing built-in vs custom themes, configuring theme settings, fixing font/display issues, or understanding ZSH_THEME configuration.
---

# ZSH Theme Skill

Complete guide to Oh My Zsh themes - selection, installation, and customization.

## Overview

Oh My Zsh themes control your terminal prompt appearance. They can display:
- Current directory path
- Git branch and status
- Exit codes and command timing
- Environment context (Python venv, Node version, K8s cluster)
- User/host information

## Quick Start

### Set a Theme

```zsh
# In ~/.zshrc
ZSH_THEME="robbyrussell"   # Default, minimal
ZSH_THEME="agnoster"        # Powerline-style (needs fonts)
ZSH_THEME="powerlevel10k/powerlevel10k"  # Custom theme

# Apply changes
source ~/.zshrc
# Or restart terminal
```

### With zsh-tool

```bash
# List available themes
zsh-tool-theme list

# Set a theme
zsh-tool-theme set agnoster

# Check current theme
zsh-tool-theme current
```

## Theme Selection Decision Tree

```
START: What's your priority?
│
├─► Maximum Performance
│   └─► Do you need git status?
│       ├─► No  → minimal, clean, dst
│       └─► Yes → powerlevel10k (async git)
│
├─► Visual Appeal
│   └─► Have Powerline/Nerd fonts?
│       ├─► Yes → agnoster, powerlevel10k, bureau
│       └─► No  → robbyrussell, af-magic, ys
│
├─► Information Density
│   └─► How much info do you want?
│       ├─► Minimal    → robbyrussell, minimal, clean
│       ├─► Moderate   → af-magic, bira, ys
│       └─► Everything → powerlevel10k, agnoster
│
└─► Cross-Platform/Team Use
    └─► Need guaranteed compatibility?
        ├─► Yes → robbyrussell (safest default)
        └─► No  → Choose based on features
```

## Recommended Default: `robbyrussell`

For team/cross-platform use, `robbyrussell` is the recommended default:

| Criteria | robbyrussell |
|----------|--------------|
| No special fonts needed | ✅ |
| Works in all terminals | ✅ |
| Fast (no blocking operations) | ✅ |
| Shows git branch | ✅ |
| Maintained by OMZ team | ✅ |
| Familiar to most devs | ✅ |

**For personal machines with Nerd Fonts:** Consider `powerlevel10k` for async git status and instant prompt.

## Built-in Themes Catalog

### Tier 1: Recommended

| Theme | Style | Git Info | Fonts Required | Best For |
|-------|-------|----------|----------------|----------|
| `robbyrussell` | Minimal | Branch only | No | Default, compatibility |
| `af-magic` | Clean | Branch + status | No | Balance of info/simplicity |
| `ys` | Informative | Full status | No | Developers wanting detail |
| `agnoster` | Powerline | Full status | Powerline | Visual appeal |
| `bira` | Two-line | Branch only | No | Long paths |

### Tier 2: Specialized

| Theme | Style | Best For |
|-------|-------|----------|
| `minimal` | Ultra-minimal | Maximum speed, distraction-free |
| `clean` | Simple | Servers, SSH sessions |
| `dst` | Minimal | Fast with basic info |
| `eastwood` | Clean | Simple with user@host |
| `fino` | Elegant | macOS aesthetics |
| `gnzh` | Multiline | Long commands |
| `mh` | Minimal | Fast, hostname focus |
| `dallas` | Colorful | Fun, personal use |

### Tier 3: Full Theme List

Oh My Zsh includes 150+ themes. Browse all:
```bash
ls ~/.oh-my-zsh/themes/
# Or visit: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
```

## Custom Themes

### Powerlevel10k (Recommended Custom)

The most popular custom theme with instant prompt and async git.

**Installation:**
```bash
# Clone to custom themes
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Set in .zshrc
ZSH_THEME="powerlevel10k/powerlevel10k"

# Run configuration wizard
p10k configure
```

**Key Features:**
- Instant prompt (~10ms first prompt)
- Async git status (never blocks)
- Highly configurable via wizard
- Transient prompt option

See [shell-prompt skill](../shell-prompt/SKILL.md) for P10k vs Starship comparison.

### Other Popular Custom Themes

| Theme | Repository | Notes |
|-------|------------|-------|
| Spaceship | spaceship-prompt/spaceship-prompt | Feature-rich, async |
| Pure | sindresorhus/pure | Minimal, async git |
| Bullet Train | caiogondim/bullet-train.zsh | Powerline, segments |

## Theme Configuration

### Basic Settings

```zsh
# ~/.zshrc

# Set theme
ZSH_THEME="your-theme-name"

# Disable auto-update prompts (for custom themes)
DISABLE_AUTO_UPDATE="true"

# Update frequency in days
UPDATE_ZSH_DAYS=13
```

### Theme-Specific Variables

Many themes support configuration via environment variables:

```zsh
# Example: agnoster
DEFAULT_USER="$USER"           # Hide user@host when matching

# Example: ys
YS_VCS_PROMPT_PREFIX=" %{$fg[yellow]%}"

# Most themes check these
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
```

### Customizing Built-in Themes

Copy and modify:
```bash
# Copy theme to custom directory
cp ~/.oh-my-zsh/themes/robbyrussell.zsh-theme \
   ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/mytheme.zsh-theme

# Edit your copy
vim ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/mytheme.zsh-theme

# Use in .zshrc
ZSH_THEME="mytheme"
```

### Creating a Simple Custom Theme

```zsh
# ~/.oh-my-zsh/custom/themes/simple.zsh-theme

# Basic prompt with git
PROMPT='%F{cyan}%~%f $(git_prompt_info)%# '

# Git formatting
ZSH_THEME_GIT_PROMPT_PREFIX="%F{yellow}("
ZSH_THEME_GIT_PROMPT_SUFFIX=")%f "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{red}*%f"
ZSH_THEME_GIT_PROMPT_CLEAN=""
```

## Font Requirements

### Themes Requiring Special Fonts

| Font Type | Themes | Install |
|-----------|--------|---------|
| Powerline | agnoster, bureau | `brew install font-powerline-symbols` |
| Nerd Fonts | powerlevel10k, spaceship | `brew install font-meslo-lg-nerd-font` |
| None | robbyrussell, af-magic, ys, minimal | Works everywhere |

### Installing Nerd Fonts (macOS)

```bash
# Via Homebrew
brew tap homebrew/cask-fonts
brew install font-meslo-lg-nerd-font

# Then configure your terminal to use "MesloLGS NF"
```

### Fallback for Missing Fonts

If you see boxes or weird characters:
```zsh
# Option 1: Switch to safe theme
ZSH_THEME="robbyrussell"

# Option 2: For Powerlevel10k, use ASCII mode
# Run: p10k configure
# Select "Few icons" or "ASCII"
```

## Performance Comparison

| Theme | First Prompt | Per-Command | Git (large repo) |
|-------|--------------|-------------|------------------|
| minimal | <5ms | <5ms | N/A |
| robbyrussell | ~10ms | ~10ms | ~50ms |
| af-magic | ~15ms | ~10ms | ~50ms |
| agnoster | ~20ms | ~15ms | ~100ms |
| powerlevel10k | ~10ms (instant) | ~15ms | Async (0ms block) |

**Note:** Git status is the main performance variable. Large repos (Linux kernel, Chromium) can cause multi-second delays with synchronous themes.

## Troubleshooting

### Theme Not Loading

```bash
# Check theme exists
ls ~/.oh-my-zsh/themes/your-theme.zsh-theme

# Check custom themes
ls ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/

# Verify ZSH_THEME is set before sourcing oh-my-zsh
grep -n "ZSH_THEME\|oh-my-zsh.sh" ~/.zshrc
```

### Broken Characters/Icons

```bash
# Test font rendering
echo "\ue0b0 \ue0b2 \uf113 \uf1d3"

# If boxes appear, install Nerd Fonts or switch theme
ZSH_THEME="robbyrussell"
```

### Slow Prompt

```bash
# Profile startup
time zsh -i -c exit

# Common fixes:
# 1. Disable NVM/RVM auto-detection in theme
# 2. Use async theme (powerlevel10k)
# 3. Disable git status: git config oh-my-zsh.hide-status 1
```

### Theme Conflicts with Plugins

Some plugins modify PROMPT. Load order matters:
```zsh
# Correct order in .zshrc
ZSH_THEME="your-theme"
plugins=(git docker)           # Before sourcing OMZ
source $ZSH/oh-my-zsh.sh       # Loads theme
# Prompt-modifying plugins after this may override theme
```

## Integration with zsh-tool

This repository's `zsh-tool` manages themes via:

```bash
# Configuration in team-config.yaml
theme: "robbyrussell"

# CLI commands
zsh-tool-theme list      # Show available themes
zsh-tool-theme set X     # Set and apply theme
zsh-tool-theme current   # Show current theme
```

The default in `lib/install/themes.zsh` is `robbyrussell` for maximum compatibility.

## References

- [references/theme-selection-guide.md](references/theme-selection-guide.md) - Detailed selection criteria
- [references/theme-customization.md](references/theme-customization.md) - Advanced customization
- [../shell-prompt/SKILL.md](../shell-prompt/SKILL.md) - P10k vs Starship deep dive

## External Links

- Oh My Zsh Themes Wiki: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
- Powerlevel10k: https://github.com/romkatv/powerlevel10k
- Nerd Fonts: https://www.nerdfonts.com/
