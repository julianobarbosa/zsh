# zsh Configuration Tool - Solution Architecture

**Author:** Barbosa
**Date:** 2025-10-01
**Project Level:** Level 2 (Small complete system)
**Architecture Style:** Modular monolith (function-based CLI)
**Repository Strategy:** Monorepo

---

## 1. Executive Summary

This document defines the technical architecture for a zsh configuration and maintenance tool targeting macOS development teams. The system automates shell environment setup, standardizes team configurations, and provides lifecycle management through sourced shell functions.

**Core Design Principles:**
- **Function-based interface** - Commands sourced into user's shell environment
- **Oh My Zsh foundation** - Leverage existing plugin/theme ecosystem
- **Idempotent operations** - Safe to run repeatedly
- **Minimal dependencies** - Shell scripts + Homebrew + git
- **XDG-compliant storage** - Configuration in `~/.config/zsh-tool/`

**Key Capabilities:**
- Automated installation with prerequisite detection
- Team-standard configuration management
- Oh My Zsh plugin/theme orchestration
- Backup/restore with git integration
- Self-update mechanism

---

## 2. Technology Stack & Decisions

| Category | Technology | Version | Rationale |
|----------|-----------|---------|-----------|
| **Core Language** | zsh | 5.8+ | Native shell scripting, macOS default since Catalina |
| **Shell Framework** | Oh My Zsh | Latest | Team preference, robust plugin ecosystem |
| **Package Manager** | Homebrew | 4.0+ | macOS standard, dependency installation |
| **Version Control** | git | 2.30+ | Dotfile management, self-update |
| **Testing Framework** | bats-core | 1.10.0 | Bash/zsh test automation, CI-friendly |
| **Linting** | shellcheck | 0.9+ | Static analysis for shell scripts |
| **CI/CD** | GitHub Actions | N/A | Automated testing, release management |

**Rationale Summary:**
- Pure zsh implementation minimizes runtime dependencies
- Oh My Zsh provides battle-tested plugin management
- Homebrew handles complex dependency installation (git, etc.)
- bats-core enables TDD for shell functions
- shellcheck ensures code quality

---

## 3. Repository & Module Architecture

### 3.1 Repository Structure

**Strategy:** Monorepo with modular function organization

**Distribution:** Git clone + install script

**Installation Flow:**
```
1. User clones repository
2. Runs ./install.sh
3. Install script:
   - Copies functions to ~/.local/bin/zsh-tool/
   - Creates ~/.config/zsh-tool/ for state
   - Adds source line to ~/.zshrc
4. User sources ~/.zshrc or opens new terminal
5. Functions available: zsh-tool-install, zsh-tool-update, etc.
```

### 3.2 Module Breakdown

**Core Modules:**
- `core/dispatcher.zsh` - Main entry point, command routing
- `core/utils.zsh` - Logging, prompts, error handling, idempotency
- `core/config.zsh` - Configuration file management

**Epic 1 Modules (Installation & Configuration):**
- `install/prerequisites.zsh` - Homebrew, git, Xcode CLI detection/installation
- `install/backup.zsh` - Pre-installation state preservation
- `install/omz.zsh` - Oh My Zsh installation/verification
- `install/config.zsh` - .zshrc, aliases, exports, PATH setup
- `install/plugins.zsh` - Oh My Zsh plugin management
- `install/themes.zsh` - Oh My Zsh theme management
- `install/verify.zsh` - Post-installation validation

**Epic 2 Modules (Maintenance):**
- `update/self.zsh` - Tool self-update via git pull
- `update/omz.zsh` - Oh My Zsh framework update
- `update/plugins.zsh` - Bulk plugin updates
- `restore/backup-mgmt.zsh` - Backup creation/listing
- `restore/restore.zsh` - Configuration restoration
- `git/integration.zsh` - Dotfile git operations

---

## 4. System Architecture

### 4.1 Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    User's Shell                         │
│  (sources ~/.zshrc with zsh-tool functions)             │
└─────────────────────────────────────────────────────────┘
                          │
                          │ function calls
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Core Dispatcher (dispatcher.zsh)           │
│  Routes: install, update, backup, restore, plugin, etc. │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Install      │  │ Update       │  │ Restore      │
│ Modules      │  │ Modules      │  │ Modules      │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┴─────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────────┐
        │    Shared Utilities (utils.zsh)     │
        │  - Logging, prompts, error handling │
        │  - Idempotency checks               │
        │  - File operations                  │
        └─────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Oh My Zsh    │  │ Homebrew     │  │ git          │
