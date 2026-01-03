#!/usr/bin/env zsh
# Story 1.4: Plugin Management System Tests
# Tests for lib/install/plugins.zsh

# Note: Not using set -e as we need to capture test failures

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test utilities
test_pass() {
  ((TESTS_PASSED++))
  echo "${GREEN}  ✓ $1${NC}"
}

test_fail() {
  ((TESTS_FAILED++))
  echo "${RED}  ✗ $1${NC}"
  [[ -n "$2" ]] && echo "${RED}    Error: $2${NC}"
}

run_test() {
  local test_name="$1"
  local test_func="$2"
  ((TESTS_RUN++))

  # Call function and capture result
  eval "$test_func"
  local result=$?

  if [[ $result -eq 0 ]]; then
    test_pass "$test_name"
  else
    test_fail "$test_name"
  fi
}

# Setup test environment
setup_test_env() {
  # Create test directories BEFORE sourcing modules
  TEST_TMP_DIR=$(mktemp -d)
  TEST_HOME="${TEST_TMP_DIR}/home"
  mkdir -p "${TEST_HOME}"

  # Save original HOME and set test HOME BEFORE sourcing
  ORIG_HOME="$HOME"
  export HOME="$TEST_HOME"

  # Create mock Oh My Zsh structure BEFORE sourcing plugins.zsh
  TEST_OMZ_DIR="${TEST_HOME}/.oh-my-zsh"
  mkdir -p "${TEST_OMZ_DIR}/plugins/git"
  mkdir -p "${TEST_OMZ_DIR}/plugins/docker"
  mkdir -p "${TEST_OMZ_DIR}/plugins/kubectl"
  mkdir -p "${TEST_OMZ_DIR}/custom/plugins"

  # Source required modules (they will use test HOME)
  source "${PROJECT_ROOT}/lib/core/utils.zsh"
  source "${PROJECT_ROOT}/lib/install/config.zsh"
  source "${PROJECT_ROOT}/lib/install/plugins.zsh"

  # Override config directory AFTER sourcing (utils.zsh sets defaults)
  ZSH_TOOL_CONFIG_DIR="${TEST_TMP_DIR}/config"
  ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/zsh-tool.log"
  ZSH_TOOL_STATE_FILE="${ZSH_TOOL_CONFIG_DIR}/state.json"
  ZSH_TOOL_TEMPLATE_DIR="${PROJECT_ROOT}/templates"

  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/templates"

  # Explicitly set OMZ_CUSTOM_PLUGINS to test path (in case sourcing reset it)
  OMZ_CUSTOM_PLUGINS="${TEST_OMZ_DIR}/custom/plugins"

  # Initialize state file for tests
  echo '{"version":"1.0.0","installed":false}' > "$ZSH_TOOL_STATE_FILE"

  # Create minimal config.yaml with only built-in plugins (avoids network calls)
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" << 'EOF'
version: "1.0"
plugins:
  - git
  - docker
  - kubectl
themes:
  default: "robbyrussell"
aliases:
  - name: "gs"
    command: "git status"
exports:
  - name: "EDITOR"
    value: "vim"
paths:
  prepend:
    - "$HOME/.local/bin"
EOF
}

# Cleanup test environment
cleanup_test_env() {
  # Restore original HOME
  [[ -n "$ORIG_HOME" ]] && export HOME="$ORIG_HOME"
  [[ -d "$TEST_TMP_DIR" ]] && rm -rf "$TEST_TMP_DIR"
  TEST_TMP_DIR=""
}

# Create mock custom plugin (simulated git repo)
create_mock_custom_plugin() {
  local plugin=$1
  local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"
  mkdir -p "${plugin_dir}/.git"
  echo "Mock plugin: $plugin" > "${plugin_dir}/README.md"
}

# ============================================
# TEST CASES - FUNCTION EXISTENCE (Task 4.1)
# ============================================

# Test: All required plugin functions are defined
test_all_plugin_functions_defined() {
  typeset -f _zsh_tool_is_builtin_plugin >/dev/null 2>&1 && \
  typeset -f _zsh_tool_is_custom_plugin_installed >/dev/null 2>&1 && \
  typeset -f _zsh_tool_install_custom_plugin >/dev/null 2>&1 && \
  typeset -f _zsh_tool_install_plugins >/dev/null 2>&1 && \
  typeset -f _zsh_tool_update_plugin >/dev/null 2>&1
}

