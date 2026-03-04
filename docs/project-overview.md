# zsh-tool Project Overview

> Generated: 2026-03-04 | Version: 1.0.0 | Scan Level: Quick

## Executive Summary

**zsh-tool** is a comprehensive command-line tool for managing zsh shell configurations on macOS. It automates installation, configuration, plugin management, and maintenance of professional zsh environments with team-standard configurations.

## Quick Reference

| Property | Value |
|----------|-------|
| **Project Type** | CLI Tool (Monolith) |
| **Primary Language** | ZSH 5.0+ |
| **Architecture** | Modular Monolith |
| **Entry Point** | `install.sh` |
| **Version** | 1.0.0 |
| **LOC** | ~18,500 total (7,266 in lib/) |
| **Modules** | 18 ZSH files across 6 domains |
| **Tests** | 15 test files, ~200 tests |
| **Config Format** | YAML |
| **State Format** | JSON |
| **Framework** | Oh My Zsh |
| **Integrations** | Atuin (shell history), Kiro CLI (AI completions) |
| **CI/CD** | GitHub Actions (AI code review only) |

## Key Capabilities

1. **Automated Installation** — Prerequisites detection, Oh My Zsh setup, plugin/theme installation
2. **Configuration Management** — Team-standard aliases, exports, PATH modifications from YAML
3. **Backup & Restore** — Automatic pre-change backups with atomic rollback
4. **Self-Updating** — Version checks and component updates
5. **Git Integration** — Bare repository pattern for dotfile version control
6. **Atuin Integration** — Enhanced shell history with search, sync, tab completion
7. **Kiro CLI Integration** — AI-powered command completions with lazy loading

## Repository Structure

```
zsh/
├── install.sh          # Entry point
├── lib/                # 18 ZSH modules (7,266 LOC)
│   ├── core/           # Utils, component manager
│   ├── install/        # Installation workflow (7 modules)
│   ├── update/         # Update lifecycle (4 modules)
│   ├── restore/        # Backup/restore (2 modules)
│   ├── git/            # Dotfile VCS (1 module)
│   └── integrations/   # Atuin, Kiro CLI (2 modules)
├── templates/          # config.yaml, zshrc template
├── tests/              # 15 test files
├── scripts/            # Utility scripts
└── docs/               # 60+ documentation files
```

## Documentation Map

| Document | Purpose |
|----------|---------|
| [Architecture](./architecture.md) | System design, tech stack, module structure |
| [Source Tree](./source-tree-analysis.md) | Annotated directory structure |
| [Development Guide](./development-guide.md) | Setup, build, test instructions |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Detailed architecture (deep dive) |
| [MODULE-REFERENCE.md](./MODULE-REFERENCE.md) | Module API reference |
| [TEST-COVERAGE.md](./TEST-COVERAGE.md) | Test coverage analysis |
| [QUICKREF.md](./QUICKREF.md) | Quick reference card |
| [INDEX.md](./INDEX.md) | Full documentation index |

## Getting Started

```bash
# Clone and install
git clone https://github.com/julianobarbosa/zsh.git
cd zsh
zsh install.sh

# Development mode (symlinks)
zsh install.sh --dev

# Run tests
zsh tests/run-all-tests.sh
```

## AI-Assisted Development

When working with AI tools on this codebase:

1. Start with this overview for project context
2. Reference `architecture.md` for design decisions
3. Use `MODULE-REFERENCE.md` for function signatures
4. Follow `_zsh_tool_` naming convention for new functions
5. Add corresponding test file for any new module
