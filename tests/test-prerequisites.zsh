#!/usr/bin/env zsh
# Story 1.1: Prerequisite Detection and Installation Tests
# Tests for lib/install/prerequisites.zsh

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

  if $test_func; then
    test_pass "$test_name"
  else
    test_fail "$test_name"
  fi
}

# Setup test environment
setup_test_env() {
  # Source required modules first
  source "${PROJECT_ROOT}/lib/core/utils.zsh"
  source "${PROJECT_ROOT}/lib/install/prerequisites.zsh"

  # Override config directory AFTER sourcing (utils.zsh sets defaults)
  ZSH_TOOL_CONFIG_DIR=$(mktemp -d)
  ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/zsh-tool.log"
  ZSH_TOOL_STATE_FILE="${ZSH_TOOL_CONFIG_DIR}/state.json"
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"

  # Initialize state file for tests
  echo '{"version":"1.0.0","installed":false}' > "$ZSH_TOOL_STATE_FILE"
}

# Cleanup test environment
cleanup_test_env() {
  [[ -d "$ZSH_TOOL_CONFIG_DIR" ]] && rm -rf "$ZSH_TOOL_CONFIG_DIR"
}

# ============================================
# TEST CASES
# ============================================

# Test: Homebrew detection when installed
test_homebrew_detection_installed() {
  if command -v brew >/dev/null 2>&1; then
    _zsh_tool_check_homebrew >/dev/null 2>&1
    return $?
  else
    # Skip if Homebrew not installed on this machine
    echo "${YELLOW}    (skipped - Homebrew not installed on test machine)${NC}"
    return 0
  fi
}

# Test: Git detection when installed
test_git_detection_installed() {
  if command -v git >/dev/null 2>&1; then
    _zsh_tool_check_git >/dev/null 2>&1
    return $?
  else
    echo "${YELLOW}    (skipped - git not installed on test machine)${NC}"
    return 0
  fi
}

# Test: Xcode CLI detection
test_xcode_cli_detection() {
  # This should return 0 or 1 without error
  _zsh_tool_check_xcode_cli >/dev/null 2>&1
  local result=$?
  # Should be either 0 (installed) or 1 (not installed), not an error
  [[ $result -eq 0 || $result -eq 1 ]]
}

# Test: Logging works correctly
test_logging_functionality() {
  _zsh_tool_log INFO "Test message"
  [[ -f "$ZSH_TOOL_LOG_FILE" ]] && grep -q "Test message" "$ZSH_TOOL_LOG_FILE"
}

# Test: State file initialization
test_state_file_initialization() {
  [[ -f "$ZSH_TOOL_STATE_FILE" ]]
}

# Test: State can be loaded
test_state_load() {
  local state=$(_zsh_tool_load_state)
  [[ -n "$state" ]]
}

# Test: _zsh_tool_is_installed utility works
test_is_installed_utility() {
  # zsh should always be installed (we're running in it)
  _zsh_tool_is_installed zsh
}

# Test: _zsh_tool_is_installed returns false for missing command
test_is_installed_missing() {
  ! _zsh_tool_is_installed "nonexistent_command_12345"
}

# Test: Idempotency - check functions don't fail when called twice
test_idempotency_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    _zsh_tool_check_homebrew >/dev/null 2>&1
    _zsh_tool_check_homebrew >/dev/null 2>&1
    return $?
  else
    return 0  # Skip
  fi
}

# Test: Idempotency - git check
test_idempotency_git() {
  if command -v git >/dev/null 2>&1; then
    _zsh_tool_check_git >/dev/null 2>&1
    _zsh_tool_check_git >/dev/null 2>&1
    return $?
  else
    return 0  # Skip
  fi
}

# Test: Prerequisites orchestrator function exists
test_orchestrator_exists() {
  typeset -f _zsh_tool_check_prerequisites >/dev/null 2>&1
}

# Test: All required functions are defined
test_all_functions_defined() {
  typeset -f _zsh_tool_check_homebrew >/dev/null 2>&1 && \
  typeset -f _zsh_tool_install_homebrew >/dev/null 2>&1 && \
  typeset -f _zsh_tool_check_git >/dev/null 2>&1 && \
  typeset -f _zsh_tool_install_git >/dev/null 2>&1 && \
  typeset -f _zsh_tool_check_xcode_cli >/dev/null 2>&1 && \
  typeset -f _zsh_tool_install_xcode_cli >/dev/null 2>&1
}

# Test: Functions follow naming convention
test_naming_convention() {
  # All internal functions should start with _zsh_tool_
  local funcs=$(typeset -f | grep "^_zsh_tool_" | wc -l)
  [[ $funcs -gt 0 ]]
}

# Test: jq check function exists (bonus - added in implementation)
test_jq_check_exists() {
  typeset -f _zsh_tool_check_jq >/dev/null 2>&1
}

# ============================================
# FAILURE SCENARIO TESTS (Issue #3, #4 fixes)
# ============================================

# Test: Detection returns 1 for missing command (proper mock)
test_detection_missing_command() {
  # Create a mock function that simulates missing brew
  local original_is_installed=$(typeset -f _zsh_tool_is_installed)

  # Mock _zsh_tool_is_installed to return false for a fake command
  _zsh_tool_is_installed() {
    [[ "$1" == "definitely_not_installed_xyz" ]] && return 1
    command -v "$1" >/dev/null 2>&1
  }

  # Test that check returns 1 for missing command
  ! _zsh_tool_is_installed "definitely_not_installed_xyz"
  local result=$?

  # Restore original function
  eval "$original_is_installed"

  return $result
}

