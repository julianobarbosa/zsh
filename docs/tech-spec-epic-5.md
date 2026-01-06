---
title: 'direnv + 1Password Integration'
slug: 'direnv-1password-integration'
created: '2026-01-05'
status: 'ready'
stepsCompleted: [1, 2, 3, 4]
tech_stack: [zsh, direnv, 1password-cli, bash]
files_to_create:
  - lib/integrations/direnv.zsh
  - direnv/lib/ai-keys.sh
  - direnv/templates/ai-keys.env.tpl
files_to_modify:
  - lib/core/dispatcher.zsh
  - templates/config.yaml
  - install.sh
  - tests/run-all-tests.sh
code_patterns:
  - function naming: _direnv_* prefix
  - helper function: load_ai_keys
  - 1Password references: op://Vault/Item/field
test_patterns:
  - unit tests in tests/test-direnv.zsh
---

# Tech-Spec: direnv + 1Password Integration

**Created:** 2026-01-05
**Story Reference:** PRD Epic 4 - Environment Management Integration

## Overview

### Problem Statement

AI development workflows require access to multiple API keys (OpenAI, Anthropic, Google AI, etc.) and workflow credentials. Storing these in plain text `.env` files is insecure. Manual export is error-prone. Teams need a secure, per-project environment variable management solution.

### Solution

Integrate direnv with 1Password CLI (`op inject`) for on-demand credential fetching with biometric authentication. Credentials are never stored on disk; they're fetched from 1Password vault when entering a project directory.

### Scope

**In Scope:**
- direnv installation verification and shell hook setup
- 1Password CLI integration via `op inject` pattern
- Reusable helper function for AI API key loading
- Template-based secret references (version controllable)
- Session caching to reduce Touch ID prompts
- Per-project `.envrc` configuration support

**Out of Scope:**
- Offline credential caching (security risk)
- Service account tokens (personal developer workflow focus)
- Multi-vault complex configurations (kept simple)
- Windows/Linux (macOS-first with Touch ID integration)

## Context for Development

### Codebase Patterns

- Functions use `_zsh_tool_` prefix for internal helpers
- Integration modules use `_<integration>_` prefix (e.g., `_direnv_`)
- Config parsing uses `_zsh_tool_parse_<section>_<field>` pattern
- Helpers installed to `~/.direnv/lib/`
- Templates installed to `~/.direnv/templates/`

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `lib/integrations/atuin.zsh` | Pattern for integration modules |
| `lib/install/prerequisites.zsh` | Pattern for dependency detection |
| `docs/analysis/brainstorming-session-2026-01-05.md` | Design decisions and rationale |

### Technical Decisions

1. **No Disk Persistence**: Secrets live only in memory (fetched on-demand)
2. **op inject Pattern**: Single command, one auth prompt, faster than multiple `op read`
3. **Template Source of Truth**: `ai-keys.env.tpl` is version controllable (no secrets)
4. **Session Caching**: `OP_CACHE_EXPIRES_IN=300` reduces Touch ID prompts
5. **Warn-but-Continue**: Graceful degradation if 1Password unavailable

### Security Model

```
1Password Vault (encrypted, synced)
    │
    ▼ (biometric auth via Touch ID)
op inject command
    │
    ▼ (stdout, never written to disk)
eval in shell session
    │
    ▼ (environment variables)
AI tools/workflows use credentials
    │
    ▼ (on directory exit)
direnv unloads variables (clean slate)
```

## Implementation Plan

### Task 1: Core Integration Module [HIGH]

**File:** `lib/integrations/direnv.zsh`

