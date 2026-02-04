# ZSH Tool Module Reference

> Complete function inventory for all modules

---

## Core Module

### lib/core/logging.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_log` | `<level> <message>` | Log message with timestamp and level |
| `_zsh_tool_log_debug` | `<message>` | Debug log (when ZSH_TOOL_DEBUG=1) |
| `_zsh_tool_ensure_log_dir` | none | Create log directory if missing |

**Log Levels:** DEBUG, INFO, WARN, ERROR

**Log Format:**
```
[2026-02-04 12:00:00] [INFO] Message here
```

---

### lib/core/state.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_init_state` | none | Initialize state.json with defaults |
| `_zsh_tool_update_state` | `<key> <value>` | Update nested JSON field (dot notation) |
| `_zsh_tool_get_state` | `<key>` | Read state value by dot-notation key |
| `_zsh_tool_state_exists` | none | Check if state file exists |

**Dot Notation Examples:**
```zsh
_zsh_tool_update_state "install.version" "\"1.0.0\""
_zsh_tool_update_state "last_backup.timestamp" "\"2026-02-04T12:00:00Z\""
_zsh_tool_get_state "install.version"  # Returns: 1.0.0
```

---

### lib/core/backup.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_create_backup` | `[tag]` | Create timestamped backup with optional tag |
| `_zsh_tool_backup_file` | `<path>` | Backup individual file to current backup dir |
| `_zsh_tool_backup_exists` | `<id>` | Check if backup ID exists |
| `_zsh_tool_get_latest_backup` | none | Return most recent backup path |

**Backup Structure:**
```
~/.config/zsh-tool/backups/
└── 2026-02-04-120000-tag/
    ├── manifest.json
    ├── .zshrc
    ├── .zsh_history
    ├── .zshrc.local
    └── oh-my-zsh-custom/
        ├── themes/
        └── plugins/
```

---

### lib/core/backup-mgmt.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_list_backups` | none | Display formatted backup list |
| `_zsh_tool_prune_backups` | `[count]` | Remove old backups (default: keep 10) |
| `_zsh_tool_get_backup_size` | `<id>` | Calculate backup size in human-readable format |
| `_zsh_tool_backup_management` | `<subcommand>` | Main dispatcher (list/prune/size) |

**Prune Behavior:**
- Sorts backups by timestamp (newest first)
- Keeps specified count, removes oldest
- Reports space reclaimed

---

### lib/core/verify.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_verify_installation` | none | Run all verification checks |
| `_zsh_tool_verify_omz` | none | Verify Oh My Zsh installation |
| `_zsh_tool_verify_plugins` | none | Check plugin availability |
| `_zsh_tool_verify_themes` | none | Check theme files exist |
| `_zsh_tool_verify_config` | none | Validate configuration files |

**Verification Output:**
```
Verifying installation...
  ✓ Oh My Zsh installed
  ✓ Plugins available (5/5)
  ✓ Theme configured
  ✓ Configuration valid
```

---

### lib/core/prompts.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_prompt_confirm` | `<message>` | Yes/No prompt, returns 0=yes, 1=no |
| `_zsh_tool_prompt_select` | `<options>` | Numbered selection menu |
| `_zsh_tool_prompt_input` | `<prompt> [default]` | Text input with optional default |

**Usage:**
```zsh
if _zsh_tool_prompt_confirm "Continue?"; then
  echo "User said yes"
fi

local choice=$(_zsh_tool_prompt_select "Option A" "Option B" "Option C")
```

---

## Install Module

### lib/install/prerequisites.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_check_prerequisites` | none | Verify all system requirements |
| `_zsh_tool_check_command` | `<cmd>` | Test if command exists in PATH |
| `_zsh_tool_check_zsh_version` | none | Verify zsh >= 5.0 |
| `_zsh_tool_check_git` | none | Verify git available |
| `_zsh_tool_check_curl_or_wget` | none | Verify curl or wget available |

**Return Codes:**
- 0: All prerequisites met
- 1: Missing prerequisites (logged)

---

### lib/install/installers.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_detect_package_manager` | none | Return: brew/apt/yum/pacman/apk/zypper |
| `_zsh_tool_install_package` | `<pkg>` | Install via detected package manager |
| `_zsh_tool_package_installed` | `<pkg>` | Check if package is installed |

**Package Manager Detection Order:**
1. brew (macOS/Linux)
2. apt/apt-get (Debian/Ubuntu)
3. yum/dnf (RHEL/Fedora)
4. pacman (Arch)
5. apk (Alpine)
6. zypper (openSUSE)

---

