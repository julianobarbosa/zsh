# Zsh Troubleshooting Guide

Common issues and solutions for zsh configuration and usage.

## Contents
- Startup Issues
- Performance Problems
- Completion Issues
- History Problems
- Display Issues
- Plugin/Framework Issues
- Common Errors

## Startup Issues

### Shell Not Loading .zshrc

**Symptoms:** Aliases, functions, or prompt not working

**Check:**
```zsh
# Verify shell is zsh
echo $SHELL
echo $0

# Check if interactive
[[ -o interactive ]] && echo "Interactive"

# Check file exists and is readable
ls -la ~/.zshrc
```

**Solutions:**
```zsh
# Ensure .zshrc exists
touch ~/.zshrc

# Check for syntax errors
zsh -n ~/.zshrc

# Source manually
source ~/.zshrc
```

### Login vs Interactive Shell Confusion

**Configuration file loading:**

| Shell Type | Files Loaded (in order) |
|------------|------------------------|
| Login + Interactive | .zshenv → .zprofile → .zshrc → .zlogin |
| Non-login Interactive | .zshenv → .zshrc |
| Non-interactive | .zshenv only |
| Login Non-interactive | .zshenv → .zprofile → .zlogin |

**Diagnosis:**
```zsh
# Check shell type
if [[ -o login ]]; then echo "Login shell"; fi
if [[ -o interactive ]]; then echo "Interactive shell"; fi

# Add to each file to trace loading
echo "Loading .zshenv" >> /tmp/zsh-load.log   # in .zshenv
echo "Loading .zshrc" >> /tmp/zsh-load.log    # in .zshrc
```

### Slow Startup

**Diagnosis:**
```zsh
# Time startup
time zsh -i -c exit

# Profile with zprof
zmodload zsh/zprof
# ... rest of .zshrc ...
zprof
```

**Common causes and fixes:**

```zsh
# 1. Slow compinit - use caching
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# 2. nvm is slow - lazy load it
lazy_nvm() {
    unset -f nvm node npm npx
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
}
nvm() { lazy_nvm; nvm "$@"; }
node() { lazy_nvm; node "$@"; }
npm() { lazy_nvm; npm "$@"; }
npx() { lazy_nvm; npx "$@"; }

# 3. pyenv is slow - lazy load
if command -v pyenv &>/dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    path=($PYENV_ROOT/bin $path)
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# 4. Reduce plugins
# Only load plugins you actually use

# 5. Use zinit turbo mode for deferred loading
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting
```

## Performance Problems

### Commands Running Slowly

**Check globbing:**
```zsh
# Glob in wrong directory can be slow
setopt NO_NOMATCH        # Don't error on no match
setopt NULL_GLOB         # Return empty on no match

# Avoid recursive globs in large directories
# Bad: **/*.log (searches everything)
# Good: logs/**/*.log (specific directory)
```

**Check completion:**
```zsh
# Disable slow completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Disable correction if slow
unsetopt CORRECT
unsetopt CORRECT_ALL
```

### High Memory Usage

```zsh
# Reduce history size
HISTSIZE=10000
SAVEHIST=10000

# Clear completion cache
rm -rf ~/.zcompdump* ~/.zsh/cache/*
```

## Completion Issues

### Completions Not Working

```zsh
# Reinitialize completions
rm -f ~/.zcompdump*
autoload -Uz compinit && compinit

# Check fpath
echo $fpath | tr ' ' '\n'

# Ensure completions directory exists
ls -la /usr/share/zsh/site-functions/
ls -la ~/.zsh/completions/
```

### Custom Completions Not Loading

```zsh
# Add to fpath BEFORE compinit
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit

# Check completion file format
# Must start with: #compdef command_name
head -1 ~/.zsh/completions/_mycommand

# Regenerate
unfunction _mycommand 2>/dev/null
autoload -Uz _mycommand
```

### Completion Too Slow

```zsh
# Enable caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
mkdir -p ~/.zsh/cache

# Reduce completers
zstyle ':completion:*' completer _expand _complete

# Limit matches
zstyle ':completion:*' max-matches 1000
```

### Wrong Completion Style

```zsh
# Reset to defaults
zstyle -d ':completion:*'

# Check current styles
zstyle -L ':completion:*'
```

## History Problems

### History Not Saving

```zsh
# Check settings
echo "HISTFILE=$HISTFILE"
echo "HISTSIZE=$HISTSIZE"
echo "SAVEHIST=$SAVEHIST"

# Ensure file is writable
touch $HISTFILE
ls -la $HISTFILE

# Required settings
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
```

### History Not Sharing Between Sessions

```zsh
# Enable shared history
setopt SHARE_HISTORY

# Or use incremental history
setopt INC_APPEND_HISTORY

# Force sync
fc -W  # Write history
fc -R  # Read history
```

### Duplicates in History

