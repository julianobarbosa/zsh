# zsh-tool

A comprehensive command-line tool for managing zsh shell configurations on macOS. This tool automates installation, configuration, plugin management, theme customization, and ongoing maintenance of zsh environments.

## Features

### Epic 1: Core Installation & Configuration
- ✓ Automated zsh installation and initial setup
- ✓ Prerequisites detection and installation
- ✓ Automatic backup before changes
- ✓ Oh My Zsh installation and management
- ✓ Team configuration deployment
- ✓ Plugin installation and management
- ✓ Theme selection and customization
- ✓ Personal customization layer support

### Epic 2: Maintenance & Lifecycle Management
- ✓ Self-update mechanism
- ✓ Bulk plugin and theme updates
- ✓ Configuration backup management (local and remote)
- ✓ Configuration restore from backup
- ✓ Git integration for dotfiles versioning
- ✓ Rollback capabilities

### Epic 3: Advanced Integrations
- ✓ Amazon Q Developer CLI integration
- ✓ Atuin compatibility configuration
- ✓ Lazy loading for performance optimization

## Requirements

- macOS 12 (Monterey) or newer
- zsh shell (pre-installed on modern macOS)
- Internet connection for initial setup
- jq (installed automatically for Amazon Q integration)

## Quick Start

### Installation

1. Clone this repository:
```bash
git clone https://github.com/yourteam/zsh-tool.git
cd zsh-tool
```

2. Run the installation script:
```bash
zsh install.sh
```

3. Reload your shell:
```bash
exec zsh
```

4. Run the initial setup:
```bash
zsh-tool-install
```

### Development Mode

For development or testing with symlinks (changes reflect immediately):
```bash
zsh install.sh --dev
```

## Usage

### Initial Setup

Install team-standard configuration on a fresh system:
```bash
zsh-tool-install
```

This command will:
- Check and install prerequisites (Homebrew, git, jq, etc.)
- Create a backup of existing configuration
- Install or verify Oh My Zsh
- Apply team-standard configuration
- Install approved plugins
- Apply default theme
- Set up personal customization layer
- Verify installation

Expected completion time: < 5 minutes

### Configuration Management

List current configuration:
```bash
zsh-tool-config list
```

Edit configuration:
```bash
zsh-tool-config edit
```

### Updates

Update all components (self, Oh My Zsh, and plugins):
```bash
zsh-tool-update
# or explicitly:
zsh-tool-update all
```

Update specific components:
```bash
zsh-tool-update self      # Update zsh-tool itself
zsh-tool-update omz       # Update Oh My Zsh only
zsh-tool-update plugins   # Update all plugins only
```

### Backup Management

Create a manual backup:
```bash
zsh-tool-backup create
```

List all available backups:
```bash
zsh-tool-backup list
```

Push backup to remote storage:
```bash
zsh-tool-backup remote
```

### Restore from Backup

List available backups:
```bash
zsh-tool-restore list
```

Restore from a specific backup:
```bash
zsh-tool-restore apply <backup-id>
```

### Git Integration

Initialize dotfiles repository:
```bash
zsh-tool-git init
```

Configure remote repository:
```bash
zsh-tool-git remote https://github.com/yourteam/dotfiles.git
```

Check status:
```bash
zsh-tool-git status
```

Add and commit changes:
```bash
zsh-tool-git add .zshrc
zsh-tool-git commit "Update shell aliases"
```

Push to remote:
```bash
zsh-tool-git push
```

Pull from remote:
```bash
zsh-tool-git pull
```

### Amazon Q Developer CLI Integration