# Test: Public dispatcher function defined
test_public_dispatcher_defined() {
  typeset -f zsh-tool-plugin >/dev/null 2>&1
}

# Test: New functions defined
test_new_functions_defined() {
  typeset -f _zsh_tool_plugin_list >/dev/null 2>&1 && \
  typeset -f _zsh_tool_plugin_add >/dev/null 2>&1 && \
  typeset -f _zsh_tool_plugin_remove >/dev/null 2>&1 && \
  typeset -f _zsh_tool_update_all_plugins >/dev/null 2>&1
}

# ============================================
# TEST CASES - BUILT-IN PLUGIN DETECTION (Task 4.2)
# ============================================

# Test: Detect built-in git plugin
test_builtin_git_detected() {
  _zsh_tool_is_builtin_plugin "git"
}

# Test: Detect built-in docker plugin
test_builtin_docker_detected() {
  _zsh_tool_is_builtin_plugin "docker"
}

# Test: Detect built-in kubectl plugin
test_builtin_kubectl_detected() {
  _zsh_tool_is_builtin_plugin "kubectl"
}

# Test: Non-existent plugin not detected as built-in
test_nonexistent_not_builtin() {
  _zsh_tool_is_builtin_plugin "nonexistent-plugin-xyz"
  [[ $? -ne 0 ]]
}

# ============================================
# TEST CASES - CUSTOM PLUGIN DETECTION (Task 4.3)
# ============================================

# Test: Detect installed custom plugin
test_custom_plugin_installed_detected() {
  create_mock_custom_plugin "test-plugin"
  _zsh_tool_is_custom_plugin_installed "test-plugin"
}

# Test: Non-installed custom plugin not detected
test_custom_plugin_not_installed() {
  _zsh_tool_is_custom_plugin_installed "not-installed-plugin"
  [[ $? -ne 0 ]]
}

# ============================================
# TEST CASES - PLUGIN INSTALLATION (Task 4.4)
# ============================================

# Test: Install custom plugin fails without URL
test_install_plugin_no_url_fails() {
  _zsh_tool_install_custom_plugin "unknown-plugin" 2>/dev/null
  [[ $? -ne 0 ]]  # Should fail (return non-zero)
}

# Test: Install plugins from config skips built-ins
test_install_plugins_skips_builtins() {
  # Should not fail with only built-in plugins in config
  _zsh_tool_install_plugins >/dev/null 2>&1
  local result=$?

  # Built-in plugins should not be in custom plugins dir
  [[ $result -eq 0 ]] && [[ ! -d "${OMZ_CUSTOM_PLUGINS}/git" ]]
}

# ============================================
# TEST CASES - IDEMPOTENCY (Task 4.5)
# ============================================

# Test: Multiple installs produce same result
test_install_idempotency() {
  # First install (only built-in plugins)
  _zsh_tool_install_plugins >/dev/null 2>&1

  # Second install should not fail
  _zsh_tool_install_plugins >/dev/null 2>&1
  local result=$?

  [[ $result -eq 0 ]]
}

# Test: Already installed plugin is skipped
test_already_installed_skipped() {
  # Only built-in plugins in config, all should be skipped
  local output=$(_zsh_tool_install_plugins 2>&1)

  # Should report skipped
  echo "$output" | grep -q "skipped"
}

# ============================================
# TEST CASES - PLUGIN LIST (Task 4.6)
# ============================================

# Test: Plugin list shows configured plugins
test_plugin_list_output() {
  local output=$(_zsh_tool_plugin_list 2>/dev/null)

  # Should show configured plugins header
  echo "$output" | grep -q "Configured plugins:" && \
  # Should show git plugin
  echo "$output" | grep -q "git"
}

# Test: Plugin list shows built-in status
test_plugin_list_builtin_status() {
  local output=$(_zsh_tool_plugin_list 2>/dev/null)

  # git should show as built-in
  echo "$output" | grep -q "built-in"
}

# Test: Plugin list shows installed custom plugins
test_plugin_list_custom_status() {
  # Add custom plugin to config - must be in plugins section, not at end of file
  # Use sed to insert after "- kubectl" line
  sed -i '' '/^  - kubectl$/a\
\  - zsh-syntax-highlighting
' "${ZSH_TOOL_CONFIG_DIR}/config.yaml" 2>/dev/null || \
  sed -i '/^  - kubectl$/a\  - zsh-syntax-highlighting' "${ZSH_TOOL_CONFIG_DIR}/config.yaml"

  create_mock_custom_plugin "zsh-syntax-highlighting"

  local output=$(_zsh_tool_plugin_list 2>/dev/null)

  # Should show installed status
  echo "$output" | grep -q "installed"
}