```zsh
setopt HIST_IGNORE_DUPS       # No consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicates
setopt HIST_SAVE_NO_DUPS      # Don't save duplicates
setopt HIST_FIND_NO_DUPS      # Don't show duplicates in search
```

### Sensitive Commands in History

```zsh
# Don't save commands starting with space
setopt HIST_IGNORE_SPACE

# Usage: prefix sensitive commands with space
 export API_KEY=secret123    # Note leading space
```

## Display Issues

### Prompt Not Displaying Correctly

```zsh
# Check PROMPT_SUBST is enabled
setopt PROMPT_SUBST

# Escape special characters
PROMPT='%% '              # Literal %
PROMPT='%% '              # Use %% for literal %

# Check for bad escape sequences
echo $PROMPT | cat -v
```

### Colors Not Working

```zsh
# Check terminal support
echo $TERM
tput colors

# Use %F/%f for colors
PROMPT='%F{red}error%f %F{green}ok%f'

# Test colors
for i in {0..255}; do
    print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f "
    ((i % 16 == 15)) && echo
done
```

### Git Info Not Showing in Prompt

```zsh
# Check vcs_info is loaded
autoload -Uz vcs_info
precmd() { vcs_info }

# Configure format
zstyle ':vcs_info:git:*' formats ' (%b)'

# Enable prompt substitution
setopt PROMPT_SUBST

# Use in prompt
PROMPT='%~${vcs_info_msg_0_} %# '
```

### Line Wrapping Issues

```zsh
# Use %{...%} for non-printing sequences
PROMPT='%{$(tput bold)%}text%{$(tput sgr0)%}'

# Or use zsh escape sequences
PROMPT='%B%F{red}text%f%b'

# Check for invisible characters
echo $PROMPT | xxd
```

## Plugin/Framework Issues

### Oh-My-Zsh Slow

```zsh
# Reduce plugins
plugins=(git)  # Only essential ones

# Disable auto-update
DISABLE_AUTO_UPDATE=true

# Use faster theme
ZSH_THEME="robbyrussell"  # Simple, fast

# Or switch to Powerlevel10k with instant prompt
```

### Plugin Not Found

```zsh
# Check plugin location
ls $ZSH/plugins/
ls $ZSH_CUSTOM/plugins/

# Verify plugin is installed
# For oh-my-zsh custom plugins:
git clone https://github.com/user/plugin $ZSH_CUSTOM/plugins/plugin
```

### Zinit Issues

```zsh
# Reinstall zinit
rm -rf ~/.local/share/zinit
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

# Clear zinit cache
rm -rf ~/.local/share/zinit/plugins/*

# Update plugins
zinit update --all
```

## Common Errors

### "command not found: compdef"

```zsh
# compinit not run
autoload -Uz compinit && compinit

# Or run before plugins that need it
```

### "zsh: no matches found"

```zsh
# Glob failed to match
# Either:
setopt NULL_GLOB     # Return empty instead
setopt NO_NOMATCH    # Pass pattern literally

# Or quote the pattern
ls "*.nonexistent"
```

### "bad option: -X"

```zsh
# Incompatible with bash option
# Use zsh equivalent or:
emulate -L zsh       # Reset to zsh defaults
```

### "permission denied"

```zsh
# Check file permissions
ls -la ~/.zshrc

# Fix ownership
chown $USER:$USER ~/.zsh*

# Fix permissions
chmod 644 ~/.zshrc
chmod 700 ~/.zsh
```

### "zsh: corrupt history file"

```zsh
# Backup and rebuild
mv ~/.zsh_history ~/.zsh_history.bad
strings ~/.zsh_history.bad > ~/.zsh_history
```

## Debugging

### Verbose Mode

```zsh
# Trace execution
zsh -x                    # Trace commands
zsh -v                    # Print input lines

# In script
set -x                    # Enable trace
set +x                    # Disable trace
```

### Debug .zshrc

```zsh
# Add timing
SECONDS=0
# ... config ...
echo "Loaded in ${SECONDS}s"

# Add checkpoints
echo "Loading completions..." >&2
autoload -Uz compinit && compinit
echo "Completions loaded" >&2
```

### Check Options

```zsh
# Show all set options
setopt

# Show all unset options
unsetopt

# Check specific option
[[ -o EXTENDED_GLOB ]] && echo "EXTENDED_GLOB is set"
```

### Reset to Defaults

```zsh
# Reset all options
emulate -R zsh

# Start fresh session
env -i HOME=$HOME TERM=$TERM zsh -f
```

## Getting Help

```zsh
# Built-in help
man zsh
man zshall              # All man pages combined
man zshbuiltins         # Built-in commands
man zshcompwid          # Completion widgets
man zshcompsys          # Completion system
man zshoptions          # All options
man zshparam            # Parameters/variables
man zshexpn             # Expansion

# Run help
autoload -Uz run-help
alias help=run-help
help setopt
```
