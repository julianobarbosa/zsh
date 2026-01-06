# zsh Product Requirements Document (PRD)

**Author:** Barbosa
**Date:** 2025-10-01 (Updated: 2025-12-23)
**Project Level:** Level 2 (Small complete system)
**Project Type:** CLI/Shell Configuration Tool
**Target Scale:** 14 stories, 3 epics

---

## Description, Context and Goals

A comprehensive command-line tool for managing zsh shell configurations on macOS. The system will automate installation, configuration, plugin management, theme customization, and ongoing maintenance of zsh environments. It will provide an opinionated yet flexible approach to setting up and maintaining professional zsh configurations, with built-in backup/restore capabilities and macOS-specific optimizations.

**Key capabilities:**
- Automated zsh installation and initial setup
- Dotfile management with version control integration
- Plugin and theme installation/updates
- Configuration backup and restore
- macOS-specific shell optimizations
- Self-update mechanism
- Advanced shell history with Atuin integration (fuzzy search, cross-machine sync)
- AI-powered command assistance via Amazon Q Developer CLI

### Deployment Intent

**MVP for internal development team** - A production-ready tool designed for onboarding and standardizing shell configurations across the development team. The system will ensure consistent development environments and reduce setup time for new team members.

### Context

Development teams often struggle with inconsistent shell configurations, leading to environment-related issues and wasted onboarding time. Manual zsh setup is error-prone and time-consuming. This tool addresses the need for a standardized, repeatable process to configure and maintain zsh environments across the team, ensuring all developers have optimized, consistent shell setups that follow team conventions.

### Goals

1. **Reduce onboarding time** - New developers can set up a fully configured zsh environment in under 10 minutes
2. **Ensure consistency** - All team members use the same base configuration, plugins, and conventions
3. **Enable easy maintenance** - Developers can update configurations, plugins, and themes with simple commands

## Requirements

### Functional Requirements

**FR001:** Users can install and configure zsh with a single command on a fresh macOS system

**FR002:** Users can apply team-standard configuration (aliases, exports, PATH modifications) automatically

**FR003:** Users can install and manage plugins from a curated team list (e.g., syntax highlighting, autosuggestions, git helpers)

**FR004:** Users can install and switch between approved theme options

**FR005:** Users can backup their current zsh configuration to local or remote storage

**FR006:** Users can restore previous configurations from backup

**FR007:** Users can update the configuration tool itself to the latest version

**FR008:** Users can update all installed plugins and themes with a single command

**FR009:** Users can initialize a new developer environment with all team standards applied

**FR010:** Users can customize their personal configuration while maintaining core team standards

**FR011:** Users can integrate their dotfiles with version control (git)

**FR012:** Users can uninstall or rollback to previous configuration states

**FR013:** Users can integrate Atuin shell history for fuzzy cross-machine history search and sync

**FR014:** Users can integrate Amazon Q Developer CLI for AI-powered command line assistance with lazy loading for performance

**FR015:** Users can integrate direnv with 1Password for secure, per-project environment variable management, enabling automatic loading of AI API keys and workflow credentials when entering project directories

### Non-Functional Requirements

**NFR001: Performance** - Initial installation and configuration must complete in under 5 minutes on standard macOS hardware

**NFR002: Reliability** - All operations must be idempotent (safe to run multiple times) and include rollback capability on failure

**NFR003: Compatibility** - Must support macOS 12 (Monterey) and newer, with both Intel and Apple Silicon architectures

**NFR004: Security** - Must not store or transmit sensitive credentials; all git operations should respect user's existing SSH/credential configuration

**NFR005: User Experience** - All commands must provide clear progress indicators and helpful error messages with suggested remediation steps

## User Journeys

### User Journey: New Developer Onboarding

**Actor:** Sarah, a new backend developer joining the team

**Goal:** Set up a fully configured zsh environment matching team standards

**Journey:**

1. **Starting Point:** Sarah receives her new MacBook and completes initial macOS setup
   - She has basic development tools installed (Xcode Command Line Tools)
   - She has access to the team's internal repository

2. **Discovery:** Sarah reads the team onboarding guide which directs her to the zsh config tool
   - She clones the team's zsh-config repository
   - She reviews the README to understand what will be installed

3. **Installation:** Sarah runs the installation command
   - Tool checks for prerequisites (Homebrew, git)
   - Installs missing dependencies automatically
   - Backs up any existing zsh configuration
   - Installs team-standard .zshrc, aliases, and exports

4. **Configuration:** Tool applies team standards
   - Installs approved plugins (syntax highlighting, autosuggestions, git helpers)
   - Applies default theme
   - Configures PATH for common development tools
   - Shows summary of changes made

5. **Verification:** Sarah opens a new terminal session
   - Auto-completion works as expected
   - Git aliases and helpers are available
   - Prompt theme displays correctly
   - All team-standard commands are accessible

6. **Personalization:** Sarah adds her personal preferences
   - Adds custom aliases to personal config file
   - Core team standards remain intact
   - Changes persist across updates

**Success Criteria:**
- Total time from start to finish: < 10 minutes
- Zero manual configuration file editing required
- Sarah's environment matches all team members' setups

## UX Design Principles

1. **Convention over Configuration** - Provide sensible defaults that work out-of-the-box; users shouldn't need to configure unless they want to customize

