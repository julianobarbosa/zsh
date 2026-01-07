#!/usr/bin/env zsh
# Test suite for Vi-Mode integration
# Tests cursor shapes, mode indicators, keybindings, and configuration

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

  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"

  # Create test config
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
vimode:
  enabled: true
  cursor:
    insert: "beam"
    normal: "block"
  escape_timeout: 10
  indicators:
    insert: "INS"
    normal: "NOR"
  atuin_compatibility: true
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

  # Load vi-mode integration
  source "${lib_dir}/integrations/vimode.zsh"
}

# ==============================================================================
# Tests
# ==============================================================================

# Test 1: Module loading
test_module_loading() {
  if [[ $(type vimode_init 2>/dev/null) ]]; then
    test_result "Module loading" "PASS"
  else
    test_result "Module loading" "FAIL" "vimode_init function not found"
  fi
}

# Test 2: Cursor codes defined
test_cursor_codes_defined() {
  if [[ -n "${VIMODE_CURSOR_CODES[block]}" ]] && \
     [[ -n "${VIMODE_CURSOR_CODES[beam]}" ]] && \
     [[ -n "${VIMODE_CURSOR_CODES[underline]}" ]]; then
    test_result "Cursor codes defined" "PASS"
  else
    test_result "Cursor codes defined" "FAIL" "Missing cursor code definitions"
  fi
}

# Test 3: Default configuration values
test_default_config() {
  local pass=true
  local issues=""

  if [[ -z "$VIMODE_CURSOR_INSERT" ]]; then
    pass=false
    issues="VIMODE_CURSOR_INSERT not set"
  fi

  if [[ -z "$VIMODE_CURSOR_NORMAL" ]]; then
    pass=false
    issues="${issues:+$issues, }VIMODE_CURSOR_NORMAL not set"
  fi

  if [[ -z "$VIMODE_ESCAPE_TIMEOUT" ]]; then
    pass=false
    issues="${issues:+$issues, }VIMODE_ESCAPE_TIMEOUT not set"
  fi

  if $pass; then
    test_result "Default configuration" "PASS"
  else
    test_result "Default configuration" "FAIL" "$issues"
  fi
}

# Test 4: Apply config function
test_apply_config() {
  _vimode_apply_config "underline" "block" "20" "INSERT" "NORMAL"

  if [[ "$VIMODE_CURSOR_INSERT" == "underline" ]] && \
     [[ "$VIMODE_CURSOR_NORMAL" == "block" ]] && \
     [[ "$VIMODE_ESCAPE_TIMEOUT" == "20" ]] && \
     [[ "$VIMODE_INDICATOR_INSERT" == "INSERT" ]] && \
     [[ "$VIMODE_INDICATOR_NORMAL" == "NORMAL" ]]; then
    test_result "Apply config" "PASS"
  else
    test_result "Apply config" "FAIL" "Config values not applied correctly"
  fi
}

# Test 5: Config validation - invalid cursor shape
test_config_validation_cursor() {
  _vimode_apply_config "invalid_shape" "block" "10"

  # Invalid shape should fall back to default
  if [[ "$VIMODE_CURSOR_INSERT" == "beam" ]]; then
    test_result "Config validation - cursor" "PASS"
  else
    test_result "Config validation - cursor" "FAIL" "Invalid cursor shape not rejected"
  fi
}

# Test 6: Config validation - invalid timeout
test_config_validation_timeout() {
  _vimode_apply_config "beam" "block" "500"

  # Invalid timeout should fall back to default (10)
  if [[ "$VIMODE_ESCAPE_TIMEOUT" == "10" ]]; then
    test_result "Config validation - timeout" "PASS"
  else
    test_result "Config validation - timeout" "FAIL" "Invalid timeout not rejected: $VIMODE_ESCAPE_TIMEOUT"
  fi
}

# Test 7: Mode indicator update
test_mode_indicator_update() {
  VIMODE_CURRENT_MODE="normal"
  _vimode_update_indicator

  if [[ "$VIMODE_INDICATOR" == "$VIMODE_INDICATOR_NORMAL" ]]; then
    test_result "Mode indicator update" "PASS"
  else
    test_result "Mode indicator update" "FAIL" "Indicator not updated for normal mode"
  fi
}

