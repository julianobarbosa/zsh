---
title: 'Migrate Amazon Q to Kiro CLI'
slug: 'kiro-cli-migration'
created: '2026-01-05'
status: 'ready'
stepsCompleted: [1, 2, 3, 4]
tech_stack: [zsh, jq, homebrew]
files_to_modify:
  - lib/integrations/amazon-q.zsh
  - lib/install/config.zsh
  - lib/integrations/atuin.zsh
  - templates/config.yaml
  - install.sh
  - tests/test-amazon-q.zsh
  - tests/test-amazon-q-edge-cases.zsh
  - README.md
code_patterns:
  - function naming: _kiro_* prefix
  - config parsing: _zsh_tool_parse_kiro_*
  - environment variables: KIRO_* prefix
test_patterns:
  - unit tests in tests/test-kiro-cli.zsh
  - edge cases in tests/test-kiro-cli-edge-cases.zsh
---

# Tech-Spec: Migrate Amazon Q to Kiro CLI

**Created:** 2026-01-05
**Story Reference:** `docs/stories/story-kiro-cli-migration.md`

## Overview

### Problem Statement

Amazon Q Developer CLI was rebranded to Kiro CLI in November 2025. The zsh-tool project has 52 files referencing "Amazon Q" that need to be updated to reflect the new branding, paths, and commands.

### Solution

Perform a comprehensive migration of all Amazon Q references to Kiro CLI, including:
- Renaming files and functions
- Updating configuration paths and environment variables
- Updating documentation and tests
- Clean break approach (no backward compatibility)

### Scope

**In Scope:**
- Core module rename: `amazon-q.zsh` → `kiro-cli.zsh`
- All function renames: `_amazonq_*` → `_kiro_*`
- Config section: `amazon_q:` → `kiro_cli:`
- Path updates: `~/.aws/amazonq/` → `~/.kiro/`
- Test file renames and updates
- Documentation updates (README, stories, implementation docs)
- Command rename: `zsh-tool-amazonq` → `zsh-tool-kiro`

**Out of Scope:**
- Backward compatibility shims
- Auto-migration of user configs (Kiro CLI handles this)
- Supporting both Amazon Q and Kiro CLI simultaneously

## Context for Development

### Codebase Patterns

- Functions use `_zsh_tool_` prefix for internal helpers
- Integration modules use `_<integration>_` prefix (e.g., `_kiro_`)
- Config parsing uses `_zsh_tool_parse_<section>_<field>` pattern
- Environment variables use `UPPERCASE_SNAKE_CASE`
- Tests follow `test_<function_name>` naming

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `lib/integrations/amazon-q.zsh` | Current implementation (497 lines) |
| `lib/install/config.zsh` | Config parsing functions |
| `templates/config.yaml` | Configuration template |
| `docs/stories/story-kiro-cli-migration.md` | Full migration story |

### Technical Decisions

1. **Clean Break**: No backward compatibility - users must update to Kiro CLI
2. **Path Mapping**: Follow official Kiro CLI paths exactly
3. **Function Naming**: Use `_kiro_` prefix consistently
4. **Config Section**: Use `kiro_cli:` (with underscore for YAML compatibility)

### Path Mapping Reference

| Component | Amazon Q (Old) | Kiro CLI (New) |
|-----------|---------------|----------------|
| User Config | `~/.aws/amazonq/` | `~/.kiro/` |
| Settings | `~/.aws/amazonq/settings.json` | `~/.kiro/settings/cli.json` |
| Shell RC | `~/.aws/amazonq/shell/zshrc` | `~/.kiro/shell/zshrc` |
| App | `/Applications/Amazon Q.app` | `/Applications/Kiro.app` |
| Homebrew | `amazon-q` | `kiro-cli` |

## Implementation Plan

### Task 1: Core Module Migration [HIGH]

**File:** `lib/integrations/amazon-q.zsh` → `lib/integrations/kiro-cli.zsh`

1. Create new file `lib/integrations/kiro-cli.zsh`
2. Copy content from `amazon-q.zsh`
3. Rename all functions:
   - `_amazonq_is_installed` → `_kiro_is_installed`
   - `_amazonq_detect` → `_kiro_detect`
   - `_amazonq_install` → `_kiro_install`
   - `_amazonq_configure_shell_integration` → `_kiro_configure_shell_integration`
   - `_amazonq_health_check` → `_kiro_health_check`
   - `_amazonq_validate_cli_name` → `_kiro_validate_cli_name`
   - `_amazonq_configure_settings` → `_kiro_configure_settings`
   - `_amazonq_configure_atuin_compatibility` → `_kiro_configure_atuin_compatibility`
   - `_amazonq_setup_lazy_loading` → `_kiro_setup_lazy_loading`
   - `amazonq_install_integration` → `kiro_install_integration`
