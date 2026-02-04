# ZSH Tool Architecture Documentation

> Generated: 2026-02-04 | Version: 1.0.0

## Overview

ZSH Tool is a modular CLI for managing ZSH shell configurations with Oh My Zsh integration. It provides automated installation, updates, backups, restoration, and dotfiles version control.

---

## Project Structure

```
zsh/
├── install.sh              # Entry point (sources main.zsh)
├── main.zsh                # CLI dispatcher and loader
├── VERSION                 # Semantic version (1.0.0)
├── templates/
│   └── config.yaml         # Default configuration template
├── lib/
│   ├── core/               # Core utilities
│   │   ├── logging.zsh     # Logging with levels (DEBUG/INFO/WARN/ERROR)
│   │   ├── state.zsh       # JSON state management
│   │   ├── backup.zsh      # Backup creation and management
│   │   ├── backup-mgmt.zsh # Backup listing, pruning, rotation
│   │   ├── verify.zsh      # Configuration verification
│   │   └── prompts.zsh     # Interactive prompts (confirm/select)
│   ├── install/            # Installation components
│   │   ├── prerequisites.zsh   # System checks (git, curl, etc.)
│   │   ├── installers.zsh      # Package manager detection
│   │   ├── omz.zsh             # Oh My Zsh installation
│   │   └── plugins.zsh         # Plugin installation
│   ├── update/             # Update management
│   │   ├── component-manager.zsh  # Parallel update orchestration
│   │   ├── self-update.zsh        # Tool self-update mechanism
│   │   ├── plugins.zsh            # Plugin update wrappers
│   │   └── themes.zsh             # Theme update wrappers
│   ├── restore/            # Configuration restoration
│   │   └── restore.zsh     # Atomic restore with rollback
│   ├── git/                # Version control
│   │   └── integration.zsh # Bare repo dotfiles management
│   └── integrations/       # Third-party integrations
│       ├── atuin.zsh       # Atuin shell history
│       └── kiro-cli.zsh    # Kiro AI completions
├── scripts/                # Utility scripts
│   ├── add_screen_recording_permissions.sh
│   └── cleanup-disk.sh
├── tests/                  # Test suite (14 files, 200+ tests)
│   └── *.zsh
└── docs/                   # Documentation
```

---

## Module Architecture

### 1. Core Module (`lib/core/`)

Foundation utilities used by all other modules.

#### logging.zsh
```zsh
# Key Functions:
_zsh_tool_log <LEVEL> <message>    # Log with timestamp
_zsh_tool_log_debug <message>      # Debug level (when ZSH_TOOL_DEBUG=1)

# Log Levels: DEBUG, INFO, WARN, ERROR
# Output: $ZSH_TOOL_LOG_FILE (~/.config/zsh-tool/logs/zsh-tool.log)
```

#### state.zsh
```zsh
# Key Functions:
_zsh_tool_init_state              # Initialize state.json
_zsh_tool_update_state <key> <value>  # Update JSON field
_zsh_tool_get_state <key>         # Read JSON field

# State File: $ZSH_TOOL_STATE_FILE (~/.config/zsh-tool/state.json)
# Format: Nested JSON with dot notation (e.g., "install.timestamp")
```

#### backup.zsh
```zsh
# Key Functions:
_zsh_tool_create_backup [tag]     # Create timestamped backup
_zsh_tool_backup_file <path>      # Backup individual file

# Backup Location: $ZSH_TOOL_BACKUP_DIR (~/.config/zsh-tool/backups/)
# Format: YYYY-MM-DD-HHMMSS[-tag]/
# Contents: .zshrc, .zsh_history, oh-my-zsh-custom/, .zshrc.local, manifest.json
```

#### backup-mgmt.zsh
```zsh
# Key Functions:
_zsh_tool_list_backups            # List available backups
_zsh_tool_prune_backups [count]   # Remove old backups (default: keep 10)
_zsh_tool_get_backup_size <id>    # Calculate backup size
```

#### verify.zsh
```zsh
# Key Functions:
_zsh_tool_verify_installation     # Full verification suite
_zsh_tool_verify_omz             # Check Oh My Zsh
_zsh_tool_verify_plugins         # Check plugin availability
_zsh_tool_verify_themes          # Check theme files
```

#### prompts.zsh
```zsh
# Key Functions:
_zsh_tool_prompt_confirm <msg>    # Yes/No prompt (returns 0/1)
_zsh_tool_prompt_select <opts>    # Numbered selection menu
```

---

### 2. Install Module (`lib/install/`)

Handles initial setup and component installation.

#### prerequisites.zsh
```zsh
# Key Functions:
_zsh_tool_check_prerequisites     # Verify system requirements
_zsh_tool_check_command <cmd>     # Test command availability

# Checks: git, curl/wget, zsh version
```

