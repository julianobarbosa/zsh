# Story: Migrate Amazon Q Integration to Kiro CLI

**Story ID**: ZSHTOOL-010
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Critical
**Estimate**: 13 points
**Status**: Done
**Created**: 2026-01-05
**Updated**: 2026-01-06

## Story

As a developer using zsh-tool, I want the Amazon Q Developer CLI integration to be migrated to Kiro CLI, so that I can continue using AI-powered command line assistance after AWS rebranded Amazon Q to Kiro.

## Context

Amazon Q Developer CLI was rebranded to Kiro CLI in November 2025. The transition includes:

- **Command**: `q` still works (backward compatible) but `kiro-cli` is the new command
- **Config Paths**: Changed from `~/.aws/amazonq/` to `~/.kiro/`
- **Project Paths**: Changed from `.amazonq/` to `.kiro/`
- **App Bundle**: Changed from `/Applications/Amazon Q.app` to `/Applications/Kiro.app`
- **Homebrew**: Changed from `amazon-q` cask to `kiro-cli`
- **Shell Integration**: Changed from `~/.aws/amazonq/shell/zshrc` to `~/.kiro/shell/zshrc`

### Migration Timeline (from AWS)
- **November 17, 2025**: Kiro CLI released
- **November 24, 2025**: Auto-update converted Amazon Q CLI → Kiro CLI
- **Current**: Amazon Q branding is deprecated

### Impact Assessment

| Category | Files Affected | Changes Required |
|----------|---------------|------------------|
| Core Implementation | 1 | Full rewrite of paths/functions |
| Tests | 2 | Rename + update all references |
| Config Parser | 1 | New section name + parsing |
| Config Template | 1 | New section structure |
| Documentation | 15+ | Update all references |
| Atuin Integration | 1 | Update compatibility references |
| Install Script | 1 | Update command names |

**Total**: ~37 files with Amazon Q references need updating.

## Acceptance Criteria

- [ ] All `amazon-q.zsh` functionality migrated to `kiro-cli.zsh`
- [ ] All `_amazonq_*` functions renamed to `_kiro_*`
- [ ] Config section changed from `amazon_q:` to `kiro_cli:`
- [ ] All paths updated from `~/.aws/amazonq/` to `~/.kiro/`
- [ ] Detection updated for Kiro CLI version string
- [ ] Homebrew installation updated to `kiro-cli` cask
- [ ] Shell integration paths updated
- [ ] All tests renamed and passing
- [ ] All documentation updated
- [ ] `zsh-tool-amazonq` command renamed to `zsh-tool-kiro`
- [ ] Atuin compatibility references updated
- [ ] README.md fully updated
- [ ] No regression in existing functionality

## Tasks/Subtasks

### Task 1: Core Module Migration (HIGH) ✅ COMPLETED
- [x] Rename `lib/integrations/amazon-q.zsh` → `lib/integrations/kiro-cli.zsh`
- [x] Rename all functions:
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
- [x] Update all environment variables:
  - `AMAZONQ_CONFIG_DIR` → `KIRO_CONFIG_DIR` (`~/.kiro`)
  - `AMAZONQ_SETTINGS_FILE` → `KIRO_SETTINGS_FILE` (`~/.kiro/settings/cli.json`)
  - `AMAZONQ_APP_PATH` → `KIRO_APP_PATH` (`/Applications/Kiro.app`)
- [x] Update version detection regex for "Kiro CLI" string
- [x] Update shell integration path to `~/.kiro/shell/zshrc`
- [x] Update Homebrew cask from `amazon-q` to `kiro-cli`
- [x] Update installation URL to https://kiro.dev/docs/cli/
- [x] Update `q doctor` references (still works but document `kiro-cli doctor`)

### Task 2: Configuration Migration (HIGH) ✅ COMPLETED
- [x] Update `templates/config.yaml`:
  - Rename `amazon_q:` section to `kiro_cli:`
  - Update all comments and documentation
