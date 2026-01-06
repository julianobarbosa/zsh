#!/usr/bin/env zsh
# Story 1.5: Theme Installation and Selection Tests
# Tests for lib/install/themes.zsh

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

  # Create mock Oh My Zsh structure BEFORE sourcing themes.zsh
  TEST_OMZ_DIR="${TEST_HOME}/.oh-my-zsh"
  mkdir -p "${TEST_OMZ_DIR}/themes"
  mkdir -p "${TEST_OMZ_DIR}/custom/themes"

  # Create mock built-in themes
  touch "${TEST_OMZ_DIR}/themes/robbyrussell.zsh-theme"
  touch "${TEST_OMZ_DIR}/themes/agnoster.zsh-theme"
  touch "${TEST_OMZ_DIR}/themes/af-magic.zsh-theme"

  # Source required modules (they will use test HOME)
  source "${PROJECT_ROOT}/lib/core/utils.zsh"
  source "${PROJECT_ROOT}/lib/install/config.zsh"
  source "${PROJECT_ROOT}/lib/install/themes.zsh"

  # Override config directory AFTER sourcing (utils.zsh sets defaults)
  ZSH_TOOL_CONFIG_DIR="${TEST_TMP_DIR}/config"
  ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/zsh-tool.log"
  ZSH_TOOL_STATE_FILE="${ZSH_TOOL_CONFIG_DIR}/state.json"
  ZSH_TOOL_TEMPLATE_DIR="${PROJECT_ROOT}/templates"

  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/templates"

  # Explicitly set OMZ_CUSTOM_THEMES to test path (in case sourcing reset it)
  OMZ_CUSTOM_THEMES="${TEST_OMZ_DIR}/custom/themes"

  # Initialize state file for tests
  echo '{"version":"1.0.0","installed":false}' > "$ZSH_TOOL_STATE_FILE"

  # Create minimal config.yaml with theme configuration
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" << 'EOF'
version: "1.0"
plugins:
  - git
themes:
  default: "robbyrussell"
  available:
    - robbyrussell
    - agnoster
    - powerlevel10k
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

# Create mock custom theme (simulated git repo)
create_mock_custom_theme() {
  local theme=$1
  local theme_dir="${OMZ_CUSTOM_THEMES}/${theme}"
  mkdir -p "${theme_dir}/.git"
  echo "Mock theme: $theme" > "${theme_dir}/README.md"
  touch "${theme_dir}/${theme}.zsh-theme"
}

# ============================================
# TEST CASES - FUNCTION EXISTENCE (Task 5.1)
# ============================================

# Test: All required theme functions are defined
test_all_theme_functions_defined() {
  typeset -f _zsh_tool_is_builtin_theme >/dev/null 2>&1 && \
  typeset -f _zsh_tool_is_custom_theme_installed >/dev/null 2>&1 && \
  typeset -f _zsh_tool_install_custom_theme >/dev/null 2>&1 && \
  typeset -f _zsh_tool_apply_theme >/dev/null 2>&1
}

# Test: Public dispatcher function defined
test_public_dispatcher_defined() {
  typeset -f zsh-tool-theme >/dev/null 2>&1
}

# Test: New functions defined
test_new_functions_defined() {
  typeset -f _zsh_tool_theme_list >/dev/null 2>&1 && \
  typeset -f _zsh_tool_theme_set >/dev/null 2>&1 && \
  typeset -f _zsh_tool_update_zshrc_theme >/dev/null 2>&1 && \
  typeset -f _zsh_tool_validate_theme_name >/dev/null 2>&1
}

# ============================================
# TEST CASES - BUILT-IN THEME DETECTION (Task 5.2)
# ============================================

# Test: Detect built-in robbyrussell theme
test_builtin_robbyrussell_detected() {
  _zsh_tool_is_builtin_theme "robbyrussell"
}

# Test: Detect built-in agnoster theme
test_builtin_agnoster_detected() {
  _zsh_tool_is_builtin_theme "agnoster"
}

