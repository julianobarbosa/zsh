#!/usr/bin/env zsh
# Interactive zsh setup script
# Usage: zsh setup-zsh.zsh

set -e

echo "=== Zsh Setup Script ==="
echo ""

# Create directories
echo "Creating directories..."
mkdir -p ~/.zsh/{completions,functions,cache}
mkdir -p ~/.config/zsh

# Backup existing config
if [[ -f ~/.zshrc ]]; then
    backup=~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    cp ~/.zshrc "$backup"
    echo "Backed up existing .zshrc to $backup"
fi

# Generate .zshrc
cat > ~/.zshrc << 'ZSHRC'
# =============================================================================
# Zsh Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# History Configuration
# -----------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY       # Add timestamps
setopt HIST_EXPIRE_DUPS_FIRST # Remove dups first when trimming
setopt HIST_IGNORE_DUPS       # Don't store consecutive dups
setopt HIST_IGNORE_ALL_DUPS   # Remove older dups
setopt HIST_IGNORE_SPACE      # Don't store commands starting with space
setopt HIST_VERIFY            # Show before executing history expansion
setopt HIST_REDUCE_BLANKS     # Remove extra whitespace
setopt SHARE_HISTORY          # Share across sessions

# -----------------------------------------------------------------------------
# Directory Navigation
# -----------------------------------------------------------------------------
setopt AUTO_CD                # cd by typing directory name
setopt AUTO_PUSHD             # Push dirs to stack
setopt PUSHD_IGNORE_DUPS      # No dups in stack
setopt PUSHD_SILENT           # Don't print stack

# -----------------------------------------------------------------------------
# Globbing and Expansion
# -----------------------------------------------------------------------------
setopt EXTENDED_GLOB          # Enable extended patterns
setopt NULL_GLOB              # Empty on no match (instead of error)
setopt GLOB_DOTS              # Include dotfiles

# -----------------------------------------------------------------------------
# Input/Output
# -----------------------------------------------------------------------------
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive mode
setopt NO_CLOBBER             # Don't overwrite files with >
setopt CORRECT                # Command spelling correction

# -----------------------------------------------------------------------------
# Completion System
# -----------------------------------------------------------------------------
# Load custom completions
fpath=(~/.zsh/completions $fpath)

# Initialize completion with caching
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Completion styles
zstyle ':completion:*' menu select                          # Menu selection
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'        # Case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"    # Colorize
zstyle ':completion:*' use-cache on                         # Enable cache
zstyle ':completion:*' cache-path ~/.zsh/cache             # Cache location

# Group completions
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'

# Process completion
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# -----------------------------------------------------------------------------
# Key Bindings
# -----------------------------------------------------------------------------
bindkey -e                                          # Emacs mode

# History search with current input
bindkey '^[[A' history-search-backward              # Up
bindkey '^[[B' history-search-forward               # Down

# Word movement
bindkey '^[[1;5C' forward-word                      # Ctrl+Right
bindkey '^[[1;5D' backward-word                     # Ctrl+Left

# Home/End
bindkey '^[[H' beginning-of-line                    # Home
bindkey '^[[F' end-of-line                          # End
bindkey '^[[3~' delete-char                         # Delete

# Edit command in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Insert last word
bindkey '^[.' insert-last-word

# -----------------------------------------------------------------------------
# Prompt
# -----------------------------------------------------------------------------
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{green}(%b)%f'
zstyle ':vcs_info:git:*' actionformats ' %F{red}(%b|%a)%f'
setopt PROMPT_SUBST

PROMPT='%F{blue}%~%f${vcs_info_msg_0_} %# '
RPROMPT='%(?..%F{red}[%?]%f)'

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find files by name
ff() {
    find . -type f -iname "*$1*"
}

# Find directories by name
fd() {
    find . -type d -iname "*$1*"
}

# -----------------------------------------------------------------------------
# Local Configuration
# -----------------------------------------------------------------------------
# Load local config if it exists
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# -----------------------------------------------------------------------------
# Custom Completions and Plugins
# Add your custom completions and plugins below
# -----------------------------------------------------------------------------

ZSHRC

echo "Created ~/.zshrc"

# Create local config template
if [[ ! -f ~/.zshrc.local ]]; then
    cat > ~/.zshrc.local << 'LOCAL'
# Local zsh configuration
# This file is sourced at the end of .zshrc
# Add machine-specific settings here

# Example: Custom PATH additions
# path+=(/opt/myapp/bin)

# Example: Override prompt
# PROMPT='%n@%m %~ %# '

# Example: Load secrets (never commit this file!)
# source ~/.secrets.env
LOCAL
    echo "Created ~/.zshrc.local template"
fi

# Create .zshenv for environment variables
if [[ ! -f ~/.zshenv ]]; then
    cat > ~/.zshenv << 'ZSHENV'
# Environment variables
# Loaded for all zsh instances (scripts, interactive, login)

# Editor
export EDITOR=vim
export VISUAL=$EDITOR

# Language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# PATH additions (use path array for easier management)
typeset -U path
path=(
    ~/bin
    ~/.local/bin
    $path
)
export PATH
ZSHENV
    echo "Created ~/.zshenv"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Files created:"
echo "  ~/.zshrc       - Main configuration"
echo "  ~/.zshrc.local - Local/machine-specific settings"
echo "  ~/.zshenv      - Environment variables"
echo ""
echo "Directories created:"
echo "  ~/.zsh/completions - Custom completion files"
echo "  ~/.zsh/functions   - Autoloaded functions"
echo "  ~/.zsh/cache       - Completion cache"
echo ""
echo "Restart your shell or run: source ~/.zshrc"
