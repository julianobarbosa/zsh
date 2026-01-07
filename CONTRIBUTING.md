# Contributing to zsh-tool

Thank you for your interest in contributing to zsh-tool! This guide will help you get started with contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

This project follows a professional code of conduct. By participating, you are expected to uphold this code:

- Be respectful and inclusive
- Focus on what is best for the community
- Show empathy towards other community members
- Accept constructive criticism gracefully
- Focus on technical merit in discussions

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- macOS 12 (Monterey) or newer
- zsh 5.8 or newer (comes with macOS)
- git 2.30 or newer
- A GitHub account
- Familiarity with shell scripting (bash/zsh)

### Finding Issues to Work On

1. Check the [GitHub Issues](https://github.com/julianobarbosa/zsh/issues) page
2. Look for issues labeled `good first issue` or `help wanted`
3. Review the [backlog](docs/backlog.md) for planned features
4. Comment on the issue to let others know you're working on it

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/zsh.git
cd zsh

# Add upstream remote
git remote add upstream https://github.com/julianobarbosa/zsh.git
```

### 2. Install in Development Mode

```bash
# Install with symlinks for immediate testing
zsh install.sh --dev
```

This creates symlinks instead of copies, so your changes are immediately reflected.

### 3. Create a Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create a feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

## Project Structure

Understanding the codebase organization:

```
zsh-tool/
├── install.sh              # Main installation entry point
├── lib/                    # Core functionality modules
│   ├── core/              # Utilities (logging, state management)
│   ├── install/           # Epic 1: Installation modules
│   │   ├── prerequisites.zsh
│   │   ├── backup.zsh
│   │   ├── omz.zsh
│   │   ├── config.zsh
│   │   ├── plugins.zsh
│   │   ├── themes.zsh
│   │   └── verify.zsh
│   ├── update/            # Epic 2: Update operations
│   ├── restore/           # Epic 2: Backup and restore
│   ├── git/               # Git integration
│   └── integrations/      # Epic 3: Advanced integrations
├── templates/             # Configuration templates
├── tests/                 # Test suite
├── docs/                  # Documentation
└── bmad/                  # BMAD workflow system
```

See [docs/CODEBASE-ANALYSIS.md](docs/CODEBASE-ANALYSIS.md) for detailed analysis.

## Development Workflow

### 1. Make Changes

- Keep changes focused and atomic
- Follow the coding standards (see below)
- Test thoroughly on your local machine
- Update documentation if needed

### 2. Test Your Changes

```bash
# Run existing tests
cd tests
zsh run-tests.zsh

# Manual testing
zsh-tool-install    # Test installation
zsh-tool-update     # Test updates
# etc.
```

### 3. Commit Your Changes

Follow conventional commit message format:

```bash
git add <files>
git commit -m "type(scope): description"
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(atuin): add sync status command
fix(install): resolve plugin installation race condition
docs(readme): update installation instructions
refactor(backup): improve error handling
test(kiro): add edge case tests
```

### 4. Keep Your Branch Updated

```bash
# Regularly sync with upstream
git checkout main
git pull upstream main
git checkout feature/your-feature-name
git rebase main
```

## Coding Standards

### Shell Scripting Guidelines

#### 1. Function Naming

```bash
# Use descriptive, snake_case names
function install_prerequisites() {
  # ...
}

# Prefix internal functions with underscore
function _internal_helper() {
  # ...
}
```

#### 2. Error Handling

```bash
# Always check command success
if ! command -v git &>/dev/null; then
  log_error "git is not installed"
  return 1
fi

# Use defensive programming
[[ -z "$required_var" ]] && {
  log_error "required_var is not set"
  return 1
}
```

#### 3. Logging

```bash
# Use consistent logging functions
log_info "Installing prerequisites..."
log_success "Installation complete"
log_warning "Plugin X is deprecated"
log_error "Failed to install Y"
```

#### 4. Variables

```bash
# Use uppercase for constants
readonly CONFIG_DIR="${HOME}/.config/zsh-tool"
readonly MAX_BACKUPS=10

# Use lowercase for local variables
local plugin_name="$1"
local install_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"

# Quote all variable expansions
rm -rf "${backup_dir}"
cd "${project_root}" || return 1
```

#### 5. Conditionals

```bash
# Use [[ ]] for tests (more robust than [ ])
if [[ -f "${config_file}" ]]; then
  source "${config_file}"
fi

# Prefer explicit conditions
if [[ "${enabled}" == "true" ]]; then
  # ...
fi
```

#### 6. Idempotency

All operations should be idempotent (safe to run multiple times):

```bash
# Good - idempotent
function install_plugin() {
  local plugin="$1"

  if [[ -d "${ZSH_CUSTOM}/plugins/${plugin}" ]]; then
    log_info "Plugin ${plugin} already installed"
    return 0
  fi

  # Install plugin...
}

# Bad - not idempotent
function install_plugin() {
  git clone "..." # Will fail if already exists
}
```

#### 7. User Feedback

```bash
# Provide clear progress indicators
log_info "Starting installation..."
log_info "  [1/3] Installing prerequisites..."
log_info "  [2/3] Configuring Oh My Zsh..."
log_info "  [3/3] Verifying installation..."
log_success "Installation complete!"

# Helpful error messages with remediation
log_error "Failed to install Homebrew"
log_info "Please install manually: /bin/bash -c \"\$(curl -fsSL ...)\""
```

### Code Organization

#### Module Structure

Each module should:

1. Have a clear, single responsibility
2. Start with a header comment explaining its purpose
3. Define public functions first, private functions last
4. Include error handling
5. Be independently testable

```bash
#!/usr/bin/env zsh
#
# lib/install/prerequisites.zsh
#
# Detects and installs prerequisites for zsh-tool:
# - Homebrew
# - git
# - Xcode Command Line Tools
# - jq (for Kiro CLI)
#

# Public functions

function install_prerequisites() {
  log_info "Checking prerequisites..."

  _check_xcode_cli_tools || return 1
  _install_homebrew || return 1
  _install_git || return 1
  _install_jq || return 1

  log_success "All prerequisites installed"
}

# Private functions

function _check_xcode_cli_tools() {
  # Implementation...
}

function _install_homebrew() {
  # Implementation...
}
```

## Testing

### Writing Tests

Add tests for all new features and bug fixes:

```bash
# tests/test-your-feature.zsh

# Setup
setup() {
  # Create test environment
}

# Test cases
test_feature_works() {
  # Arrange
  local input="test"

  # Act
  local result=$(your_function "$input")

  # Assert
  [[ "$result" == "expected" ]] || {
    echo "FAIL: Expected 'expected', got '$result'"
    return 1
  }

  echo "PASS: test_feature_works"
}

# Cleanup
teardown() {
  # Clean up test environment
}

# Run tests
setup
test_feature_works
teardown
```

### Running Tests

```bash
# Run all tests
cd tests
zsh run-all-tests.sh

# Run specific test
zsh test-kiro-cli.zsh

# Run edge case tests
zsh test-kiro-cli-edge-cases.zsh
```

### Test Coverage

Aim for comprehensive test coverage:

- Happy path scenarios
- Error conditions
- Edge cases
- Idempotency (running twice should produce same result)
- Backward compatibility

## Documentation

### When to Update Documentation

Update documentation when:

- Adding new features
- Changing existing behavior
- Fixing bugs that affected documented behavior
- Adding new configuration options

### Documentation Standards

1. **README.md**: Update user-facing documentation
2. **docs/**: Add technical documentation
3. **Inline comments**: Explain complex logic
4. **Function headers**: Document parameters and return values

### Documentation Format

```bash
#!/usr/bin/env zsh
#
# lib/example/feature.zsh
#
# Description of what this module does.
#

#
# install_feature - Install and configure feature
#
# Arguments:
#   $1 - Feature name
#   $2 - Installation directory (optional)
#
# Returns:
#   0 on success, 1 on failure
#
# Example:
#   install_feature "my-feature" "/opt/features"
#
function install_feature() {
  # Implementation...
}
```

## Submitting Changes

### Pull Request Process

1. **Update your branch**
   ```bash
   git checkout main
   git pull upstream main
   git checkout feature/your-feature
   git rebase main
   ```

2. **Push to your fork**
   ```bash
   git push origin feature/your-feature
   ```

3. **Create Pull Request**
   - Go to GitHub and create a PR from your fork
   - Use a clear, descriptive title
   - Reference any related issues
   - Describe your changes comprehensively

### Pull Request Template

```markdown
## Description
Brief description of what this PR does.

## Related Issues
Fixes #123
Related to #456

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on macOS 12 (Monterey)
- [ ] Tested on macOS 13 (Ventura)
- [ ] Tested on macOS 14 (Sonoma)
- [ ] Added/updated tests
- [ ] All tests passing

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] Tests added/updated
- [ ] Backward compatible (or breaking changes documented)
```

### Review Process

1. Maintainers will review your PR
2. Address any requested changes
3. Once approved, a maintainer will merge your PR
4. Your contribution will be included in the next release

## Release Process

Maintainers follow this process for releases:

1. **Version Bump**: Update version in relevant files
2. **Changelog**: Update CHANGELOG.md with all changes
3. **Testing**: Run full test suite
4. **Tag**: Create git tag (e.g., `v1.2.3`)
5. **Release**: Create GitHub release with notes
6. **Announce**: Notify team/users of new release

## Questions?

If you have questions:

1. Check existing documentation in [docs/](docs/)
2. Search [existing issues](https://github.com/julianobarbosa/zsh/issues)
3. Create a new issue with the `question` label
4. Ask in team Slack: #dev-tools

## Additional Resources

- [PRD](docs/PRD.md) - Product requirements and goals
- [Architecture](docs/solution-architecture.md) - Technical design
- [Codebase Analysis](docs/CODEBASE-ANALYSIS.md) - Code structure
- [Troubleshooting Guides](docs/INDEX.md#troubleshooting--fixes) - Common issues

---

Thank you for contributing to zsh-tool!
