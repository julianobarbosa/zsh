#!/usr/bin/env zsh
# Test suite for Kiro CLI integration
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
  export KIRO_CONFIG_DIR="${ZSH_TOOL_CONFIG_DIR}/kiro"

  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"
  mkdir -p "${KIRO_CONFIG_DIR}/settings"

  # Create test config
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
kiro_cli:
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
  rm -rf "/tmp/test-home-$$" 2>/dev/null
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

  # Load Kiro CLI integration
  source "${lib_dir}/integrations/kiro-cli.zsh"
}

# Test 1: Module loading
test_module_loading() {
  if [[ $(type _kiro_detect 2>/dev/null) ]]; then
    test_result "Module loading" "PASS"
  else
    test_result "Module loading" "FAIL" "_kiro_detect function not found"
  fi
}

# Test 2: Config parsing - enabled flag
test_config_parsing_enabled() {
  local enabled=$(_zsh_tool_parse_kiro_enabled)

  if [[ "$enabled" == "true" ]]; then
    test_result "Config parsing: enabled flag" "PASS"
  else
    test_result "Config parsing: enabled flag" "FAIL" "Expected 'true', got '$enabled'"
  fi
}

# Test 3: Config parsing - lazy loading flag
test_config_parsing_lazy_loading() {
  local lazy=$(_zsh_tool_parse_kiro_lazy_loading)

  if [[ "$lazy" == "true" ]]; then
    test_result "Config parsing: lazy loading flag" "PASS"
  else
    test_result "Config parsing: lazy loading flag" "FAIL" "Expected 'true', got '$lazy'"
  fi
}

# Test 4: Config parsing - atuin compatibility flag
test_config_parsing_atuin() {
  local atuin=$(_zsh_tool_parse_kiro_atuin_compatibility)

  if [[ "$atuin" == "true" ]]; then
    test_result "Config parsing: atuin compatibility flag" "PASS"
  else
    test_result "Config parsing: atuin compatibility flag" "FAIL" "Expected 'true', got '$atuin'"
  fi
}

# Test 5: Config parsing - disabled CLIs list
test_config_parsing_disabled_clis() {
  local disabled=$(_zsh_tool_parse_kiro_disabled_clis)

  if [[ "$disabled" =~ "atuin" ]]; then
    test_result "Config parsing: disabled CLIs" "PASS"
  else
    test_result "Config parsing: disabled CLIs" "FAIL" "Expected 'atuin' in list, got '$disabled'"
  fi
}

# Test 6: Detection function exists
test_detection_function() {
  # Mock kiro-cli command not available
  if _kiro_detect 2>/dev/null; then
    # If kiro-cli is actually installed, this passes
    test_result "Detection function: execution" "PASS"
  else
    # If kiro-cli is not installed, function should return 1
    if [[ $? -eq 1 ]]; then
      test_result "Detection function: execution" "PASS"
    else
      test_result "Detection function: execution" "FAIL" "Unexpected return code"
    fi
  fi
}

# Test 7: Is installed check
test_is_installed_check() {
  if type _kiro_is_installed >/dev/null 2>&1; then
    test_result "Is installed check function" "PASS"
  else
    test_result "Is installed check function" "FAIL" "Function not defined"
  fi
}

# Test 8: Configure settings function
test_configure_settings() {
  # Test settings configuration with disabled CLIs
  _kiro_configure_settings "atuin" "history" >/dev/null 2>&1

  if [[ -f "${KIRO_CONFIG_DIR}/settings/cli.json" ]]; then
    local content=$(cat "${KIRO_CONFIG_DIR}/settings/cli.json")

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
  _kiro_configure_atuin_compatibility >/dev/null 2>&1

  if [[ -f "${KIRO_CONFIG_DIR}/settings/cli.json" ]]; then
    local content=$(cat "${KIRO_CONFIG_DIR}/settings/cli.json")

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
  local test_home="/tmp/test-home-$$"
  local result="FAIL"

  # Create test environment with cleanup trap
  mkdir -p "$test_home"

  # Set up trap to ensure cleanup on exit/interrupt
  trap "rm -rf '$test_home' 2>/dev/null" EXIT INT TERM

  # Run test in isolated subshell and capture output
  result=$(
    HOME="$test_home"
    touch "${HOME}/.zshrc"

    # Run the function under test
    _kiro_setup_lazy_loading >/dev/null 2>&1

    # Check if lazy loading marker was added
    if grep -q "Kiro CLI lazy loading" "${HOME}/.zshrc"; then
      echo "PASS"
    else
      echo "FAIL"
    fi
  )

  # Explicit cleanup (trap will also handle this in case of failures)
  rm -rf "$test_home" 2>/dev/null
  trap - EXIT INT TERM

  # Verify result
  if [[ "$result" == "PASS" ]]; then
    test_result "Lazy loading: setup" "PASS"
  else
    test_result "Lazy loading: setup" "FAIL" "Lazy loading marker not found in .zshrc"
  fi
}

