# zsh-tool

A comprehensive command-line tool for managing zsh shell configurations on macOS. Automate installation, configuration, plugin management, and maintenance of professional zsh environments with team-standard configurations.

## Why zsh-tool?

- **Fast onboarding**: Set up a fully configured zsh environment in under 5 minutes
- **Team consistency**: Ensure all developers use the same base configuration and conventions
- **Easy maintenance**: Update configurations, plugins, and themes with simple commands
- **Safe operations**: Automatic backups before changes with easy rollback
- **Advanced integrations**: Optional Atuin shell history and Kiro CLI support

## Quick Start

```bash
# 1. Clone and install
git clone https://github.com/julianobarbosa/zsh.git
cd zsh
zsh install.sh

# 2. Reload your shell
exec zsh

# 3. Run initial setup
zsh-tool-install
```

That's it! Your zsh environment is now configured with team standards.

## Features

### Core Capabilities
- **Automated Installation**: Prerequisites detection, Oh My Zsh setup, plugin installation
- **Configuration Management**: Team-standard aliases, exports, PATH modifications
- **Backup & Restore**: Automatic backups with local/remote storage options
- **Self-Updating**: Keep the tool and all plugins up to date with one command
- **Git Integration**: Version control for your dotfiles

### Advanced Integrations
- **[Atuin](https://atuin.sh)**: Enhanced shell history with searchable SQLite database, sync across machines
- **[Kiro CLI](https://kiro.dev/docs/cli/)**: AI-powered command completions and suggestions
- **Compatibility Layer**: Automatic configuration for Atuin + Kiro CLI coexistence

## Common Commands

```bash
# Initial setup
zsh-tool-install

# Update everything
zsh-tool-update

# Backup configuration
zsh-tool-backup create

# Restore from backup
zsh-tool-restore list
zsh-tool-restore apply <backup-id>

# Atuin shell history
zsh-tool-atuin install
zsh-tool-atuin stats

# Kiro CLI
zsh-tool-kiro install
zsh-tool-kiro status

# Get help
zsh-tool-help
```

## Requirements

- macOS 12 (Monterey) or newer
- zsh shell (pre-installed on modern macOS)
- Internet connection for initial setup

## Project Structure

```
zsh-tool/
├── install.sh              # Main installation entry point
├── lib/                    # Core functionality modules
│   ├── core/              # Utilities and shared functions
│   ├── install/           # Installation modules
│   ├── update/            # Update operations
│   ├── restore/           # Backup and restore
│   ├── git/               # Git integration
│   └── integrations/      # Atuin, Kiro CLI
├── templates/             # Configuration templates
├── tests/                 # Test suite
├── docs/                  # Comprehensive documentation
└── bmad/                  # BMAD workflow system
```

## Documentation

- **[User Guide](docs/README.md)**: Comprehensive usage documentation
- **[Product Requirements](docs/PRD.md)**: Goals, requirements, and user journeys
- **[Architecture](docs/solution-architecture.md)**: Technical design and decisions
- **[Epic Stories](docs/epic-stories.md)**: Feature breakdown and acceptance criteria
- **[Codebase Analysis](docs/CODEBASE-ANALYSIS.md)**: Detailed code structure

### Troubleshooting & Fixes
- [Atuin + Kiro CLI Compatibility](docs/ATUIN-CTRL-R-FIX.md)
- [iTerm2 XPC Connection Fix](docs/ITERM2-XPC-CONNECTION-FIX.md)
- [Lazy Completion Optimization](docs/LAZY-COMPLETION-FIX.md)
- [Security & Reliability Fixes](docs/FIXES-2025-10-02.md)

### Utilities
- [Disk Cleanup Guide](docs/DISK_CLEANUP_GUIDE.md)
- [Disk Cleanup README](docs/DISK_CLEANUP_README.md)

## Configuration

Configuration is stored in `~/.config/zsh-tool/config.yaml`:

```yaml
team_config:
  plugins:
    - git
    - zsh-autosuggestions
    - zsh-syntax-highlighting
  theme: "robbyrussell"

atuin:
  enabled: true
  import_history: true
  search_mode: "fuzzy"

kiro_cli:
  enabled: false
  lazy_loading: true
  atuin_compatibility: true
```

## Customization

Add personal customizations to `~/.zsh_custom.zsh` (preserved across updates):

```bash
# Personal aliases
alias myproject="cd ~/projects/myproject"

# Environment variables
export MY_VAR="value"

# Custom functions
function my_function() {
  echo "Custom function"
}
```

## Development

### Running Tests
```bash
zsh tests/run-all-tests.sh
```

### Development Mode
Install with symlinks for immediate testing of changes:
```bash
zsh install.sh --dev
```

## Architecture Principles

- **Idempotent**: Safe to run operations multiple times
- **Reversible**: Automatic backups before all changes
- **Modular**: Clear separation of concerns
- **Well-logged**: Progress indicators and helpful error messages
- **Non-intrusive**: Preserves user customizations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

## Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/julianobarbosa/zsh/issues)
- **Documentation**: See [docs/](docs/) directory

## License

MIT License - See LICENSE file for details

## Acknowledgments

Built with:
- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Atuin](https://atuin.sh) - Shell history enhancement
- [Kiro CLI](https://kiro.dev/docs/cli/) - AI-powered CLI assistance

---

**Current Status**: Production-ready | Epic 1-3 Complete | Actively Maintained

For detailed roadmap and future features, see [docs/PRD.md](docs/PRD.md).