### lib/install/omz.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_install_omz` | none | Install Oh My Zsh |
| `_zsh_tool_check_omz_installed` | none | Check if OMZ exists |
| `_zsh_tool_setup_omz_custom` | none | Create custom directories |
| `_zsh_tool_install_custom_theme` | `<name> <repo>` | Clone theme to custom/themes |

**Oh My Zsh Paths:**
```
~/.oh-my-zsh/           # Main installation
~/.oh-my-zsh/custom/    # User customizations
  ├── themes/           # Custom themes
  └── plugins/          # Custom plugins
```

---

### lib/install/plugins.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_install_plugins` | `<list>` | Install array of plugins |
| `_zsh_tool_install_plugin` | `<name> <repo>` | Clone single plugin |
| `_zsh_tool_plugin_installed` | `<name>` | Check if plugin directory exists |
| `_zsh_tool_get_plugin_repo` | `<name>` | Get default repo URL for known plugins |

**Known Plugins:**
- zsh-autosuggestions → `zsh-users/zsh-autosuggestions`
- zsh-syntax-highlighting → `zsh-users/zsh-syntax-highlighting`
- zsh-completions → `zsh-users/zsh-completions`
- zsh-history-substring-search → `zsh-users/zsh-history-substring-search`

---

## Update Module

### lib/update/component-manager.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_update_components` | `[type]` | Update all or specific component type |
| `_zsh_tool_update_component` | `<type> <name>` | Update single component |
| `_zsh_tool_parallel_update` | `<items>` | Run updates in parallel |
| `_zsh_tool_collect_update_results` | none | Aggregate parallel job results |

**Component Types:**
- `plugin` - Custom plugins in ~/.oh-my-zsh/custom/plugins/
- `theme` - Custom themes in ~/.oh-my-zsh/custom/themes/
- `omz` - Oh My Zsh core
- `self` - zsh-tool itself

**Parallel Execution:**
```zsh
# Background jobs for each plugin
for plugin in $plugins; do
  _zsh_tool_update_component plugin "$plugin" &
done
wait  # Wait for all to complete
```

---

### lib/update/self-update.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_check_for_updates` | none | Check remote version vs local |
| `_zsh_tool_self_update` | none | Pull latest changes |
| `_zsh_tool_get_local_version` | none | Read VERSION file |
| `_zsh_tool_get_remote_version` | none | Fetch remote VERSION |

**Update Flow:**
1. Compare local/remote VERSION
2. If different, prompt for update
3. Create pre-update backup
4. Git pull in tool directory
5. Verify update success

---

### lib/update/plugins.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_update_plugins` | none | Update all custom plugins |
| `_zsh_tool_update_plugin` | `<name>` | Update single plugin (git pull) |
| `_zsh_tool_get_plugin_list` | none | List installed custom plugins |

---

### lib/update/themes.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_update_themes` | none | Update all custom themes |
| `_zsh_tool_update_theme` | `<name>` | Update single theme (git pull) |
| `_zsh_tool_get_theme_list` | none | List installed custom themes |

---

## Restore Module

### lib/restore/restore.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_restore_from_backup` | `<id> [flags]` | Main restore entry point |
| `_zsh_tool_restore_file` | `<src> <dst>` | Atomic file restore |
| `_zsh_tool_rollback_restore` | `<backup>` | Rollback to pre-restore state |
| `_zsh_tool_verify_restore` | `<backup>` | Verify restoration success |
| `_zsh_tool_parse_manifest` | `<backup_path>` | Read backup manifest.json |
| `_zsh_tool_display_backup_contents` | `<backup_path>` | Show what will be restored |
| `_zsh_tool_restore_partial_stub` | `<files>` | Stub for --files (not implemented) |

**Flags:**
- `--force`, `-f` - Skip confirmation prompt
- `--no-backup` - Internal: skip pre-restore backup (used in rollback)
- `--files <list>` - Partial restore (stub, not implemented)

**Atomic Restore Pattern:**
```zsh
local temp_file="${dest}.tmp.$$"
cp -Rp "$source" "$temp_file"
mv "$temp_file" "$dest"
```

**Return Codes:**
- 0: Success
- 1: General failure
- 2: Permission denied

---

## Git Module

### lib/git/integration.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_git_init_repo` | none | Initialize bare repo at DOTFILES_REPO |
| `_zsh_tool_git_setup_remote` | `<url>` | Configure origin remote |
| `_zsh_tool_git_status` | none | Show dotfiles status |
| `_zsh_tool_git_add` | `<files>` | Add files to dotfiles repo |
| `_zsh_tool_git_commit` | `<message>` | Commit with message |
| `_zsh_tool_git_push` | `[args]` | Push to remote |
| `_zsh_tool_git_pull` | `[args]` | Pull from remote (creates backup first) |
| `_zsh_tool_git_integration` | `<subcommand>` | Main dispatcher |
| `_zsh_tool_create_dotfiles_gitignore` | none | Generate gitignore template |
| `_zsh_tool_check_git_config` | none | Verify git user.name/email set |