[Amazon Q Developer CLI](https://aws.amazon.com/q/developer/) provides AI-powered command completions, inline suggestions, and chat capabilities for the command line. zsh-tool includes built-in integration with performance optimization and Atuin compatibility.

#### Quick Setup

Enable Amazon Q in configuration:
```bash
zsh-tool-config edit
# Set amazon_q.enabled: true
```

Install and configure Amazon Q:
```bash
zsh-tool-amazonq install
```

Check Amazon Q status:
```bash
zsh-tool-amazonq status
```

Run Amazon Q health check:
```bash
zsh-tool-amazonq health
```

Configure Atuin compatibility (prevents keybinding conflicts):
```bash
zsh-tool-amazonq config-atuin
```

#### Performance Considerations

Amazon Q adds ~11ms overhead per command and ~1.8s startup delay. zsh-tool includes:
- **Lazy loading** (enabled by default): Defers initialization until first use
- **Conditional loading**: Only loads when enabled in config
- **Per-CLI exclusions**: Disable Amazon Q for specific commands

#### Troubleshooting Amazon Q

**Arrow keys not working with Atuin:**
```bash
zsh-tool-amazonq config-atuin
```

**Slow shell startup:**
Ensure `lazy_loading: true` in config.yaml (default)

**Amazon Q not responding:**
```bash
zsh-tool-amazonq health
q doctor  # Run Amazon Q diagnostics
```

**Learn more:**
- [Amazon Q Developer Documentation](https://docs.aws.amazon.com/amazonq/)
- [Amazon Q CLI on GitHub](https://github.com/aws/amazon-q-developer-cli)

### Help

Display all available commands:
```bash
zsh-tool-help
```

## Project Structure

```
zsh-tool/
├── install.sh              # Main installation script
├── lib/                    # Core functionality modules
│   ├── core/              # Core utilities
│   │   └── utils.zsh      # Logging, state management
│   ├── install/           # Epic 1: Installation modules
│   │   ├── prerequisites.zsh
│   │   ├── backup.zsh
│   │   ├── omz.zsh
│   │   ├── config.zsh
│   │   ├── plugins.zsh
│   │   ├── themes.zsh
│   │   └── verify.zsh
│   ├── update/            # Epic 2: Update modules
│   │   ├── self.zsh
│   │   ├── omz.zsh
│   │   └── plugins.zsh
│   ├── restore/           # Epic 2: Restore modules
│   │   ├── backup-mgmt.zsh
│   │   └── restore.zsh
│   ├── git/               # Epic 2: Git integration
│   │   └── integration.zsh
│   └── integrations/      # Epic 3: Advanced integrations
│       └── amazon-q.zsh   # Amazon Q Developer CLI
├── templates/             # Configuration templates
│   ├── config.yaml        # Team configuration template
│   ├── zshrc.template     # .zshrc template
│   └── custom.zsh.template # Personal customization template
├── tests/                 # Test files
├── docs/                  # Documentation
│   ├── PRD.md            # Product requirements
│   ├── epic-stories.md   # Story breakdown
│   └── solution-architecture.md
└── bmad/                  # BMAD workflow system
```

## Configuration

Configuration is stored in `~/.config/zsh-tool/config.yaml`:

```yaml
team_config:
  plugins:
    - git
    - zsh-autosuggestions
    - zsh-syntax-highlighting
  theme: "robbyrussell"

backup:
  local_dir: "~/.local/share/zsh-tool/backups"
  max_backups: 10

git:
  enabled: false
  remote_url: ""

amazon_q:
  enabled: false
  lazy_loading: true
  atuin_compatibility: true
  disabled_clis:
    - atuin
```

## User Customization

Personal customizations should be added to `~/.zsh_custom.zsh`, which is automatically sourced and preserved across updates:

```bash
# Example personal customizations
alias myproject="cd ~/projects/myproject"
export MY_VAR="value"
```

## Troubleshooting

### Installation fails with permission errors
Run the script with zsh explicitly:
```bash
zsh install.sh
```

### Commands not found after installation
Reload your shell:
```bash
exec zsh
```

### Restore previous configuration
List and restore from automatic backups:
```bash
zsh-tool-restore list
zsh-tool-restore apply pre-install-YYYYMMDD-HHMMSS
```

## Development

### Running Tests
```bash
cd tests
zsh run-tests.zsh
```

### Development Mode Installation
```bash
zsh install.sh --dev
```

This creates symlinks instead of copies, allowing you to test changes immediately.

## Architecture

This tool follows a modular architecture with clear separation of concerns:

- **Core utilities**: Logging, state management, error handling
- **Installation modules**: Each aspect of setup (prerequisites, backup, OMZ, config, plugins, themes, verification)
- **Update modules**: Self-update, OMZ updates, plugin updates
- **Restore modules**: Backup management and restoration
- **Git integration**: Dotfiles version control

All operations are:
- **Idempotent**: Safe to run multiple times
- **Reversible**: Automatic backups before changes
- **Well-logged**: Clear progress indicators and error messages

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[Your License Here]

## Support

For issues and questions:
- GitHub Issues: https://github.com/yourteam/zsh-tool/issues
- Team Slack: #dev-tools

## Roadmap

See `docs/PRD.md` for complete product requirements and future phases.

### Out of Scope (Future Considerations)
- Cross-platform support (Windows, Linux)
- Multi-shell support (bash, fish)
- GUI/Web interface
- Centralized configuration server
- Custom plugin registry
- Advanced security auditing
- Usage analytics
- Multi-environment profiles