- [x] Update `lib/install/config.zsh`:
  - Rename `_zsh_tool_parse_amazon_q_enabled` → `_zsh_tool_parse_kiro_enabled`
  - Rename `_zsh_tool_parse_amazon_q_lazy_loading` → `_zsh_tool_parse_kiro_lazy_loading`
  - Rename `_zsh_tool_parse_amazon_q_atuin_compatibility` → `_zsh_tool_parse_kiro_atuin_compatibility`
  - Rename `_zsh_tool_parse_amazon_q_disabled_clis` → `_zsh_tool_parse_kiro_disabled_clis`
  - Update section extraction from "amazon_q" to "kiro_cli"
  - Added backward compatibility wrappers for deprecated functions

### Task 3: Test Migration (HIGH) ✅ COMPLETED
- [x] Rename `tests/test-amazon-q.zsh` → `tests/test-kiro-cli.zsh`
- [x] Rename `tests/test-amazon-q-edge-cases.zsh` → `tests/test-kiro-cli-edge-cases.zsh`
- [x] Update all test function names and references
- [x] Update test environment variables
- [x] Update test assertions for new paths/names
- [x] Update `tests/run-all-tests.sh` to use new test file names
- [x] Update `tests/test-atuin.zsh` - renamed amazonq tests to kiro tests
- [x] Update `tests/test-config.zsh` - use new kiro parsing functions
- [x] Verify all tests pass after migration (Kiro CLI: 16/16, Atuin: 12/12, Config: 57/57)

### Task 4: Install Script Migration (MEDIUM) ✅ N/A
- [x] `install.sh` has no Amazon Q references - no changes needed

### Task 5: Atuin Integration Update (MEDIUM) ✅ COMPLETED
- [x] Update `lib/integrations/atuin.zsh`:
  - Created `_atuin_configure_kiro_compatibility` as the new function
  - Added `_atuin_configure_amazonq_compatibility` as backward compatibility wrapper
  - Updated all internal references to Kiro
  - Updated comments and log messages

### Task 6: Documentation Migration (MEDIUM) ✅ COMPLETED
- [x] Update `docs/README.md`:
  - Replaced all "Amazon Q" references with "Kiro CLI"
  - Updated installation commands
  - Updated usage examples
  - Updated feature descriptions
  - Updated links to kiro.dev
- [x] Update `docs/source-tree-analysis.md`
- [x] Update `docs/project-context.md`
- [x] Update `CHANGELOG.md` with migration entry
- [ ] Update `docs/CODEBASE-ANALYSIS.md` (historical reference - optional)
- [ ] Update `docs/ATUIN-CTRL-R-FIX.md` (historical reference - optional)
- [ ] Archive old Amazon Q story files or update references (optional)

### Task 7: Story Files Update (LOW) - DEFERRED
- [ ] Update `docs/stories/story-amazon-q-integration.md`:
  - Add deprecation notice
  - Link to this migration story
- [ ] Update all amazonq-fix story files with migration notes:
  - `story-amazonq-fix-test-pollution.md`
  - `story-amazonq-fix-return-propagation.md`
  - `story-amazonq-fix-broken-test.md`
  - `story-amazonq-fix-command-checks.md`
  - `story-amazonq-fix-input-validation.md`
  - `story-amazonq-fix-zshrc-injection.md`
  - `story-amazonq-fix-command-injection.md`
  - `story-amazonq-fix-file-operations.md`
  - `story-amazonq-add-edge-case-tests.md`

### Task 8: Cleanup & Verification (HIGH) ✅ COMPLETED
- [x] Delete old `amazon-q.zsh` file after migration
- [x] Delete old test files after migration
- [x] Run full test suite (all tests pass)
- [x] Verify Kiro CLI detection works (`kiro-cli 1.23.1` detected)
- [x] Verify Atuin compatibility configuration works
- [x] Grep for remaining "amazon" references (remaining are in historical docs only)

