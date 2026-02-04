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
source "${ZSH_TOOL_LIB_DIR}/update/themes.zsh"

# Load restore modules (Epic 2)
source "${ZSH_TOOL_LIB_DIR}/restore/backup-mgmt.zsh"
source "${ZSH_TOOL_LIB_DIR}/restore/restore.zsh"

# Load git integration (Epic 2)
source "${ZSH_TOOL_LIB_DIR}/git/integration.zsh"

# Load integrations (Epic 3)
if [[ -d "${ZSH_TOOL_LIB_DIR}/integrations" ]]; then
  source "${ZSH_TOOL_LIB_DIR}/integrations/atuin.zsh"
  source "${ZSH_TOOL_LIB_DIR}/integrations/kiro-cli.zsh"
fi

# Setup integrations based on config
_zsh_tool_setup_integrations() {
  _zsh_tool_log INFO "Setting up integrations..."

  # Check if Atuin is enabled in config
  local atuin_enabled=$(_zsh_tool_parse_atuin_enabled)
  local kiro_enabled=$(_zsh_tool_parse_kiro_enabled)

  if [[ "$atuin_enabled" == "true" ]]; then
    _zsh_tool_log INFO "Atuin enabled in configuration"

    local import_history=$(_zsh_tool_parse_atuin_import_history)
    local sync_enabled=$(_zsh_tool_parse_atuin_sync_enabled)

    # If Kiro CLI is also enabled, configure compatibility
    local configure_kiro="false"
    if [[ "$kiro_enabled" == "true" ]]; then
      configure_kiro="true"
    fi

    # Install and configure Atuin
    _atuin_install_integration "$import_history" "$configure_kiro" "$sync_enabled"
  else
    _zsh_tool_log DEBUG "Atuin not enabled, skipping"
  fi

  # Check if Kiro CLI is enabled in config
  if [[ "$kiro_enabled" == "true" ]]; then
    _zsh_tool_log INFO "Kiro CLI enabled in configuration"

    local lazy_loading=$(_zsh_tool_parse_kiro_lazy_loading)
    local atuin_compat=$(_zsh_tool_parse_kiro_atuin_compatibility)

    # Install and configure Kiro CLI
    kiro_install_integration "$lazy_loading" "$atuin_compat"
  else
    _zsh_tool_log DEBUG "Kiro CLI not enabled, skipping"
  fi

  return 0
}

# Main install command
zsh-tool-install() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --help|-h)
        cat <<'INSTALL_HELP'
Usage: zsh-tool-install [OPTIONS]

Install and configure zsh-tool with team configuration.

Options:
  --help, -h    Show this help message and exit

What this command does:
  1. Check prerequisites (Homebrew, git, jq, Xcode CLI tools)
  2. Create backup of existing configuration
  3. Install/verify Oh My Zsh
  4. Install team configuration (.zshrc, aliases, etc.)
  5. Install configured plugins
  6. Apply configured theme
  7. Setup personal customization layer
  8. Setup integrations (Atuin, Kiro CLI if enabled)
  9. Verify installation and display summary

Examples:
  zsh-tool-install          Run full installation
  zsh-tool-install --help   Show this help

Related commands:
  zsh-tool-update           Update components
  zsh-tool-backup           Manage backups
  zsh-tool-restore          Restore from backup
  zsh-tool-config           Manage configuration
  zsh-tool-help             Show all commands
INSTALL_HELP
        return 0
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: zsh-tool-install [--help]"
        return 1
        ;;
    esac
  done

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
  # HIGH-4 FIX: Only mark as installed if verification passes
  if ! _zsh_tool_verify_installation; then
    _zsh_tool_log ERROR "Installation verification failed"
    _zsh_tool_update_state "installed" "false"
    _zsh_tool_update_state "verification_failed" "true"
    _zsh_tool_update_state "verification_timestamp" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  INSTALLATION VERIFICATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The installation completed but verification failed."
    echo ""
    echo "Rollback options:"
    echo "  1. Restore from backup: zsh-tool-restore apply <backup-id>"
    echo "  2. List available backups: zsh-tool-restore list"
    echo "  3. Re-run installation: zsh-tool-install"
    echo ""
    echo "Check logs for details: \$ZSH_TOOL_LOG_FILE"
    echo ""

    return 1
  fi

  # Display summary (Story 1.7)
  _zsh_tool_display_summary

  # Update state - mark as installed (only after successful verification)
  _zsh_tool_update_state "installed" "true"
  _zsh_tool_update_state "verification_failed" "false"
  _zsh_tool_update_state "install_timestamp" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""

  return 0
}