│ Framework    │  │ Package Mgr  │  │ VCS          │
└──────────────┘  └──────────────┘  └──────────────┘
```

### 4.2 Execution Flow Example: `zsh-tool-install`

```
1. User runs: zsh-tool-install
2. Dispatcher validates command
3. Prerequisites module:
   - Check Homebrew → install if missing
   - Check git → install via Homebrew if missing
   - Check Xcode CLI tools → prompt user if missing
4. Backup module:
   - Snapshot current .zshrc, .zsh_history, etc.
   - Store in ~/.config/zsh-tool/backups/YYYY-MM-DD-HHMMSS/
5. Oh My Zsh module:
   - Check ~/.oh-my-zsh → install if missing
   - Verify installation integrity
6. Config module:
   - Generate team .zshrc from templates
   - Merge with personal customizations (if .zshrc.local exists)
   - Set up aliases, exports, PATH
7. Plugins module:
   - Read plugin list from config
   - Install each via Oh My Zsh plugin manager
8. Theme module:
   - Install default theme
   - Apply to .zshrc
9. Verify module:
   - Check all components loaded
   - Display summary
   - Prompt user to reload shell
```

---

## 5. Data Architecture

### 5.1 Configuration Files

**Primary Configuration:** `~/.config/zsh-tool/config.yaml`

```yaml
version: "1.0"
team_config_repo: "https://github.com/yourteam/zsh-config.git"

plugins:
  - zsh-syntax-highlighting
  - zsh-autosuggestions
  - git
  - docker
  - kubectl

themes:
  default: "robbyrussell"
  available:
    - robbyrussell
    - agnoster
    - powerlevel10k

aliases:
  - name: "gs"
    command: "git status"
  - name: "gp"
    command: "git pull"

exports:
  - name: "EDITOR"
    value: "vim"

paths:
  prepend:
    - "$HOME/.local/bin"
    - "$HOME/bin"
```

**State Files:**
- `~/.config/zsh-tool/state.json` - Installation status, versions
- `~/.config/zsh-tool/backups/` - Timestamped backup directories
- `~/.config/zsh-tool/last-update` - Update check timestamp

### 5.2 Backup Structure

```
~/.config/zsh-tool/backups/
├── 2025-10-01-120000/
│   ├── .zshrc
│   ├── .zsh_history
│   ├── .oh-my-zsh/custom/ (if exists)
│   └── manifest.json (metadata)
├── 2025-10-15-093000/
│   └── ...
```

**Manifest Format:**
```json
{
  "timestamp": "2025-10-01T12:00:00Z",
  "trigger": "pre-install",
  "files": [".zshrc", ".zsh_history"],
  "omz_version": "master-abc123",
  "tool_version": "1.0.0"
}
```

### 5.3 Team Configuration Repository

**Structure:**
```
team-zsh-config/
├── config.yaml (canonical team config)
├── templates/
│   ├── zshrc.template
│   ├── aliases.zsh
│   └── exports.zsh
├── plugins/ (custom team plugins)
└── README.md
```

**Update Flow:**
1. Tool fetches config.yaml from team repo
2. Merges with local ~/.config/zsh-tool/config.yaml
3. User customizations preserved via .zshrc.local

---

## 6. Function Interface Design

### 6.1 Public Functions (User-Facing)

All functions prefixed with `zsh-tool-` to avoid naming conflicts.

**Installation:**
```zsh
zsh-tool-install [--force] [--no-backup]
# Installs team configuration
# --force: Overwrite existing without prompts
# --no-backup: Skip backup step (dangerous)
```

**Configuration:**
```zsh
zsh-tool-config [list|edit|reset]
# list: Show current configuration
# edit: Open config.yaml in $EDITOR
# reset: Restore to team defaults
```

**Plugin Management:**
```zsh
zsh-tool-plugin [list|add|remove|update] [plugin-name]
# Manages Oh My Zsh plugins
```

**Theme Management:**
```zsh
zsh-tool-theme [list|set|preview] [theme-name]
# Manages Oh My Zsh themes
```

**Backup/Restore:**
```zsh
zsh-tool-backup [create] [--remote]
# create: Manual backup
# --remote: Push to git remote

