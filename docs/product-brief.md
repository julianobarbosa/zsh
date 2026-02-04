# Product Brief: zsh

**Author:** Barbosa
**Date:** 2026-02-04
**Status:** Complete

## Executive Summary

**zsh-tool** is a sophisticated Zsh configuration management framework that brings the "Configuration as Code" paradigm to shell environments. It enables teams to standardize, version-control, and automate their shell configurations while preserving individual developer customization freedom. The tool transforms the traditionally manual, error-prone process of shell setup into a declarative, reproducible, and team-friendly workflow.

---

## Core Vision

### Problem Statement

Development teams struggle with inconsistent shell environments across team members. Each developer manually configures their Zsh setup - plugins, themes, aliases, PATH modifications, and integrations - leading to:
- "Works on my machine" debugging sessions caused by environment differences
- Hours lost during new developer onboarding recreating shell configurations
- Tribal knowledge about "the right plugins" and "useful aliases" that never gets documented
- Configuration drift as developers make ad-hoc changes over time

### Problem Impact

Without standardized shell environments:
- **Onboarding friction**: New team members spend their first day(s) setting up their shell instead of contributing code
- **Inconsistent tooling**: Some developers have helpful aliases and plugins others don't know about
- **No version control**: Shell configurations live in dotfiles that rarely get committed or shared
- **Update chaos**: Rolling out a new team-wide plugin or alias requires manual intervention on every machine

### Why Existing Solutions Fall Short

Current approaches to shell configuration management include:
- **Manual dotfiles repos**: Require manual syncing, lack declarative structure, and don't handle dependencies well
- **Oh My Zsh alone**: Provides plugins but no team standardization or configuration-as-code approach
- **Chezmoi/yadm**: General dotfile managers that don't understand Zsh-specific semantics or team workflows
- **Custom scripts**: Brittle, hard to maintain, and lack idempotency guarantees

### Proposed Solution

**zsh-tool** provides a complete configuration management framework where:
1. A central `config.yaml` declares the team's standard environment (plugins, themes, aliases, exports, paths)
2. A template-based system (`zshrc.template`) transforms configuration into a functional `.zshrc`
3. Idempotent installation ensures safe, repeatable deployments
4. A personal customization layer (`~/.zshrc.local`) lets individuals extend without conflicting with team standards
5. Modern integrations (Atuin history, Kiro CLI) are first-class citizens with declarative configuration

### Key Differentiators

1. **True Configuration as Code**: YAML-defined environments that can be version-controlled, code-reviewed, and deployed like any other infrastructure
2. **Team-First, Individual-Friendly**: Standardize across the team while preserving personal customization freedom
3. **Idempotent by Design**: Run the installer repeatedly without fear - it handles backups, updates, and state management
4. **Modern Integration Ready**: Built-in support for Atuin shell history and Kiro CLI with simple enable/disable toggles
5. **Modular Architecture**: Clean separation between core utilities, installation logic, and configuration parsing

---

## Target Users

### Primary Users

#### 1. Platform Engineer / DevOps Lead - "Maya"

**Context:** Maya is a senior platform engineer at a mid-sized tech company with 50+ developers. She's responsible for developer experience and tooling standardization.

**Current Pain:**
- Spends hours helping new hires debug shell configuration issues
- Maintains a wiki page of "recommended shell setup" that nobody follows consistently
- Gets pinged weekly about "what plugin does X?" or "how do I get that alias?"
- Can't easily roll out security-related shell changes across the team

**Success Vision:**
- New developers run one command and have the team's shell environment ready
- Configuration changes are PRs that get reviewed and deployed like code
- She can audit who has what configuration and ensure compliance

**Key Interactions:**
- Maintains the team's `config.yaml` in version control
- Reviews PRs that propose new aliases or plugins
- Runs installation on CI/CD for validation
- Monitors adoption across team machines

#### 2. Software Developer - "Dev"

**Context:** Dev is a full-stack developer who joined the team 6 months ago. Uses the terminal constantly for git, docker, kubectl, and various CLI tools.

**Current Pain:**
- Spent first two days copying dotfiles from a senior dev's machine
- Still discovers useful aliases colleagues have that they never shared
- Worries about breaking their shell when trying new plugins
- Has custom settings they don't want to lose