# Epic 2 Commands

# Update command (Story 2.2: Bulk Plugin and Theme Updates)
zsh-tool-update() {
  local target="all"
  local check_only=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --help|-h)
        cat <<'UPDATE_HELP'
Usage: zsh-tool-update [OPTIONS] [TARGET]

Update zsh-tool components.

Options:
  --help, -h    Show this help message and exit
  --check       Check for updates without applying them

Targets:
  self          Update zsh-tool itself
  omz           Update Oh My Zsh
  plugins       Update all plugins
  themes        Update all themes
  all           Update everything (default)

Examples:
  zsh-tool-update                 Update all components
  zsh-tool-update --check         Check for updates only
  zsh-tool-update plugins         Update plugins only
  zsh-tool-update --check omz     Check Oh My Zsh for updates
UPDATE_HELP
        return 0
        ;;
      --check)
        check_only=true
        shift
        ;;
      self|omz|plugins|themes|all)
        target=$1
        shift
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: zsh-tool-update [--help] [--check] [self|omz|plugins|themes|all]"
        return 1
        ;;
    esac
  done

  # Check-only mode
  if [[ "$check_only" == "true" ]]; then
    _zsh_tool_log INFO "Checking for updates (no changes will be applied)..."
    echo ""

    local updates_found=false

    case "$target" in
      self)
        if _zsh_tool_check_for_updates >/dev/null 2>&1; then
          _zsh_tool_log INFO "✓ zsh-tool has updates available"
          updates_found=true
        else
          _zsh_tool_log INFO "✓ zsh-tool is up to date"
        fi
        ;;
      omz)
        if _zsh_tool_check_omz_updates; then
          _zsh_tool_log INFO "✓ Oh My Zsh has updates available"
          updates_found=true
        else
          _zsh_tool_log INFO "✓ Oh My Zsh is up to date"
        fi
        ;;
      plugins)
        if _zsh_tool_check_all_plugins; then
          updates_found=true
        fi
        ;;
      themes)
        if _zsh_tool_check_all_themes; then
          updates_found=true
        fi
        ;;
      all)
        # Check all components
        local self_updates=false
        local omz_updates=false
        local plugin_updates=false
        local theme_updates=false

        _zsh_tool_check_for_updates >/dev/null 2>&1 && self_updates=true
        _zsh_tool_check_omz_updates && omz_updates=true
        _zsh_tool_check_all_plugins && plugin_updates=true
        _zsh_tool_check_all_themes && theme_updates=true

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Update Check Summary:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        [[ "$self_updates" == "true" ]] && echo "  • zsh-tool: Updates available" || echo "  • zsh-tool: Up to date"
        [[ "$omz_updates" == "true" ]] && echo "  • Oh My Zsh: Updates available" || echo "  • Oh My Zsh: Up to date"
        [[ "$plugin_updates" == "true" ]] && echo "  • Plugins: Updates available" || echo "  • Plugins: Up to date"
        [[ "$theme_updates" == "true" ]] && echo "  • Themes: Updates available" || echo "  • Themes: Up to date"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        if [[ "$self_updates" == "true" || "$omz_updates" == "true" || "$plugin_updates" == "true" || "$theme_updates" == "true" ]]; then
          echo "Run 'zsh-tool-update all' to apply updates"
          updates_found=true
        else
          echo "Everything is up to date!"
        fi
        ;;
    esac

    echo ""
    [[ "$updates_found" == "true" ]] && return 0 || return 1
  fi

  # Apply updates mode
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
    themes)
      _zsh_tool_create_backup "pre-update" || return 1
      _zsh_tool_update_all_themes
      ;;
    all)
      _zsh_tool_log INFO "Updating all components..."
      echo ""

      # Update self
      _zsh_tool_self_update --check && _zsh_tool_apply_update

      # Create backup before updating OMZ, plugins, and themes
      _zsh_tool_create_backup "pre-update" || return 1

      # Update OMZ
      _zsh_tool_update_omz

      # Update plugins
      _zsh_tool_update_all_plugins

      # Update themes
      _zsh_tool_update_all_themes

      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "✓ All updates complete!"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Reload shell to apply updates: exec zsh"
      echo ""
      ;;
    *)
      echo "Usage: zsh-tool-update [--check] [self|omz|plugins|themes|all]"
      return 1
      ;;
  esac
}