zsh-tool-restore [list|apply] [backup-id]
# list: Show available backups
# apply: Restore from backup
```

**Updates:**
```zsh
zsh-tool-update [self|omz|plugins|all]
# self: Update zsh-tool
# omz: Update Oh My Zsh framework
# plugins: Update all plugins
# all: Update everything
```

**Git Integration:**
```zsh
zsh-tool-git [init|status|commit|push|pull]
# Manages dotfiles as git repository
```

### 6.2 Internal Functions

**Utilities:**
```zsh
_zsh_tool_log [level] [message]
# Levels: info, warn, error, debug

_zsh_tool_prompt_confirm [message]
# Returns 0 if yes, 1 if no

_zsh_tool_is_installed [command]
# Check if command exists

_zsh_tool_is_idempotent_safe [operation]
# Check if operation already completed
```

**Oh My Zsh Integration:**
```zsh
_zsh_tool_omz_install
_zsh_tool_omz_verify
_zsh_tool_omz_plugin_install [plugin]
_zsh_tool_omz_plugin_remove [plugin]
_zsh_tool_omz_theme_set [theme]
```

---

## 7. Cross-Cutting Concerns

### 7.1 Error Handling

**Strategy:** Fail-fast with informative messages

```zsh
# Error handling pattern
_zsh_tool_error_handler() {
  local exit_code=$?
  local line_number=$1
  _zsh_tool_log error "Failed at line $line_number with exit code $exit_code"
  _zsh_tool_log error "Run 'zsh-tool-restore list' to recover"
  return $exit_code
}

trap '_zsh_tool_error_handler $LINENO' ERR
```

**Rollback on Failure:**
- All destructive operations create backup first
- On error, prompt user to restore from latest backup
- State file tracks operation progress for resume capability

### 7.2 Logging

**Implementation:** File-based logging with rotation

**Log Location:** `~/.config/zsh-tool/logs/zsh-tool.log`

**Log Levels:**
- ERROR: Operation failures, unrecoverable issues
- WARN: Non-critical issues, deprecation notices
- INFO: Operation start/complete, user actions
- DEBUG: Detailed execution trace (disabled by default)

**Log Format:**
```
[2025-10-01 12:00:00] [INFO] zsh-tool-install: Starting installation
[2025-10-01 12:00:05] [DEBUG] Checking Homebrew installation
[2025-10-01 12:00:10] [ERROR] Failed to install plugin: zsh-syntax-highlighting
```

**Rotation:** Max 10MB per file, keep 5 most recent

### 7.3 Idempotency

**Design Pattern:** Check-then-act

```zsh
# Example: Plugin installation
_zsh_tool_plugin_install() {
  local plugin=$1

  # Check if already installed
  if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" ]]; then
    _zsh_tool_log info "Plugin $plugin already installed, skipping"
    return 0
  fi

  # Proceed with installation
  # ...
}
```

**State Tracking:** `~/.config/zsh-tool/state.json`
```json
{
  "installed": true,
  "version": "1.0.0",
  "omz_installed": true,
  "plugins": ["git", "zsh-syntax-highlighting"],
  "theme": "robbyrussell",
  "last_backup": "2025-10-01-120000"
}
```

### 7.4 Security

**Principles:**
1. **No credential storage** - Respect git's existing SSH/credential config (NFR004)
2. **No remote execution** - All code sourced from cloned repository, user reviewed
3. **Backup before destructive ops** - Automatic backups before any file modifications
4. **User confirmation** - Prompt for destructive actions unless `--force` flag

**Git Operations:**
- Use user's existing git config (name, email, SSH keys)
- Never store credentials in config files
- Remote URLs use SSH format for team repo access

### 7.5 Performance

**Target:** < 5 minutes total installation (NFR001)

**Breakdown:**
- Prerequisite check: < 10s
- Homebrew installation (if needed): 2-3 min
- Oh My Zsh installation: 30-60s
- Plugin installation (5 plugins): 30s
- Configuration write: < 5s
- Total: ~4 minutes worst case

**Optimizations:**
- Parallel plugin downloads where possible
- Skip already-installed components (idempotency)
- Cache Homebrew package list
- Minimal dependency chain (only Homebrew + git)

---

## 8. Component & Integration Overview

### 8.1 External Dependencies

**Homebrew:**
- **Purpose:** Install git if missing, future dependency management
- **Integration:** Shell out to `brew install`, check exit codes
- **Error Handling:** If Homebrew unavailable and git missing, fail with install instructions

**Oh My Zsh:**
- **Purpose:** Plugin/theme ecosystem, framework
- **Integration:** Official install script, then custom configuration
- **Custom Location:** Support custom `$ZSH` variable
- **Verification:** Check `~/.oh-my-zsh/oh-my-zsh.sh` exists and is sourceable

**git:**
- **Purpose:** Clone team config repo, dotfile version control, self-update
- **Integration:** Native git commands via shell
- **Authentication:** User-configured SSH keys or credentials

### 8.2 Oh My Zsh Integration Points

**Plugin Installation:**
```zsh
# Standard Oh My Zsh approach
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

