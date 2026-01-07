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
- ✓ Atuin shell history integration (search, sync, statistics)
- ✓ Amazon Q Developer CLI integration
- ✓ Atuin-Amazon Q compatibility configuration
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

### Atuin Shell History Integration

[Atuin](https://atuin.sh) replaces your default shell history with a searchable SQLite database, providing enhanced search, statistics, and optional sync across machines. zsh-tool includes built-in integration with automatic configuration and Amazon Q compatibility.

#### Features

- **Enhanced search**: Fuzzy, prefix, or full-text search with interactive UI (Ctrl+R)
- **SQLite database**: Fast queries on large command histories
- **Statistics**: View command usage, frequency, and patterns
- **Optional sync**: Share history across machines (requires account or self-hosted server)
- **Context awareness**: Filter by directory, session, or host
- **Import existing history**: Seamlessly import from .zsh_history

#### Quick Setup

Enable Atuin in configuration (enabled by default):
```bash
zsh-tool-config edit
# Verify atuin.enabled: true
```

Install and configure Atuin:
```bash
zsh-tool-atuin install
```

This will:
1. Detect or install Atuin (via Homebrew or manual)
2. Configure Atuin settings (search mode, UI style, etc.)
3. Add shell integration to .zshrc.local
4. Import existing zsh history
5. Configure Amazon Q compatibility (if enabled)

#### Commands

Check Atuin status:
```bash
zsh-tool-atuin status
```

Run health check:
```bash
zsh-tool-atuin health
```

View history statistics:
```bash
zsh-tool-atuin stats
```

Import existing history manually:
```bash
zsh-tool-atuin import
```

Setup sync (optional):
```bash
zsh-tool-atuin sync-setup
```

#### Usage

After installation, press **Ctrl+R** to open Atuin's interactive search:
- Type to search commands (fuzzy search by default)
- Use arrow keys to navigate
- Press Enter to execute
- Press Esc to cancel

View detailed statistics:
```bash
atuin stats
```

Search from command line:
```bash
atuin search "git commit"
```

#### Configuration

Atuin settings in `config.yaml`:
```yaml
atuin:
  enabled: true              # Enable Atuin integration
  import_history: true       # Import existing .zsh_history on setup
  sync_enabled: false        # Enable sync (requires registration)
  search_mode: "fuzzy"       # fuzzy, prefix, fulltext, skim
  filter_mode: "global"      # global, host, session, directory
  inline_height: 20          # Search UI height (lines)
  style: "auto"              # auto, compact, full
```

Advanced configuration in `~/.config/atuin/config.toml`:
```toml
search_mode = "fuzzy"
filter_mode = "global"
style = "auto"
inline_height = 20
show_preview = true
```

#### Sync Setup (Optional)

Atuin can sync history across machines using cloud or self-hosted server:

1. Register for Atuin sync service:
```bash
atuin register -u <username> -e <email>
```

2. Login on other machines:
```bash
atuin login -u <username>
```

3. Sync history:
```bash
atuin sync
```

Or self-host your own sync server: https://docs.atuin.sh/self-hosting/

#### Amazon Q Compatibility

When both Atuin and Amazon Q are enabled, zsh-tool automatically:
1. Configures Amazon Q to ignore Atuin commands
2. Restores Ctrl+R keybinding to Atuin after Amazon Q loads

This prevents Amazon Q from intercepting Atuin's Ctrl+R search shortcut.

Manual configuration (if needed):
```bash
zsh-tool-amazonq config-atuin
```

#### Troubleshooting

**Ctrl+R not opening Atuin:**
- Check if Atuin is installed: `command -v atuin`
- Verify keybinding: `bindkey | grep '^R'`
- Reload shell: `exec zsh`
- Check Amazon Q compatibility: `zsh-tool-amazonq config-atuin`

**History not importing:**
```bash
zsh-tool-atuin import
# or manually:
atuin import auto
```

**Sync not working:**
- Verify login: `atuin account status`
- Check sync config: `cat ~/.config/atuin/config.toml | grep sync`
- Manual sync: `atuin sync`

**Learn more:**
- [Atuin Documentation](https://docs.atuin.sh)
- [Atuin GitHub](https://github.com/atuinsh/atuin)
- [Compatibility with Amazon Q](/docs/ATUIN-CTRL-R-FIX.md)

### Kiro CLI Integration

[Kiro CLI](https://kiro.dev/) (formerly Amazon Q Developer CLI) provides AI-powered command completions, inline suggestions, and chat capabilities for the command line. zsh-tool includes built-in integration with performance optimization and Atuin compatibility.

#### Quick Setup

Enable Kiro CLI in configuration:
```bash
zsh-tool-config edit
# Set kiro_cli.enabled: true
```

Install and configure Kiro CLI:
```bash
zsh-tool-kiro install
```

Check Kiro CLI status:
```bash
zsh-tool-kiro status
```

Run Kiro CLI health check:
```bash
zsh-tool-kiro health
```

Configure Atuin compatibility (prevents keybinding conflicts):
```bash
zsh-tool-kiro config-atuin
```

#### Performance Considerations

Kiro CLI adds ~11ms overhead per command and ~1.8s startup delay. zsh-tool includes:
- **Lazy loading** (enabled by default): Defers initialization until first use
- **Conditional loading**: Only loads when enabled in config
- **Per-CLI exclusions**: Disable Kiro CLI for specific commands

#### Troubleshooting Kiro CLI

**Arrow keys not working with Atuin:**
```bash
zsh-tool-kiro config-atuin
```

**Slow shell startup:**
Ensure `lazy_loading: true` in config.yaml (default)

**Kiro CLI not responding:**
```bash
zsh-tool-kiro health
kiro-cli doctor  # Run Kiro CLI diagnostics
```

**Learn more:**
- [Kiro CLI Documentation](https://kiro.dev/docs/cli/)
- [Kiro CLI Migration Guide](https://kiro.dev/docs/cli/migrating-from-q/)

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
│       ├── atuin.zsh      # Atuin shell history
│       └── kiro-cli.zsh   # Kiro CLI (formerly Amazon Q)
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

atuin:
  enabled: true
  import_history: true
  sync_enabled: false
  search_mode: "fuzzy"
  filter_mode: "global"
  inline_height: 20
  style: "auto"

kiro_cli:
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
