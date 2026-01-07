# Changelog

All notable changes to zsh-tool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **BREAKING**: Migrated Amazon Q Developer CLI to Kiro CLI (AWS rebranded Nov 2025)
  - All `amazon-q.zsh` functionality migrated to `kiro-cli.zsh`
  - All `_amazonq_*` functions renamed to `_kiro_*`
  - Config section changed from `amazon_q:` to `kiro_cli:`
  - All paths updated from `~/.aws/amazonq/` to `~/.kiro/`
  - Commands renamed: `zsh-tool-amazonq` → `zsh-tool-kiro`
  - Tests migrated: `test-amazon-q*.zsh` → `test-kiro-cli*.zsh`
  - Backward compatibility wrappers provided for deprecated functions

### Added
- Project documentation: README.md, CONTRIBUTING.md, LICENSE
- Documentation index: docs/INDEX.md
- Disk cleanup utility with interactive and automated modes
- Comprehensive Atuin shell history integration
- Kiro CLI integration with lazy loading (formerly Amazon Q Developer CLI)

### Fixed
- Infinite recursion in Kiro CLI lazy loading
- Atuin/Kiro CLI Ctrl+R keybinding conflicts
- iTerm2 XPC connection stability issues
- Lazy completion performance optimization

## [1.0.0] - 2025-10-22

### Added

#### Epic 1: Core Installation & Configuration
- Automated zsh installation and initial setup
- Prerequisites detection and installation (Homebrew, git, Xcode CLI tools)
- Automatic backup creation before changes
- Oh My Zsh installation and management
- Team configuration deployment from YAML
- Plugin installation and management system
- Theme selection and customization
- Personal customization layer support (`.zsh_custom.zsh`)
- Post-installation verification checks

#### Epic 2: Maintenance & Lifecycle Management
- Self-update mechanism via git pull
- Bulk Oh My Zsh framework updates
- Bulk plugin updates
- Configuration backup management (local and remote)
- Configuration restore from backup with listing
- Git integration for dotfiles versioning
- Rollback capabilities with backup restoration

### Features by Command

#### Installation
- `zsh-tool-install` - One-command setup of complete zsh environment

#### Configuration Management
- `zsh-tool-config list` - Display current configuration
- `zsh-tool-config edit` - Edit team configuration

#### Updates
- `zsh-tool-update` / `zsh-tool-update all` - Update all components
- `zsh-tool-update self` - Update zsh-tool itself
- `zsh-tool-update omz` - Update Oh My Zsh framework
- `zsh-tool-update plugins` - Update all plugins

#### Backup & Restore
- `zsh-tool-backup create` - Create manual backup
- `zsh-tool-backup list` - List all backups
- `zsh-tool-backup remote` - Push backup to remote storage
- `zsh-tool-restore list` - List available backups
- `zsh-tool-restore apply <id>` - Restore from specific backup

#### Git Integration
- `zsh-tool-git init` - Initialize dotfiles repository
- `zsh-tool-git remote <url>` - Configure remote repository
- `zsh-tool-git status` - Check dotfiles status
- `zsh-tool-git add <file>` - Stage dotfile changes
- `zsh-tool-git commit <msg>` - Commit changes
- `zsh-tool-git push` - Push to remote
- `zsh-tool-git pull` - Pull from remote

#### Help
- `zsh-tool-help` - Display all available commands

### Technical Implementation

#### Architecture
- Modular design with clear separation of concerns
- Function-based interface (not external scripts)
- Idempotent operations (safe to run multiple times)
- Automatic rollback on failure
- Comprehensive error handling with helpful messages

#### File Organization
```
lib/
├── core/utils.zsh          (195 lines) - Logging, state management
├── install/                (859 lines total)
│   ├── prerequisites.zsh   (185 lines)
│   ├── backup.zsh          (132 lines)
│   ├── omz.zsh             (76 lines)
│   ├── config.zsh          (262 lines)
│   ├── plugins.zsh         (116 lines)
│   ├── themes.zsh          (72 lines)
│   └── verify.zsh          (152 lines)
├── update/                 (432 lines total)
│   ├── self.zsh            (206 lines)
│   ├── omz.zsh             (89 lines)
│   └── plugins.zsh         (137 lines)
├── restore/                (395 lines total)
│   ├── backup-mgmt.zsh     (263 lines)
│   └── restore.zsh         (132 lines)
└── git/                    (282 lines total)
    └── integration.zsh     (282 lines)
```

#### Configuration
- YAML-based team configuration
- Template system for .zshrc and custom files
- Personal customization layer preserved across updates
- Support for team aliases, exports, PATH modifications

### Non-Functional Achievements

#### Performance
- Installation completes in < 5 minutes on standard hardware
- Lazy loading for performance-critical integrations

#### Reliability
- All operations idempotent
- Automatic backups before destructive operations
- Easy rollback capability
- Comprehensive error handling

#### Compatibility
- macOS 12 (Monterey) and newer
- Intel and Apple Silicon architectures
- zsh 5.8+

#### Security
- No credential storage or transmission
- Respects user's existing SSH/git configuration
- Safe file operations with permission checks