# Tool modifies ~/.zshrc to update plugins array
# Then sources ~/.zshrc to activate
```

**Custom Plugins:**
```zsh
# Team-specific plugins in ~/.oh-my-zsh/custom/plugins/
# Tool symlinks from team config repo
```

**Theme Application:**
```zsh
# Modify ZSH_THEME variable in ~/.zshrc
ZSH_THEME="robbyrussell"

# Tool handles .zshrc parsing and rewriting
```

### 8.3 File System Operations

**Critical Files:**
- `~/.zshrc` - Main configuration, modified carefully to preserve user sections
- `~/.zsh_history` - Preserved during backup/restore
- `~/.oh-my-zsh/` - Framework directory
- `~/.config/zsh-tool/` - Tool state and configuration
- `~/.local/bin/zsh-tool/` - Function definitions

**Modification Strategy:**
- Read entire file into memory
- Parse for zsh-tool markers
- Replace only marked sections
- Write atomically with backup

**Markers Example:**
```zsh
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
# Do not manually edit this section
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
ZSH_THEME="robbyrussell"
# ===== ZSH-TOOL MANAGED SECTION END =====

# User custom section below (not managed by tool)
alias myalias="echo custom"
```

---

## 9. Architecture Decision Records

### ADR-001: Function-Based CLI vs Standalone Binary

**Context:** Need command interface for zsh configuration tool.

**Decision:** Function-based (sourced into shell) rather than standalone binary.

**Rationale:**
- Direct access to shell environment variables
- No process spawning overhead
- Native zsh language consistency
- Simpler distribution (no compilation)
- User explicitly sources, understands what's loaded

**Tradeoff:** Less isolation than binary, but acceptable for shell configuration tool.

---

### ADR-002: Oh My Zsh as Foundation

**Context:** Need plugin/theme management system.

**Decision:** Use Oh My Zsh as base framework.

**Rationale:**
- Team preference (per requirements)
- Mature ecosystem (1000+ plugins)
- Active maintenance
- Standard in zsh community
- Well-documented plugin structure

**Alternatives Considered:**
- Prezto: Less popular, smaller ecosystem
- zinit: Faster but complex configuration
- Custom: Reinventing wheel, maintenance burden

---

### ADR-003: YAML for Configuration

**Context:** Need human-readable, editable configuration format.

**Decision:** YAML for `config.yaml`.

**Rationale:**
- Human-friendly for team editing
- Comments supported
- Structured data (lists, maps)
- Standard in DevOps tooling

**Implementation:** Use `yq` (Homebrew package) or pure zsh parsing for simple cases.

**Fallback:** JSON if YAML parsing proves problematic.

---

### ADR-004: XDG Base Directory Specification

**Context:** Where to store configuration and state files.

**Decision:** Follow XDG specification: `~/.config/zsh-tool/`.

**Rationale:**
- Modern standard for user configurations
- Avoids home directory clutter
- Predictable for users familiar with XDG
- Easy cleanup (single directory)

**State:** `~/.config/zsh-tool/state.json`
**Logs:** `~/.config/zsh-tool/logs/`
**Backups:** `~/.config/zsh-tool/backups/`

---

### ADR-005: Git-Based Distribution and Updates

**Context:** How to distribute tool and manage updates.

**Decision:** Git clone + install script, self-update via git pull.

**Rationale:**
- Simple for developers (familiar with git)
- Atomic updates (git pull)
- Version history built-in
- No package registry needed for internal tool
- Easy rollback (git checkout)

**Update Mechanism:**
```zsh
zsh-tool-update self
# Internally: cd ~/.local/bin/zsh-tool && git pull
```

---

### ADR-006: Backup Strategy

**Context:** Need safety mechanism before destructive operations.

**Decision:** Automatic timestamped backups to `~/.config/zsh-tool/backups/`.

**Rationale:**
- Simple directory copy (no compression needed)
- Timestamp preserves multiple restore points
- Local-first (fast, no network dependency)
- Optional remote backup via git

**Retention:** Keep last 10 backups, prune oldest automatically.

---

### ADR-007: Idempotency via State Tracking

**Context:** Operations must be safe to run multiple times (NFR002).

**Decision:** State file + check-then-act pattern.

**Rationale:**
- Prevents duplicate installations
- Allows resume after failure
- Fast re-runs (skip completed steps)
- JSON state file easily parsable

**State File:** `~/.config/zsh-tool/state.json`

---

### ADR-008: Testing with bats-core

**Context:** Need automated testing for shell functions.

**Decision:** bats-core as testing framework.

**Rationale:**
- De facto standard for Bash/zsh testing
- Simple syntax
- CI/CD friendly (exit codes)
- Active maintenance
- Good documentation

**Test Structure:**
```
tests/
├── install.bats
├── update.bats
├── backup.bats
└── utils.bats
```

---

## 10. Implementation Guidance

### 10.1 Development Workflow

**Setup:**
```zsh
git clone https://github.com/yourteam/zsh-tool.git
cd zsh-tool
./install.sh --dev  # Dev mode: symlinks instead of copies
```

**Testing:**
```zsh
# Unit tests
bats tests/*.bats

# Linting
shellcheck lib/**/*.zsh

