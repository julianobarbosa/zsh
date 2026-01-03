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

# Load installation modules (Epic 1)
source "${ZSH_TOOL_LIB_DIR}/install/prerequisites.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/backup.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/omz.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/config.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/plugins.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/themes.zsh"
source "${ZSH_TOOL_LIB_DIR}/install/verify.zsh"

# Load update modules (Epic 2)
source "${ZSH_TOOL_LIB_DIR}/update/self.zsh"
source "${ZSH_TOOL_LIB_DIR}/update/omz.zsh"
source "${ZSH_TOOL_LIB_DIR}/update/plugins.zsh"

# Load restore modules (Epic 2)
source "${ZSH_TOOL_LIB_DIR}/restore/backup-mgmt.zsh"
source "${ZSH_TOOL_LIB_DIR}/restore/restore.zsh"

# Load git integration (Epic 2)
source "${ZSH_TOOL_LIB_DIR}/git/integration.zsh"

# Load integrations (Epic 3)
if [[ -d "${ZSH_TOOL_LIB_DIR}/integrations" ]]; then
  source "${ZSH_TOOL_LIB_DIR}/integrations/atuin.zsh"
  source "${ZSH_TOOL_LIB_DIR}/integrations/amazon-q.zsh"
fi

# Setup integrations based on config
_zsh_tool_setup_integrations() {
  _zsh_tool_log INFO "Setting up integrations..."

  # Check if Atuin is enabled in config
  local atuin_enabled=$(_zsh_tool_parse_atuin_enabled)
  local amazonq_enabled=$(_zsh_tool_parse_amazon_q_enabled)

  if [[ "$atuin_enabled" == "true" ]]; then
    _zsh_tool_log INFO "Atuin enabled in configuration"

    local import_history=$(_zsh_tool_parse_atuin_import_history)
    local sync_enabled=$(_zsh_tool_parse_atuin_sync_enabled)

    # If Amazon Q is also enabled, configure compatibility
    local configure_amazonq="false"
    if [[ "$amazonq_enabled" == "true" ]]; then
      configure_amazonq="true"
    fi

    # Install and configure Atuin
    _atuin_install_integration "$import_history" "$configure_amazonq" "$sync_enabled"
  else
    _zsh_tool_log DEBUG "Atuin not enabled, skipping"
  fi

  # Check if Amazon Q is enabled in config
  if [[ "$amazonq_enabled" == "true" ]]; then
    _zsh_tool_log INFO "Amazon Q enabled in configuration"

    local lazy_loading=$(_zsh_tool_parse_amazon_q_lazy_loading)
    local atuin_compat=$(_zsh_tool_parse_amazon_q_atuin_compatibility)

    # Install and configure Amazon Q
    _amazonq_install_integration "$lazy_loading" "$atuin_compat"
  else
    _zsh_tool_log DEBUG "Amazon Q not enabled, skipping"
  fi

  return 0
}

# Main install command
zsh-tool-install() {
  # Record installation start time
  local start_time=$(date +%s)
  local start_iso=$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S%z)

  _zsh_tool_log INFO "Starting zsh-tool installation..."
  echo ""

  # Track installation start in state (Story 1.7)
  _zsh_tool_update_state "installation_start" "\"${start_iso}\""

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

  # Setup integrations (if enabled in config)
  _zsh_tool_setup_integrations

  # Record installation end time (Story 1.7)
  local end_time=$(date +%s)
  local end_iso=$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S%z)
  local duration=$((end_time - start_time))

  # Track installation end and duration in state (Story 1.7)
  _zsh_tool_update_state "installation_end" "\"${end_iso}\""
  _zsh_tool_update_state "installation_duration_seconds" "$duration"

  # Verify installation (Story 1.7)
  _zsh_tool_verify_installation

  # Display summary (Story 1.7)
  _zsh_tool_display_summary

  # Update state - mark as installed
  _zsh_tool_update_state "installed" "true"
  _zsh_tool_update_state "install_timestamp" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  return 0
}

# Epic 2 Commands

# Update command
zsh-tool-update() {
  local target="${1:-all}"

  case "$target" in
    self)
      _zsh_tool_self_update
      ;;
    omz)
      _zsh_tool_create_backup "pre-update" || return 1
      _zsh_tool_update_omz
      ;;
    plugins)
      _zsh_tool_create_backup "pre-update" || return 1
      _zsh_tool_update_all_plugins
      ;;
    all)
      _zsh_tool_log INFO "Updating all components..."
      echo ""

      # Update self
      _zsh_tool_self_update --check && _zsh_tool_apply_update

      # Create backup before updating OMZ and plugins
      _zsh_tool_create_backup "pre-update" || return 1

      # Update OMZ
      _zsh_tool_update_omz

      # Update plugins
      _zsh_tool_update_all_plugins

      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "✓ All updates complete!"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Reload shell to apply updates: exec zsh"
      echo ""
      ;;
    *)
      echo "Usage: zsh-tool-update [self|omz|plugins|all]"
      return 1
      ;;
  esac
}

# Backup command
zsh-tool-backup() {
  local subcommand="${1:-create}"

  case "$subcommand" in
    create)
      _zsh_tool_create_manual_backup
      ;;
    list)
      _zsh_tool_list_backups
      ;;
    remote)
      _zsh_tool_backup_to_remote
      ;;
    *)
      echo "Usage: zsh-tool-backup [create|list|remote]"
      return 1
      ;;
  esac
}