# Test: Detect built-in af-magic theme
test_builtin_afmagic_detected() {
  _zsh_tool_is_builtin_theme "af-magic"
}

# Test: Non-existent theme not detected as built-in
test_nonexistent_not_builtin() {
  _zsh_tool_is_builtin_theme "nonexistent-theme-xyz"
  [[ $? -ne 0 ]]
}

# ============================================
# TEST CASES - CUSTOM THEME DETECTION (Task 5.3)
# ============================================

# Test: Detect installed custom theme
test_custom_theme_installed_detected() {
  create_mock_custom_theme "test-theme"
  _zsh_tool_is_custom_theme_installed "test-theme"
}

# Test: Non-installed custom theme not detected
test_custom_theme_not_installed() {
  _zsh_tool_is_custom_theme_installed "not-installed-theme"
  [[ $? -ne 0 ]]
}

# ============================================
# TEST CASES - THEME INSTALLATION (Task 5.4)
# ============================================

# Test: Install custom theme fails without URL
test_install_theme_no_url_fails() {
  _zsh_tool_install_custom_theme "unknown-theme" 2>/dev/null
  [[ $? -ne 0 ]]  # Should fail (return non-zero)
}

# Test: Install theme with URL creates directory
test_install_theme_creates_directory() {
  # This test would normally require network, so we mock by checking the path logic
  # Verify the function correctly identifies missing URLs
  local output=$(_zsh_tool_install_custom_theme "no-url-theme" 2>&1)
  echo "$output" | grep -qi "no url"
}

# ============================================
# TEST CASES - IDEMPOTENCY (Task 5.5)
# ============================================

# Test: Apply theme multiple times produces same result
test_theme_apply_idempotency() {
  # First apply (robbyrussell is built-in)
  _zsh_tool_apply_theme >/dev/null 2>&1

  # Second apply should not fail
  _zsh_tool_apply_theme >/dev/null 2>&1
  local result=$?

  [[ $result -eq 0 ]]
}

# Test: Already installed custom theme is skipped
test_already_installed_theme_skipped() {
  create_mock_custom_theme "already-installed"

  # Try to "install" - should report it's already there
  _zsh_tool_is_custom_theme_installed "already-installed"
}

# ============================================
# TEST CASES - THEME LIST (Task 5.6)
# ============================================

# Test: Theme list shows available themes
test_theme_list_output() {
  local output=$(_zsh_tool_theme_list 2>/dev/null)

  # Should show available themes header
  echo "$output" | grep -q "Available themes:" && \
  # Should show robbyrussell
  echo "$output" | grep -q "robbyrussell"
}

# Test: Theme list shows built-in status
test_theme_list_builtin_status() {
  local output=$(_zsh_tool_theme_list 2>/dev/null)

  # Should show built-in indicator
  echo "$output" | grep -q "built-in"
}

# Test: Theme list shows custom themes section
test_theme_list_custom_section() {
  local output=$(_zsh_tool_theme_list 2>/dev/null)

  # Should show custom themes section
  echo "$output" | grep -q "Custom themes"
}

# ============================================
# TEST CASES - THEME SET COMMAND (Task 5.7)
# ============================================

