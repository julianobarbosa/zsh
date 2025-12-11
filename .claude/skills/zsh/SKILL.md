---
name: zsh
description: Guide for using Zsh (Z shell) - an extended Bourne shell with powerful features for interactive use and scripting. Use when configuring zsh, writing shell scripts, setting up prompts, configuring completions, managing history, working with arrays and parameter expansion, troubleshooting shell issues, or optimizing shell performance.
---

# Zsh Skill

Powerful shell with advanced features for scripting and interactive use.

## Overview

Zsh provides:
- Advanced completion system with programmable completions
- Powerful globbing and parameter expansion
- Extensive customization via options and modules
- Plugin/framework ecosystem (oh-my-zsh, zinit, prezto)
- Vi and Emacs line editing modes
- Spelling correction and approximate completion

## Quick Start

### Installation

```bash
# macOS (usually pre-installed)
brew install zsh

# Linux (Debian/Ubuntu)
sudo apt install zsh

# Linux (Fedora)
sudo dnf install zsh

# Set as default shell
chsh -s $(which zsh)

# Verify
echo $SHELL
zsh --version
```

### Configuration Files (Load Order)

| File | When Loaded | Use Case |
|------|-------------|----------|
| `.zshenv` | Always (every zsh) | Environment vars needed everywhere |
| `.zprofile` | Login shells | Login-time setup (like `.bash_profile`) |
| `.zshrc` | Interactive shells | Aliases, functions, prompt, completions |
| `.zlogin` | Login shells (after .zshrc) | Post-login commands |
| `.zlogout` | Login shell exit | Cleanup on logout |

**Recommended structure**: Put most config in `.zshrc`, environment variables in `.zshenv`.

## Essential Configuration

### Minimal .zshrc

```zsh
# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # Add timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST # Remove duplicates first when trimming
setopt HIST_IGNORE_DUPS       # Don't store duplicates
setopt HIST_IGNORE_SPACE      # Don't store commands starting with space
setopt HIST_VERIFY            # Show before executing history expansion
setopt SHARE_HISTORY          # Share history across sessions

# Directory navigation
setopt AUTO_CD                # cd by typing directory name
setopt AUTO_PUSHD             # Push dirs to stack automatically
setopt PUSHD_IGNORE_DUPS      # No duplicates in dir stack
setopt PUSHD_SILENT           # Don't print stack after pushd/popd

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Key bindings (emacs mode)
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f%F{green}${vcs_info_msg_0_}%f %# '
```

## Shell Options

Most important options (enable with `setopt`, disable with `unsetopt`):

```zsh
# Globbing
setopt EXTENDED_GLOB          # Enable ^, ~, # in globs
setopt NULL_GLOB              # Failed globs return empty (no error)
setopt GLOB_DOTS              # Include dotfiles in globs

# Corrections
setopt CORRECT                # Correct command spelling
setopt CORRECT_ALL            # Correct all arguments

# Safety
setopt NO_CLOBBER             # Don't overwrite files with >
setopt RM_STAR_WAIT           # Wait 10s before rm with *

# Scripting
setopt PIPE_FAIL              # Return rightmost non-zero exit code
setopt ERR_EXIT               # Exit on error (like set -e)
```

See [references/shell-options.md](references/shell-options.md) for complete list.

## Completion System

### Setup

```zsh
# Initialize completion
autoload -Uz compinit && compinit

# Cache completions for faster startup
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
```

### Common Styles

```zsh
# Menu selection with arrow keys
zstyle ':completion:*' menu select

# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Colorize completions using ls colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group completions by type
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'

# Process completion with menu
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
```

See [references/completion-system.md](references/completion-system.md) for full reference.

## Parameter Expansion

### String Operations

```zsh
var="Hello World"

# Length
echo ${#var}                  # 11

# Case modification
echo ${var:u}                 # HELLO WORLD (uppercase)
echo ${var:l}                 # hello world (lowercase)
echo ${(C)var}                # Hello World (capitalize words)

# Substring
echo ${var:0:5}               # Hello (offset:length)
echo ${var:6}                 # World (from offset)

# Search/replace
echo ${var/World/Zsh}         # Hello Zsh (first match)
echo ${var//o/0}              # Hell0 W0rld (all matches)
echo ${var/#Hello/Hi}         # Hi World (anchor start)
echo ${var/%World/Universe}   # Hello Universe (anchor end)
```

### Default Values

```zsh
# Use default if unset or empty
echo ${var:-default}          # Use default
echo ${var:=default}          # Assign and use default

# Error if unset
echo ${var:?error message}    # Exit with message if unset

# Use alternative if set
echo ${var:+alternative}      # Use alternative if var is set
```

See [references/parameter-expansion.md](references/parameter-expansion.md) for full reference.

## Globbing

### Extended Globbing (setopt EXTENDED_GLOB)