**Success Vision:**
- Get productive immediately with a well-configured shell
- Discover team-blessed plugins and aliases automatically
- Keep personal customizations without conflicting with team updates
- Shell updates "just work" without manual intervention

**Key Interactions:**
- Runs installer once during onboarding
- Uses `~/.zshrc.local` for personal preferences
- Receives automatic updates when team config changes
- Benefits from Atuin history sync and Kiro CLI integration

### Secondary Users

#### 3. Engineering Manager / Tech Lead - "Jordan"

**Context:** Leads a team of 8 developers and cares about consistency and onboarding efficiency.

**Value Derived:**
- Reduced onboarding friction means new hires contribute faster
- Standardized environments reduce "works on my machine" debugging
- Can enforce security practices (e.g., no sensitive data in shell history)

**Key Interactions:**
- Approves configuration changes in PRs
- Uses metrics to track team tool adoption
- Advocates for the tool to other teams

#### 4. New Hire - "Alex"

**Context:** Just joined the company, overwhelmed with onboarding tasks.

**Value Derived:**
- One-command setup instead of following a 20-step wiki
- Immediately productive with team-standard tooling
- Feels like part of the team with same aliases and shortcuts

**Key Interactions:**
- Runs installer on day one
- Optionally customizes via `~/.zshrc.local`
- Learns team conventions through the configuration itself

### User Journey

**Discovery → Onboarding → Daily Use → Advocacy**

1. **Discovery:** Platform engineer finds zsh-tool while searching for "team shell standardization" or through DevOps community recommendations

2. **Evaluation:** Creates initial `config.yaml` with team's existing Oh My Zsh plugins, aliases, and exports; tests on own machine

3. **Rollout:** Adds to team's infrastructure repo, documents in onboarding guide, announces in Slack

4. **Onboarding (New Dev):** New hire clones repo, runs `./install.sh`, immediately has working environment with all team tools

5. **Daily Use:** Developers use standardized aliases (`gs`, `gco`, `k` for kubectl), benefit from shared plugins, add personal touches in `~/.zshrc.local`

6. **Updates:** Platform engineer adds new alias or plugin via PR → merged → developers get it on next shell restart

7. **Advocacy:** Developers share with friends at other companies; platform engineer presents at internal tech talks

---

## Success Metrics

### User Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Onboarding Time** | < 5 minutes from clone to working shell | Time from `git clone` to successful `zsh` launch with all features |
| **Installation Success Rate** | > 95% first-attempt success | Installer exit codes and error logs |
| **Configuration Consistency** | 100% of team members on same base config | Automated config hash comparison |
| **Personal Customization Adoption** | > 60% of users have `~/.zshrc.local` | File existence check during updates |
| **Zero Shell Breakage** | 0 broken shells after updates | User-reported issues and rollback triggers |

### User Success Indicators

- **Immediate Value:** User can run team-standard aliases within 5 minutes of installation
- **"Aha!" Moment:** New hire realizes they have same shortcuts as senior developers on day one
- **Sustained Value:** User never manually edits `.zshrc` for team-standard features
- **Expansion:** User adds personal customizations to `~/.zshrc.local` without fear

### Business Objectives

For an open-source developer tool, business objectives focus on adoption, community health, and team productivity impact:

| Objective | 3-Month Target | 12-Month Target |
|-----------|----------------|-----------------|
| **Team Adoption** | 80% of target team using zsh-tool | 100% coverage + 2 additional teams |
| **Configuration PRs** | At least 1 config improvement PR per month | Active config evolution with team participation |
| **Support Burden** | 50% reduction in shell-related support tickets | Near-zero shell onboarding support needed |
| **Onboarding Efficiency** | Shell setup drops from hours to minutes | Shell setup is invisible part of onboarding |

### Key Performance Indicators

#### Adoption KPIs
- **Installation Count:** Number of successful installations (tracked via state.json)
- **Active Users:** Unique machines with zsh-tool in last 30 days
- **Team Coverage:** Percentage of team members with consistent config hash

#### Quality KPIs
- **Installation Idempotency:** Repeat installations produce identical results
- **Rollback Rate:** Percentage of users who revert to previous config
- **Error Rate:** Installation failures per 100 attempts

#### Engagement KPIs
- **Config Contribution Rate:** Team members proposing config changes via PR
- **Personal Customization Rate:** Users extending via `~/.zshrc.local`
- **Integration Adoption:** Percentage enabling Atuin history and Kiro CLI

