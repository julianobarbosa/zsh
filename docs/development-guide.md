# Development Guide

> Generated: 2026-03-04 | Version: 1.0.0

## Prerequisites

- **macOS** (primary target platform)
- **ZSH 5.0+** (default shell on macOS)
- **Git** (for repository management and dotfile integration)
- **Homebrew** (recommended for dependency management)

## Getting Started

### Clone and Install (Development Mode)

```bash
git clone https://github.com/julianobarbosa/zsh.git
cd zsh

# Development mode — uses symlinks so changes take effect immediately
zsh install.sh --dev

# Reload shell
exec zsh
```

### Production Install

```bash
zsh install.sh
exec zsh
zsh-tool-install
```

## Project Structure

```
lib/
├── core/           # Shared utilities (utils.zsh, component-manager.zsh)
├── install/        # Installation modules (7 files)
├── update/         # Update modules (4 files)
├── restore/        # Backup/restore (2 files)
├── git/            # Git integration (1 file)
└── integrations/   # External tools (2 files)
```

## Development Conventions

### Function Naming

All functions MUST use the `_zsh_tool_` prefix:

```zsh
_zsh_tool_install_plugins() { ... }
_zsh_tool_backup_create() { ... }
```

### File Operations

Use atomic write pattern (temp file + mv):

```zsh
local tmp_file="${target_file}.tmp.$$"
# write to tmp_file
mv "$tmp_file" "$target_file"
```

### Configuration

- All settings in `templates/config.yaml`
- Parsed by `lib/install/config.zsh`
- User config stored at `~/.config/zsh-tool/config.yaml`

### State Management

- JSON files for persistent state
- Dot-notation access via `lib/core/utils.zsh`

## Testing

### Run All Tests

```bash
zsh tests/run-all-tests.sh
```

### Run Individual Test

```bash
zsh tests/test-plugins.zsh
zsh tests/test-atuin.zsh
```

### Test Conventions

- Each `lib/` module has a matching `tests/test-*.zsh` file
- Tests use ZSH's built-in assertion patterns
- Security tests cover input validation and edge cases
- 15 test files, ~200 total tests

### Test File Mapping

| Module | Test File |
|--------|-----------|
| `lib/install/prerequisites.zsh` | `tests/test-prerequisites.zsh` |
| `lib/install/plugins.zsh` | `tests/test-plugins.zsh` |
| `lib/install/themes.zsh` | `tests/test-themes.zsh` |
| `lib/install/config.zsh` | `tests/test-config.zsh` |
| `lib/install/backup.zsh` | `tests/test-backup.zsh` |
| `lib/install/verify.zsh` | `tests/test-verify.zsh` |
| `lib/restore/backup-mgmt.zsh` | `tests/test-backup-mgmt.zsh` |
| `lib/restore/restore.zsh` | `tests/test-restore.zsh` |
| `lib/update/self.zsh` | `tests/test-self-update.zsh` |
| `lib/update/plugins.zsh + themes.zsh` | `tests/test-bulk-update.zsh` |
| `lib/git/integration.zsh` | `tests/test-git-integration.zsh` |
| `lib/integrations/atuin.zsh` | `tests/test-atuin.zsh` |
| `lib/integrations/kiro-cli.zsh` | `tests/test-kiro-cli.zsh`, `tests/test-kiro-cli-edge-cases.zsh` |

## CI/CD

GitHub Actions workflows (`.github/workflows/`):

- **claude.yml** — Claude AI integration
- **claude-code-review.yml** — AI-assisted code review on PRs

No automated test execution in CI (tests run locally).

## Common Development Tasks

### Adding a New Module

1. Create `lib/{category}/new-module.zsh`
2. Use `_zsh_tool_` prefix for all functions
3. Create matching `tests/test-new-module.zsh`
4. Register in `lib/core/component-manager.zsh` if needed

### Adding a New Integration

1. Create `lib/integrations/new-tool.zsh`
2. Add configuration section to `templates/config.yaml`
3. Add parsing logic to `lib/install/config.zsh`
4. Create test file and edge-case tests
5. Update documentation

### Modifying Configuration Schema

1. Edit `templates/config.yaml`
2. Update parsing in `lib/install/config.zsh`
3. Update `templates/zshrc.template` if new shell configuration needed
4. Test with `zsh tests/test-config.zsh`