# Integration test
./tests/integration.sh
```

**Release:**
```zsh
# Tag version
git tag v1.0.0
git push origin v1.0.0

# Users update via:
zsh-tool-update self
```

### 10.2 Epic Implementation Order

**Epic 1: Core Installation & Configuration**
1. Story 1.1: Prerequisites detection/installation → `install/prerequisites.zsh`
2. Story 1.2: Backup mechanism → `install/backup.zsh`
3. Story 1.3: Team configuration install → `install/config.zsh`
4. Story 1.4: Plugin management → `install/plugins.zsh`
5. Story 1.5: Theme installation → `install/themes.zsh`
6. Story 1.6: Personal customization layer → `core/config.zsh` (merge logic)
7. Story 1.7: Verification → `install/verify.zsh`

**Epic 2: Maintenance & Lifecycle**
1. Story 2.1: Self-update → `update/self.zsh`
2. Story 2.2: Bulk updates → `update/omz.zsh`, `update/plugins.zsh`
3. Story 2.3: Backup management → `restore/backup-mgmt.zsh`
4. Story 2.4: Restore → `restore/restore.zsh`
5. Story 2.5: Git integration → `git/integration.zsh`

### 10.3 Key Implementation Patterns

**Config File Parsing:**
```zsh
# Using yq for YAML parsing
_zsh_tool_config_get_plugins() {
  yq eval '.plugins[]' ~/.config/zsh-tool/config.yaml
}