#### installers.zsh
```zsh
# Key Functions:
_zsh_tool_detect_package_manager  # Detect brew/apt/yum/pacman
_zsh_tool_install_package <pkg>   # Install via detected manager
```

#### omz.zsh
```zsh
# Key Functions:
_zsh_tool_install_omz            # Install Oh My Zsh
_zsh_tool_check_omz_installed    # Check if OMZ exists

# Custom Theme Support: Copies themes to ~/.oh-my-zsh/custom/themes/
```

#### plugins.zsh
```zsh
# Key Functions:
_zsh_tool_install_plugins <list>  # Install plugin list
_zsh_tool_install_plugin <name> <repo>  # Clone single plugin

# Plugin Location: ~/.oh-my-zsh/custom/plugins/
# Supports: zsh-autosuggestions, zsh-syntax-highlighting, etc.
```

---

### 3. Update Module (`lib/update/`)

Manages component updates with parallel execution.

#### component-manager.zsh
```zsh
# Key Functions:
_zsh_tool_update_components       # Orchestrate all updates
_zsh_tool_update_component <type> <name>  # Update single component
_zsh_tool_parallel_update <items>  # Parallel git pull operations

# Update Types: plugin, theme, omz, self
# Parallelization: Background jobs with wait
```

#### self-update.zsh
```zsh
# Key Functions:
_zsh_tool_check_for_updates       # Check remote version
_zsh_tool_self_update             # Pull latest changes

# Version Check: Compares local VERSION with remote
# Update Method: git pull in tool directory
```

---

### 4. Restore Module (`lib/restore/`)

Configuration restoration with safety features.

#### restore.zsh
```zsh
# Key Functions:
_zsh_tool_restore_from_backup <id> [--force]  # Main restore entry
_zsh_tool_restore_file <src> <dst>  # Atomic file restore
_zsh_tool_rollback_restore <backup>  # Rollback on failure
_zsh_tool_verify_restore <backup>    # Verify restoration

# Atomic Operations: Copy to .tmp.$$ then mv
# Safety: Pre-restore backup created automatically
# Rollback: Triggered on any file operation failure
```

---

### 5. Git Module (`lib/git/`)

Dotfiles version control using bare repository pattern.

#### integration.zsh
```zsh
# Key Functions:
_zsh_tool_git_init_repo           # Initialize bare repo at ~/.dotfiles
_zsh_tool_git_setup_remote <url>  # Configure origin
_zsh_tool_git_status/add/commit/push/pull  # Git wrappers

# Bare Repo: ~/.dotfiles (GIT_DIR)
# Work Tree: $HOME
# Alias: dotfiles='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'

# Gitignore Template: Excludes sensitive data (.ssh, .gnupg, .aws, etc.)
```

---

### 6. Integrations Module (`lib/integrations/`)

Third-party tool integrations.

#### atuin.zsh
```zsh
# Key Functions:
_zsh_tool_setup_atuin             # Full Atuin setup
_zsh_tool_check_atuin_installed   # Detection
_zsh_tool_configure_atuin_toml    # Config file setup
_zsh_tool_atuin_health_check      # Verify working state

# Config: ~/.config/atuin/config.toml
# Features: search_mode=fuzzy, style=compact, Ctrl+R keybinding
# Compatibility: Works alongside Kiro CLI
```

#### kiro-cli.zsh
```zsh
# Key Functions:
_zsh_tool_setup_kiro_cli          # Full Kiro setup
_zsh_tool_kiro_complete <input>   # AI completion request
_zsh_tool_validate_kiro_input     # Security validation

# Security: Rejects command injection (;, |, &, $(), backticks)
# Length Limit: 500 characters max
# Unicode: ASCII-only input required
# Config: ~/.kiro-cli/config.yaml
```

---

## Design Patterns

### 1. Function Namespacing
All functions use `_zsh_tool_` prefix to avoid conflicts:
```zsh
_zsh_tool_<module>_<action>
# Examples:
_zsh_tool_log
_zsh_tool_git_init_repo
_zsh_tool_restore_from_backup
```

### 2. State Management
JSON-based state with atomic updates:
```json
{
  "install": {
    "timestamp": "2026-02-04T12:00:00Z",
    "version": "1.0.0"
  },
  "last_backup": {
    "timestamp": "2026-02-04T12:00:00Z",
    "path": "/path/to/backup"
  }
}
```

### 3. Atomic File Operations
All file writes use temp file + move pattern:
```zsh
local temp_file="${dest}.tmp.$$"
cp -Rp "$source" "$temp_file"
mv "$temp_file" "$dest"
```

### 4. Error Handling
Consistent return codes and logging:
```zsh
if [[ $result -ne 0 ]]; then
    _zsh_tool_log ERROR "Operation failed: $details"
    return 1
fi
```

