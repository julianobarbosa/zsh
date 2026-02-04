# ZSH Tool Test Coverage

> Comprehensive test suite documentation

---

## Test Suite Overview

| Test File | Tests | Module | Description |
|-----------|-------|--------|-------------|
| test-prerequisites.zsh | 15 | Install | System requirement checks |
| test-plugins.zsh | 12 | Install | Plugin installation |
| test-themes.zsh | 10 | Install | Theme management |
| test-backup.zsh | 20 | Core | Backup creation |
| test-backup-mgmt.zsh | 18 | Core | Backup listing, pruning |
| test-restore.zsh | 25 | Restore | Restore operations |
| test-config.zsh | 50+ | Core | Configuration/YAML parsing |
| test-git-integration.zsh | 36 | Git | Dotfiles version control |
| test-atuin.zsh | 15 | Integrations | Atuin shell history |
| test-kiro-cli.zsh | 20 | Integrations | Kiro CLI basic |
| test-kiro-cli-edge-cases.zsh | 28 | Integrations | Security/edge cases |
| test-verify.zsh | 12 | Core | Installation verification |
| test-bulk-update.zsh | 15 | Update | Parallel updates |
| test-self-update.zsh | 10 | Update | Self-update mechanism |

**Total: 200+ tests**

---

## Test Framework

### Setup/Teardown Pattern

```zsh
# Test file structure
setup() {
  # Create isolated test environment
  TEST_HOME=$(mktemp -d)
  TEST_CONFIG_DIR="${TEST_HOME}/.config/zsh-tool"
  mkdir -p "$TEST_CONFIG_DIR"

  # Override environment
  export HOME="$TEST_HOME"
  export ZSH_TOOL_CONFIG_DIR="$TEST_CONFIG_DIR"
}

teardown() {
  # Cleanup
  rm -rf "$TEST_HOME"
}

test_something() {
  # Arrange
  setup

  # Act
  result=$(_zsh_tool_some_function)

  # Assert
  [[ "$result" == "expected" ]] || fail "Expected 'expected', got '$result'"

  # Cleanup
  teardown
}
```

### Assertion Functions

```zsh
# Common assertions used in tests
assert_equals() {
  [[ "$1" == "$2" ]] || fail "Expected '$2', got '$1'"
}

assert_file_exists() {
  [[ -f "$1" ]] || fail "File not found: $1"
}

assert_dir_exists() {
  [[ -d "$1" ]] || fail "Directory not found: $1"
}

assert_contains() {
  [[ "$1" == *"$2"* ]] || fail "String '$1' does not contain '$2'"
}

assert_return_code() {
  [[ $? -eq $1 ]] || fail "Expected return code $1, got $?"
}
```

---

## Detailed Test Coverage

### test-prerequisites.zsh (15 tests)

| Test | Description |
|------|-------------|
| `test_check_command_exists` | Verify `_zsh_tool_check_command` for existing commands |
| `test_check_command_missing` | Verify failure for non-existent commands |
| `test_check_zsh_version_valid` | Test zsh version >= 5.0 passes |
| `test_check_zsh_version_old` | Test zsh version < 5.0 fails |
| `test_check_git_available` | Verify git detection |
| `test_check_curl_available` | Verify curl detection |
| `test_check_wget_fallback` | Verify wget fallback when no curl |
| `test_all_prerequisites_pass` | Full prerequisite check with all present |
| `test_prerequisites_fail_no_git` | Fail when git missing |
| `test_prerequisites_fail_no_curl_wget` | Fail when both curl/wget missing |

---

### test-plugins.zsh (12 tests)

| Test | Description |
|------|-------------|
| `test_plugin_installed_check` | Check if plugin directory exists |
| `test_install_known_plugin` | Install zsh-autosuggestions |
| `test_install_custom_plugin` | Install from custom repo URL |
| `test_get_plugin_repo_known` | Get default repo for known plugin |
| `test_get_plugin_repo_unknown` | Handle unknown plugin name |
| `test_install_multiple_plugins` | Batch plugin installation |
| `test_plugin_already_installed` | Skip already installed plugins |
| `test_install_plugin_git_failure` | Handle git clone failures |

---

### test-themes.zsh (10 tests)

| Test | Description |
|------|-------------|
| `test_theme_list` | List installed custom themes |
| `test_install_custom_theme` | Clone theme to custom/themes |
| `test_theme_already_installed` | Skip existing themes |
| `test_update_theme` | Git pull for theme update |
| `test_theme_update_failure` | Handle update failures |

---

### test-backup.zsh (20 tests)

| Test | Description |
|------|-------------|
| `test_create_backup_basic` | Create backup with default name |
| `test_create_backup_with_tag` | Create backup with custom tag |
| `test_backup_contains_zshrc` | Verify .zshrc included |
| `test_backup_contains_history` | Verify .zsh_history included |
| `test_backup_contains_omz_custom` | Verify oh-my-zsh/custom included |
| `test_backup_contains_zshrc_local` | Verify .zshrc.local included |
| `test_backup_manifest_created` | Verify manifest.json generated |
| `test_backup_manifest_contents` | Verify manifest has correct fields |
| `test_backup_timestamp_format` | Verify YYYY-MM-DD-HHMMSS format |
| `test_backup_missing_file_handled` | Skip non-existent files gracefully |
| `test_backup_permission_denied` | Handle readonly directories |
| `test_backup_state_updated` | Verify state.json updated after backup |