**Bare Repository Pattern:**
```zsh
# All git commands use:
git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" <command>

# Alias added to .zshrc.local:
alias dotfiles='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'
```

**Default Gitignore:**
```gitignore
# Sensitive data
.ssh/
.gnupg/
.aws/
.config/gcloud/
*.pem
*.key

# Credentials
.netrc
.gitconfig.local
credentials.json

# Large files
.zsh_history
.cache/
.npm/
.cargo/
node_modules/

# Tool state
.config/zsh-tool/state.json
.config/zsh-tool/backups/
.config/zsh-tool/logs/

# OS files
.DS_Store
.Trash/
```

---

## Integrations Module

### lib/integrations/atuin.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_setup_atuin` | none | Full Atuin installation and config |
| `_zsh_tool_check_atuin_installed` | none | Detection check |
| `_zsh_tool_configure_atuin_toml` | none | Generate config.toml |
| `_zsh_tool_atuin_health_check` | none | Verify Atuin working |
| `_zsh_tool_setup_atuin_keybinding` | none | Configure Ctrl+R binding |
| `_zsh_tool_atuin_integration` | `<subcommand>` | Main dispatcher |

**Atuin Config (~/.config/atuin/config.toml):**
```toml
search_mode = "fuzzy"
style = "compact"
inline_height = 20
show_preview = true
```

**Keybinding Setup:**
```zsh
# In .zshrc.local
bindkey '^R' _atuin_search_widget
```

---

### lib/integrations/kiro-cli.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `_zsh_tool_setup_kiro_cli` | none | Full Kiro CLI setup |
| `_zsh_tool_check_kiro_installed` | none | Detection check |
| `_zsh_tool_configure_kiro` | none | Generate config.yaml |
| `_zsh_tool_kiro_complete` | `<input>` | Request AI completion |
| `_zsh_tool_validate_kiro_input` | `<input>` | Security validation |
| `_zsh_tool_kiro_health_check` | none | Verify Kiro working |
| `_zsh_tool_kiro_integration` | `<subcommand>` | Main dispatcher |

**Security Validation:**
```zsh
_zsh_tool_validate_kiro_input() {
  local input="$1"

  # Length check
  [[ ${#input} -gt 500 ]] && return 1

  # Command injection patterns
  [[ "$input" == *";"* ]] && return 1
  [[ "$input" == *"|"* ]] && return 1
  [[ "$input" == *"&"* ]] && return 1
  [[ "$input" == *'$('* ]] && return 1
  [[ "$input" == *'`'* ]] && return 1

  # Unicode rejection (ASCII only)
  [[ "$input" =~ [^[:ascii:]] ]] && return 1

  return 0
}
```

---

## Main Entry Points

### main.zsh

| Function | Parameters | Description |
|----------|------------|-------------|
| `zsh-tool` | `<command> [args]` | Main CLI entry point |
| `zsh-tool-git` | `<command> [args]` | Git integration entry |
| `zsh-tool-atuin` | `<command> [args]` | Atuin integration entry |
| `zsh-tool-kiro` | `<command> [args]` | Kiro integration entry |
| `zsh-tool-restore` | `<command> [args]` | Restore operations entry |
| `zsh-tool-backup` | `<command> [args]` | Backup operations entry |

**Command Routing:**
```zsh
zsh-tool() {
  case "$1" in
    install)   _zsh_tool_install "${@:2}" ;;
    update)    _zsh_tool_update_components "${@:2}" ;;
    backup)    _zsh_tool_create_backup "${@:2}" ;;
    restore)   _zsh_tool_restore_from_backup "${@:2}" ;;
    verify)    _zsh_tool_verify_installation "${@:2}" ;;
    status)    _zsh_tool_show_status "${@:2}" ;;
    self-update) _zsh_tool_self_update "${@:2}" ;;
    *)         _zsh_tool_show_help ;;
  esac
}
```

---

## Error Handling Conventions

### Return Codes
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Permission denied |
| 3 | Invalid argument |
| 4 | Not found |

### Logging Pattern
```zsh
if ! some_operation; then
  _zsh_tool_log ERROR "Operation failed: $reason"
  return 1
fi
_zsh_tool_log INFO "✓ Operation completed"
```

### State Update Pattern
```zsh
# After successful operation
_zsh_tool_update_state "operation.timestamp" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
_zsh_tool_update_state "operation.result" "\"success\""
```