```zsh
#!/usr/bin/env zsh
# direnv + 1Password integration for secure environment management

# Check if direnv is installed
_direnv_is_installed() {
  command -v direnv &>/dev/null
}

# Check if 1Password CLI is installed
_direnv_op_is_installed() {
  command -v op &>/dev/null
}

# Verify 1Password desktop app integration
_direnv_op_has_desktop_integration() {
  [[ -f "$HOME/.config/op/config" ]] || [[ -f "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/Library/Application Support/1Password/config/settings.json" ]]
}

# Install direnv if missing
_direnv_install() {
  if ! _direnv_is_installed; then
    _zsh_tool_log info "Installing direnv via Homebrew..."
    brew install direnv || return 1
  fi
  return 0
}

# Install 1Password CLI if missing
_direnv_op_install() {
  if ! _direnv_op_is_installed; then
    _zsh_tool_log info "Installing 1Password CLI via Homebrew..."
    brew install --cask 1password-cli || return 1
  fi
  return 0
}

# Setup direnv shell hook in .zshrc
_direnv_setup_shell_hook() {
  local zshrc="$HOME/.zshrc"
  local hook_line='eval "$(direnv hook zsh)"'

  if ! grep -qF "$hook_line" "$zshrc" 2>/dev/null; then
    _zsh_tool_log info "Adding direnv hook to .zshrc..."
    echo "" >> "$zshrc"
    echo "# direnv shell hook (added by zsh-tool)" >> "$zshrc"
    echo "$hook_line" >> "$zshrc"
  fi
  return 0
}

# Create direnv directory structure
_direnv_create_structure() {
  mkdir -p "$HOME/.direnv/lib"
  mkdir -p "$HOME/.direnv/templates"
  return 0
}

# Install AI keys helper function
_direnv_install_ai_keys_helper() {
  local helper_file="$HOME/.direnv/lib/ai-keys.sh"

  cat > "$helper_file" << 'HELPER_EOF'
#!/usr/bin/env bash
# AI API Keys loader - fetches credentials from 1Password
# Usage: source ~/.direnv/lib/ai-keys.sh && load_ai_keys

load_ai_keys() {
  # Check if op is available
  if ! command -v op &>/dev/null; then
    echo "⚠️  1Password CLI (op) not found - AI keys not loaded"
    return 1
  fi

  # Enable session caching (5 minutes)
  export OP_CACHE_EXPIRES_IN=300

  # Check for template file
  local template="$HOME/.direnv/templates/ai-keys.env.tpl"
  if [[ ! -f "$template" ]]; then
    echo "⚠️  Template not found: $template"
    return 1
  fi

  # Inject secrets from 1Password
  eval "$(op inject -i "$template" 2>/dev/null)" \
    && echo "✅ AI keys loaded ($(date +%H:%M))" \
    || echo "⚠️  AI keys not loaded - check 1Password"
}
HELPER_EOF

  chmod +x "$helper_file"
  return 0
}

# Install AI keys template
_direnv_install_ai_keys_template() {
  local template_file="$HOME/.direnv/templates/ai-keys.env.tpl"

  # Only create if doesn't exist (preserve user customizations)
  if [[ ! -f "$template_file" ]]; then
    cat > "$template_file" << 'TEMPLATE_EOF'
# AI API Keys - fetched from 1Password
# Customize vault/item names to match your 1Password setup
# Format: VARIABLE_NAME={{ op://Vault/Item/field }}

OPENAI_API_KEY={{ op://AI Keys/OpenAI/credential }}
ANTHROPIC_API_KEY={{ op://AI Keys/Anthropic/credential }}
# GOOGLE_AI_API_KEY={{ op://AI Keys/Google AI/credential }}
# GITHUB_TOKEN={{ op://Development/GitHub/token }}

# Add more keys as needed...
TEMPLATE_EOF
  fi
  return 0
}

# Main installation function
direnv_install_integration() {
  _zsh_tool_log info "Setting up direnv + 1Password integration..."

  # Install dependencies
  _direnv_install || return 1
  _direnv_op_install || return 1

  # Verify 1Password desktop app integration
  if ! _direnv_op_has_desktop_integration; then
    _zsh_tool_log warn "1Password desktop app integration not detected"
    _zsh_tool_log info "Enable CLI integration: 1Password > Settings > Developer > Command-Line Interface"
  fi

  # Setup shell hook
  _direnv_setup_shell_hook || return 1

  # Create directory structure
  _direnv_create_structure || return 1

  # Install helper and template
  _direnv_install_ai_keys_helper || return 1
  _direnv_install_ai_keys_template || return 1

  _zsh_tool_log info "direnv + 1Password integration complete!"
  _zsh_tool_log info ""
  _zsh_tool_log info "Next steps:"
  _zsh_tool_log info "  1. Edit ~/.direnv/templates/ai-keys.env.tpl to match your 1Password vault"
  _zsh_tool_log info "  2. Create .envrc in your project:"
  _zsh_tool_log info "     source ~/.direnv/lib/ai-keys.sh"
  _zsh_tool_log info "     load_ai_keys"
  _zsh_tool_log info "  3. Run: direnv allow"

  return 0
}

# Health check function
_direnv_health_check() {
  local status=0

  echo "direnv + 1Password Health Check"
  echo "================================"

  # Check direnv
  if _direnv_is_installed; then
    echo "✅ direnv: $(direnv version)"
  else
    echo "❌ direnv: not installed"
    status=1
  fi

  # Check 1Password CLI
  if _direnv_op_is_installed; then
    echo "✅ 1Password CLI: $(op --version 2>/dev/null || echo 'installed')"
  else
    echo "❌ 1Password CLI: not installed"
    status=1
  fi

  # Check desktop integration
  if _direnv_op_has_desktop_integration; then
    echo "✅ 1Password desktop integration: configured"
  else
    echo "⚠️  1Password desktop integration: not detected"
  fi

  # Check helper file
  if [[ -f "$HOME/.direnv/lib/ai-keys.sh" ]]; then
    echo "✅ AI keys helper: installed"
  else
    echo "❌ AI keys helper: not found"
    status=1
  fi

  # Check template file
  if [[ -f "$HOME/.direnv/templates/ai-keys.env.tpl" ]]; then
    echo "✅ AI keys template: installed"
  else
    echo "❌ AI keys template: not found"
    status=1
  fi

  return $status
}
```

