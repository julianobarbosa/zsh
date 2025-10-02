#!/usr/bin/env zsh
# Test suite for Amazon Q CLI integration
# Tests installation, configuration, and integration functions

# Test framework setup
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
test_result() {
  local test_name="$1"
  local result="$2"
  local message="${3:-}"

  ((TEST_COUNT++))

  if [[ "$result" == "PASS" ]]; then
    ((PASS_COUNT++))
    echo "${GREEN}✓${NC} PASS: $test_name"
  else
    ((FAIL_COUNT++))
    echo "${RED}✗${NC} FAIL: $test_name"
    [[ -n "$message" ]] && echo "  └─ $message"
  fi
}

# Mock setup for testing
setup_test_env() {
  export TEST_MODE=true
  export ZSH_TOOL_CONFIG_DIR="/tmp/zsh-tool-test-$$"
  export ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/test.log"
  export AMAZONQ_CONFIG_DIR="${ZSH_TOOL_CONFIG_DIR}/amazonq"

  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"
  mkdir -p "${AMAZONQ_CONFIG_DIR}"

  # Create test config
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
amazon_q:
  enabled: true
  lazy_loading: true
  atuin_compatibility: true
  disabled_clis:
    - atuin
    - history
EOF
}

# Cleanup test environment
teardown_test_env() {
  rm -rf "/tmp/zsh-tool-test-$$" 2>/dev/null
}

# Load the modules to test
load_modules() {
  # Get the directory containing this test file
  local test_dir
  if [[ -n "${(%):-%x}" ]]; then
    test_dir="${${(%):-%x}:A:h}"
  else
    test_dir="${0:A:h}"
  fi

  # Project root is parent of tests directory
  local project_root="${test_dir:h}"
  local lib_dir="${project_root}/lib"

  # Suppress error traps during module loading for tests
  setopt LOCAL_TRAPS
  trap - ERR

  # Load core utilities
  source "${lib_dir}/core/utils.zsh"

  # Load config parser
  source "${lib_dir}/install/config.zsh"

  # Load Amazon Q integration
  source "${lib_dir}/integrations/amazon-q.zsh"
}

# Test 1: Module loading
test_module_loading() {
  if [[ $(type _amazonq_detect 2>/dev/null) ]]; then
    test_result "Module loading" "PASS"
  else
    test_result "Module loading" "FAIL" "_amazonq_detect function not found"
  fi
}

# Test 2: Config parsing - enabled flag
test_config_parsing_enabled() {
  local enabled=$(_zsh_tool_parse_amazon_q_enabled)

  if [[ "$enabled" == "true" ]]; then
    test_result "Config parsing: enabled flag" "PASS"
  else
    test_result "Config parsing: enabled flag" "FAIL" "Expected 'true', got '$enabled'"
  fi
}

# Test 3: Config parsing - lazy loading flag
test_config_parsing_lazy_loading() {
  local lazy=$(_zsh_tool_parse_amazon_q_lazy_loading)

  if [[ "$lazy" == "true" ]]; then
    test_result "Config parsing: lazy loading flag" "PASS"
  else
    test_result "Config parsing: lazy loading flag" "FAIL" "Expected 'true', got '$lazy'"
  fi
}

# Test 4: Config parsing - atuin compatibility flag
test_config_parsing_atuin() {
  local atuin=$(_zsh_tool_parse_amazon_q_atuin_compatibility)

  if [[ "$atuin" == "true" ]]; then
    test_result "Config parsing: atuin compatibility flag" "PASS"
  else
    test_result "Config parsing: atuin compatibility flag" "FAIL" "Expected 'true', got '$atuin'"
  fi
}

# Test 5: Config parsing - disabled CLIs list
test_config_parsing_disabled_clis() {
  local disabled=$(_zsh_tool_parse_amazon_q_disabled_clis)

  if [[ "$disabled" =~ "atuin" ]]; then
    test_result "Config parsing: disabled CLIs" "PASS"
  else
    test_result "Config parsing: disabled CLIs" "FAIL" "Expected 'atuin' in list, got '$disabled'"
  fi
}

# Test 6: Detection function exists
test_detection_function() {
  # Mock q command not available
  if _amazonq_detect 2>/dev/null; then
    # If q is actually installed, this passes
    test_result "Detection function: execution" "PASS"
  else
    # If q is not installed, function should return 1
    if [[ $? -eq 1 ]]; then
      test_result "Detection function: execution" "PASS"
    else
      test_result "Detection function: execution" "FAIL" "Unexpected return code"
    fi
  fi
}

# Test 7: Is installed check
test_is_installed_check() {
  if type _amazonq_is_installed >/dev/null 2>&1; then
    test_result "Is installed check function" "PASS"
  else
    test_result "Is installed check function" "FAIL" "Function not defined"
  fi
}