# Fallback: pure zsh (if yq unavailable)
_zsh_tool_config_get_plugins_fallback() {
  grep '  -' ~/.config/zsh-tool/config.yaml | sed 's/  - //'
}
```

**Atomic File Updates:**
```zsh
_zsh_tool_atomic_write() {
  local target=$1
  local content=$2
  local temp=$(mktemp)

  echo "$content" > "$temp"
  mv "$temp" "$target"  # Atomic on same filesystem
}
```

**Progress Indication:**
```zsh
_zsh_tool_with_spinner() {
  local message=$1
  shift
  local cmd="$@"

  echo -n "$message... "
  $cmd &
  local pid=$!

  while kill -0 $pid 2>/dev/null; do
    printf "."
    sleep 0.5
  done

  wait $pid
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    echo " ✓"
  else
    echo " ✗"
  fi

  return $exit_code
}
```

---

## 11. Proposed Source Tree

```
zsh-tool/
├── README.md                    # User-facing documentation
├── LICENSE                      # Open source license
├── install.sh                   # Installation script
├── uninstall.sh                 # Cleanup script
│
├── lib/                         # Function library (installed to ~/.local/bin/zsh-tool/)
│   ├── zsh-tool.zsh            # Main loader (sourced by ~/.zshrc)
│   │
│   ├── core/
│   │   ├── dispatcher.zsh      # Command routing
│   │   ├── utils.zsh           # Logging, prompts, error handling
│   │   └── config.zsh          # Configuration management
│   │
│   ├── install/
│   │   ├── prerequisites.zsh   # Homebrew, git detection/install
│   │   ├── backup.zsh          # Pre-install backup
│   │   ├── omz.zsh             # Oh My Zsh installation
│   │   ├── config.zsh          # .zshrc management
│   │   ├── plugins.zsh         # Plugin installation
│   │   ├── themes.zsh          # Theme management
│   │   └── verify.zsh          # Post-install verification
│   │
│   ├── update/
│   │   ├── self.zsh            # Tool self-update
│   │   ├── omz.zsh             # Oh My Zsh update
│   │   └── plugins.zsh         # Plugin bulk update
│   │
│   ├── restore/
│   │   ├── backup-mgmt.zsh     # Backup creation/listing
│   │   └── restore.zsh         # Restoration logic
│   │
│   └── git/
│       └── integration.zsh     # Dotfile git operations
│
├── templates/                   # Configuration templates
│   ├── config.yaml              # Default tool configuration
│   ├── zshrc.template           # Team .zshrc template
│   ├── aliases.zsh              # Standard aliases
│   └── exports.zsh              # Standard exports
│
├── tests/                       # Automated tests
│   ├── install.bats             # Installation tests
│   ├── update.bats              # Update tests
│   ├── backup.bats              # Backup/restore tests
│   ├── utils.bats               # Utility function tests
│   └── integration.sh           # End-to-end integration test
│
├── docs/                        # Extended documentation
│   ├── PRD.md                   # Product requirements
│   ├── epic-stories.md          # Epic breakdown
│   ├── solution-architecture.md # This document
│   └── troubleshooting.md       # Common issues
│
└── .github/
    └── workflows/
        ├── test.yml             # CI: run tests on PR
        └── release.yml          # CD: tag-based releases
```

**Installation Result:**
```
~/.local/bin/zsh-tool/           # Tool functions (copied from lib/)
~/.config/zsh-tool/              # User configuration and state
  ├── config.yaml
  ├── state.json
  ├── logs/
  │   └── zsh-tool.log
  └── backups/
      └── 2025-10-01-120000/
~/.zshrc                         # Modified to source zsh-tool.zsh
```

---

## 12. Testing Strategy

### 12.1 Unit Tests (bats)

**Coverage:**
- All public functions
- Critical internal functions (backup, restore, config parsing)
- Edge cases (missing files, permission errors)

**Example Test:**
```bash
# tests/install.bats

@test "prerequisites: detects installed Homebrew" {
  # Mock: Homebrew installed
  function brew() { return 0; }
  export -f brew

  source lib/install/prerequisites.zsh
  run _zsh_tool_check_homebrew

  [ "$status" -eq 0 ]
  [ "$output" = "Homebrew already installed" ]
}

@test "prerequisites: installs Homebrew if missing" {
  # Mock: Homebrew not installed
  function brew() { return 127; }
  export -f brew

  source lib/install/prerequisites.zsh
  run _zsh_tool_install_homebrew

  [ "$status" -eq 0 ]
  # Verify install script was called (mocked)
}
```

### 12.2 Integration Tests

**Scope:** Full installation flow in isolated environment

**Approach:** Docker container with macOS-like environment
```dockerfile
FROM ubuntu:22.04  # Linux approximation for CI
RUN apt-get update && apt-get install -y zsh git
# Run install.sh in isolated environment
# Verify all functions loaded
# Run basic commands
```

**macOS-Specific Testing:**
- Manual testing on macOS 12, 13, 14
- GitHub Actions with macOS runners

### 12.3 Linting & Static Analysis

**shellcheck:**
```zsh
# Run in CI
shellcheck -x lib/**/*.zsh

