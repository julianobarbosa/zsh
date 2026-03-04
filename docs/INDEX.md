# zsh-tool Documentation Index

> Generated: 2026-03-04 | Project Type: CLI Tool (Monolith)

## Project Overview

- **Type:** Monolith CLI Tool
- **Primary Language:** ZSH 5.0+
- **Architecture:** Modular Monolith with domain-driven organization
- **Tech Stack:** Pure ZSH, YAML config, JSON state, Oh My Zsh
- **Entry Point:** `install.sh`
- **Version:** 1.0.0
- **Total LOC:** ~18,500 (7,266 in lib/)

## Quick Reference

- **Install:** `git clone ... && zsh install.sh`
- **Dev mode:** `zsh install.sh --dev`
- **Run tests:** `zsh tests/run-all-tests.sh`
- **Config:** `~/.config/zsh-tool/config.yaml`
- **Modules:** 18 ZSH files across 6 domains (core, install, update, restore, git, integrations)
- **Integrations:** Atuin (shell history), Kiro CLI (AI completions)

## Getting Started

1. **[README.md](README.md)** — User guide with installation, usage, and examples
2. **[project-overview.md](project-overview.md)** — Executive summary and quick reference
3. **[development-guide.md](development-guide.md)** — Developer setup and workflow

## Generated Documentation (2026-03-04)

| Document | Description |
|----------|-------------|
| [project-overview.md](project-overview.md) | Executive summary, tech stack, capabilities |
| [architecture.md](architecture.md) | System design, module architecture, data flow |
| [source-tree-analysis.md](source-tree-analysis.md) | Annotated directory structure with LOC counts |
| [development-guide.md](development-guide.md) | Prerequisites, setup, testing, conventions |

## Existing Documentation

### Architecture & Design

| Document | Description | Best For |
|----------|-------------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Detailed architecture (deep dive, 2026-02-04) | Comprehensive system understanding |
| [solution-architecture.md](solution-architecture.md) | Technical design and architecture decisions | Understanding system design |
| [CODEBASE-ANALYSIS.md](CODEBASE-ANALYSIS.md) | Detailed code structure analysis | Understanding codebase organization |
| [MODULE-REFERENCE.md](MODULE-REFERENCE.md) | Module API reference | Function signatures and usage |
| [cohesion-check-report.md](cohesion-check-report.md) | Code cohesion analysis | Code quality insights |

### Product & Planning

| Document | Description | Best For |
|----------|-------------|----------|
| [PRD.md](PRD.md) | Product Requirements Document | Scope and requirements |
| [product-brief.md](product-brief.md) | Product Brief — vision, personas, metrics | High-level product understanding |
| [epic-stories.md](epic-stories.md) | Story breakdown with acceptance criteria | Feature implementation details |
| [backlog.md](backlog.md) | Engineering backlog and future work | Upcoming features |
| [PRD-validation-report.md](PRD-validation-report.md) | PRD validation findings | Requirement completeness |

### Technical Specifications

| Document | Description |
|----------|-------------|
| [tech-spec-epic-1.md](tech-spec-epic-1.md) | Core Installation & Configuration |
| [tech-spec-epic-2.md](tech-spec-epic-2.md) | Maintenance & Lifecycle Management |
| [tech-spec-epic-3.md](tech-spec-epic-3.md) | Advanced Integrations (Atuin, Kiro CLI) |
| [tech-spec-epic-4.md](tech-spec-epic-4.md) | Additional specifications |

### Reference & Quick Access

| Document | Description |
|----------|-------------|
| [QUICKREF.md](QUICKREF.md) | Quick reference card |
| [TEST-COVERAGE.md](TEST-COVERAGE.md) | Test coverage analysis |
| [test-design-system.md](test-design-system.md) | Test design approach |
| [project-context.md](project-context.md) | AI project context |

### Troubleshooting & Fixes

| Document | Description |
|----------|-------------|
| [ATUIN-CTRL-R-FIX.md](ATUIN-CTRL-R-FIX.md) | Atuin/Kiro CLI Ctrl+R conflict resolution |
| [ATUIN-TAB-COMPLETION.md](ATUIN-TAB-COMPLETION.md) | Atuin tab completion setup |
| [ITERM2-XPC-CONNECTION-FIX.md](ITERM2-XPC-CONNECTION-FIX.md) | iTerm2 stability fixes |
| [LAZY-COMPLETION-FIX.md](LAZY-COMPLETION-FIX.md) | Performance optimization |
| [FIXES-2025-10-02.md](FIXES-2025-10-02.md) | Security and reliability fixes |

### Utilities & Tools

| Document | Description |
|----------|-------------|
| [DISK_CLEANUP_README.md](DISK_CLEANUP_README.md) | Disk cleanup utility overview |
| [DISK_CLEANUP_GUIDE.md](DISK_CLEANUP_GUIDE.md) | Disk cleanup usage guide |
| [TOUCH-ID-SUDO-TMUX.md](TOUCH-ID-SUDO-TMUX.md) | Touch ID for sudo in terminal multiplexers |
| [FABRIC-AI-GUIDE.md](FABRIC-AI-GUIDE.md) | Fabric AI patterns integration |

### Development & Workflow

| Document | Description |
|----------|-------------|
| [AGENTS.md](AGENTS.md) | BMAD method agents reference |
| [project-workflow-analysis.md](project-workflow-analysis.md) | Development workflow analysis |
| [technical-decisions-template.md](technical-decisions-template.md) | ADR template |
| [stories/](stories/) | Implementation story files |

### Implementation Artifacts

| Document | Description |
|----------|-------------|
| [implementation-artifacts/](implementation-artifacts/) | Story-level implementation specs |
| [implementation-readiness-report-2026-01-03-v3.md](implementation-readiness-report-2026-01-03-v3.md) | Latest readiness report |

## Common Use Cases

| I want to... | Go to... |
|--------------|----------|
| Install and use zsh-tool | [README.md](README.md) |
| Understand the project quickly | [project-overview.md](project-overview.md) |
| Learn the architecture | [architecture.md](architecture.md) or [ARCHITECTURE.md](ARCHITECTURE.md) |
| Navigate the codebase | [source-tree-analysis.md](source-tree-analysis.md) |
| Set up for development | [development-guide.md](development-guide.md) |
| Look up a function | [MODULE-REFERENCE.md](MODULE-REFERENCE.md) |
| Fix Atuin keybinding issues | [ATUIN-CTRL-R-FIX.md](ATUIN-CTRL-R-FIX.md) |
| Clean up disk space | [DISK_CLEANUP_GUIDE.md](DISK_CLEANUP_GUIDE.md) |
| Review test coverage | [TEST-COVERAGE.md](TEST-COVERAGE.md) |

## AI-Assisted Development

When using AI tools with this codebase:

1. Start with **project-overview.md** for project context
2. Reference **architecture.md** for design decisions and data flow
3. Use **MODULE-REFERENCE.md** for function signatures
4. Follow `_zsh_tool_` naming convention for new functions
5. Add corresponding test file for any new module
6. Reference **development-guide.md** for conventions and testing

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

When adding documentation:
1. Use UPPERCASE for fixes/guides, lowercase for specs
2. Update this INDEX.md with the new document
3. Add links in README.md if user-facing

---

Last Updated: 2026-03-04