# Restore command
zsh-tool-restore() {
  local subcommand="$1"
  shift

  case "$subcommand" in
    list)
      _zsh_tool_list_backups
      ;;
    apply)
      _zsh_tool_restore_from_backup "$@"
      ;;
    *)
      echo "Usage: zsh-tool-restore [list|apply <backup-id>]"
      return 1
      ;;
  esac
}

# Git integration command
zsh-tool-git() {
  _zsh_tool_git_integration "$@"
}

# Atuin integration command
zsh-tool-atuin() {
  local subcommand="${1:-status}"

  case "$subcommand" in
    install)
      _zsh_tool_log INFO "Installing Atuin shell history integration..."
      local import_history=$(_zsh_tool_parse_atuin_import_history)
      local sync_enabled=$(_zsh_tool_parse_atuin_sync_enabled)
      local amazonq_enabled=$(_zsh_tool_parse_amazon_q_enabled)
      local configure_amazonq="false"
      if [[ "$amazonq_enabled" == "true" ]]; then
        configure_amazonq="true"
      fi
      _atuin_install_integration "$import_history" "$configure_amazonq" "$sync_enabled"
      ;;
    status|detect)
      _atuin_detect
      ;;
    health|doctor)
      _atuin_health_check
      ;;
    import)
      _atuin_import_history
      ;;
    stats)
      if command -v atuin >/dev/null 2>&1; then
        atuin stats
      else
        _zsh_tool_log ERROR "Atuin not installed"
      fi
      ;;
    sync-setup)
      _atuin_setup_sync
      ;;
    *)
      cat <<ATUIN_HELP
Usage: zsh-tool-atuin [command]

Commands:
  install         Install and configure Atuin shell history
  status          Check Atuin installation status
  health          Run Atuin health check
  import          Import existing zsh history
  stats           Show history statistics
  sync-setup      Setup history sync across machines

For more info: https://docs.atuin.sh
ATUIN_HELP
      ;;
  esac
}

# Amazon Q integration command
zsh-tool-amazonq() {
  local subcommand="${1:-status}"

  case "$subcommand" in
    install)
      _zsh_tool_log INFO "Installing Amazon Q CLI integration..."
      local lazy_loading=$(_zsh_tool_parse_amazon_q_lazy_loading)
      local atuin_compat=$(_zsh_tool_parse_amazon_q_atuin_compatibility)
      _amazonq_install_integration "$lazy_loading" "$atuin_compat"
      ;;
    status|detect)
      _amazonq_detect
      ;;
    health|doctor)
      _amazonq_health_check
      ;;
    config-atuin)
      _amazonq_configure_atuin_compatibility
      ;;
    *)
      cat <<AMAZONQ_HELP
Usage: zsh-tool-amazonq [command]

Commands:
  install         Install and configure Amazon Q CLI
  status          Check Amazon Q CLI installation status
  health          Run Amazon Q health check (q doctor)
  config-atuin    Configure Atuin compatibility

For more info: https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html
AMAZONQ_HELP
      ;;
  esac
}

# Config management command
zsh-tool-config() {
  local subcommand="${1:-list}"

  case "$subcommand" in
    list)
      cat "${CONFIG_DIR}/config.yaml"
      ;;
    edit)
      "${EDITOR:-vim}" "${CONFIG_DIR}/config.yaml"
      ;;
    *)
      echo "Usage: zsh-tool-config [list|edit]"
      return 1
      ;;
  esac
}

# Help command
zsh-tool-help() {
  cat <<HELP
zsh-tool - zsh Configuration Management Tool

Epic 1 - Installation & Configuration:
  zsh-tool-install              Install team configuration
  zsh-tool-config [list|edit]   Manage configuration

Epic 2 - Maintenance & Lifecycle:
  zsh-tool-update [target]      Update components
    self                        Update zsh-tool itself
    omz                         Update Oh My Zsh
    plugins                     Update all plugins
    all                         Update everything (default)

  zsh-tool-backup [action]      Manage backups
    create                      Create manual backup (default)
    list                        List all backups
    remote                      Push backup to remote

  zsh-tool-restore [action]     Restore from backup
    list                        List available backups
    apply <id>                  Restore from backup

  zsh-tool-git [command]        Git integration for dotfiles
    init                        Initialize dotfiles repository
    remote <url>                Configure remote URL
    status                      Show dotfiles status
    add <files>                 Add files to version control
    commit <message>            Commit changes
    push                        Push to remote
    pull                        Pull from remote

Epic 3 - Integrations:
  zsh-tool-atuin [command]      Atuin shell history integration
    install                     Install and configure Atuin
    status                      Check installation status
    health                      Run health check
    import                      Import existing zsh history
    stats                       Show history statistics
    sync-setup                  Setup history sync

  zsh-tool-amazonq [command]    Amazon Q CLI integration
    install                     Install and configure Amazon Q
    status                      Check installation status
    health                      Run health check (q doctor)
    config-atuin                Configure Atuin compatibility

Other:
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
echo "Epic 1 - Core Installation & Configuration:"
echo "  ✓ Prerequisites detection and installation"
echo "  ✓ Automatic backups"
echo "  ✓ Oh My Zsh installation"
echo "  ✓ Team configuration management"
echo "  ✓ Plugin installation"
echo "  ✓ Theme selection"
echo "  ✓ Personal customization layer"
echo ""
echo "Epic 2 - Maintenance & Lifecycle Management:"
echo "  ✓ Self-update mechanism"
echo "  ✓ Bulk plugin and theme updates"
echo "  ✓ Configuration backup management"
echo "  ✓ Configuration restore from backup"
echo "  ✓ Git integration for dotfiles"
echo ""