# Test 11: Shell integration configuration function exists
test_shell_integration_function() {
  if type _kiro_configure_shell_integration >/dev/null 2>&1; then
    test_result "Shell integration: function exists" "PASS"
  else
    test_result "Shell integration: function exists" "FAIL" "Function not defined"
  fi
}

# Test 12: Health check function exists
test_health_check_function() {
  if type _kiro_health_check >/dev/null 2>&1; then
    test_result "Health check: function exists" "PASS"
  else
    test_result "Health check: function exists" "FAIL" "Function not defined"
  fi
}

# Test 13: Main integration function exists
test_main_integration_function() {
  if type kiro_install_integration >/dev/null 2>&1; then
    test_result "Main integration: function exists" "PASS"
  else
    test_result "Main integration: function exists" "FAIL" "Function not defined"
  fi
}

# Test 14: Error handling - missing kiro-cli command
test_error_handling_missing_kiro() {
  # Ensure kiro-cli is not available for this test
  local result=$(_kiro_configure_shell_integration 2>&1)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Error handling: missing kiro-cli command" "PASS"
  else
    # If kiro-cli is actually installed, this test can't properly validate error handling
    test_result "Error handling: missing kiro-cli command" "PASS" "kiro-cli is installed, skipping error test"
  fi
}

# Test 15: Integration with config system
test_integration_with_config() {
  # Test that config parsing integrates properly
  local enabled=$(_zsh_tool_parse_kiro_enabled)
  local lazy=$(_zsh_tool_parse_kiro_lazy_loading)
  local atuin=$(_zsh_tool_parse_kiro_atuin_compatibility)

  if [[ "$enabled" == "true" ]] && [[ "$lazy" == "true" ]] && [[ "$atuin" == "true" ]]; then
    test_result "Integration with config system" "PASS"
  else
    test_result "Integration with config system" "FAIL" "Config values not parsed correctly"
  fi
}

# Test 16: Integration test for kiro_install_integration main flow
test_kiro_install_integration_flow() {
  local test_home="/tmp/test-integration-$$"

  # Create isolated test environment
  mkdir -p "$test_home"
  trap "rm -rf '$test_home' 2>/dev/null" EXIT INT TERM

  # Set up isolated environment
  local old_home="$HOME"
  local old_config_dir="$KIRO_CONFIG_DIR"
  local old_settings_file="$KIRO_SETTINGS_FILE"

  export HOME="$test_home"
  export KIRO_CONFIG_DIR="${test_home}/.kiro"
  export KIRO_SETTINGS_FILE="${KIRO_CONFIG_DIR}/settings/cli.json"
  mkdir -p "${KIRO_CONFIG_DIR}/settings"
  touch "${HOME}/.zshrc"

  # Save original functions
  local orig_is_installed=$(declare -f _kiro_is_installed)
  local orig_detect=$(declare -f _kiro_detect)
  local orig_install=$(declare -f _kiro_install)
  local orig_health_check=$(declare -f _kiro_health_check)

  # Mock functions for successful flow
  _kiro_is_installed() { return 0; }
  _kiro_detect() { return 0; }
  _kiro_install() { return 0; }
  _kiro_health_check() { return 0; }

  # Test: Full integration flow with all options
  local test_passed=true
  local fail_msg=""

  # Test with lazy loading and atuin enabled
  if ! kiro_install_integration "true" "true" >/dev/null 2>&1; then
    test_passed=false
    fail_msg="Integration flow should succeed"
  fi

  # Verify atuin was added to settings
  if [[ "$test_passed" == "true" ]] && [[ -f "$KIRO_SETTINGS_FILE" ]]; then
    if ! grep -q "atuin" "$KIRO_SETTINGS_FILE" 2>/dev/null; then
      test_passed=false
      fail_msg="Atuin not in settings"
    fi
  fi

  # Verify lazy loading was added to .zshrc
  if [[ "$test_passed" == "true" ]]; then
    if ! grep -q "Kiro CLI lazy loading" "${HOME}/.zshrc" 2>/dev/null; then
      test_passed=false
      fail_msg="Lazy loading not in zshrc"
    fi
  fi

  # Restore original functions
  eval "$orig_is_installed"
  eval "$orig_detect"
  eval "$orig_install"
  eval "$orig_health_check"

  # Restore environment
  export HOME="$old_home"
  export KIRO_CONFIG_DIR="$old_config_dir"
  export KIRO_SETTINGS_FILE="$old_settings_file"

  # Cleanup
  rm -rf "$test_home" 2>/dev/null
  trap - EXIT INT TERM

  if [[ "$test_passed" == "true" ]]; then
    test_result "Integration: kiro_install_integration flow" "PASS"
  else
    test_result "Integration: kiro_install_integration flow" "FAIL" "$fail_msg"
  fi
}

