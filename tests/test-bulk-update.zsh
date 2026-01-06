#!/usr/bin/env zsh
# Tests for Story 2.2: Bulk Plugin and Theme Updates

# Test setup
TEST_DIR="${0:A:h}"
LIB_DIR="${TEST_DIR:h}/lib"

# Mock environment
ZSH_TOOL_CONFIG_DIR="/tmp/zsh-tool-test-$$"
ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/zsh-tool.log"
ZSH_TOOL_STATE_FILE="${ZSH_TOOL_CONFIG_DIR}/state.json"
OMZ_INSTALL_DIR="${ZSH_TOOL_CONFIG_DIR}/.oh-my-zsh"
# Set ZSH_CUSTOM before sourcing modules so they use test paths
ZSH_CUSTOM="${OMZ_INSTALL_DIR}/custom"
OMZ_CUSTOM_PLUGINS="${ZSH_CUSTOM}/plugins"
OMZ_CUSTOM_THEMES="${ZSH_CUSTOM}/themes"

# Load modules (they will use ZSH_CUSTOM to determine paths)
source "${LIB_DIR}/core/utils.zsh"
source "${LIB_DIR}/update/omz.zsh"
source "${LIB_DIR}/update/plugins.zsh"
source "${LIB_DIR}/update/themes.zsh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
setup_test_env() {
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"
  mkdir -p "${OMZ_INSTALL_DIR}"
  mkdir -p "${OMZ_CUSTOM_PLUGINS}"
  mkdir -p "${OMZ_CUSTOM_THEMES}"

  # Initialize empty state
  echo '{}' > "$ZSH_TOOL_STATE_FILE"
}

teardown_test_env() {
  rm -rf "$ZSH_TOOL_CONFIG_DIR"
}

create_mock_git_plugin() {
  local plugin_name=$1
  local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin_name}"

  mkdir -p "$plugin_dir"
  cd "$plugin_dir"
  git init --initial-branch=main >/dev/null 2>&1
  git config user.name "Test" >/dev/null 2>&1
  git config user.email "test@test.com" >/dev/null 2>&1
  git config commit.gpgsign false >/dev/null 2>&1
  git config tag.gpgsign false >/dev/null 2>&1
  echo "# $plugin_name" > README.md
  git add . >/dev/null 2>&1
  git commit --no-verify -m "Initial commit" >/dev/null 2>&1
  git tag -a v1.0.0 -m "Version 1.0.0" --no-sign >/dev/null 2>&1
  cd - >/dev/null
}

create_mock_git_theme() {
  local theme_name=$1
  local theme_dir="${OMZ_CUSTOM_THEMES}/${theme_name}"

  mkdir -p "$theme_dir"
  cd "$theme_dir"
  git init --initial-branch=main >/dev/null 2>&1
  git config user.name "Test" >/dev/null 2>&1
  git config user.email "test@test.com" >/dev/null 2>&1
  git config commit.gpgsign false >/dev/null 2>&1
  git config tag.gpgsign false >/dev/null 2>&1
  echo "# $theme_name" > theme.zsh
  git add . >/dev/null 2>&1
  git commit --no-verify -m "Initial commit" >/dev/null 2>&1
  git tag -a v1.0.0 -m "Version 1.0.0" --no-sign >/dev/null 2>&1
  cd - >/dev/null
}

assert_equals() {
  local expected=$1
  local actual=$2
  local message=$3

  ((TESTS_RUN++))

  if [[ "$expected" == "$actual" ]]; then
    ((TESTS_PASSED++))
    echo "✓ PASS: $message"
    return 0
  else
    ((TESTS_FAILED++))
    echo "✗ FAIL: $message"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    return 1
  fi
}

assert_success() {
  local command=$1
  local message=$2

  ((TESTS_RUN++))

  if eval "$command" >/dev/null 2>&1; then
    ((TESTS_PASSED++))
    echo "✓ PASS: $message"
    return 0
  else
    ((TESTS_FAILED++))
    echo "✗ FAIL: $message"
    echo "  Command failed: $command"
    return 1
  fi
}