# Common issues caught:
# - Unquoted variables
# - Missing error handling
# - Deprecated syntax
```

**Code Style:**
- 2-space indentation
- Functions prefixed `_zsh_tool_` (internal) or `zsh-tool-` (public)
- Error handling on all external commands

---

## 13. Deployment & Rollout Strategy

### 13.1 Initial Deployment

**Phase 1: Alpha (Week 1)**
- PM and 1-2 volunteer developers
- Test installation on various macOS versions
- Gather feedback on UX

**Phase 2: Beta (Week 2)**
- 5-10 developers
- Test update mechanisms
- Refine backup/restore

**Phase 3: General Availability (Week 3-4)**
- All team members
- Include in onboarding documentation
- Monitor for issues

### 13.2 Update Distribution

**Self-Update Mechanism:**
```zsh
zsh-tool-update self
# 1. git fetch origin
# 2. Check for new commits
# 3. Prompt user with changelog
# 4. git pull (or git reset --hard if user approves)
# 5. Reload functions
```

**Breaking Changes:**
- Major version bump (v2.0.0)
- Migration script included
- Backward compatibility for 1 version

### 13.3 Rollback Procedure

**User-Initiated:**
```zsh
cd ~/.local/bin/zsh-tool
git log --oneline  # Find previous version
git checkout v1.0.0
source ~/.zshrc
```

**Automated (if update fails):**
- Detect failure during update
- Automatic rollback to previous commit
- Preserve user's config.yaml

---

## 14. Security Considerations

**Threat Model:**
1. **Malicious team config repo** - Mitigated by SSH access control, code review
2. **Compromised Oh My Zsh plugins** - Mitigated by curated plugin list
3. **Credential exposure in logs** - Mitigated by never logging sensitive data
4. **Arbitrary code execution** - Mitigated by no remote code fetching without user consent

**Security Controls:**
- Tool code reviewed before deployment
- Team config repo has restricted write access
- Plugin installation from official Oh My Zsh repo only (no third-party URLs)
- Logs scrubbed of potential secrets (API keys, tokens)
- No `eval` of user input
- All git operations use user's existing credentials (no storage)

---

## 15. Monitoring & Observability

**Metrics (Future):**
- Installation success rate (self-reported opt-in)
- Average installation time
- Common error patterns
- Plugin popularity
- Update adoption rate

**MVP (Current):**
- Local logs only: `~/.config/zsh-tool/logs/zsh-tool.log`
- User manually shares logs for troubleshooting
- No telemetry

**Log Retention:**
- 10MB per log file
- Keep 5 most recent rotated logs
- Automatic cleanup via log rotation

---

## 16. Future Enhancements (Out of Scope for MVP)

From PRD Out of Scope section, potential future work:

1. **Cross-Platform Support** - Linux, Windows (WSL)
2. **Multi-Shell Support** - bash, fish compatibility
3. **GUI/TUI** - Interactive configuration editor
4. **Centralized Config Server** - Push updates to all team members
5. **Custom Plugin Registry** - Host internal plugins
6. **Security Auditing** - Plugin vulnerability scanning
7. **Usage Analytics** - Opt-in telemetry
8. **Multi-Environment Profiles** - Work/personal/client contexts
9. **Testing Framework** - Plugin development tools
10. **Cloud Sync** - Config sync across machines

---

## 17. Appendix

### 17.1 Glossary

- **Oh My Zsh**: Popular zsh configuration framework
- **Plugin**: Oh My Zsh extension for additional functionality
- **Theme**: Oh My Zsh visual prompt customization
- **Dotfiles**: User configuration files (e.g., .zshrc)
- **Idempotent**: Safe to run multiple times with same result
- **XDG**: Cross-Desktop Group standard for config file locations

### 17.2 References

- [Oh My Zsh Documentation](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Homebrew Documentation](https://docs.brew.sh/)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [bats-core Testing Framework](https://github.com/bats-core/bats-core)
- [shellcheck Linter](https://www.shellcheck.net/)

### 17.3 Team Contacts

- **Product Manager:** Barbosa
- **Tech Lead:** TBD
- **DevOps:** TBD

---

**Document Version:** 1.0
**Last Updated:** 2025-10-01
**Status:** Ready for Review