4. Update environment variables:
   - `AMAZONQ_CONFIG_DIR` → `KIRO_CONFIG_DIR` (default: `~/.kiro`)
   - `AMAZONQ_SETTINGS_FILE` → `KIRO_SETTINGS_FILE` (default: `~/.kiro/settings/cli.json`)
   - `AMAZONQ_APP_PATH` → `KIRO_APP_PATH` (default: `/Applications/Kiro.app`)
5. Update version detection for "Kiro" string
6. Update shell integration path to `~/.kiro/shell/zshrc`
7. Update Homebrew cask to `kiro-cli`
8. Update all log messages and comments
9. Delete old `amazon-q.zsh` file

### Task 2: Configuration Migration [HIGH]

**File:** `templates/config.yaml`

1. Rename `amazon_q:` section to `kiro_cli:`
2. Update all comments referencing Amazon Q

**File:** `lib/install/config.zsh`

3. Rename parsing functions:
   - `_zsh_tool_parse_amazon_q_enabled` → `_zsh_tool_parse_kiro_enabled`
   - `_zsh_tool_parse_amazon_q_lazy_loading` → `_zsh_tool_parse_kiro_lazy_loading`
   - `_zsh_tool_parse_amazon_q_atuin_compatibility` → `_zsh_tool_parse_kiro_atuin_compatibility`
   - `_zsh_tool_parse_amazon_q_disabled_clis` → `_zsh_tool_parse_kiro_disabled_clis`
4. Update section extraction from "amazon_q" to "kiro_cli"

### Task 3: Test Migration [HIGH]

1. Rename `tests/test-amazon-q.zsh` → `tests/test-kiro-cli.zsh`
2. Rename `tests/test-amazon-q-edge-cases.zsh` → `tests/test-kiro-cli-edge-cases.zsh`
3. Update all test function names
4. Update test environment variables
5. Update test assertions for new paths/names
6. Update `tests/run-all-tests.sh` references
7. Update `tests/test-config.zsh` if it references Amazon Q

### Task 4: Install Script Migration [MEDIUM]

**File:** `install.sh`

1. Rename command `zsh-tool-amazonq` → `zsh-tool-kiro`
2. Update help text and usage examples
3. Update integration loader to source `kiro-cli.zsh`

### Task 5: Atuin Integration Update [MEDIUM]

**File:** `lib/integrations/atuin.zsh`

1. Rename `_atuin_configure_amazonq_compatibility` → `_atuin_configure_kiro_compatibility`
2. Update all Amazon Q references to Kiro
3. Update comments and log messages

### Task 6: Documentation Migration [MEDIUM]

Update these files:
- `README.md` - Replace all "Amazon Q" with "Kiro CLI"
- `CONTRIBUTING.md` - Update references
- `CHANGELOG.md` - Add migration entry
- `docs/CODEBASE-ANALYSIS.md`
- `docs/ATUIN-CTRL-R-FIX.md`
- `docs/project-context.md`

### Task 7: Story Files Update [LOW]

1. Verify deprecation notice in `docs/stories/story-amazon-q-integration.md`
2. Add migration notes to amazonq-fix story files

### Task 8: Cleanup & Verification [HIGH]

1. Delete old files:
   - `lib/integrations/amazon-q.zsh`
   - `tests/test-amazon-q.zsh`
   - `tests/test-amazon-q-edge-cases.zsh`
2. Run full test suite
3. Grep for remaining "amazon" references
4. Manual verification of installation flow

## Acceptance Criteria

### AC1: Core Module
```gherkin
Given the kiro-cli.zsh module exists
When I source the module
Then all _kiro_* functions are available
And no _amazonq_* functions exist
```

### AC2: Configuration
```gherkin
Given a config.yaml with kiro_cli: section
When the config is parsed
Then kiro_enabled, kiro_lazy_loading values are correctly extracted
And amazon_q section parsing returns empty/default
```

### AC3: Detection
```gherkin
Given Kiro CLI is installed
When _kiro_is_installed is called
Then it returns 0 (success)
And correctly identifies the Kiro version string
```

### AC4: Tests Pass
```gherkin
Given all test files are migrated
When ./tests/run-all-tests.sh is executed
Then all tests pass
And no test references amazon-q
```

### AC5: No Amazon References
```gherkin
Given the migration is complete
When grep -ri "amazon.q\|amazonq" is run (excluding archives/stories)
Then no matches are found in active code files
```

## Additional Context

### Dependencies

- Kiro CLI installed (for testing)
- jq for JSON manipulation
- macOS 12+ (Kiro CLI requirement)

### Testing Strategy

1. **Unit tests**: Verify each renamed function works identically
2. **Integration tests**: Full installation flow with Kiro CLI
3. **Regression tests**: Ensure no Amazon Q references break anything
4. **Manual testing**: Install on clean system

### Notes

- The `q` command still works in Kiro CLI (backward compatible)
- Kiro CLI auto-migrates configs from `~/.aws/amazonq/` to `~/.kiro/`
- We're doing a clean break - no dual support
- Estimated: 13 story points (~2-3 hours focused work)

---
**Generated from:** `docs/stories/story-kiro-cli-migration.md`
**Template Version:** BMad Method v6
