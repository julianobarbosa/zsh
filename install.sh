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

# Load installation modules
source "${ZSH_TOOL_LIB_DIR}/install/prerequisites.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/backup.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/omz.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/config.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/plugins.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/themes.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/verify.zsh"

# Main install command
zsh-tool-install() {
  local start_time=$(date +%s)

  _zsh_tool_log INFO "Starting zsh-tool installation..."
  echo ""

  # Check prerequisites (Story 1.1)
  _zsh_tool_check_prerequisites || return 1

  # Create backup (Story 1.2)
  _zsh_tool_create_backup "pre-install" || return 1

  # Install/verify Oh My Zsh
  _zsh_tool_ensure_omz || return 1

  # Install team configuration (Story 1.3)
  _zsh_tool_install_config || return 1

  # Install plugins (Story 1.4)
  _zsh_tool_install_plugins || return 1

  # Apply theme (Story 1.5)
  _zsh_tool_apply_theme || return 1

  # Setup customization layer (Story 1.6)
  _zsh_tool_setup_custom_layer || return 1

  # Verify installation (Story 1.7)
  _zsh_tool_verify_installation

  # Display summary
  _zsh_tool_display_summary "$start_time"

  # Update state - mark as installed
  _zsh_tool_update_state "installed" "true"
  _zsh_tool_update_state "install_timestamp" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  return 0
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
echo "Epic 1 features available:"
echo "  ✓ Prerequisites detection and installation"
echo "  ✓ Automatic backups"
echo "  ✓ Oh My Zsh installation"
echo "  ✓ Team configuration management"
echo "  ✓ Plugin installation"
echo "  ✓ Theme selection"
echo "  ✓ Personal customization layer"
echo ""