assert_failure() {
  local command=$1
  local message=$2

  ((TESTS_RUN++))

  if ! eval "$command" >/dev/null 2>&1; then
    ((TESTS_PASSED++))
    echo "✓ PASS: $message"
    return 0
  else
    ((TESTS_FAILED++))
    echo "✗ FAIL: $message"
    echo "  Command should have failed: $command"
    return 1
  fi
}

# Test 1: Theme version detection
test_theme_version_detection() {
  echo ""
  echo "TEST 1: Theme version detection"
  setup_test_env

  create_mock_git_theme "test-theme"
  local version=$(_zsh_tool_get_theme_version "test-theme")

  assert_equals "v1.0.0" "$version" "Should detect theme version from git tag"

  teardown_test_env
}

# Test 2: Non-git theme handling
test_non_git_theme() {
  echo ""
  echo "TEST 2: Non-git theme handling"
  setup_test_env

  mkdir -p "${OMZ_CUSTOM_THEMES}/non-git-theme"
  # Capture version and exit code separately to avoid local masking exit code
  local version
  version=$(_zsh_tool_get_theme_version "non-git-theme" 2>/dev/null)
  local exit_code=$?

  assert_equals "1" "$exit_code" "Should return error for non-git theme"
  assert_equals "not-git" "$version" "Should return 'not-git' for non-git theme"

  teardown_test_env
}

# Test 3: Theme update - already up to date
test_theme_update_up_to_date() {
  echo ""
  echo "TEST 3: Theme update when already up to date"
  setup_test_env

  create_mock_git_theme "test-theme"

  assert_success "_zsh_tool_update_theme test-theme" "Should successfully 'update' theme that's already current"

  teardown_test_env
}

# Test 4: Update all themes
test_update_all_themes() {
  echo ""
  echo "TEST 4: Update all themes"
  setup_test_env

  create_mock_git_theme "theme1"
  create_mock_git_theme "theme2"
  mkdir -p "${OMZ_CUSTOM_THEMES}/non-git-theme"

  assert_success "_zsh_tool_update_all_themes" "Should update all git-based themes"

  teardown_test_env
}

# Test 5: Check theme updates
test_check_theme_updates() {
  echo ""
  echo "TEST 5: Check for theme updates without applying"
  setup_test_env

  create_mock_git_theme "test-theme"

  # No updates available (same commit)
  assert_failure "_zsh_tool_check_theme_updates test-theme" "Should return failure when no updates available"

  teardown_test_env
}

# Test 6: Check all themes
test_check_all_themes() {
  echo ""
  echo "TEST 6: Check all themes for updates"
  setup_test_env

  create_mock_git_theme "theme1"
  create_mock_git_theme "theme2"

  # No updates available
  assert_failure "_zsh_tool_check_all_themes" "Should return failure when all themes are up to date"

  teardown_test_env
}

# Test 7: Check all plugins
test_check_all_plugins() {
  echo ""
  echo "TEST 7: Check all plugins for updates"
  setup_test_env

  create_mock_git_plugin "plugin1"
  create_mock_git_plugin "plugin2"

  # No updates available
  assert_failure "_zsh_tool_check_all_plugins" "Should return failure when all plugins are up to date"

  teardown_test_env
}

# Test 8: State tracking for themes
test_theme_state_tracking() {
  echo ""
  echo "TEST 8: Theme state tracking"
  setup_test_env

  create_mock_git_theme "test-theme"
  _zsh_tool_update_theme "test-theme" >/dev/null 2>&1

  # Check state file contains theme version
  local state_content=$(cat "$ZSH_TOOL_STATE_FILE")

  if [[ "$state_content" == *"test-theme"* ]]; then
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo "✓ PASS: State file should contain theme update information"
  else
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    echo "✗ FAIL: State file should contain theme update information"
  fi

  teardown_test_env
}

