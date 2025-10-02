#!/usr/bin/env zsh
# zsh-tool Installation Script

set -e

INSTALL_DIR="${HOME}/.local/bin/zsh-tool"
CONFIG_DIR="${HOME}/.config/zsh-tool"

echo "🚀 zsh-tool Installation"
echo "======================="
echo ""

# Check if zsh
if [[ -z "$ZSH_VERSION" ]]; then
  echo "❌ This script must be run with zsh"
  echo "Run: zsh install.sh"
  exit 1
fi

# Get script directory
SCRIPT_DIR="${0:A:h}"

# Dev mode check (symlinks instead of copies)
DEV_MODE=false
if [[ "$1" == "--dev" ]]; then
  DEV_MODE=true
  echo "📝 Development mode: Using symlinks"
  echo ""
fi

# Create installation directory
echo "📁 Creating installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# Copy or symlink lib files
echo "📦 Installing zsh-tool functions..."
if [[ "$DEV_MODE" == "true" ]]; then
  # Symlink for development
  ln -sf "${SCRIPT_DIR}/lib" "${INSTALL_DIR}/lib"
else
  # Copy for production
  cp -R "${SCRIPT_DIR}/lib/"* "$INSTALL_DIR/"
fi

# Copy templates
echo "📄 Installing templates..."
cp -R "${SCRIPT_DIR}/templates" "${CONFIG_DIR}/"

# Create config.yaml if doesn't exist
if [[ ! -f "${CONFIG_DIR}/config.yaml" ]]; then
  cp "${CONFIG_DIR}/templates/config.yaml" "${CONFIG_DIR}/config.yaml"
  echo "✓ Created config.yaml"
fi

# Create zsh-tool.zsh loader
cat > "${INSTALL_DIR}/zsh-tool.zsh" <<'EOF'
#!/usr/bin/env zsh
# zsh-tool main loader

# Determine installation directory
ZSH_TOOL_INSTALL_DIR="${0:A:h}"

# Check if lib exists (dev mode symlink) or files are directly in install dir
if [[ -d "${ZSH_TOOL_INSTALL_DIR}/lib" ]]; then
  ZSH_TOOL_LIB_DIR="${ZSH_TOOL_INSTALL_DIR}/lib"
else
  ZSH_TOOL_LIB_DIR="${ZSH_TOOL_INSTALL_DIR}"
fi

# Load core utilities
source "${ZSH_TOOL_LIB_DIR}/core/utils.zsh"

# Load installation functions
source "${ZSH_TOOL_LIB_DIR}/install/prerequisites.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/backup.zsh"
# Additional modules loaded on demand

# Main install command
zsh-tool-install() {
  _zsh_tool_log INFO "Starting zsh-tool installation..."

  # Check prerequisites
  _zsh_tool_check_prerequisites || return 1

  # Create backup
  _zsh_tool_create_backup "pre-install" || return 1

  _zsh_tool_log INFO "Installation will continue in future iterations..."
  _zsh_tool_log INFO "Currently implemented: prerequisites check and backup"
}

# Help command
zsh-tool-help() {
  cat <<HELP
zsh-tool - zsh Configuration Management Tool

Available commands:
  zsh-tool-install              Install team configuration
  zsh-tool-config [list|edit]   Manage configuration
  zsh-tool-help                 Show this help message

For more information, see: https://github.com/yourteam/zsh-tool
HELP
}
EOF

chmod +x "${INSTALL_DIR}/zsh-tool.zsh"

# Add source line to .zshrc if not already present
if ! grep -q "zsh-tool.zsh" "${HOME}/.zshrc" 2>/dev/null; then
  echo "" >> "${HOME}/.zshrc"
  echo "# Load zsh-tool" >> "${HOME}/.zshrc"
  echo "[[ -f ~/.local/bin/zsh-tool/zsh-tool.zsh ]] && source ~/.local/bin/zsh-tool/zsh-tool.zsh" >> "${HOME}/.zshrc"
  echo "✓ Added zsh-tool to .zshrc"
else
  echo "✓ zsh-tool already in .zshrc"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Reload your shell: exec zsh"
echo "  2. Run installation: zsh-tool-install"
echo "  3. Get help: zsh-tool-help"
echo ""
echo "Note: This is an MVP implementation with prerequisites and backup functionality."
echo "Additional features (plugins, themes, etc.) will be added in future iterations."