# ============================================
# TEST CASES - PLUGIN ADD (Task 4.7)
# ============================================

# Test: Add plugin requires name
test_add_plugin_requires_name() {
  _zsh_tool_plugin_add "" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Add built-in plugin succeeds without clone
test_add_builtin_succeeds() {
  _zsh_tool_plugin_add "git" >/dev/null 2>&1
}

# Test: Add already installed plugin succeeds
test_add_already_installed_succeeds() {
  create_mock_custom_plugin "my-plugin"

  _zsh_tool_plugin_add "my-plugin" >/dev/null 2>&1
}

# ============================================
# TEST CASES - PLUGIN REMOVE (Task 4.8)
# ============================================

# Test: Remove plugin requires name
test_remove_plugin_requires_name() {
  _zsh_tool_plugin_remove "" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Remove custom plugin deletes directory
test_remove_custom_plugin_deletes_dir() {
  create_mock_custom_plugin "removable-plugin"

  # Verify exists
  if [[ ! -d "${OMZ_CUSTOM_PLUGINS}/removable-plugin" ]]; then
    return 1
  fi

  # Remove
  _zsh_tool_plugin_remove "removable-plugin" >/dev/null 2>&1

  # Should be gone
  [[ ! -d "${OMZ_CUSTOM_PLUGINS}/removable-plugin" ]]
}

# Test: Remove updates config file
test_remove_updates_config() {
  # Add plugin to config manually
  echo "  - test-remove-plugin" >> "${ZSH_TOOL_CONFIG_DIR}/config.yaml"

  _zsh_tool_plugin_remove "test-remove-plugin" >/dev/null 2>&1

  # Should not be in config
  grep -q "test-remove-plugin" "${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  [[ $? -ne 0 ]]
}

# ============================================
# TEST CASES - PLUGIN UPDATE (Task 4.9)
# ============================================

# Test: Update non-installed plugin fails
test_update_noninstalled_fails() {
  _zsh_tool_update_plugin "not-installed" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Update all with no plugins succeeds
test_update_all_empty_succeeds() {
  # Clear custom plugins (suppress glob warning if empty)
  rm -rf "${OMZ_CUSTOM_PLUGINS}"/* 2>/dev/null || true

  _zsh_tool_update_all_plugins >/dev/null 2>&1
}

# ============================================
# TEST CASES - STATE UPDATE (Task 4.10)
# ============================================

# Test: Install plugins updates state
test_install_updates_state() {
  _zsh_tool_install_plugins >/dev/null 2>&1

  grep -q '"plugins"' "$ZSH_TOOL_STATE_FILE"
}

# ============================================
# TEST CASES - AC5 .ZSHRC PLUGIN UPDATE (Task 5.2)
# ============================================

# Test: Update function exists
test_update_zshrc_plugins_exists() {
  typeset -f _zsh_tool_update_zshrc_plugins >/dev/null
}

# Test: Update .zshrc plugins with no .zshrc fails gracefully
test_update_zshrc_no_file() {
  HOME="$TEST_HOME"
  rm -f "${HOME}/.zshrc"

  _zsh_tool_update_zshrc_plugins 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Update .zshrc plugins without managed section fails
test_update_zshrc_no_managed_section() {
  HOME="$TEST_HOME"
  echo "# No managed section" > "${HOME}/.zshrc"
  echo "plugins=(old)" >> "${HOME}/.zshrc"

  _zsh_tool_update_zshrc_plugins 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Update .zshrc plugins with managed section succeeds
test_update_zshrc_managed_section() {
  HOME="$TEST_HOME"

  # Create .zshrc with managed section
  cat > "${HOME}/.zshrc" << 'EOF'
# User content before
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(old-plugin)
source $ZSH/oh-my-zsh.sh
# ===== ZSH-TOOL MANAGED SECTION END =====
# User content after
EOF

  _zsh_tool_update_zshrc_plugins >/dev/null 2>&1
  local result=$?

  # Check if plugins line was updated with config plugins (git docker kubectl from test config)
  if grep -q "plugins=(git docker kubectl" "${HOME}/.zshrc"; then
    return 0
  fi
  return 1
}

# Test: Update .zshrc preserves user content outside managed section
test_update_zshrc_preserves_user_content() {
  HOME="$TEST_HOME"

  cat > "${HOME}/.zshrc" << 'EOF'
# MY CUSTOM HEADER
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
plugins=(old)
# ===== ZSH-TOOL MANAGED SECTION END =====
# MY CUSTOM FOOTER
alias myalias="echo hello"
EOF

  _zsh_tool_update_zshrc_plugins >/dev/null 2>&1

  # Verify user content preserved
  grep -q "MY CUSTOM HEADER" "${HOME}/.zshrc" && \
  grep -q "MY CUSTOM FOOTER" "${HOME}/.zshrc" && \
  grep -q 'alias myalias="echo hello"' "${HOME}/.zshrc"
}

# Test: Install plugins calls .zshrc update
test_install_plugins_updates_zshrc() {
  HOME="$TEST_HOME"

  # Create .zshrc with managed section
  cat > "${HOME}/.zshrc" << 'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
plugins=(placeholder)
# ===== ZSH-TOOL MANAGED SECTION END =====
EOF

  _zsh_tool_install_plugins >/dev/null 2>&1

  # Check plugins line was updated
  grep -q "plugins=(git docker kubectl" "${HOME}/.zshrc"
}

# ============================================
# TEST CASES - ERROR HANDLING (Task 4.11)
# ============================================

# Test: Unknown plugin URL returns error
test_unknown_plugin_error() {
  _zsh_tool_install_custom_plugin "totally-unknown-plugin-xyz" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Invalid action shows help
test_invalid_action_shows_help() {
  local output=$(zsh-tool-plugin invalid-action 2>&1)
  echo "$output" | grep -q "Usage:"
}

# ============================================
# TEST CASES - PUBLIC DISPATCHER
# ============================================

# Test: Dispatcher list action
test_dispatcher_list() {
  local output=$(zsh-tool-plugin list 2>/dev/null)
  echo "$output" | grep -q "Configured plugins:"
}

# Test: Dispatcher default action is list
test_dispatcher_default_list() {
  local output=$(zsh-tool-plugin 2>/dev/null)
  echo "$output" | grep -q "Configured plugins:"
}

# Test: Dispatcher add without plugin shows error
test_dispatcher_add_no_plugin() {
  zsh-tool-plugin add 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Dispatcher remove without plugin shows error
test_dispatcher_remove_no_plugin() {
  zsh-tool-plugin remove 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Dispatcher update all
test_dispatcher_update_all() {
  zsh-tool-plugin update all >/dev/null 2>&1
}

# ============================================
# TEST CASES - INTEGRATION
# ============================================

# Test: Full add/list/remove workflow
test_full_add_list_remove_workflow() {
  create_mock_custom_plugin "workflow-test-plugin"

  # Add to config (already "installed" via mock)
  echo "  - workflow-test-plugin" >> "${ZSH_TOOL_CONFIG_DIR}/config.yaml"

  # List should show it
  local list_output=$(_zsh_tool_plugin_list 2>/dev/null)
  if ! echo "$list_output" | grep -q "workflow-test-plugin"; then
    return 1
  fi

  # Remove
  _zsh_tool_plugin_remove "workflow-test-plugin" >/dev/null 2>&1

  # Should be gone from filesystem
  if [[ -d "${OMZ_CUSTOM_PLUGINS}/workflow-test-plugin" ]]; then
    return 1
  fi

  # Should be gone from config
  grep -q "workflow-test-plugin" "${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  [[ $? -ne 0 ]]
}

# ============================================
# RUN ALL TESTS
# ============================================

echo ""
echo "${BLUE}========================================${NC}"
echo "${BLUE}  Story 1.4: Plugin Management Tests${NC}"
echo "${BLUE}========================================${NC}"
echo ""

# Setup
echo "${YELLOW}Setting up test environment...${NC}"
setup_test_env

# Function Existence Tests
echo ""
echo "${BLUE}Function Existence Tests${NC}"
run_test "All plugin functions defined" test_all_plugin_functions_defined
run_test "Public dispatcher defined" test_public_dispatcher_defined
run_test "New functions defined" test_new_functions_defined

# Built-in Plugin Detection Tests
echo ""
echo "${BLUE}Built-in Plugin Detection Tests${NC}"
run_test "Detect built-in git plugin" test_builtin_git_detected
run_test "Detect built-in docker plugin" test_builtin_docker_detected
run_test "Detect built-in kubectl plugin" test_builtin_kubectl_detected
run_test "Non-existent plugin not detected as built-in" test_nonexistent_not_builtin

# Custom Plugin Detection Tests
echo ""
echo "${BLUE}Custom Plugin Detection Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Detect installed custom plugin" test_custom_plugin_installed_detected
run_test "Non-installed custom plugin not detected" test_custom_plugin_not_installed

# Plugin Installation Tests
echo ""
echo "${BLUE}Plugin Installation Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Install plugin fails without URL" test_install_plugin_no_url_fails
cleanup_test_env
setup_test_env
run_test "Install plugins skips built-ins" test_install_plugins_skips_builtins

# Idempotency Tests
echo ""
echo "${BLUE}Idempotency Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Multiple installs produce same result" test_install_idempotency
cleanup_test_env
setup_test_env
run_test "Already installed plugin is skipped" test_already_installed_skipped

# Plugin List Tests
echo ""
echo "${BLUE}Plugin List Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Plugin list shows configured plugins" test_plugin_list_output
run_test "Plugin list shows built-in status" test_plugin_list_builtin_status
cleanup_test_env
setup_test_env
run_test "Plugin list shows installed custom plugins" test_plugin_list_custom_status

# Plugin Add Tests
echo ""
echo "${BLUE}Plugin Add Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Add plugin requires name" test_add_plugin_requires_name
run_test "Add built-in plugin succeeds" test_add_builtin_succeeds
cleanup_test_env
setup_test_env
run_test "Add already installed plugin succeeds" test_add_already_installed_succeeds

# Plugin Remove Tests
echo ""
echo "${BLUE}Plugin Remove Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Remove plugin requires name" test_remove_plugin_requires_name
cleanup_test_env
setup_test_env
run_test "Remove custom plugin deletes directory" test_remove_custom_plugin_deletes_dir
cleanup_test_env
setup_test_env
run_test "Remove updates config file" test_remove_updates_config

# Plugin Update Tests
echo ""
echo "${BLUE}Plugin Update Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Update non-installed plugin fails" test_update_noninstalled_fails
run_test "Update all with no plugins succeeds" test_update_all_empty_succeeds

# State Update Tests
echo ""
echo "${BLUE}State Update Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Install plugins updates state" test_install_updates_state

# AC5 .zshrc Plugin Update Tests
echo ""
echo "${BLUE}AC5 .zshrc Plugin Update Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Update zshrc plugins function exists" test_update_zshrc_plugins_exists
cleanup_test_env
setup_test_env
run_test "Update zshrc fails without file" test_update_zshrc_no_file
cleanup_test_env
setup_test_env
run_test "Update zshrc fails without managed section" test_update_zshrc_no_managed_section
cleanup_test_env
setup_test_env
run_test "Update zshrc with managed section succeeds" test_update_zshrc_managed_section
cleanup_test_env
setup_test_env
run_test "Update zshrc preserves user content" test_update_zshrc_preserves_user_content
cleanup_test_env
setup_test_env
run_test "Install plugins updates zshrc" test_install_plugins_updates_zshrc

# Error Handling Tests
echo ""
echo "${BLUE}Error Handling Tests${NC}"
run_test "Unknown plugin URL returns error" test_unknown_plugin_error
run_test "Invalid action shows help" test_invalid_action_shows_help

# Public Dispatcher Tests
echo ""
echo "${BLUE}Public Dispatcher Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Dispatcher list action" test_dispatcher_list
run_test "Dispatcher default action is list" test_dispatcher_default_list
run_test "Dispatcher add without plugin shows error" test_dispatcher_add_no_plugin
run_test "Dispatcher remove without plugin shows error" test_dispatcher_remove_no_plugin
run_test "Dispatcher update all" test_dispatcher_update_all

# Integration Tests
echo ""
echo "${BLUE}Integration Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Full add/list/remove workflow" test_full_add_list_remove_workflow

# Cleanup
echo ""
echo "${YELLOW}Cleaning up test environment...${NC}"
cleanup_test_env

# Summary
echo ""
echo "${BLUE}========================================${NC}"
echo "${BLUE}  Test Summary${NC}"
echo "${BLUE}========================================${NC}"
echo ""
echo "Tests run:    ${TESTS_RUN}"
echo "${GREEN}Tests passed: ${TESTS_PASSED}${NC}"
echo "${RED}Tests failed: ${TESTS_FAILED}${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo "${RED}Some tests failed!${NC}"
  exit 1
fi
