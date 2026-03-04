# Source Tree Analysis

> Generated: 2026-03-04 | Scan Level: Quick | Project Type: CLI Tool (Monolith)

## Project Root Structure

```
zsh/
├── install.sh                          # [ENTRY POINT] Main installer (dev/prod modes)
├── VERSION                             # Semantic version (1.0.0)
├── README.md                           # User guide and quick start
├── CONTRIBUTING.md                     # Contribution guidelines
├── CHANGELOG.md                        # Release history
├── LICENSE                             # Project license
├── TODO.md                             # Current task tracking
│
├── lib/                                # [CORE] All ZSH modules (7,266 LOC)
│   ├── core/                           # Shared utilities and component management
│   │   ├── utils.zsh                   # (299 LOC) Logging, prompts, JSON state management
│   │   └── component-manager.zsh       # (281 LOC) Module loading and lifecycle
│   │
│   ├── install/                        # Installation workflow modules
│   │   ├── prerequisites.zsh           # (280 LOC) System dependency detection
│   │   ├── omz.zsh                     # (76 LOC) Oh My Zsh installation
│   │   ├── plugins.zsh                 # (372 LOC) Plugin management and installation
│   │   ├── themes.zsh                  # (344 LOC) Theme installation and selection
│   │   ├── config.zsh                  # (837 LOC) Configuration generation from YAML
│   │   ├── backup.zsh                  # (230 LOC) Pre-install backup creation
│   │   └── verify.zsh                  # (692 LOC) Post-install verification
│   │
│   ├── update/                         # Maintenance and update modules
│   │   ├── self.zsh                    # (499 LOC) Self-update mechanism
│   │   ├── plugins.zsh                 # (81 LOC) Plugin update orchestration
│   │   ├── themes.zsh                  # (82 LOC) Theme update orchestration
│   │   └── omz.zsh                     # (115 LOC) Oh My Zsh framework updates
│   │
│   ├── restore/                        # Backup and restore operations
│   │   ├── restore.zsh                 # (461 LOC) Configuration restore with rollback
│   │   └── backup-mgmt.zsh            # (530 LOC) Backup listing, cleanup, management
│   │
│   ├── git/                            # Version control integration
│   │   └── integration.zsh            # (322 LOC) Bare git repo for dotfiles
│   │
│   └── integrations/                   # External tool integrations
│       ├── atuin.zsh                   # (1,128 LOC) Atuin shell history integration
│       └── kiro-cli.zsh               # (637 LOC) Kiro CLI AI completions
│
├── templates/                          # Configuration templates
│   ├── config.yaml                     # Team/user configuration template
│   └── zshrc.template                  # Generated .zshrc template
│
├── tests/                              # Test suite (15 test files)
│   ├── run-all-tests.sh                # Test runner script
│   ├── test-prerequisites.zsh          # System dependency tests
│   ├── test-plugins.zsh               # Plugin management tests
│   ├── test-themes.zsh                # Theme management tests
│   ├── test-config.zsh                # Configuration tests
│   ├── test-backup.zsh               # Backup creation tests
│   ├── test-backup-mgmt.zsh          # Backup management tests
│   ├── test-restore.zsh              # Restore operation tests
│   ├── test-verify.zsh               # Verification tests
│   ├── test-self-update.zsh          # Self-update tests
│   ├── test-bulk-update.zsh          # Bulk update tests
│   ├── test-git-integration.zsh      # Git integration tests
│   ├── test-atuin.zsh                # Atuin integration tests
│   ├── test-kiro-cli.zsh             # Kiro CLI tests
│   └── test-kiro-cli-edge-cases.zsh  # Kiro CLI security/edge case tests
│
├── scripts/                            # Utility scripts
│   ├── cleanup-disk.sh                # macOS disk cleanup utility
│   ├── add_screen_recording_permissions.sh  # macOS permissions helper
│   └── test-all-voices.sh            # Voice testing utility
│
├── .github/workflows/                  # CI/CD
│   ├── claude.yml                     # Claude AI integration
│   └── claude-code-review.yml         # AI-assisted code review
│
└── docs/                               # Documentation (60+ files)
    ├── INDEX.md                        # Master documentation index
    ├── README.md                       # Detailed user guide
    ├── ARCHITECTURE.md                 # System architecture
    ├── MODULE-REFERENCE.md             # Module API reference
    └── [50+ additional docs]           # See INDEX.md for full listing
```

## Critical Directories

| Directory | Purpose | Files | LOC |
|-----------|---------|-------|-----|
| `lib/core/` | Shared utilities, JSON state, component manager | 2 | 580 |
| `lib/install/` | Full installation workflow | 7 | 2,831 |
| `lib/update/` | Update lifecycle management | 4 | 777 |
| `lib/restore/` | Backup/restore with rollback | 2 | 991 |
| `lib/git/` | Dotfile version control | 1 | 322 |
| `lib/integrations/` | External tool integrations | 2 | 1,765 |
| `tests/` | Test suite | 15 | ~8,000 |
| `templates/` | Config and zshrc templates | 2 | ~150 |

## Key Patterns

- **Function namespacing**: All functions prefixed with `_zsh_tool_` (1,025 occurrences across 18 files)
- **Module organization**: By epic/domain (install, update, restore, git, integrations)
- **Entry flow**: `install.sh` → copies `lib/` to `~/.local/bin/zsh-tool/` → loads via `zsh-tool.zsh`
- **Config flow**: `templates/config.yaml` → `~/.config/zsh-tool/config.yaml` → parsed by `lib/install/config.zsh`
- **Test coverage**: 1:1 mapping between lib modules and test files