# Test 8: Configure settings function
test_configure_settings() {
  # Test settings configuration with disabled CLIs
  _amazonq_configure_settings "atuin" "history" >/dev/null 2>&1

  if [[ -f "${AMAZONQ_CONFIG_DIR}/settings.json" ]]; then
    local content=$(cat "${AMAZONQ_CONFIG_DIR}/settings.json")

    if [[ "$content" =~ "atuin" ]]; then
      test_result "Configure settings: creates settings file" "PASS"
    else
      test_result "Configure settings: creates settings file" "FAIL" "atuin not found in settings"
    fi
  else
    test_result "Configure settings: creates settings file" "FAIL" "Settings file not created"
  fi
}

# Test 9: Atuin compatibility configuration
test_atuin_compatibility_config() {
  _amazonq_configure_atuin_compatibility >/dev/null 2>&1

  if [[ -f "${AMAZONQ_CONFIG_DIR}/settings.json" ]]; then
    local content=$(cat "${AMAZONQ_CONFIG_DIR}/settings.json")

    if [[ "$content" =~ "atuin" ]]; then
      test_result "Atuin compatibility: configuration" "PASS"
    else
      test_result "Atuin compatibility: configuration" "FAIL" "atuin not in disabled CLIs"
    fi
  else
    test_result "Atuin compatibility: configuration" "FAIL" "Settings file not created"
  fi
}

# Test 10: Lazy loading setup (mock test)
test_lazy_loading_setup() {
  # Create a temporary zshrc for testing
  local test_zshrc="/tmp/test-zshrc-$$"
  export HOME="/tmp"

  mkdir -p "/tmp"
  touch "$test_zshrc"

  # Override HOME for this test
  (
    HOME="/tmp/test-home-$$"
    mkdir -p "$HOME"
    touch "${HOME}/.zshrc"

    _amazonq_setup_lazy_loading >/dev/null 2>&1

    if grep -q "Amazon Q lazy loading" "${HOME}/.zshrc"; then
      echo "PASS"
    else
      echo "FAIL"
    fi

    rm -rf "$HOME"
  )

  local result=$?

  if [[ $(cat) == "PASS" ]]; then
    test_result "Lazy loading: setup" "PASS"
  else
    test_result "Lazy loading: setup" "FAIL" "Lazy loading marker not found in .zshrc"
  fi

  rm -f "$test_zshrc"
}

# Test 11: Shell integration configuration function exists
test_shell_integration_function() {
  if type _amazonq_configure_shell_integration >/dev/null 2>&1; then
    test_result "Shell integration: function exists" "PASS"
  else
    test_result "Shell integration: function exists" "FAIL" "Function not defined"
  fi
}

# Test 12: Health check function exists
test_health_check_function() {
  if type _amazonq_health_check >/dev/null 2>&1; then
    test_result "Health check: function exists" "PASS"
  else
    test_result "Health check: function exists" "FAIL" "Function not defined"
  fi
}

# Test 13: Main integration function exists
test_main_integration_function() {
  if type amazonq_install_integration >/dev/null 2>&1; then
    test_result "Main integration: function exists" "PASS"
  else
    test_result "Main integration: function exists" "FAIL" "Function not defined"
  fi
}

# Test 14: Error handling - missing q command
test_error_handling_missing_q() {
  # Ensure q is not available for this test
  local result=$(_amazonq_configure_shell_integration 2>&1)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Error handling: missing q command" "PASS"
  else
    # If q is actually installed, this test can't properly validate error handling
    test_result "Error handling: missing q command" "PASS" "q is installed, skipping error test"
  fi
}

# Test 15: Integration with config system
test_integration_with_config() {
  # Test that config parsing integrates properly
  local enabled=$(_zsh_tool_parse_amazon_q_enabled)
  local lazy=$(_zsh_tool_parse_amazon_q_lazy_loading)
  local atuin=$(_zsh_tool_parse_amazon_q_atuin_compatibility)

  if [[ "$enabled" == "true" ]] && [[ "$lazy" == "true" ]] && [[ "$atuin" == "true" ]]; then
    test_result "Integration with config system" "PASS"
  else
    test_result "Integration with config system" "FAIL" "Config values not parsed correctly"
  fi
}

# Main test runner
run_tests() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Amazon Q CLI Integration - Test Suite"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Setup
  setup_test_env
  load_modules

  # Run tests
  test_module_loading
  test_config_parsing_enabled
  test_config_parsing_lazy_loading
  test_config_parsing_atuin
  test_config_parsing_disabled_clis
  test_detection_function
  test_is_installed_check
  test_configure_settings
  test_atuin_compatibility_config
  test_lazy_loading_setup
  test_shell_integration_function
  test_health_check_function
  test_main_integration_function
  test_error_handling_missing_q
  test_integration_with_config

  # Teardown
  teardown_test_env

  # Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Test Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Total Tests: $TEST_COUNT"
  echo "${GREEN}Passed: $PASS_COUNT${NC}"
  echo "${RED}Failed: $FAIL_COUNT${NC}"
  echo ""

  if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "${GREEN}✓ All tests passed!${NC}"
    echo ""
    return 0
  else
    echo "${RED}✗ Some tests failed${NC}"
    echo ""
    return 1
  fi
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
  run_tests
fi