# Backup command (Story 2.3: Configuration Backup Management)
zsh-tool-backup() {
  local subcommand="${1:-create}"
  shift 2>/dev/null || true

  case "$subcommand" in
    --help|-h)
      cat <<'BACKUP_HELP'
Usage: zsh-tool-backup [COMMAND]

Manage zsh configuration backups.

Commands:
  create          Create a manual backup (default)
  list            List all available backups
  status          Show backup status summary
  prune           Prune old backups beyond retention limit
  remote          Push backups to configured remote
  remote-config   Configure remote backup URL
  remote-disable  Disable remote backup sync
  fetch           Fetch backups from remote

Examples:
  zsh-tool-backup                           Create backup
  zsh-tool-backup list                      List all backups
  zsh-tool-backup prune                     Prune old backups
  zsh-tool-backup remote-config git@...     Configure remote
  zsh-tool-backup remote                    Push to remote
BACKUP_HELP
      return 0
      ;;
    create)
      _zsh_tool_create_manual_backup
      ;;
    list)
      _zsh_tool_list_backups
      ;;
    status)
      _zsh_tool_backup_status
      ;;
    prune)
      _zsh_tool_prune_old_backups
      local count=$(_zsh_tool_get_backup_count)
      echo ""
      echo "Backup pruning complete."
      echo "Remaining backups: $count / ${ZSH_TOOL_BACKUP_RETENTION:-10}"
      echo ""
      ;;
    remote)
      _zsh_tool_backup_to_remote
      ;;
    remote-config)
      _zsh_tool_configure_remote_backup "$@"
      ;;
    remote-disable)
      _zsh_tool_disable_remote_backup
      ;;
    fetch)
      _zsh_tool_fetch_remote_backups
      ;;
    *)
      cat <<BACKUP_HELP
Usage: zsh-tool-backup [command]

Commands:
  create          Create a manual backup (default)
  list            List all available backups
  status          Show backup status summary
  prune           Prune old backups beyond retention limit
  remote          Push backups to configured remote
  remote-config   Configure remote backup URL
  remote-disable  Disable remote backup sync
  fetch           Fetch backups from remote

Examples:
  zsh-tool-backup                           # Create backup
  zsh-tool-backup list                      # List all backups
  zsh-tool-backup prune                     # Prune old backups
  zsh-tool-backup remote-config git@...     # Configure remote
  zsh-tool-backup remote                    # Push to remote
BACKUP_HELP
      return 1
      ;;
  esac
}

# Restore command
zsh-tool-restore() {
  local subcommand="$1"
  shift 2>/dev/null || true

  case "$subcommand" in
    --help|-h)
      cat <<'RESTORE_HELP'
Usage: zsh-tool-restore [COMMAND] [ARGS]

Restore zsh configuration from backup.

Commands:
  list              List available backups
  apply <backup-id> Restore from specific backup

Examples:
  zsh-tool-restore list              List all backups
  zsh-tool-restore apply 2026-02-04  Restore from backup
RESTORE_HELP
      return 0
      ;;
    list)
      _zsh_tool_list_backups
      ;;
    apply)
      _zsh_tool_restore_from_backup "$@"
      ;;
    *)
      echo "Usage: zsh-tool-restore [--help] [list|apply <backup-id>]"
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
    --help|-h)
      cat <<'ATUIN_HELP'
Usage: zsh-tool-atuin [COMMAND]

Manage Atuin shell history integration.

Commands:
  install         Install and configure Atuin shell history
  status          Check Atuin installation status (default)
  health          Run Atuin health check
  import          Import existing zsh history
  stats           Show history statistics
  sync-setup      Setup history sync across machines