2. **Clear Feedback** - Every operation should provide clear progress indicators and completion status; errors must include actionable remediation steps

3. **Safe by Default** - All destructive operations require confirmation; automatic backups before making changes; easy rollback capability

4. **Discoverability** - Built-in help documentation; intuitive command naming; self-documenting commands with examples

5. **Non-Intrusive** - Respect existing user configurations; layer team standards without breaking personal customizations

## Epics

### Epic 1: Core Installation & Configuration System
**Goal:** Enable developers to install and configure a standardized zsh environment with a single command

**Priority:** P0 - Must Have

**Dependencies:** None (greenfield)

**Estimated Stories:** 7

### Epic 2: Maintenance & Lifecycle Management
**Goal:** Provide tools for ongoing management, updates, backups, and restoration of zsh configurations

**Priority:** P0 - Must Have

**Dependencies:** Epic 1 (Core Installation)

**Estimated Stories:** 5

### Epic 3: Advanced Integrations
**Goal:** Provide seamless integration with external shell productivity tools (Atuin, Amazon Q) while maintaining compatibility and optimal performance

**Priority:** P1 - Should Have

**Dependencies:** Epic 1 (Core Installation), Epic 2 (Maintenance)

**Estimated Stories:** 2

**Stories:**
- **Story 13:** Atuin Shell History Integration (5 points) - Fuzzy search, cross-machine sync, keybinding configuration
- **Story 14:** Amazon Q CLI Integration (8 points) - AI-powered assistance, lazy loading, Atuin compatibility

### Epic 4: Environment Management Integration
**Goal:** Provide secure, per-project environment variable management through direnv integration with 1Password for credential storage

**Priority:** P1 - Should Have

**Dependencies:** Epic 1 (Core Installation), 1Password CLI (`op`)

**Estimated Stories:** 2

**Stories:**
- **Story 15:** direnv + 1Password Integration (8 points) - Secure credential fetching, per-project environment loading, AI API key management
- **Story 16:** Workflow Environment Templates (3 points) - Reusable environment templates for common AI/DevOps workflows

**Total Stories:** 16

_See epic-stories.md for detailed story breakdown with acceptance criteria and story points._

## Out of Scope

The following features are intentionally excluded from the initial release but may be considered for future phases:

1. **Cross-Platform Support** - Windows and Linux support (MVP is macOS-only)

2. **Multi-Shell Support** - Support for bash, fish, or other shells (MVP focuses exclusively on zsh)

3. **GUI/Web Interface** - Graphical configuration interface (MVP is CLI-only)

4. **Centralized Configuration Server** - Team-wide configuration management server for pushing updates centrally

5. **Custom Plugin Registry** - Self-hosted plugin repository or marketplace for team-developed plugins

6. **Advanced Security Auditing** - Automated security scanning and vulnerability detection for plugins

7. **Usage Analytics** - Telemetry or analytics to track feature usage and adoption

8. **Multi-Environment Profiles** - Support for switching between different configuration profiles (work, personal, client projects)

9. **Automated Testing Framework** - Built-in testing utilities for custom plugin/configuration development

10. **Cloud Sync** - Automatic configuration synchronization via cloud services

These items are preserved for potential future development but are not required for the core MVP functionality.

---

## Implementation Status

> **Status: IN PROGRESS** - Epics 1-3 complete and in production. Epic 4 (direnv integration) in development.

### Completed Phases

#### Phase 1: Solution Architecture & Design
- [x] Solution architecture defined (`solution-architecture.md`)
- [x] Technology stack: ZSH scripting, Oh My Zsh, YAML/TOML/JSON configs
- [x] File structure and module organization designed
- [x] Configuration file formats specified
- [x] Testing strategy established

#### Phase 2: Development Preparation
- [x] Repository structure established
- [x] Test framework implemented (`tests/`)
- [x] Coding standards defined
- [x] Development environment documented

#### Phase 3: Implementation
- [x] Epic 1: Core Installation & Configuration (7 stories) - Complete
- [x] Epic 2: Maintenance & Lifecycle Management (5 stories) - Complete
- [x] Epic 3: Advanced Integrations (2 stories) - Complete
- [x] User acceptance testing completed

#### Phase 4: Deployment & Adoption
- [x] Comprehensive documentation created (`docs/`)
- [x] Tool in active use
- [x] Feedback incorporated via Epic 3 additions

### Technical Specifications

| Epic | Tech Spec | Status |
|------|-----------|--------|
| Epic 1 | `tech-spec-epic-1.md` | Complete |
| Epic 2 | `tech-spec-epic-2.md` | Complete |
| Epic 3 | `tech-spec-epic-3.md` | Complete |
| Epic 4 | `tech-spec-epic-5.md` | In Progress |

### Future Considerations

See `backlog.md` for potential future enhancements beyond current scope.

## Document Status

- [x] Goals and context validated with stakeholders
- [x] All functional requirements reviewed (FR001-FR015)
- [x] User journeys cover primary persona (new developer onboarding)
- [x] Epic structure approved (4 epics, 16 stories)
- [x] Architecture phase complete
- [x] Epics 1-3 implementation complete
- [ ] Epic 4 (direnv + 1Password) in progress
- [x] Documentation in progress

_Note: See `solution-architecture.md` for technical decisions and architecture details._

---

_This PRD adapts to project level Level 2 - providing appropriate detail without overburden._