#### User Experience
- Clear progress indicators
- Helpful error messages with remediation steps
- Intuitive command naming
- Built-in help documentation

### Documentation
- Product Requirements Document (PRD)
- Solution Architecture Document
- Epic Stories with Acceptance Criteria
- Technical Specifications for Epic 1 & 2
- Comprehensive README with examples
- Codebase Analysis
- Project Workflow Analysis

## [0.1.0] - 2025-10-01

### Added
- Initial project structure
- BMAD workflow system integration
- Project planning and requirements documentation

---

## Epic 3: Advanced Integrations (Added Post-1.0)

### [1.1.0] - 2025-10-02

#### Added
- Atuin shell history integration (491 lines)
  - Enhanced shell history with SQLite database
  - Interactive fuzzy/prefix/fulltext search
  - Optional cross-machine sync
  - Command statistics and analytics
  - Existing .zsh_history import
  - Configurable search/filter modes
- Amazon Q Developer CLI integration (441 lines)
  - AI-powered command completions
  - Inline suggestions and CLI chat
  - Lazy loading optimization
  - Performance tuning
  - Atuin compatibility configuration
  - Error recovery and health checks

#### Commands Added
- `zsh-tool-atuin install` - Install and configure Atuin
- `zsh-tool-atuin status` - Check Atuin installation status
- `zsh-tool-atuin health` - Run health checks
- `zsh-tool-atuin stats` - Display command statistics
- `zsh-tool-atuin import` - Import existing zsh history
- `zsh-tool-atuin sync-setup` - Configure history sync
- `zsh-tool-kiro install` - Install Kiro CLI (formerly Amazon Q)
- `zsh-tool-kiro status` - Check Kiro CLI status
- `zsh-tool-kiro health` - Run health diagnostics
- `zsh-tool-kiro config-atuin` - Configure Atuin compatibility

#### Fixed
- Security and reliability issues (FIXES-2025-10-02.md)
- Atuin Ctrl+R keybinding conflicts with Kiro CLI
- Lazy completion performance issues
- iTerm2 XPC connection stability

#### Documentation Added
- ATUIN-CTRL-R-FIX.md - Atuin/Kiro CLI compatibility guide
- LAZY-COMPLETION-FIX.md - Performance optimization guide
- ITERM2-XPC-CONNECTION-FIX.md - Terminal stability fixes
- FIXES-2025-10-02.md - Security and reliability fixes

### [1.2.0] - 2025-11-16

#### Added
- Disk cleanup utility (cleanup-disk.sh)
  - Interactive macOS disk cleanup
  - Three cleanup levels (safe, moderate, aggressive)
  - Dry-run mode for safe preview
  - Automated and interactive modes
  - Cleanup targets: npm, homebrew, python caches, Docker, ML models

#### Documentation Added
- DISK_CLEANUP_README.md - Disk cleanup utility overview
- DISK_CLEANUP_GUIDE.md - Detailed usage guide

#### Fixed
- Infinite recursion bug in Amazon Q lazy loading

#### Documentation Improvements
- Added root-level README.md for better discoverability
- Created comprehensive documentation index (docs/INDEX.md)
- Added CONTRIBUTING.md with development guidelines
- Added LICENSE (MIT)
- Created CHANGELOG.md (this file)
- Reorganized documentation structure

---

## Version History Summary

| Version | Date | Description |
|---------|------|-------------|
| 1.2.0 | 2025-11-16 | Disk cleanup utility, documentation improvements |
| 1.1.0 | 2025-10-02 | Atuin & Amazon Q integrations, fixes |
| 1.0.0 | 2025-10-22 | Epic 1 & 2 complete, production ready |
| 0.1.0 | 2025-10-01 | Initial project structure |

---

## Upgrade Guide

### From 1.0.x to 1.1.0

No breaking changes. To enable new integrations:

```bash
# Update zsh-tool
zsh-tool-update self

# Optional: Install Atuin
zsh-tool-config edit  # Set atuin.enabled: true
zsh-tool-atuin install

# Optional: Install Kiro CLI (formerly Amazon Q)
zsh-tool-config edit  # Set kiro_cli.enabled: true
zsh-tool-kiro install
```

### From 1.1.x to 1.2.0

No breaking changes. New disk cleanup utility is standalone:

```bash
# Update zsh-tool
zsh-tool-update self

# Use disk cleanup (optional)
./cleanup-disk.sh --help
```

---

## Future Roadmap

See [docs/PRD.md](docs/PRD.md) and [docs/backlog.md](docs/backlog.md) for planned features.

### Potential Future Features (Out of Scope for Current Version)

- Cross-platform support (Windows, Linux)
- Multi-shell support (bash, fish)
- GUI/Web interface
- Centralized configuration server
- Custom plugin registry
- Advanced security auditing
- Usage analytics
- Multi-environment profiles
- Automated testing framework for custom plugins
- Cloud sync

---

[Unreleased]: https://github.com/julianobarbosa/zsh/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/julianobarbosa/zsh/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/julianobarbosa/zsh/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/julianobarbosa/zsh/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/julianobarbosa/zsh/releases/tag/v0.1.0