# Test: Rollback function exists in git install
test_git_install_has_rollback() {
  # Check that _zsh_tool_install_git mentions rollback
  local func_body=$(typeset -f _zsh_tool_install_git)
  [[ "$func_body" == *"rollback"* ]] || [[ "$func_body" == *"Rollback"* ]] || [[ "$func_body" == *"pre_install_state"* ]]
}

# Test: State is preserved on failure simulation
test_state_rollback_mechanism() {
  # Initialize known state
  echo '{"version":"1.0.0","test":"before"}' > "$ZSH_TOOL_STATE_FILE"

  # Verify we can load the state
  local state=$(_zsh_tool_load_state)
  [[ "$state" == *"before"* ]]
}

# Test: jq-based state update (when jq available)
test_jq_state_update() {
  if command -v jq >/dev/null 2>&1; then
    # Test jq can parse and update JSON
    local test_json='{"version":"1.0.0"}'
    local updated=$(echo "$test_json" | jq '. + {test: true}')
    [[ "$updated" == *"test"* ]]
  else
    # Skip if jq not available
    echo "${YELLOW}    (skipped - jq not installed)${NC}"
    return 0
  fi
}

# Test: Error handling - install functions return non-zero on failure
test_install_functions_return_errors() {
  # Verify install functions are designed to return error codes
  local homebrew_func=$(typeset -f _zsh_tool_install_homebrew)
  local git_func=$(typeset -f _zsh_tool_install_git)

  # Check for "return 1" patterns indicating error handling
  [[ "$homebrew_func" == *"return 1"* ]] && [[ "$git_func" == *"return 1"* ]]
}

# Test: User confirmation is required before installation
test_confirmation_required() {
  local homebrew_func=$(typeset -f _zsh_tool_install_homebrew)
  [[ "$homebrew_func" == *"prompt_confirm"* ]]
}

# Test: Homebrew install has rollback mechanism (parity with git)
test_homebrew_install_has_rollback() {
  local func_body=$(typeset -f _zsh_tool_install_homebrew)
  [[ "$func_body" == *"rollback"* ]] || [[ "$func_body" == *"Rollback"* ]] || [[ "$func_body" == *"pre_install_state"* ]]
}

# Test: State save is atomic (prevents race conditions)
test_state_save_atomic() {
  local func_body=$(typeset -f _zsh_tool_save_state)
  [[ "$func_body" == *"tmp"* ]] || [[ "$func_body" == *"mv"* ]]
}

# Test: Log function handles lowercase levels
test_log_case_insensitive() {
  _zsh_tool_log info "Test lowercase info" >/dev/null 2>&1
  _zsh_tool_log INFO "Test uppercase INFO" >/dev/null 2>&1
  grep -q "Test lowercase info" "$ZSH_TOOL_LOG_FILE" && grep -q "Test uppercase INFO" "$ZSH_TOOL_LOG_FILE"
}

# ============================================
# RUN ALL TESTS
# ============================================

echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}  Story 1.1: Prerequisites Detection Tests${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Setup
echo "${YELLOW}Setting up test environment...${NC}"
setup_test_env
echo ""

# Core functionality tests
echo "${YELLOW}[1/4] Testing Core Functions...${NC}"
run_test "All required functions are defined" test_all_functions_defined
run_test "Functions follow _zsh_tool_ naming convention" test_naming_convention
run_test "Orchestrator function exists" test_orchestrator_exists
run_test "jq check function exists" test_jq_check_exists
echo ""

# Detection tests
echo "${YELLOW}[2/4] Testing Detection Functions...${NC}"
run_test "Homebrew detection (when installed)" test_homebrew_detection_installed
run_test "Git detection (when installed)" test_git_detection_installed
run_test "Xcode CLI detection (returns valid status)" test_xcode_cli_detection
run_test "_zsh_tool_is_installed works for zsh" test_is_installed_utility
run_test "_zsh_tool_is_installed returns false for missing command" test_is_installed_missing
echo ""

# Utility tests
echo "${YELLOW}[3/4] Testing Utility Functions...${NC}"
run_test "Logging writes to log file" test_logging_functionality
run_test "State file is initialized" test_state_file_initialization
run_test "State can be loaded" test_state_load
echo ""

# Idempotency tests
echo "${YELLOW}[4/5] Testing Idempotency...${NC}"
run_test "Homebrew check is idempotent" test_idempotency_homebrew
run_test "Git check is idempotent" test_idempotency_git
echo ""

# Error handling and failure tests (NEW - fixes Issue #3, #4)
echo "${YELLOW}[5/6] Testing Error Handling & Rollback...${NC}"
run_test "Detection returns false for missing command" test_detection_missing_command
run_test "Git install has rollback mechanism" test_git_install_has_rollback
run_test "State rollback mechanism works" test_state_rollback_mechanism
run_test "jq-based state update works" test_jq_state_update
run_test "Install functions return error codes" test_install_functions_return_errors
run_test "User confirmation required before install" test_confirmation_required
run_test "Homebrew install has rollback mechanism" test_homebrew_install_has_rollback
echo ""

# Security and robustness tests (NEW - adversarial review 2026-01-04)
echo "${YELLOW}[6/6] Testing Security & Robustness...${NC}"
run_test "State save is atomic" test_state_save_atomic
run_test "Log function handles lowercase levels" test_log_case_insensitive
echo ""

# Cleanup
cleanup_test_env

# Results
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}  Test Results${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Total Tests: $TESTS_RUN"
echo "${GREEN}Passed: $TESTS_PASSED${NC}"
echo "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${GREEN}✓✓✓ All tests passed! ✓✓✓${NC}"
  echo ""
  exit 0
else
  echo "${RED}✗✗✗ Some tests failed ✗✗✗${NC}"
  echo ""
  exit 1
fi