# Test: Set theme requires name
test_set_theme_requires_name() {
  _zsh_tool_theme_set "" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Set built-in theme succeeds
test_set_builtin_theme_succeeds() {
  HOME="$TEST_HOME"

  # Create .zshrc with managed section
  cat > "${HOME}/.zshrc" << 'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
ZSH_THEME="old-theme"
# ===== ZSH-TOOL MANAGED SECTION END =====
EOF

  _zsh_tool_theme_set "robbyrussell" >/dev/null 2>&1
}

# Test: Set already installed custom theme succeeds
test_set_installed_custom_theme_succeeds() {
  HOME="$TEST_HOME"
  create_mock_custom_theme "custom-installed"

  # Create .zshrc with managed section
  cat > "${HOME}/.zshrc" << 'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
ZSH_THEME="old-theme"
# ===== ZSH-TOOL MANAGED SECTION END =====
EOF

  _zsh_tool_theme_set "custom-installed" >/dev/null 2>&1
}

# ============================================
# TEST CASES - FALLBACK BEHAVIOR (Task 5.8)
# ============================================

# Test: Invalid theme falls back to robbyrussell
test_invalid_theme_fallback() {
  HOME="$TEST_HOME"

  # Create .zshrc with managed section
  cat > "${HOME}/.zshrc" << 'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
ZSH_THEME="old-theme"
# ===== ZSH-TOOL MANAGED SECTION END =====
EOF

  # Try to set a theme that doesn't exist and has no URL
  _zsh_tool_theme_set "nonexistent-theme" >/dev/null 2>&1
  local result=$?

  # Should succeed by falling back
  [[ $result -eq 0 ]]
}

# ============================================
# TEST CASES - STATE UPDATE (Task 5.9)
# ============================================

# Test: Theme set updates state
test_theme_set_updates_state() {
  HOME="$TEST_HOME"

  # Create .zshrc with managed section
  cat > "${HOME}/.zshrc" << 'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
ZSH_THEME="old-theme"
# ===== ZSH-TOOL MANAGED SECTION END =====
EOF

  _zsh_tool_theme_set "robbyrussell" >/dev/null 2>&1

  # Check state file for theme
  grep -q "theme" "$ZSH_TOOL_STATE_FILE"
}

# ============================================
# TEST CASES - .ZSHRC ZSH_THEME UPDATE (Task 5.10)
# ============================================

# Test: Update zshrc theme function exists
test_update_zshrc_theme_exists() {
  typeset -f _zsh_tool_update_zshrc_theme >/dev/null 2>&1
}

# Test: Update zshrc fails without file
test_update_zshrc_theme_no_file() {
  HOME="$TEST_HOME"
  rm -f "${HOME}/.zshrc" 2>/dev/null

  _zsh_tool_update_zshrc_theme "test-theme" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Update zshrc fails without managed section
test_update_zshrc_theme_no_managed_section() {
  HOME="$TEST_HOME"
  echo "# No managed section" > "${HOME}/.zshrc"

  _zsh_tool_update_zshrc_theme "test-theme" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Update zshrc with managed section succeeds
test_update_zshrc_theme_managed_section() {
  HOME="$TEST_HOME"

  cat > "${HOME}/.zshrc" << 'EOF'
# User content before
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="old-theme"
plugins=(git)
source $ZSH/oh-my-zsh.sh
# ===== ZSH-TOOL MANAGED SECTION END =====
# User content after
EOF

  _zsh_tool_update_zshrc_theme "robbyrussell" >/dev/null 2>&1
  local result=$?

  # Check if ZSH_THEME line was updated
  if grep -q 'ZSH_THEME="robbyrussell"' "${HOME}/.zshrc"; then
    return 0
  fi
  return 1
}

# Test: Update zshrc preserves user content outside managed section
test_update_zshrc_theme_preserves_user_content() {
  HOME="$TEST_HOME"

  cat > "${HOME}/.zshrc" << 'EOF'
# MY CUSTOM HEADER
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
ZSH_THEME="old"
# ===== ZSH-TOOL MANAGED SECTION END =====
# MY CUSTOM FOOTER
alias myalias="echo hello"
EOF

  _zsh_tool_update_zshrc_theme "agnoster" >/dev/null 2>&1

  # Verify user content preserved
  grep -q "MY CUSTOM HEADER" "${HOME}/.zshrc" && \
  grep -q "MY CUSTOM FOOTER" "${HOME}/.zshrc" && \
  grep -q 'alias myalias="echo hello"' "${HOME}/.zshrc"
}

# ============================================
# TEST CASES - THEME VALIDATION
# ============================================

# Test: Valid theme name accepted
test_validate_valid_theme_name() {
  _zsh_tool_validate_theme_name "my-theme-123"
}

# Test: Theme name with path traversal rejected
test_validate_path_traversal_rejected() {
  _zsh_tool_validate_theme_name "../evil-theme"
  [[ $? -ne 0 ]]
}

# Test: Theme name with slash rejected
test_validate_slash_rejected() {
  _zsh_tool_validate_theme_name "evil/theme"
  [[ $? -ne 0 ]]
}

# Test: Empty theme name rejected
test_validate_empty_rejected() {
  _zsh_tool_validate_theme_name ""
  [[ $? -ne 0 ]]
}

# Test: Theme name with special characters rejected
test_validate_special_chars_rejected() {
  _zsh_tool_validate_theme_name "theme;rm -rf"
  [[ $? -ne 0 ]]
}

# ============================================
# TEST CASES - ERROR HANDLING (Task 5.11)
# ============================================

# Test: Unknown theme URL returns error
test_unknown_theme_error() {
  _zsh_tool_install_custom_theme "totally-unknown-theme-xyz" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Invalid action shows help
test_invalid_action_shows_help() {
  local output=$(zsh-tool-theme invalid-action 2>&1)
  echo "$output" | grep -q "Usage:"
}

# ============================================
# TEST CASES - PUBLIC DISPATCHER
# ============================================

# Test: Dispatcher list action
test_dispatcher_list() {
  local output=$(zsh-tool-theme list 2>/dev/null)
  echo "$output" | grep -q "Available themes:"
}

# Test: Dispatcher default action is list
test_dispatcher_default_list() {
  local output=$(zsh-tool-theme 2>/dev/null)
  echo "$output" | grep -q "Available themes:"
}

# Test: Dispatcher set without theme shows error
test_dispatcher_set_no_theme() {
  zsh-tool-theme set 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Dispatcher current shows current theme
test_dispatcher_current() {
  local output=$(zsh-tool-theme current 2>/dev/null)
  echo "$output" | grep -q "Current theme:"
}

# ============================================
# TEST CASES - THEME CONFLICT HANDLING
# ============================================

# Test: Built-in theme takes precedence over custom with same name
test_builtin_takes_precedence_over_custom() {
  # Create a custom theme with the same name as a built-in
  create_mock_custom_theme "robbyrussell"

  # The built-in check should still return true (built-in takes precedence)
  _zsh_tool_is_builtin_theme "robbyrussell"
}

# Test: Theme set uses built-in when both built-in and custom exist
test_theme_set_uses_builtin_priority() {
  HOME="$TEST_HOME"

  # Create custom theme with same name as built-in
  create_mock_custom_theme "agnoster"

  # Create .zshrc with managed section
  cat > "${HOME}/.zshrc" << 'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
ZSH_THEME="old-theme"
# ===== ZSH-TOOL MANAGED SECTION END =====
EOF

  # Set agnoster - should succeed using built-in (priority)
  _zsh_tool_theme_set "agnoster" >/dev/null 2>&1
  local result=$?

  # Should succeed because built-in exists
  [[ $result -eq 0 ]]
}

# ============================================
# TEST CASES - INTEGRATION
# ============================================

# Test: Full set theme workflow
test_full_set_theme_workflow() {
  HOME="$TEST_HOME"

  # Create .zshrc with managed section
  cat > "${HOME}/.zshrc" << 'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
ZSH_THEME="robbyrussell"
# ===== ZSH-TOOL MANAGED SECTION END =====
EOF

  # Set to agnoster
  zsh-tool-theme set agnoster >/dev/null 2>&1

  # Verify theme was changed
  if grep -q 'ZSH_THEME="agnoster"' "${HOME}/.zshrc"; then
    return 0
  fi
  return 1
}

# ============================================
# RUN ALL TESTS
# ============================================

echo ""
echo "${BLUE}========================================${NC}"
echo "${BLUE}  Story 1.5: Theme Installation Tests${NC}"
echo "${BLUE}========================================${NC}"
echo ""

# Setup
echo "${YELLOW}Setting up test environment...${NC}"
setup_test_env

# Function Existence Tests
echo ""
echo "${BLUE}Function Existence Tests${NC}"
run_test "All theme functions defined" test_all_theme_functions_defined
run_test "Public dispatcher defined" test_public_dispatcher_defined
run_test "New functions defined" test_new_functions_defined

# Built-in Theme Detection Tests
echo ""
echo "${BLUE}Built-in Theme Detection Tests${NC}"
run_test "Detect built-in robbyrussell theme" test_builtin_robbyrussell_detected
run_test "Detect built-in agnoster theme" test_builtin_agnoster_detected
run_test "Detect built-in af-magic theme" test_builtin_afmagic_detected
run_test "Non-existent theme not detected as built-in" test_nonexistent_not_builtin

# Custom Theme Detection Tests
echo ""
echo "${BLUE}Custom Theme Detection Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Detect installed custom theme" test_custom_theme_installed_detected
run_test "Non-installed custom theme not detected" test_custom_theme_not_installed

# Theme Installation Tests
echo ""
echo "${BLUE}Theme Installation Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Install theme fails without URL" test_install_theme_no_url_fails
run_test "Install theme creates directory logic" test_install_theme_creates_directory

# Idempotency Tests
echo ""
echo "${BLUE}Idempotency Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Multiple applies produce same result" test_theme_apply_idempotency
run_test "Already installed theme is detected" test_already_installed_theme_skipped

# Theme List Tests
echo ""
echo "${BLUE}Theme List Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Theme list shows available themes" test_theme_list_output
run_test "Theme list shows built-in status" test_theme_list_builtin_status
run_test "Theme list shows custom section" test_theme_list_custom_section

# Theme Set Tests
echo ""
echo "${BLUE}Theme Set Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Set theme requires name" test_set_theme_requires_name
cleanup_test_env
setup_test_env
run_test "Set built-in theme succeeds" test_set_builtin_theme_succeeds
cleanup_test_env
setup_test_env
run_test "Set installed custom theme succeeds" test_set_installed_custom_theme_succeeds

# Fallback Tests
echo ""
echo "${BLUE}Fallback Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Invalid theme falls back to default" test_invalid_theme_fallback

# State Update Tests
echo ""
echo "${BLUE}State Update Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Theme set updates state" test_theme_set_updates_state

# .zshrc Theme Update Tests
echo ""
echo "${BLUE}.zshrc ZSH_THEME Update Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Update zshrc theme function exists" test_update_zshrc_theme_exists
cleanup_test_env
setup_test_env
run_test "Update zshrc fails without file" test_update_zshrc_theme_no_file
cleanup_test_env
setup_test_env
run_test "Update zshrc fails without managed section" test_update_zshrc_theme_no_managed_section
cleanup_test_env
setup_test_env
run_test "Update zshrc with managed section succeeds" test_update_zshrc_theme_managed_section
cleanup_test_env
setup_test_env
run_test "Update zshrc preserves user content" test_update_zshrc_theme_preserves_user_content

# Theme Validation Tests
echo ""
echo "${BLUE}Theme Validation Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Valid theme name accepted" test_validate_valid_theme_name
run_test "Path traversal rejected" test_validate_path_traversal_rejected
run_test "Slash in name rejected" test_validate_slash_rejected
run_test "Empty name rejected" test_validate_empty_rejected
run_test "Special characters rejected" test_validate_special_chars_rejected

# Error Handling Tests
echo ""
echo "${BLUE}Error Handling Tests${NC}"
run_test "Unknown theme URL returns error" test_unknown_theme_error
run_test "Invalid action shows help" test_invalid_action_shows_help

# Public Dispatcher Tests
echo ""
echo "${BLUE}Public Dispatcher Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Dispatcher list action" test_dispatcher_list
run_test "Dispatcher default action is list" test_dispatcher_default_list
run_test "Dispatcher set without theme shows error" test_dispatcher_set_no_theme
run_test "Dispatcher current shows current theme" test_dispatcher_current

# Theme Conflict Handling Tests
echo ""
echo "${BLUE}Theme Conflict Handling Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Built-in theme takes precedence over custom" test_builtin_takes_precedence_over_custom
cleanup_test_env
setup_test_env
run_test "Theme set uses built-in priority" test_theme_set_uses_builtin_priority

# Integration Tests
echo ""
echo "${BLUE}Integration Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Full set theme workflow" test_full_set_theme_workflow

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