#### Impact KPIs
- **Onboarding Time Saved:** Hours saved per new hire (baseline vs. zsh-tool)
- **Support Ticket Reduction:** Shell-related tickets before vs. after adoption
- **"Works on my machine" Incidents:** Environment-related debugging sessions

---

## MVP Scope

### Core Features (MVP)

The MVP delivers a complete, production-ready shell configuration management system:

#### 1. Configuration as Code Engine
- **config.yaml parsing**: Read and validate team configuration file
- **Template processing**: Transform `zshrc.template` with config values
- **Variable substitution**: Replace placeholders (plugins, themes, aliases, exports, paths)

#### 2. Installation System
- **Idempotent installer**: `install.sh` that can be run safely multiple times
- **Backup management**: Automatic backup of existing `.zshrc` before changes
- **Oh My Zsh integration**: Install/verify Oh My Zsh as foundation
- **State tracking**: `state.json` for installation state management

#### 3. Configuration Categories
- **Plugins**: Oh My Zsh plugin management (git, docker, kubectl, etc.)
- **Themes**: Theme selection and configuration (Powerlevel10k, etc.)
- **Aliases**: Team-standard command shortcuts
- **Exports**: Environment variable definitions
- **Paths**: PATH prepends and appends

#### 4. Modern Integrations
- **Atuin shell history**: Declarative configuration for Atuin (enabled, import, sync, search modes)
- **Kiro CLI**: Declarative configuration for Kiro CLI (enabled, lazy loading, compatibility)

#### 5. User Customization Layer
- **~/.zshrc.local support**: Personal customizations that survive updates
- **Non-destructive updates**: Team config updates don't overwrite personal settings

### Out of Scope for MVP

The following features are explicitly deferred to future versions:

| Feature | Rationale | Target Version |
|---------|-----------|----------------|
| **External tracker integration** | Jira/Linear/Trello sync adds complexity | v2.0 |
| **Remote config sync** | Cloud storage for configs across machines | v2.0 |
| **Configuration validation** | Schema validation and linting for config.yaml | v1.5 |
| **Team analytics dashboard** | Adoption metrics and compliance reporting | v2.0 |
| **Bash/Fish support** | Focus on Zsh first, expand shells later | v3.0 |
| **GUI configuration editor** | CLI-first approach, GUI adds maintenance | v3.0 |
| **Plugin auto-discovery** | Recommend plugins based on project type | v2.0 |
| **Configuration diff/merge** | Visual comparison of config versions | v1.5 |

### MVP Success Criteria

The MVP is considered successful when:

#### User Validation
- [ ] New team member completes installation in < 5 minutes
- [ ] Zero shell breakage reported after installation
- [ ] Users successfully extend via `~/.zshrc.local`
- [ ] Team lead can update config and all members receive changes

#### Technical Validation
- [ ] Idempotent: repeat installations produce identical results
- [ ] Rollback: users can restore previous configuration
- [ ] Cross-platform: works on macOS and Linux

#### Business Validation
- [ ] > 80% of target team adopts within first month
- [ ] Support tickets for shell setup drop by > 50%
- [ ] At least one config improvement PR from non-maintainer

### Future Vision

#### Version 1.5: Configuration Intelligence
- Schema validation for `config.yaml` with helpful error messages
- Configuration diff tool to compare versions
- Pre-commit hooks for config validation
- "Dry run" mode to preview changes before applying

#### Version 2.0: Team Collaboration
- Integration with issue trackers (Jira, Linear) for sprint tracking
- Team analytics: adoption rates, config drift detection
- Plugin recommendations based on project dependencies
- Remote config sync for multi-machine developers

#### Version 3.0: Platform Expansion
- Bash and Fish shell support with config translation
- GUI configuration editor (web-based)
- Enterprise features: SSO, audit logging, compliance reporting
- Marketplace for community-contributed configurations

#### Long-term Vision
**zsh-tool becomes the standard for team shell environment management**, similar to how tools like ESLint standardized code style or how Terraform standardized infrastructure. Teams expect shell configurations to be:
- Versioned and reviewed like code
- Deployed consistently across all machines
- Customizable without conflict
- Integrated with modern developer tooling