# Test 9: Missing themes directory
test_missing_themes_directory() {
  echo ""
  echo "TEST 9: Handle missing themes directory"
  setup_test_env

  rm -rf "$OMZ_CUSTOM_THEMES"

  assert_success "_zsh_tool_update_all_themes" "Should handle missing themes directory gracefully"

  teardown_test_env
}

# Test 10: Mixed git and non-git themes
test_mixed_themes() {
  echo ""
  echo "TEST 10: Handle mix of git and non-git themes"
  setup_test_env

  create_mock_git_theme "git-theme"
  mkdir -p "${OMZ_CUSTOM_THEMES}/non-git-theme"

  assert_success "_zsh_tool_update_all_themes" "Should update git themes and skip non-git"

  teardown_test_env
}

# Test 11: Theme update counter accuracy
test_theme_update_counters() {
  echo ""
  echo "TEST 11: Theme update counter accuracy"
  setup_test_env

  create_mock_git_theme "theme1"
  create_mock_git_theme "theme2"
  mkdir -p "${OMZ_CUSTOM_THEMES}/non-git-theme"

  local output=$(_zsh_tool_update_all_themes 2>&1)

  if [[ "$output" == *"2 updated"* ]] && [[ "$output" == *"1 skipped"* ]]; then
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo "✓ PASS: Counter should show 2 updated and 1 skipped"
  else
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    echo "✗ FAIL: Counter should show 2 updated and 1 skipped"
    echo "  Output: $output"
  fi

  teardown_test_env
}

# Test 12: Plugin version detection
test_plugin_version_detection() {
  echo ""
  echo "TEST 12: Plugin version detection"
  setup_test_env

  create_mock_git_plugin "test-plugin"
  local version=$(_zsh_tool_get_plugin_version "test-plugin")

  assert_equals "v1.0.0" "$version" "Should detect plugin version from git tag"

  teardown_test_env
}

# Test 13: Update all plugins
test_update_all_plugins() {
  echo ""
  echo "TEST 13: Update all plugins"
  setup_test_env

  create_mock_git_plugin "plugin1"
  create_mock_git_plugin "plugin2"
  mkdir -p "${OMZ_CUSTOM_PLUGINS}/non-git-plugin"

  assert_success "_zsh_tool_update_all_plugins" "Should update all git-based plugins"

  teardown_test_env
}

# Test 14: Oh My Zsh version detection
test_omz_version_detection() {
  echo ""
  echo "TEST 14: Oh My Zsh version detection"
  setup_test_env

  # Create mock OMZ git repo
  cd "$OMZ_INSTALL_DIR"
  git init --initial-branch=main >/dev/null 2>&1
  git config user.name "Test" >/dev/null 2>&1
  git config user.email "test@test.com" >/dev/null 2>&1
  git config commit.gpgsign false >/dev/null 2>&1
  echo "# OMZ" > README.md
  git add . >/dev/null 2>&1
  git commit --no-verify -m "Initial commit" >/dev/null 2>&1
  cd - >/dev/null

  local version=$(_zsh_tool_get_omz_version)

  if [[ -n "$version" && "$version" != "not-installed" ]]; then
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo "✓ PASS: Should detect OMZ version"
  else
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    echo "✗ FAIL: Should detect OMZ version"
  fi

  teardown_test_env
}

# Test 15: Handle directory change failures
test_directory_change_safety() {
  echo ""
  echo "TEST 15: Safe directory change handling"
  setup_test_env

  # Create a theme directory without permissions
  create_mock_git_theme "restricted-theme"
  chmod 000 "${OMZ_CUSTOM_THEMES}/restricted-theme"

  # Should handle failure gracefully and not break
  _zsh_tool_update_theme "restricted-theme" 2>/dev/null
  local exit_code=$?

  # Restore permissions for cleanup
  chmod 755 "${OMZ_CUSTOM_THEMES}/restricted-theme"

  assert_equals "1" "$exit_code" "Should fail gracefully when cannot access theme directory"

  teardown_test_env
}