### Task 2: Helper Function [HIGH]

**File:** `direnv/lib/ai-keys.sh`

```bash
#!/usr/bin/env bash
# AI API Keys loader - fetches credentials from 1Password
# Usage: source ~/.direnv/lib/ai-keys.sh && load_ai_keys

load_ai_keys() {
  # Check if op is available
  if ! command -v op &>/dev/null; then
    echo "⚠️  1Password CLI (op) not found - AI keys not loaded"
    return 1
  fi

  # Enable session caching (5 minutes)
  export OP_CACHE_EXPIRES_IN=300

  # Check for template file
  local template="$HOME/.direnv/templates/ai-keys.env.tpl"
  if [[ ! -f "$template" ]]; then
    echo "⚠️  Template not found: $template"
    return 1
  fi

  # Inject secrets from 1Password
  eval "$(op inject -i "$template" 2>/dev/null)" \
    && echo "✅ AI keys loaded ($(date +%H:%M))" \
    || echo "⚠️  AI keys not loaded - check 1Password"
}
```

### Task 3: Template File [MEDIUM]

**File:** `direnv/templates/ai-keys.env.tpl`

```bash
# AI API Keys - fetched from 1Password
# Customize vault/item names to match your 1Password setup
# Format: VARIABLE_NAME={{ op://Vault/Item/field }}

OPENAI_API_KEY={{ op://AI Keys/OpenAI/credential }}
ANTHROPIC_API_KEY={{ op://AI Keys/Anthropic/credential }}
# GOOGLE_AI_API_KEY={{ op://AI Keys/Google AI/credential }}
# GITHUB_TOKEN={{ op://Development/GitHub/token }}

# Add more keys as needed...
```

### Task 4: Configuration Updates [MEDIUM]

**File:** `templates/config.yaml` - Add direnv section:

```yaml
direnv:
  enabled: true
  onepassword_integration: true
  vault_name: "AI Keys"
  session_cache_seconds: 300
```

### Task 5: Dispatcher Integration [MEDIUM]

**File:** `lib/core/dispatcher.zsh` - Add direnv command:

```zsh
# Add to command routing
zsh-tool-direnv() {
  case "$1" in
    install)
      direnv_install_integration
      ;;
    status|health)
      _direnv_health_check
      ;;
    *)
      echo "Usage: zsh-tool-direnv [install|status]"
      echo ""
      echo "Commands:"
      echo "  install  Install direnv + 1Password integration"
      echo "  status   Check integration health"
      return 1
      ;;
  esac
}
```