# Test 8: Terminal detection function exists
test_terminal_detection() {
  if [[ $(type _vimode_detect_terminal 2>/dev/null) ]]; then
    # Function exists, run it
    _vimode_detect_terminal
    local result=$?
    # Result doesn't matter, just that it runs without error
    test_result "Terminal detection" "PASS"
  else
    test_result "Terminal detection" "FAIL" "_vimode_detect_terminal function not found"
  fi
}

# Test 9: tmux detection function
test_tmux_detection() {
  # Save original TMUX value
  local original_tmux="$TMUX"

  # Test with TMUX set
  export TMUX="/tmp/tmux-test/default,12345,0"
  if _vimode_in_tmux; then
    # Test with TMUX unset
    unset TMUX
    if ! _vimode_in_tmux; then
      test_result "tmux detection" "PASS"
    else
      test_result "tmux detection" "FAIL" "Failed to detect non-tmux environment"
    fi
  else
    test_result "tmux detection" "FAIL" "Failed to detect tmux environment"
  fi

  # Restore original TMUX value
  if [[ -n "$original_tmux" ]]; then
    export TMUX="$original_tmux"
  fi
}

# Test 10: Cursor escape function
test_cursor_escape() {
  local escape_seq=$(_vimode_cursor_escape '\e[2 q')

  if [[ -n "$escape_seq" ]]; then
    test_result "Cursor escape sequence" "PASS"
  else
    test_result "Cursor escape sequence" "FAIL" "Empty escape sequence returned"
  fi
}

# Test 11: vimode_indicator function
test_indicator_function() {
  VIMODE_INDICATOR="TEST"
  local indicator=$(vimode_indicator)

  if [[ "$indicator" == "TEST" ]]; then
    test_result "vimode_indicator function" "PASS"
  else
    test_result "vimode_indicator function" "FAIL" "Unexpected output: $indicator"
  fi
}

# Test 12: Colored indicator function
test_colored_indicator() {
  VIMODE_CURRENT_MODE="insert"
  VIMODE_INDICATOR="INS"
  local colored=$(vimode_indicator_colored)

  # Should contain color codes and the indicator
  if [[ "$colored" == *"INS"* ]] && [[ "$colored" == *"%F{"* ]]; then
    test_result "Colored indicator function" "PASS"
  else
    test_result "Colored indicator function" "FAIL" "Missing color codes or indicator"
  fi
}

# Test 13: Installation integration function exists
test_install_integration_exists() {
  if [[ $(type vimode_install_integration 2>/dev/null) ]]; then
    test_result "Install integration function" "PASS"
  else
    test_result "Install integration function" "FAIL" "vimode_install_integration not found"
  fi
}

# Test 14: Health check function exists
test_health_check_exists() {
  if [[ $(type _vimode_health_check 2>/dev/null) ]]; then
    test_result "Health check function" "PASS"
  else
    test_result "Health check function" "FAIL" "_vimode_health_check not found"
  fi
}

# Test 15: Atuin compatibility setup function
test_atuin_compat_function() {
  if [[ $(type _vimode_setup_atuin_compatibility 2>/dev/null) ]]; then
    test_result "Atuin compatibility function" "PASS"
  else
    test_result "Atuin compatibility function" "FAIL" "_vimode_setup_atuin_compatibility not found"
  fi
}

# ==============================================================================
# Main test runner
# ==============================================================================

main() {
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Vi-Mode Integration Test Suite"
  echo "═══════════════════════════════════════════════════════════"
  echo ""

  # Setup
  setup_test_env
  load_modules

  # Run tests
  test_module_loading
  test_cursor_codes_defined
  test_default_config
  test_apply_config
  test_config_validation_cursor
  test_config_validation_timeout
  test_mode_indicator_update
  test_terminal_detection
  test_tmux_detection
  test_cursor_escape
  test_indicator_function
  test_colored_indicator
  test_install_integration_exists
  test_health_check_exists
  test_atuin_compat_function

  # Cleanup
  teardown_test_env

  # Summary
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Test Summary"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "Total:  $TEST_COUNT"
  echo "Passed: ${GREEN}$PASS_COUNT${NC}"
  echo "Failed: ${RED}$FAIL_COUNT${NC}"
  echo ""

  if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "${GREEN}All tests passed!${NC}"
    return 0
  else
    echo "${RED}Some tests failed.${NC}"
    return 1
  fi
}

# Run tests
main "$@"