```zsh
# Negation
ls ^*.txt                     # Everything except .txt files

# Recursive
ls **/*.py                    # All .py files recursively

# Qualifiers
ls *(.)                       # Regular files only
ls *(/)                       # Directories only
ls *(@)                       # Symlinks only
ls *(m-7)                     # Modified in last 7 days
ls *(Lk+100)                  # Larger than 100KB
ls *(om[1,5])                 # 5 most recent files
ls *(.x)                      # Executable files

# Combining
ls **/*(.m-1)                 # Files modified today, recursively
ls *(om[1])                   # Most recently modified file
```

See [references/globbing.md](references/globbing.md) for full reference.

## Arrays

```zsh
# Indexed arrays
arr=(one two three)
echo $arr[1]                  # one (1-indexed!)
echo $arr[-1]                 # three (negative index)
echo ${arr[@]}                # All elements
echo ${#arr[@]}               # Count: 3

# Array operations
arr+=(four)                   # Append
arr[2]=TWO                    # Modify
arr=(${arr[@]:1})             # Remove first element

# Associative arrays
typeset -A hash
hash=(key1 val1 key2 val2)
hash[key3]=val3
echo ${hash[key1]}            # val1
echo ${(k)hash}               # Keys
echo ${(v)hash}               # Values

# Array flags
echo ${(j:,:)arr}             # Join with comma
echo ${(s:/:)PATH}            # Split on /
echo ${(u)arr}                # Unique elements
echo ${(o)arr}                # Sort ascending
echo ${(O)arr}                # Sort descending
```

## Key Bindings

```zsh
# Set mode
bindkey -e                    # Emacs mode (default)
bindkey -v                    # Vi mode

# Common bindings
bindkey '^R' history-incremental-search-backward
bindkey '^[[A' history-search-backward    # Up arrow
bindkey '^[[B' history-search-forward     # Down arrow
bindkey '^[[1;5C' forward-word            # Ctrl+Right
bindkey '^[[1;5D' backward-word           # Ctrl+Left
bindkey '^[[H' beginning-of-line          # Home
bindkey '^[[F' end-of-line                # End
bindkey '^[[3~' delete-char               # Delete

# Show current bindings
bindkey -L                    # List all bindings
```

See [references/key-bindings.md](references/key-bindings.md) for full reference.

## Functions

```zsh
# Basic function
greet() {
    echo "Hello, ${1:-World}!"
}

# With local variables
mkcd() {
    local dir="$1"
    mkdir -p "$dir" && cd "$dir"
}

# Autoload functions from directory
fpath=(~/.zsh/functions $fpath)
autoload -Uz myfunction

# Anonymous functions
() {
    local temp="only visible here"
    echo $temp
}
```

## Prompt Customization

```zsh
# Basic prompts
PROMPT='%n@%m:%~%# '          # user@host:path$
RPROMPT='%T'                  # Right prompt: time

# Escape sequences
# %n - username     %m - hostname     %~ - current dir
# %# - # or %       %? - exit status  %D - date
# %T - time (24h)   %* - time with seconds

# Colors
PROMPT='%F{red}%n%f@%F{green}%m%f:%F{blue}%~%f%# '

# Git integration
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%~${vcs_info_msg_0_} %# '
```

## Frameworks and Plugin Managers

### Oh-My-Zsh

```bash
# Install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Configure in .zshrc
plugins=(git docker kubectl node npm)
ZSH_THEME="robbyrussell"
source $ZSH/oh-my-zsh.sh
```

### Zinit (Fast Plugin Manager)

```bash
# Install
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

# Usage in .zshrc
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit snippet OMZP::git
```

### Powerlevel10k (Fast Prompt)

```bash
# With zinit
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Run configuration wizard
p10k configure
```

## Performance Optimization

```zsh
# Lazy-load completions
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Profile startup time
zmodload zsh/zprof
# ... rest of config ...
zprof

# Measure startup
time zsh -i -c exit

# Defer slow operations
zsh-defer source slow-plugin.zsh
```

## Troubleshooting

```bash
# Debug startup
zsh -xv                       # Verbose with trace

# Check syntax
zsh -n script.zsh             # Parse without executing

# Check options
setopt                        # Show enabled options
unsetopt                      # Show disabled options

# Reset to defaults
emulate -R zsh                # Reset all options
```

See [references/troubleshooting.md](references/troubleshooting.md) for common issues.

## References

- [references/shell-options.md](references/shell-options.md) - Complete shell options reference
- [references/completion-system.md](references/completion-system.md) - Completion system guide
- [references/parameter-expansion.md](references/parameter-expansion.md) - Parameter expansion reference
- [references/globbing.md](references/globbing.md) - Glob patterns and qualifiers
- [references/key-bindings.md](references/key-bindings.md) - Key binding reference
- [references/troubleshooting.md](references/troubleshooting.md) - Common issues and fixes
- Official docs: https://zsh.sourceforge.io/Doc/
- Wiki: https://zsh.sourceforge.io/
