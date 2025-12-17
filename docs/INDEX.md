# Documentation Index

Complete guide to zsh-tool documentation. This index helps you find the right documentation for your needs.

## Getting Started

Start here if you're new to zsh-tool:

1. **[README.md](README.md)** - Complete user guide with installation, usage, and examples
2. **[PRD.md](PRD.md)** - Product overview, goals, and requirements
3. **[Quick Start](#quick-start)** - See README.md for quick installation

## Documentation Categories

### Product & Planning

| Document | Description | Best For |
|----------|-------------|----------|
| [PRD.md](PRD.md) | Product Requirements Document - goals, requirements, user journeys | Understanding project scope and requirements |
| [epic-stories.md](epic-stories.md) | Story breakdown with acceptance criteria | Understanding feature implementation details |
| [PRD-validation-report.md](PRD-validation-report.md) | PRD validation findings and recommendations | Checking requirement completeness |
| [backlog.md](backlog.md) | Engineering backlog and future work | Upcoming features and improvements |

### Architecture & Design

| Document | Description | Best For |
|----------|-------------|----------|
| [project-overview.md](project-overview.md) | Executive summary and quick reference | Quick project understanding |
| [source-tree-analysis.md](source-tree-analysis.md) | Annotated directory structure | Navigating the codebase |
| [solution-architecture.md](solution-architecture.md) | Technical design and architecture decisions | Understanding system design |
| [tech-spec-epic-1.md](tech-spec-epic-1.md) | Technical specification for Core Installation & Configuration | Epic 1 implementation details |
| [tech-spec-epic-2.md](tech-spec-epic-2.md) | Technical specification for Maintenance & Lifecycle Management | Epic 2 implementation details |
| [CODEBASE-ANALYSIS.md](CODEBASE-ANALYSIS.md) | Detailed code structure analysis | Understanding codebase organization |
| [cohesion-check-report.md](cohesion-check-report.md) | Code cohesion analysis and recommendations | Code quality insights |

### Troubleshooting & Fixes

| Document | Description | Best For |
|----------|-------------|----------|
| [ATUIN-CTRL-R-FIX.md](ATUIN-CTRL-R-FIX.md) | Atuin/Amazon Q Ctrl+R conflict resolution | Fixing Atuin keybinding conflicts |
| [ITERM2-XPC-CONNECTION-FIX.md](ITERM2-XPC-CONNECTION-FIX.md) | iTerm2 stability fixes | Resolving terminal stability issues |
| [LAZY-COMPLETION-FIX.md](LAZY-COMPLETION-FIX.md) | Performance optimization documentation | Improving shell performance |
| [FIXES-2025-10-02.md](FIXES-2025-10-02.md) | Security and reliability fixes (Oct 2, 2025) | Understanding recent bug fixes |

### Utilities & Tools

| Document | Description | Best For |
|----------|-------------|----------|
| [DISK_CLEANUP_README.md](DISK_CLEANUP_README.md) | Disk cleanup utility overview | Understanding disk cleanup features |
| [DISK_CLEANUP_GUIDE.md](DISK_CLEANUP_GUIDE.md) | Detailed disk cleanup usage guide | Using disk cleanup utility |
| [TOUCH-ID-SUDO-TMUX.md](TOUCH-ID-SUDO-TMUX.md) | Touch ID for sudo with tmux/screen | Enabling biometric sudo in terminal multiplexers |
| [FABRIC-AI-GUIDE.md](FABRIC-AI-GUIDE.md) | Fabric AI patterns and integration | Using AI patterns with shell workflows |

### Development & Workflow

| Document | Description | Best For |
|----------|-------------|----------|
| [development-guide.md](development-guide.md) | Developer setup and workflow | Getting started with development |
| [AGENTS.md](AGENTS.md) | BMAD method agents reference | Understanding workflow automation |
| [project-workflow-analysis.md](project-workflow-analysis.md) | Development workflow analysis | Understanding development process |
| [technical-decisions-template.md](technical-decisions-template.md) | Template for documenting technical decisions | Recording architecture decisions |
| [stories/](stories/) | Individual story documentation | Detailed implementation stories |

## Common Use Cases

### I want to...

**Install and use zsh-tool**
→ Start with [README.md](README.md)

**Understand what zsh-tool does**
→ Read [PRD.md](PRD.md) - Description, Context and Goals section

**Learn the technical architecture**
→ Review [solution-architecture.md](solution-architecture.md)

**Understand the codebase structure**
→ Check [CODEBASE-ANALYSIS.md](CODEBASE-ANALYSIS.md)

**Fix Atuin + Amazon Q conflicts**
→ Follow [ATUIN-CTRL-R-FIX.md](ATUIN-CTRL-R-FIX.md)

**Fix iTerm2 stability issues**
→ Apply [ITERM2-XPC-CONNECTION-FIX.md](ITERM2-XPC-CONNECTION-FIX.md)

**Improve shell performance**
→ Implement [LAZY-COMPLETION-FIX.md](LAZY-COMPLETION-FIX.md)

**Clean up disk space on macOS**
→ Use [DISK_CLEANUP_GUIDE.md](DISK_CLEANUP_GUIDE.md)

**Contribute to the project**
→ Review [CODEBASE-ANALYSIS.md](CODEBASE-ANALYSIS.md) and [solution-architecture.md](solution-architecture.md)

**Understand a specific feature**
→ Check [epic-stories.md](epic-stories.md) and [stories/](stories/) directory

**Review recent fixes**
→ Read [FIXES-2025-10-02.md](FIXES-2025-10-02.md)

## Documentation by Epic

### Epic 1: Core Installation & Configuration

- [tech-spec-epic-1.md](tech-spec-epic-1.md) - Technical specification
- [epic-stories.md](epic-stories.md) - Stories 1-7
- [README.md](README.md) - Usage: Initial Setup section

### Epic 2: Maintenance & Lifecycle Management

- [tech-spec-epic-2.md](tech-spec-epic-2.md) - Technical specification
- [epic-stories.md](epic-stories.md) - Stories 8-12
- [README.md](README.md) - Usage: Updates, Backup, Restore, Git sections

### Epic 3: Advanced Integrations

- [ATUIN-CTRL-R-FIX.md](ATUIN-CTRL-R-FIX.md) - Atuin integration compatibility
- [LAZY-COMPLETION-FIX.md](LAZY-COMPLETION-FIX.md) - Performance optimization
- [README.md](README.md) - Atuin and Amazon Q sections
- [stories/](stories/) - Amazon Q implementation stories

## File Organization

```
docs/
├── INDEX.md                          # This file - Documentation index
├── README.md                         # Main user guide
├── PRD.md                           # Product Requirements Document
│
├── Architecture & Design
│   ├── solution-architecture.md     # System architecture
│   ├── tech-spec-epic-1.md         # Epic 1 technical spec
│   ├── tech-spec-epic-2.md         # Epic 2 technical spec
│   ├── CODEBASE-ANALYSIS.md        # Code structure analysis
│   └── cohesion-check-report.md    # Code quality analysis
│
├── Product & Planning
│   ├── epic-stories.md             # Story breakdown
│   ├── PRD-validation-report.md    # PRD validation
│   └── backlog.md                  # Engineering backlog
│
├── Troubleshooting & Fixes
│   ├── ATUIN-CTRL-R-FIX.md         # Atuin compatibility fix
│   ├── ITERM2-XPC-CONNECTION-FIX.md # iTerm2 stability fix
│   ├── LAZY-COMPLETION-FIX.md      # Performance fix
│   └── FIXES-2025-10-02.md         # Recent bug fixes
│
├── Utilities
│   ├── DISK_CLEANUP_README.md      # Disk cleanup overview
│   ├── DISK_CLEANUP_GUIDE.md       # Disk cleanup guide
│   ├── TOUCH-ID-SUDO-TMUX.md       # Touch ID for sudo in tmux
│   └── FABRIC-AI-GUIDE.md          # Fabric AI integration guide
│
├── Development
│   ├── AGENTS.md                   # BMAD workflow agents
│   ├── project-workflow-analysis.md # Workflow analysis
│   ├── technical-decisions-template.md # ADR template
│   └── stories/                    # Implementation stories
│       ├── story-lazy-load-amazonq.md
│       ├── story-amazonq-integration.md
│       └── [more stories...]
└── Templates
    └── technical-decisions-template.md
```

## Quick Reference

### Most Important Documents

1. **[README.md](README.md)** - Start here for usage and installation
2. **[solution-architecture.md](solution-architecture.md)** - Technical overview
3. **[CODEBASE-ANALYSIS.md](CODEBASE-ANALYSIS.md)** - Code structure
4. **[PRD.md](PRD.md)** - Product requirements and goals

### Frequently Referenced

- [ATUIN-CTRL-R-FIX.md](ATUIN-CTRL-R-FIX.md) - Atuin keybinding fix
- [LAZY-COMPLETION-FIX.md](LAZY-COMPLETION-FIX.md) - Performance optimization
- [epic-stories.md](epic-stories.md) - Feature breakdown

## Contributing to Documentation

When adding new documentation:

1. Follow the naming convention: Use UPPERCASE for fixes/guides, lowercase for specs
2. Update this INDEX.md with the new document
3. Add appropriate links in README.md if user-facing
4. Use clear, descriptive titles and sections
5. Include a "When to use this document" section

## Documentation Standards

All documentation follows these principles:

- **Clear Purpose**: Each document has a specific purpose and audience
- **Up-to-date**: Documentation is updated alongside code changes
- **Cross-referenced**: Related documents link to each other
- **Categorized**: Documents are organized by type and purpose
- **Searchable**: Use descriptive titles and headers

## Getting Help

If you can't find what you're looking for:

1. Check the [README.md](README.md) for user-facing documentation
2. Review this index for the appropriate category
3. Search the docs directory for keywords
4. Check [backlog.md](backlog.md) for planned features
5. Create an issue on GitHub

---

Last Updated: 2025-12-17