Examples:
  zsh-tool-atuin              Check status
  zsh-tool-atuin install      Install Atuin
  zsh-tool-atuin import       Import zsh history
  zsh-tool-atuin sync-setup   Setup cross-machine sync

For more info: https://docs.atuin.sh
ATUIN_HELP
      return 0
      ;;
    install)
      _zsh_tool_log INFO "Installing Atuin shell history integration..."
      local import_history=$(_zsh_tool_parse_atuin_import_history)
      local sync_enabled=$(_zsh_tool_parse_atuin_sync_enabled)
      local kiro_enabled=$(_zsh_tool_parse_kiro_enabled)
      local configure_kiro="false"
      if [[ "$kiro_enabled" == "true" ]]; then
        configure_kiro="true"
      fi
      _atuin_install_integration "$import_history" "$configure_kiro" "$sync_enabled"
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

# Kiro CLI integration command
zsh-tool-kiro() {
  local subcommand="${1:-status}"

  case "$subcommand" in
    --help|-h)
      cat <<'KIRO_HELP'
Usage: zsh-tool-kiro [COMMAND]

Manage Kiro CLI integration.

Commands:
  install         Install and configure Kiro CLI
  status          Check Kiro CLI installation status (default)
  health          Run Kiro CLI health check (kiro-cli doctor)
  config-atuin    Configure Atuin compatibility

Examples:
  zsh-tool-kiro              Check status
  zsh-tool-kiro install      Install Kiro CLI
  zsh-tool-kiro health       Run health check

For more info: https://kiro.dev/docs/cli/
KIRO_HELP
      return 0
      ;;
    install)
      _zsh_tool_log INFO "Installing Kiro CLI integration..."
      local lazy_loading=$(_zsh_tool_parse_kiro_lazy_loading)
      local atuin_compat=$(_zsh_tool_parse_kiro_atuin_compatibility)
      kiro_install_integration "$lazy_loading" "$atuin_compat"
      ;;
    status|detect)
      _kiro_detect
      ;;
    health|doctor)
      _kiro_health_check
      ;;
    config-atuin)
      _kiro_configure_atuin_compatibility
      ;;
    *)
      cat <<KIRO_HELP
Usage: zsh-tool-kiro [command]

Commands:
  install         Install and configure Kiro CLI
  status          Check Kiro CLI installation status
  health          Run Kiro CLI health check (kiro-cli doctor)
  config-atuin    Configure Atuin compatibility

For more info: https://kiro.dev/docs/cli/
KIRO_HELP
      ;;
  esac
}

# Config management command
zsh-tool-config() {
  local subcommand="${1:-list}"
  local config_dir="${ZSH_TOOL_CONFIG_DIR:-${HOME}/.config/zsh-tool}"

  case "$subcommand" in
    --help|-h)
      cat <<'CONFIG_HELP'
Usage: zsh-tool-config [COMMAND]

Manage zsh-tool configuration.

Commands:
  list    Display current configuration (default)
  edit    Open configuration in editor

Config location: ~/.config/zsh-tool/config.yaml

Examples:
  zsh-tool-config           Show config
  zsh-tool-config list      Show config
  zsh-tool-config edit      Edit config in $EDITOR
CONFIG_HELP
      return 0
      ;;
    list)
      cat "${config_dir}/config.yaml"
      ;;
    edit)
      "${EDITOR:-vim}" "${config_dir}/config.yaml"
      ;;
    *)
      echo "Usage: zsh-tool-config [--help] [list|edit]"
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
  zsh-tool-update [--check] [target]  Update components
    --check                     Check for updates without applying
    self                        Update zsh-tool itself
    omz                         Update Oh My Zsh
    plugins                     Update all plugins
    themes                      Update all themes
    all                         Update everything (default)

  zsh-tool-backup [action]      Manage backups
    create                      Create manual backup (default)
    list                        List all backups with metadata
    status                      Show backup status summary
    remote                      Push backups to remote
    remote-config <url>         Configure remote backup URL
    remote-disable              Disable remote sync
    fetch                       Fetch backups from remote

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

  zsh-tool-kiro [command]       Kiro CLI integration
    install                     Install and configure Kiro CLI
    status                      Check installation status
    health                      Run health check (kiro-cli doctor)
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