### 5. Configuration Precedence
1. Environment variables (highest)
2. User config (~/.config/zsh-tool/config.yaml)
3. Default config (templates/config.yaml)

---

## CLI Commands

```bash
# Installation
zsh-tool install              # Interactive full install
zsh-tool install --minimal    # Core only, no plugins

# Updates
zsh-tool update               # Update all components
zsh-tool update plugins       # Update plugins only
zsh-tool update themes        # Update themes only
zsh-tool self-update          # Update zsh-tool itself

# Backups
zsh-tool backup               # Create backup
zsh-tool backup list          # List backups
zsh-tool backup prune [n]     # Keep last n backups

# Restore
zsh-tool restore list         # List available backups
zsh-tool restore apply <id>   # Restore from backup
zsh-tool restore apply <id> --force  # Skip confirmation

# Git Integration
zsh-tool-git init             # Initialize dotfiles repo
zsh-tool-git remote <url>     # Set remote URL
zsh-tool-git status/add/commit/push/pull  # Git operations

# Integrations
zsh-tool-atuin setup          # Setup Atuin
zsh-tool-atuin status         # Check Atuin status
zsh-tool-kiro setup           # Setup Kiro CLI

# Verification
zsh-tool verify               # Full system verification
zsh-tool status               # Show configuration status
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_TOOL_CONFIG_DIR` | `~/.config/zsh-tool` | Configuration directory |
| `ZSH_TOOL_BACKUP_DIR` | `~/.config/zsh-tool/backups` | Backup storage |
| `ZSH_TOOL_LOG_FILE` | `~/.config/zsh-tool/logs/zsh-tool.log` | Log file path |
| `ZSH_TOOL_STATE_FILE` | `~/.config/zsh-tool/state.json` | State file path |
| `ZSH_TOOL_DEBUG` | `0` | Enable debug logging |
| `DOTFILES_REPO` | `~/.dotfiles` | Bare git repo location |
| `DOTFILES_GITIGNORE` | `~/.config/zsh-tool/dotfiles.gitignore` | Gitignore template |

---

## Security Considerations

### Input Validation (Kiro CLI)
- Command injection prevention: `;`, `|`, `&`, `$()`, backticks rejected
- Length limits: 500 character maximum
- Character set: ASCII-only (no unicode)

### File Operations
- Atomic writes prevent partial file corruption
- Pre-restore backups enable rollback
- Sensitive paths excluded from dotfiles tracking

### Credentials Protection
Default gitignore excludes:
- `.ssh/`, `.gnupg/`, `.aws/`
- `*.pem`, `*.key`
- `.netrc`, `credentials.json`

---

## Test Coverage

| Test File | Tests | Module Coverage |
|-----------|-------|-----------------|
| test-prerequisites.zsh | 15 | Prerequisites checking |
| test-plugins.zsh | 12 | Plugin installation |
| test-themes.zsh | 10 | Theme management |
| test-backup.zsh | 20 | Backup creation |
| test-backup-mgmt.zsh | 18 | Backup management |
| test-restore.zsh | 25 | Restore operations |
| test-config.zsh | 50+ | Configuration/YAML |
| test-git-integration.zsh | 36 | Git dotfiles |
| test-atuin.zsh | 15 | Atuin integration |
| test-kiro-cli.zsh | 20 | Kiro CLI basic |
| test-kiro-cli-edge-cases.zsh | 28 | Security/edge cases |
| test-verify.zsh | 12 | Verification |
| test-bulk-update.zsh | 15 | Parallel updates |
| test-self-update.zsh | 10 | Self-update |

**Total: 200+ tests**

---

## Dependencies

### Required
- `zsh` >= 5.0
- `git`
- `curl` or `wget`

### Optional
- `jq` (enhanced JSON parsing)
- `atuin` (shell history)
- `kiro-cli` (AI completions)

---

## File Formats

### manifest.json (Backup)
```json
{
  "timestamp": "2026-02-04T12:00:00Z",
  "version": "1.0.0",
  "files": [".zshrc", ".zsh_history", "oh-my-zsh-custom/", ".zshrc.local"],
  "tag": "pre-restore"
}
```

### state.json
```json
{
  "install": {
    "timestamp": "2026-02-04T12:00:00Z",
    "version": "1.0.0"
  },
  "last_backup": {
    "timestamp": "2026-02-04T12:00:00Z",
    "path": "/Users/user/.config/zsh-tool/backups/2026-02-04-120000"
  },
  "git_integration": {
    "enabled": true,
    "repo_type": "bare",
    "repo_path": "/Users/user/.dotfiles"
  }
}
```

### config.yaml
```yaml
plugins:
  - git
  - zsh-autosuggestions
  - zsh-syntax-highlighting

theme: powerlevel10k

integrations:
  atuin:
    enabled: true
    sync: true
  kiro:
    enabled: true
```