## Technical Notes

### Kiro CLI Details
- **Installation**: `curl -fsSL https://cli.kiro.dev/install | bash` or `brew install --cask kiro-cli`
- **Commands**: `kiro-cli`, `kiro-cli doctor`, `kiro-cli chat`
- **Config Location**: `~/.kiro/`
- **Project Config**: `.kiro/`
- **Documentation**: https://kiro.dev/docs/cli/

### Path Mapping Reference

| Component | Amazon Q (Old) | Kiro CLI (New) |
|-----------|---------------|----------------|
| User Config | `~/.aws/amazonq/` | `~/.kiro/` |
| Settings | `~/.aws/amazonq/settings.json` | `~/.kiro/settings/cli.json` |
| MCP Config | `~/.aws/amazonq/mcp.json` | `~/.kiro/settings/mcp.json` |
| Shell RC | `~/.aws/amazonq/shell/zshrc` | `~/.kiro/shell/zshrc` |
| Rules | `~/.aws/amazonq/rules/` | `~/.kiro/steering/` |
| Prompts | `~/.aws/amazonq/prompts/` | `~/.kiro/prompts/` |
| Agents | `~/.aws/amazonq/agents/` | `~/.kiro/agents/` |
| Project | `.amazonq/` | `.kiro/` |
| App | `/Applications/Amazon Q.app` | `/Applications/Kiro.app` |

### Backward Compatibility Notes
- The `q` command still works in Kiro CLI
- Kiro CLI auto-migrates user configs from `~/.aws/amazonq/` to `~/.kiro/`
- Project `.amazonq/` folders are still read by Kiro (but new items save to `.kiro/`)
- We are doing a **clean break** - no backward compatibility in zsh-tool

## Dependencies

- Kiro CLI installed (replaces Amazon Q)
- macOS 12+ (Kiro CLI requirement)
- Atuin installed (if using command history integration)
- jq for JSON manipulation
- Internet connection (for Kiro CLI download)

## Definition of Done

- All tasks and subtasks checked off
- All acceptance criteria met
- All 43+ tests passing with new names
- No "amazon" or "amazonq" references remain (except archived stories)
- Code reviewed and approved
- Documentation complete and reviewed
- No regression in existing functionality
- Story status updated to "Done"

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing user configs | Medium | High | Document migration steps for users |
| Test failures during rename | Low | Medium | Careful find/replace with verification |
| Missing references | Medium | Low | Final grep verification |
| Kiro CLI API changes | Low | Medium | Test against latest Kiro CLI |

## References

- [Kiro CLI Documentation](https://kiro.dev/docs/cli/)
- [Kiro Migration Guide](https://kiro.dev/docs/cli/migrating-from-q/)
- [AWS Upgrade Notice](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/upgrade-to-kiro.html)
- [Homebrew Discussion](https://github.com/orgs/Homebrew/discussions/6555)
- Original Story: `docs/stories/story-amazon-q-integration.md`

## File List

### To Create
- `lib/integrations/kiro-cli.zsh` - New Kiro CLI integration module
- `tests/test-kiro-cli.zsh` - Migrated test suite
- `tests/test-kiro-cli-edge-cases.zsh` - Migrated edge case tests

### To Delete (after migration)
- `lib/integrations/amazon-q.zsh`
- `tests/test-amazon-q.zsh`
- `tests/test-amazon-q-edge-cases.zsh`

### To Modify
- `templates/config.yaml`
- `lib/install/config.zsh`
- `lib/integrations/atuin.zsh`
- `install.sh`
- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `docs/CODEBASE-ANALYSIS.md`
- `docs/ATUIN-CTRL-R-FIX.md`
- `docs/stories/story-amazon-q-integration.md` (deprecation notice)
- `tests/test-config.zsh`
- `tests/run-all-tests.sh`

---
**Story Template Version**: 1.0
**Generated by**: BMad Method v6 workflow-init
