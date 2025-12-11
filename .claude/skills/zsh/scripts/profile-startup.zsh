#!/usr/bin/env zsh
# Profile zsh startup time and identify slow operations
# Usage: zsh profile-startup.zsh

set -e

echo "=== Zsh Startup Profiling ==="
echo ""

# Basic timing
echo "Basic startup time:"
for i in {1..5}; do
    time zsh -i -c exit 2>&1 | grep real
done

echo ""
echo "Average from 5 runs above"
echo ""

# Check if zprof is available
echo "=== Detailed Profiling ==="
echo ""
echo "Add the following to the START of your ~/.zshrc:"
echo ""
echo '  zmodload zsh/zprof'
echo ""
echo "Add the following to the END of your ~/.zshrc:"
echo ""
echo '  zprof'
echo ""
echo "Then start a new shell to see detailed timing."
echo ""

# Analyze common slow operations
echo "=== Checking Common Slow Operations ==="
echo ""

# Check for nvm
if [[ -d "$HOME/.nvm" ]]; then
    echo "⚠️  nvm detected - consider lazy loading:"
    echo '
# Lazy load nvm
lazy_nvm() {
    unset -f nvm node npm npx
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
}
nvm() { lazy_nvm; nvm "$@"; }
node() { lazy_nvm; node "$@"; }
npm() { lazy_nvm; npm "$@"; }
npx() { lazy_nvm; npx "$@"; }
'
fi

# Check for pyenv
if command -v pyenv &>/dev/null; then
    echo "⚠️  pyenv detected - consider lazy loading"
fi

# Check for rbenv
if command -v rbenv &>/dev/null; then
    echo "⚠️  rbenv detected - consider lazy loading"
fi

# Check compinit cache
if [[ -f ~/.zcompdump ]]; then
    local dump_age=$(( ($(date +%s) - $(stat -f %m ~/.zcompdump 2>/dev/null || stat -c %Y ~/.zcompdump 2>/dev/null)) / 3600 ))
    if (( dump_age > 24 )); then
        echo "ℹ️  Completion cache is ${dump_age}h old - consider adding:"
        echo '
# Cache compinit for 24 hours
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
'
    else
        echo "✓ Completion cache is recent (${dump_age}h old)"
    fi
else
    echo "ℹ️  No completion cache found"
fi

# Check oh-my-zsh
if [[ -n "$ZSH" ]]; then
    echo ""
    echo "⚠️  Oh-My-Zsh detected"
    echo "   Consider reducing plugins or switching to zinit with turbo mode"
fi

echo ""
echo "=== Startup Time Breakdown ==="
echo ""
echo "Run this to see file-by-file loading time:"
echo ""
echo '  zsh -xv 2>&1 | ts -i "%.s" | head -1000'
echo ""
echo "(Requires 'moreutils' package for 'ts' command)"