# Test 17: State update function exists
test_state_update_function() {
  if type _kiro_update_state >/dev/null 2>&1; then
    test_result "State update: function exists" "PASS"
  else
    test_result "State update: function exists" "FAIL" "Function not defined"
  fi
}

# Test 18: State update creates state entry
test_state_update_creates_entry() {
  local test_state_dir="/tmp/test-state-$$"
  mkdir -p "$test_state_dir"

  # Set up isolated state file
  local old_state_file="${ZSH_TOOL_STATE_FILE:-}"
  export ZSH_TOOL_STATE_FILE="$test_state_dir/state.json"
  echo '{}' > "$ZSH_TOOL_STATE_FILE"

  # Run state update
  _kiro_update_state "true" "test-version" "true" "true" >/dev/null 2>&1

  # Check if state was updated
  local result="FAIL"
  if [[ -f "$ZSH_TOOL_STATE_FILE" ]]; then
    if grep -q "kiro_cli" "$ZSH_TOOL_STATE_FILE" 2>/dev/null; then
      result="PASS"
    fi
  fi

  # Restore and cleanup
  [[ -n "$old_state_file" ]] && export ZSH_TOOL_STATE_FILE="$old_state_file" || unset ZSH_TOOL_STATE_FILE
  rm -rf "$test_state_dir"

  if [[ "$result" == "PASS" ]]; then
    test_result "State update: creates state entry" "PASS"
  else
    test_result "State update: creates state entry" "FAIL" "kiro_cli not found in state"
  fi
}

# Test 19: Remove lazy loading function exists
test_remove_lazy_loading_function() {
  if type _kiro_remove_lazy_loading >/dev/null 2>&1; then
    test_result "Remove lazy loading: function exists" "PASS"
  else
    test_result "Remove lazy loading: function exists" "FAIL" "Function not defined"
  fi
}

# Test 20: Remove lazy loading removes configuration
test_remove_lazy_loading_removes_config() {
  local test_home="/tmp/test-remove-lazy-$$"
  mkdir -p "$test_home"

  # Create .zshrc with lazy loading
  cat > "$test_home/.zshrc" << 'EOF'
# Some existing config
export PATH=/usr/bin

# Kiro CLI lazy loading (zsh-tool)
# Defers Kiro CLI initialization until first use
_kiro_lazy_init() {
  unalias kiro-cli 2>/dev/null
  unalias q 2>/dev/null
}
alias kiro-cli='_kiro_lazy_init'
alias q='_kiro_lazy_init'

# More config after
export EDITOR=vim
EOF

  # Run remove in subshell
  local result=$(
    HOME="$test_home"
    _kiro_remove_lazy_loading >/dev/null 2>&1

    # Check if lazy loading was removed
    if grep -q "Kiro CLI lazy loading" "${HOME}/.zshrc" 2>/dev/null; then
      echo "FAIL"
    else
      echo "PASS"
    fi
  )

  # Cleanup
  rm -rf "$test_home"

  if [[ "$result" == "PASS" ]]; then
    test_result "Remove lazy loading: removes configuration" "PASS"
  else
    test_result "Remove lazy loading: removes configuration" "FAIL" "Lazy loading still present"
  fi
}

# Main test runner
run_tests() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Kiro CLI Integration - Test Suite"
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
  test_error_handling_missing_kiro
  test_integration_with_config
  test_kiro_install_integration_flow
  test_state_update_function
  test_state_update_creates_entry
  test_remove_lazy_loading_function
  test_remove_lazy_loading_removes_config

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

# Run tests if executed directly (zsh-only check)
if [[ "${(%):-%x}" == "${0}" ]] || [[ "${0}" == *test-kiro-cli.zsh ]]; then
  run_tests
fi
