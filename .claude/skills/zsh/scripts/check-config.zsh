#!/usr/bin/env zsh
# Check zsh configuration for common issues
# Usage: zsh check-config.zsh

set -e

echo "=== Zsh Configuration Check ==="
echo ""

errors=0
warnings=0

# Color helpers
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

error() { ((errors++)); red "✗ $1"; }
warn() { ((warnings++)); yellow "⚠ $1"; }
ok() { green "✓ $1"; }

# -----------------------------------------------------------------------------
# Check shell
# -----------------------------------------------------------------------------
echo "=== Shell Check ==="
if [[ "$SHELL" == *zsh ]]; then
    ok "Default shell is zsh: $SHELL"
else
    warn "Default shell is not zsh: $SHELL"
fi

zsh_version=$(zsh --version 2>/dev/null | head -1)
ok "Zsh version: $zsh_version"
echo ""

# -----------------------------------------------------------------------------
# Check config files
# -----------------------------------------------------------------------------
echo "=== Configuration Files ==="

for file in ~/.zshenv ~/.zprofile ~/.zshrc ~/.zlogin ~/.zlogout; do
    if [[ -f "$file" ]]; then
        # Check for syntax errors
        if zsh -n "$file" 2>/dev/null; then
            ok "$file exists and has valid syntax"
        else
            error "$file has syntax errors"
        fi
    else
        if [[ "$file" == ~/.zshrc ]]; then
            error "$file is missing (required for interactive shells)"
        else
            echo "  $file not found (optional)"
        fi
    fi
done
echo ""

# -----------------------------------------------------------------------------
# Check .zshrc content
# -----------------------------------------------------------------------------
echo "=== .zshrc Analysis ==="

if [[ -f ~/.zshrc ]]; then
    # Check for compinit
    if grep -q 'compinit' ~/.zshrc; then
        ok "Completion system initialized"
    else
        warn "Completion system not initialized (add 'autoload -Uz compinit && compinit')"
    fi

    # Check for history settings
    if grep -qE 'HISTFILE|HISTSIZE|SAVEHIST' ~/.zshrc; then
        ok "History settings found"
    else
        warn "History settings not configured"
    fi

    # Check for PROMPT_SUBST if using prompt variables
    if grep -qE '\$\{.*\}' ~/.zshrc && grep -q 'PROMPT=' ~/.zshrc; then
        if grep -q 'PROMPT_SUBST' ~/.zshrc; then
            ok "PROMPT_SUBST enabled for dynamic prompts"
        else
            warn "Using variables in PROMPT but PROMPT_SUBST not enabled"
        fi
    fi

    # Check for common slow patterns
    if grep -qE 'source.*nvm\.sh' ~/.zshrc; then
        if ! grep -qE 'lazy.*nvm|nvm\(\)' ~/.zshrc; then
            warn "nvm sourced directly - consider lazy loading for faster startup"
        fi
    fi

    if grep -qE 'eval.*\$\(rbenv' ~/.zshrc; then
        warn "rbenv eval found - consider lazy loading for faster startup"
    fi

    if grep -qE 'eval.*\$\(pyenv' ~/.zshrc; then
        warn "pyenv eval found - consider lazy loading for faster startup"
    fi

    # Check for deprecated oh-my-zsh patterns
    if grep -q 'ZSH_THEME=' ~/.zshrc; then
        ok "Oh-My-Zsh theme configured"
    fi
fi
echo ""

# -----------------------------------------------------------------------------
# Check completion cache
# -----------------------------------------------------------------------------
echo "=== Completion System ==="

if [[ -f ~/.zcompdump ]]; then
    dump_size=$(wc -c < ~/.zcompdump)
    dump_mod=$(stat -f %m ~/.zcompdump 2>/dev/null || stat -c %Y ~/.zcompdump)
    now=$(date +%s)
    age_hours=$(( (now - dump_mod) / 3600 ))

    ok "Completion cache exists (~${dump_size} bytes, ${age_hours}h old)"

    if (( age_hours > 168 )); then  # 7 days
        warn "Completion cache is old - consider running: rm ~/.zcompdump* && compinit"
    fi
else
    warn "No completion cache found"
fi

# Check fpath
echo "  fpath contains ${#fpath[@]} directories"
for dir in $fpath; do
    if [[ ! -d "$dir" ]]; then
        warn "fpath contains non-existent directory: $dir"
    fi
done
echo ""

# -----------------------------------------------------------------------------
# Check history
# -----------------------------------------------------------------------------
echo "=== History ==="

if [[ -n "$HISTFILE" ]]; then
    if [[ -f "$HISTFILE" ]]; then
        hist_lines=$(wc -l < "$HISTFILE")
        hist_size=$(du -h "$HISTFILE" | cut -f1)
        ok "History file: $HISTFILE (${hist_lines} lines, ${hist_size})"

        if [[ -w "$HISTFILE" ]]; then
            ok "History file is writable"
        else
            error "History file is not writable"
        fi
    else
        warn "History file configured but doesn't exist: $HISTFILE"
    fi
else
    warn "HISTFILE not configured"
fi

echo "  HISTSIZE=$HISTSIZE"
echo "  SAVEHIST=$SAVEHIST"

if (( ${HISTSIZE:-0} < 1000 )); then
    warn "HISTSIZE is low ($HISTSIZE) - consider increasing"
fi
echo ""

# -----------------------------------------------------------------------------
# Check important options
# -----------------------------------------------------------------------------
echo "=== Shell Options ==="

# Good options to have
for opt in EXTENDED_HISTORY HIST_IGNORE_DUPS SHARE_HISTORY AUTO_CD; do
    if [[ -o $opt ]]; then
        ok "$opt is enabled"
    else
        echo "  $opt is not enabled (optional)"
    fi
done

# Potentially problematic options
for opt in SH_WORD_SPLIT KSH_ARRAYS; do
    if [[ -o $opt ]]; then
        warn "$opt is enabled (may cause compatibility issues with zsh scripts)"
    fi
done
echo ""

# -----------------------------------------------------------------------------
# Check environment
# -----------------------------------------------------------------------------
echo "=== Environment ==="

if [[ -n "$EDITOR" ]]; then
    ok "EDITOR=$EDITOR"
else
    warn "EDITOR not set"
fi

if [[ -n "$TERM" ]]; then
    ok "TERM=$TERM"
else
    warn "TERM not set"
fi

# Check PATH for duplicates
path_dupes=$(echo "$PATH" | tr ':' '\n' | sort | uniq -d)
if [[ -z "$path_dupes" ]]; then
    ok "PATH has no duplicates"
else
    warn "PATH contains duplicates: $path_dupes"
fi
echo ""

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo "=== Summary ==="
if (( errors > 0 )); then
    red "$errors errors found"
fi
if (( warnings > 0 )); then
    yellow "$warnings warnings found"
fi
if (( errors == 0 && warnings == 0 )); then
    green "No issues found!"
fi
echo ""

# Return non-zero if errors found
exit $errors