---

### test-backup-mgmt.zsh (18 tests)

| Test | Description |
|------|-------------|
| `test_list_backups_empty` | No backups available message |
| `test_list_backups_single` | List one backup |
| `test_list_backups_multiple` | List multiple backups sorted by date |
| `test_prune_backups_default` | Keep 10, remove older |
| `test_prune_backups_custom` | Keep specified count |
| `test_prune_nothing_to_remove` | No action when under limit |
| `test_get_backup_size` | Calculate size correctly |
| `test_backup_size_format` | Human-readable size (KB/MB) |

---

### test-restore.zsh (25 tests)

| Test | Description |
|------|-------------|
| **AC1** | `test_restore_list_backups` | List available backups for restore |
| **AC2** | `test_restore_apply_by_number` | Restore using backup number |
| **AC2** | `test_restore_apply_by_timestamp` | Restore using full timestamp |
| **AC3** | `test_restore_shows_manifest` | Display what will be restored |
| **AC4** | `test_restore_creates_pre_backup` | Pre-restore backup created |
| **AC5** | `test_restore_atomic_copy` | Atomic file operations |
| **AC5** | `test_restore_temp_file_cleanup` | Temp files cleaned on failure |
| **AC6** | `test_restore_state_updated` | State reflects restore metadata |
| **AC7** | `test_restore_force_flag` | --force skips confirmation |
| **AC8** | `test_restore_reload_prompt` | Shows "exec zsh" message |
| **AC9** | `test_restore_not_found_error` | Error with backup list on not found |
| **AC10** | `test_restore_rollback_on_failure` | Automatic rollback on error |
| **AC10** | `test_rollback_restores_original` | Pre-restore state recovered |
| **AC11** | `test_partial_restore_stub` | --files flag stub message |
| **AC12** | `test_restore_permission_error` | Actionable permission error |
| | `test_restore_invalid_backup_id` | Error on invalid ID |
| | `test_restore_empty_backup` | Handle backup with no files |
| | `test_restore_zshrc_only` | Restore single file backup |
| | `test_restore_preserves_permissions` | File permissions maintained |

---

### test-config.zsh (50+ tests)

| Test | Description |
|------|-------------|
| **YAML Parsing** | |
| `test_parse_yaml_plugins` | Extract plugin list from YAML |
| `test_parse_yaml_theme` | Extract theme name |
| `test_parse_yaml_nested` | Handle nested structures |
| `test_parse_yaml_empty` | Handle empty config |
| **Zshrc Generation** | |
| `test_generate_zshrc_plugins` | Plugins array in generated file |
| `test_generate_zshrc_theme` | Theme variable set |
| `test_generate_zshrc_managed_section` | Managed section markers |
| `test_generate_zshrc_idempotent` | Re-run produces same result |
| **Installation** | |
| `test_install_creates_config_dir` | Config directory created |
| `test_install_copies_template` | Default config copied |
| `test_install_preserves_existing` | Don't overwrite user config |
| **Custom Layer** | |
| `test_custom_layer_merged` | User customizations preserved |
| `test_custom_layer_priority` | User values override defaults |
| **Validation** | |
| `test_validate_config_valid` | Valid config passes |
| `test_validate_config_invalid_yaml` | Invalid YAML detected |
| `test_validate_path_absolute` | Absolute paths required |
| `test_validate_path_traversal` | Block path traversal |

---

### test-git-integration.zsh (36 tests)

| Test | Description |
|------|-------------|
| **Init** | |
| `test_git_init_creates_bare_repo` | Bare repo at DOTFILES_REPO |
| `test_git_init_creates_gitignore` | Gitignore template created |
| `test_git_init_adds_alias` | Dotfiles alias in .zshrc.local |
| `test_git_init_sets_untracked_config` | status.showUntrackedFiles=no |
| `test_git_init_requires_git_config` | Requires user.name/email |
| `test_git_init_already_exists` | Error if repo exists |
| **Remote** | |
| `test_git_remote_add` | Add origin remote |
| `test_git_remote_update` | Update existing remote URL |
| `test_git_remote_empty_url_error` | Error on empty URL |
| **Operations** | |
| `test_git_status_shows_changes` | Status works correctly |
| `test_git_add_file` | Add file to index |
| `test_git_add_multiple` | Add multiple files |
| `test_git_commit_with_message` | Commit with -m |
| `test_git_commit_empty_message_error` | Error on empty message |
| `test_git_push_succeeds` | Push to remote |
| `test_git_pull_creates_backup` | Backup before pull |
| **State** | |
| `test_git_state_enabled` | State shows enabled |
| `test_git_state_repo_type` | State shows bare |
| `test_git_state_last_commit` | Timestamp updated |
| **Dispatcher** | |
| `test_dispatcher_init` | Routes to init |
| `test_dispatcher_unknown` | Shows help on unknown |