# Test 16: Empty themes directory
test_empty_themes_directory() {
  echo ""
  echo "TEST 16: Handle empty themes directory"
  setup_test_env

  # Themes directory exists but is empty
  assert_success "_zsh_tool_update_all_themes" "Should handle empty themes directory"

  teardown_test_env
}

# Test 17: State file theme timestamp
test_theme_timestamp_in_state() {
  echo ""
  echo "TEST 17: Theme update timestamp in state"
  setup_test_env

  create_mock_git_theme "test-theme"
  _zsh_tool_update_theme "test-theme" >/dev/null 2>&1

  local state_content=$(cat "$ZSH_TOOL_STATE_FILE")

  if [[ "$state_content" == *"last_update"* ]]; then
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo "✓ PASS: State should contain last_update timestamp"
  else
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    echo "✗ FAIL: State should contain last_update timestamp"
  fi

  teardown_test_env
}

# Test 18: Idempotency - run update twice
test_update_idempotency() {
  echo ""
  echo "TEST 18: Update idempotency (run twice)"
  setup_test_env

  create_mock_git_theme "test-theme"

  _zsh_tool_update_theme "test-theme" >/dev/null 2>&1
  local first_exit=$?

  _zsh_tool_update_theme "test-theme" >/dev/null 2>&1
  local second_exit=$?

  assert_equals "0" "$first_exit" "First update should succeed"
  assert_equals "0" "$second_exit" "Second update should succeed (idempotent)"

  teardown_test_env
}

# Test 19: Log file creation
test_log_file_creation() {
  echo ""
  echo "TEST 19: Log file is created and used"
  setup_test_env

  create_mock_git_theme "test-theme"
  _zsh_tool_update_theme "test-theme" >/dev/null 2>&1

  if [[ -f "$ZSH_TOOL_LOG_FILE" ]]; then
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo "✓ PASS: Log file should be created"
  else
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    echo "✗ FAIL: Log file should be created"
  fi

  teardown_test_env
}

# Test 20: Error handling - repos without remotes
test_network_failure_handling() {
  echo ""
  echo "TEST 20: Handle repos without remotes gracefully"
  setup_test_env

  create_mock_git_theme "test-theme"

  # Remove git remote to simulate a local-only repo
  (
    cd "${OMZ_CUSTOM_THEMES}/test-theme"
    git remote remove origin 2>/dev/null
  )

  # Should succeed - local-only repos are considered up-to-date
  _zsh_tool_update_theme "test-theme" 2>/dev/null
  local exit_code=$?

  # Local-only repos should be handled gracefully (succeed, not crash)
  if [[ $exit_code -eq 0 ]]; then
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo "✓ PASS: Should handle local-only repos gracefully"
  else
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    echo "✗ FAIL: Local-only repos should succeed"
  fi

  teardown_test_env
}

# Run all tests
echo "======================================"
echo "Story 2.2: Bulk Plugin and Theme Updates"
echo "Test Suite"
echo "======================================"

test_theme_version_detection
test_non_git_theme
test_theme_update_up_to_date
test_update_all_themes
test_check_theme_updates
test_check_all_themes
test_check_all_plugins
test_theme_state_tracking
test_missing_themes_directory
test_mixed_themes
test_theme_update_counters
test_plugin_version_detection
test_update_all_plugins
test_omz_version_detection
test_directory_change_safety
test_empty_themes_directory
test_theme_timestamp_in_state
test_update_idempotency
test_log_file_creation
test_network_failure_handling

# Summary
echo ""
echo "======================================"
echo "Test Summary"
echo "======================================"
echo "Total tests:  $TESTS_RUN"
echo "Passed:       $TESTS_PASSED"
echo "Failed:       $TESTS_FAILED"
echo "======================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
