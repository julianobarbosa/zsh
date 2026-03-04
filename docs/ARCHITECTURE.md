# zsh-tool Architecture

> Generated: 2026-03-04 | Version: 1.0.0 | Scan Level: Quick

## Executive Summary

zsh-tool is a ZSH configuration management CLI tool that automates installation, configuration, plugin management, and maintenance of professional zsh environments. Built as a modular monolith in pure ZSH, it uses YAML for configuration and JSON for state management.

## Technology Stack

| Category | Technology | Version | Notes |
|----------|-----------|---------|-------|
| Primary Language | ZSH | 5.0+ | Pure shell scripting |
| Configuration | YAML | - | `config.yaml` for all user/team settings |
| State Management | JSON | - | Backup state, component tracking |
| Shell Framework | Oh My Zsh | Latest | Plugin & theme management |
| Package Detection | Homebrew / apt | - | Auto-detected via prerequisites |
| Testing | ZSH test scripts | - | 15 test files, ~200 tests |
| Version Control | Git bare repo | - | Dotfile management |
| CI/CD | GitHub Actions | - | Claude AI code review |
| Integration: Atuin | Shell history | - | SQLite search, cross-machine sync |
| Integration: Kiro CLI | AI completions | - | Lazy-loaded, Atuin-compatible |

## Architecture Pattern

**Modular Monolith** with domain-driven organization.

### Design Principles

1. **Function namespacing**: All functions use `_zsh_tool_` prefix (1,025 occurrences across 18 modules)
2. **Atomic operations**: Temp file + mv pattern for safe file writes
3. **Automatic rollback**: Failed operations trigger automatic restore
4. **JSON state management**: Dot-notation access for structured data
5. **Security validation**: Input validation for AI-generated completions

### Module Architecture

```
install.sh (Entry Point)
    │
    ▼
lib/core/
    ├── utils.zsh           ← Logging, prompts, JSON state
    └── component-manager.zsh ← Module loading
         │
    ┌────┴────────────────────────────┐
    ▼                                  ▼
lib/install/                     lib/update/
    ├── prerequisites.zsh        ├── self.zsh
    ├── omz.zsh                  ├── plugins.zsh
    ├── plugins.zsh              ├── themes.zsh
    ├── themes.zsh               └── omz.zsh
    ├── config.zsh
    ├── backup.zsh          lib/restore/
    └── verify.zsh               ├── restore.zsh
                                 └── backup-mgmt.zsh
lib/git/
    └── integration.zsh     lib/integrations/
                                 ├── atuin.zsh
                                 └── kiro-cli.zsh
```

### Data Flow

1. **Configuration**: `templates/config.yaml` → copied to `~/.config/zsh-tool/config.yaml` → parsed by `config.zsh`
2. **Installation**: `install.sh` → `prerequisites` → `omz` → `plugins` → `themes` → `config` → `verify`
3. **State**: JSON files in `~/.config/zsh-tool/` track backups, component versions, and status
4. **Backup/Restore**: Pre-change backups → atomic restore with rollback on failure

### Installation Paths

| Path | Purpose |
|------|---------|
| `~/.local/bin/zsh-tool/` | Installed modules (lib/) |
| `~/.config/zsh-tool/` | User configuration and state |
| `~/.config/zsh-tool/config.yaml` | User/team settings |
| `~/.config/zsh-tool/backups/` | Configuration backups |
| `~/.oh-my-zsh/` | Oh My Zsh framework |

## Testing Strategy

- **15 test files** with ~200 tests covering all modules
- **1:1 test-to-module mapping**: Each `lib/` module has a corresponding `tests/test-*.zsh`
- **Security tests**: 28 tests for input validation and edge cases
- **Test runner**: `tests/run-all-tests.sh` executes full suite
- **No CI test automation**: Tests run locally (GitHub Actions used only for AI code review)

## Deployment Architecture

- **Distribution**: Git clone + `zsh install.sh`
- **Dev mode**: `zsh install.sh --dev` uses symlinks for development
- **Self-update**: `lib/update/self.zsh` handles version checks and updates
- **No container/cloud deployment**: Local-only CLI tool

## Codebase Metrics

| Metric | Value |
|--------|-------|
| Total project LOC | ~18,502 |
| Library LOC | 7,266 |
| Test LOC | ~8,000 |
| Modules | 18 ZSH files |
| Test files | 15 |
| Functions | ~100+ (namespaced) |
| Documentation files | 60+ |