---

### test-atuin.zsh (15 tests)

| Test | Description |
|------|-------------|
| **AC1** | `test_atuin_detection_installed` | Detect atuin in PATH |
| **AC1** | `test_atuin_detection_not_installed` | Handle missing atuin |
| **AC3** | `test_atuin_config_toml_created` | Config file generated |
| **AC3** | `test_atuin_config_search_mode` | search_mode=fuzzy set |
| **AC3** | `test_atuin_config_style` | style=compact set |
| **AC5** | `test_atuin_keybinding_ctrl_r` | Ctrl+R binding configured |
| **AC6** | `test_atuin_kiro_compatibility` | Works alongside Kiro |
| **AC9** | `test_atuin_health_check_pass` | Health check passes |
| **AC9** | `test_atuin_health_check_fail` | Health check failure handling |
| | `test_atuin_setup_idempotent` | Re-run safe |
| | `test_atuin_preserves_existing_config` | Don't overwrite user config |

---

### test-kiro-cli.zsh (20 tests)

| Test | Description |
|------|-------------|
| `test_kiro_detection` | Detect kiro-cli in PATH |
| `test_kiro_config_created` | Config.yaml generated |
| `test_kiro_complete_basic` | Basic completion request |
| `test_kiro_validate_input_valid` | Valid input passes |
| `test_kiro_validate_input_too_long` | >500 chars rejected |
| `test_kiro_health_check` | Health check passes |
| `test_kiro_setup_idempotent` | Re-run safe |

---

### test-kiro-cli-edge-cases.zsh (28 tests)

| Test | Description |
|------|-------------|
| **Command Injection** | |
| `test_reject_semicolon` | `;` rejected |
| `test_reject_pipe` | `\|` rejected |
| `test_reject_ampersand` | `&` rejected |
| `test_reject_subshell` | `$()` rejected |
| `test_reject_backticks` | Backticks rejected |
| `test_reject_double_ampersand` | `&&` rejected |
| `test_reject_double_pipe` | `\|\|` rejected |
| **Length Limits** | |
| `test_accept_500_chars` | Exactly 500 chars OK |
| `test_reject_501_chars` | 501 chars rejected |
| `test_accept_empty_string` | Empty string handled |
| **Unicode** | |
| `test_reject_unicode_emoji` | Emoji rejected |
| `test_reject_unicode_chinese` | Chinese chars rejected |
| `test_accept_ascii_only` | ASCII-only passes |
| **Filesystem** | |
| `test_invalid_json_config` | Handle corrupted config |
| `test_readonly_config_dir` | Handle readonly directory |
| `test_missing_config_dir` | Create missing config dir |
| **Concurrent Access** | |
| `test_concurrent_requests` | Multiple simultaneous calls |
| `test_temp_file_collision` | Unique temp files per process |
| **Stress Tests** | |
| `test_rapid_requests` | 100 rapid requests |
| `test_temp_file_stress` | Temp file collision prevention |

---

## Test Isolation Patterns

### HOME Isolation
```zsh
# Each test gets isolated HOME
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
```

### PATH Restoration
```zsh
# Save/restore PATH to prevent test pollution
local original_path="$PATH"
# ... test that modifies PATH ...
export PATH="$original_path"
```

### Git Config Isolation
```zsh
# Use test-scoped git config
export GIT_CONFIG_GLOBAL="${TEST_HOME}/.gitconfig"
git config --global user.name "Test User"
git config --global user.email "test@example.com"
```

### State Isolation
```zsh
# Reset state between tests
rm -f "$ZSH_TOOL_STATE_FILE"
_zsh_tool_init_state
```

---

## Running Tests

```bash
# Run all tests
./tests/run-tests.sh

# Run specific test file
./tests/run-tests.sh test-restore.zsh

# Run with verbose output
ZSH_TOOL_DEBUG=1 ./tests/run-tests.sh

# Run single test function
./tests/run-tests.sh test-restore.zsh test_restore_force_flag
```

---

## Known Test Fixes

| ID | Description | File | Fix |
|----|-------------|------|-----|
| HIGH-1 | Test counting accuracy | test-backup.zsh | Fixed counter increment |
| HIGH-4 | PATH restoration | test-atuin.zsh | Save/restore PATH |
| HIGH-5 | Test isolation | test-atuin.zsh | Proper teardown |
| MEDIUM-2 | Temp file collision | test-kiro-cli.zsh | Use $$ in temp names |
| MEDIUM-3 | State cleanup | test-config.zsh | Reset state between tests |
| CRITICAL-1 | Git config isolation | test-git-integration.zsh | GIT_CONFIG_GLOBAL |
| CRITICAL-2 | Permission test mock | test-restore.zsh | Use readonly directory |