### Task 6: Tests [HIGH]

**File:** `tests/test-direnv.zsh`

```zsh
#!/usr/bin/env zsh
# Tests for direnv + 1Password integration

# Source test helpers
source "${0:A:h}/test-helpers.zsh"

# Source the module
source "${0:A:h}/../lib/integrations/direnv.zsh"

test_direnv_is_installed() {
  # This test checks if direnv detection works
  # Mock: direnv is installed
  if command -v direnv &>/dev/null; then
    assert_success "_direnv_is_installed"
  else
    assert_failure "_direnv_is_installed"
  fi
}

test_op_is_installed() {
  # Check 1Password CLI detection
  if command -v op &>/dev/null; then
    assert_success "_direnv_op_is_installed"
  else
    assert_failure "_direnv_op_is_installed"
  fi
}

test_create_structure() {
  # Test directory creation
  local test_home=$(mktemp -d)
  HOME="$test_home" _direnv_create_structure

  assert_dir_exists "$test_home/.direnv/lib"
  assert_dir_exists "$test_home/.direnv/templates"

  rm -rf "$test_home"
}

test_helper_installation() {
  # Test helper file creation
  local test_home=$(mktemp -d)
  mkdir -p "$test_home/.direnv/lib"

  HOME="$test_home" _direnv_install_ai_keys_helper

  assert_file_exists "$test_home/.direnv/lib/ai-keys.sh"
  assert_file_contains "$test_home/.direnv/lib/ai-keys.sh" "load_ai_keys"

  rm -rf "$test_home"
}

test_template_installation() {
  # Test template file creation
  local test_home=$(mktemp -d)
  mkdir -p "$test_home/.direnv/templates"

  HOME="$test_home" _direnv_install_ai_keys_template

  assert_file_exists "$test_home/.direnv/templates/ai-keys.env.tpl"
  assert_file_contains "$test_home/.direnv/templates/ai-keys.env.tpl" "op://"

  rm -rf "$test_home"
}

# Run tests
run_tests
```

## Acceptance Criteria

### AC1: Prerequisites Detection
```gherkin
Given a fresh macOS system
When I run zsh-tool-direnv install
Then it detects if direnv is installed
And it detects if 1Password CLI is installed
And it offers to install missing dependencies
```

### AC2: Helper Function Works
```gherkin
Given direnv and 1Password CLI are installed
And the ai-keys.sh helper is sourced
When I call load_ai_keys
Then it fetches credentials from 1Password
And exports them as environment variables
And shows success/failure feedback
```

### AC3: Template-Based Configuration
```gherkin
Given the ai-keys.env.tpl template exists
When I add a new secret reference
And run load_ai_keys
Then the new secret is fetched and exported
```

### AC4: Session Caching
```gherkin
Given OP_CACHE_EXPIRES_IN=300 is set
When I load keys multiple times within 5 minutes
Then only the first load requires Touch ID
```

### AC5: Graceful Degradation
```gherkin
Given 1Password is not available
When I run load_ai_keys
Then it shows a warning message
And does not break the shell session
```

## Additional Context

### Dependencies

- direnv 2.32+ (via Homebrew)
- 1Password CLI 2.0+ (via Homebrew)
- 1Password desktop app with CLI integration enabled

### Example Project Setup

```bash
# In your project directory
cat > .envrc << 'EOF'
source ~/.direnv/lib/ai-keys.sh
load_ai_keys
EOF

# Allow direnv
direnv allow
```

### 1Password Vault Structure

Recommended organization:
```
AI Keys (vault)
├── OpenAI
│   └── credential (API key)
├── Anthropic
│   └── credential (API key)
├── Google AI
│   └── credential (API key)
└── GitHub
    └── token (PAT)
```

### Notes

- Touch ID required for first credential fetch per session
- 5-minute session cache reduces auth prompts
- Template is version controllable (commit to git)
- Secrets never stored on disk
- Estimated: 8 story points

---
**Generated from:** PRD Epic 4, brainstorming session 2026-01-05
**Template Version:** BMad Method v6
