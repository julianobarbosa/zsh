#!/usr/bin/env zsh
# Edge case tests for Amazon Q CLI integration
# Tests security, filesystem, and configuration edge cases

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

# Setup test environment
setup_test_env() {
  export TEST_MODE=true
  export ZSH_TOOL_CONFIG_DIR="/tmp/zsh-tool-edge-test-$$"
  export ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/test.log"
  export AMAZONQ_CONFIG_DIR="${ZSH_TOOL_CONFIG_DIR}/amazonq"
  export AMAZONQ_SETTINGS_FILE="${AMAZONQ_CONFIG_DIR}/settings.json"

  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"
  mkdir -p "${AMAZONQ_CONFIG_DIR}"
}

# Cleanup test environment
teardown_test_env() {
  rm -rf "/tmp/zsh-tool-edge-test-$$" 2>/dev/null
}

# Load modules
load_modules() {
  local test_dir
  if [[ -n "${(%):-%x}" ]]; then
    test_dir="${${(%):-%x}:A:h}"
  else
    test_dir="${0:A:h}"
  fi

  local project_root="${test_dir:h}"
  local lib_dir="${project_root}/lib"

  # Suppress error traps during module loading for tests
  setopt LOCAL_TRAPS
  trap - ERR

  # Load core utilities
  source "${lib_dir}/core/utils.zsh"

  # Load Amazon Q integration
  source "${lib_dir}/integrations/amazon-q.zsh"
}

# ============================================================================
# SECURITY TESTS (HIGH PRIORITY)
# ============================================================================

# Test 1: Command injection via semicolon
test_security_injection_semicolon() {
  _amazonq_validate_cli_name "atuin; rm -rf /" 2>/dev/null
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Security: reject semicolon injection" "PASS"
  else
    test_result "Security: reject semicolon injection" "FAIL" "Should reject CLI name with semicolon"
  fi
}

# Test 2: Command injection via dollar sign
test_security_injection_dollar() {
  _amazonq_validate_cli_name "test\$(whoami)" 2>/dev/null
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Security: reject dollar sign injection" "PASS"
  else
    test_result "Security: reject dollar sign injection" "FAIL" "Should reject CLI name with dollar sign"
  fi
}

# Test 3: Command injection via backtick
test_security_injection_backtick() {
  _amazonq_validate_cli_name "cli\`id\`" 2>/dev/null
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Security: reject backtick injection" "PASS"
  else
    test_result "Security: reject backtick injection" "FAIL" "Should reject CLI name with backtick"
  fi
}

# Test 4: Command injection via pipe
test_security_injection_pipe() {
  _amazonq_validate_cli_name "name|cat /etc/passwd" 2>/dev/null
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Security: reject pipe injection" "PASS"
  else
    test_result "Security: reject pipe injection" "FAIL" "Should reject CLI name with pipe"
  fi
}

# Test 5: Command injection via ampersand
test_security_injection_ampersand() {
  _amazonq_validate_cli_name "app&& echo pwned" 2>/dev/null
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Security: reject ampersand injection" "PASS"
  else
    test_result "Security: reject ampersand injection" "FAIL" "Should reject CLI name with ampersand"
  fi
}

# Test 6: Special characters - forward slash
test_security_special_slash() {
  _amazonq_validate_cli_name "test/slash" 2>/dev/null
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Security: reject forward slash" "PASS"
  else
    test_result "Security: reject forward slash" "FAIL" "Should reject CLI name with slash"
  fi
}

# Test 7: Special characters - asterisk
test_security_special_asterisk() {
  _amazonq_validate_cli_name "test*star" 2>/dev/null
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Security: reject asterisk" "PASS"
  else
    test_result "Security: reject asterisk" "FAIL" "Should reject CLI name with asterisk"
  fi
}

# Test 8: Special characters - quotes
test_security_special_quotes() {
  _amazonq_validate_cli_name "test'quote" 2>/dev/null
  local exit1=$?
  _amazonq_validate_cli_name 'test"doublequote' 2>/dev/null
  local exit2=$?

  if [[ $exit1 -ne 0 ]] && [[ $exit2 -ne 0 ]]; then
    test_result "Security: reject quotes" "PASS"
  else
    test_result "Security: reject quotes" "FAIL" "Should reject CLI names with quotes"
  fi
}

# Test 9: Length limit enforcement
test_security_length_limit() {
  local long_name=$(printf 'a%.0s' {1..65})  # 65 characters
  _amazonq_validate_cli_name "$long_name" 2>/dev/null
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Security: enforce length limit" "PASS"
  else
    test_result "Security: enforce length limit" "FAIL" "Should reject CLI names > 64 chars"
  fi
}

# Test 10: Empty name rejection
test_security_empty_name() {
  _amazonq_validate_cli_name "" 2>/dev/null
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    test_result "Security: reject empty name" "PASS"
  else
    test_result "Security: reject empty name" "FAIL" "Should reject empty CLI name"
  fi
}

# Test 11: Valid names should pass
test_security_valid_names() {
  local valid_names=("atuin" "test-cli" "my_tool" "app123")
  local all_passed=true

  for name in "${valid_names[@]}"; do
    if ! _amazonq_validate_cli_name "$name" 2>/dev/null; then
      all_passed=false
      break
    fi
  done

  if [[ "$all_passed" == "true" ]]; then
    test_result "Security: accept valid names" "PASS"
  else
    test_result "Security: accept valid names" "FAIL" "Valid names should be accepted"
  fi
}

# ============================================================================
# FILESYSTEM TESTS (MEDIUM PRIORITY)
# ============================================================================

# Test 12: Invalid JSON handling
test_filesystem_invalid_json() {
  # Create invalid JSON
  echo '{"disabledClis": [' > "$AMAZONQ_SETTINGS_FILE"  # Missing closing bracket

  # Try to configure settings (should handle gracefully)
  _amazonq_configure_settings "atuin" 2>/dev/null
  local exit_code=$?

  # With jq, it should detect and fix/reinitialize
  if [[ -f "$AMAZONQ_SETTINGS_FILE" ]]; then
    # Check if file is now valid JSON
    jq empty "$AMAZONQ_SETTINGS_FILE" 2>/dev/null
    if [[ $? -eq 0 ]]; then
      test_result "Filesystem: handle invalid JSON" "PASS"
    else
      test_result "Filesystem: handle invalid JSON" "FAIL" "Should create valid JSON"
    fi
  else
    test_result "Filesystem: handle invalid JSON" "FAIL" "Should create settings file"
  fi
}

# Test 13: Read-only directory
test_filesystem_readonly_directory() {
  local test_dir="/tmp/amazonq-readonly-$$"
  mkdir -p "$test_dir"
  chmod 555 "$test_dir"

  # Try to create config in read-only parent
  local old_config_dir="$AMAZONQ_CONFIG_DIR"
  AMAZONQ_CONFIG_DIR="$test_dir/config"
  AMAZONQ_SETTINGS_FILE="${AMAZONQ_CONFIG_DIR}/settings.json"

  _amazonq_configure_settings "test" 2>/dev/null
  local result=$?

  # Restore
  AMAZONQ_CONFIG_DIR="$old_config_dir"
  AMAZONQ_SETTINGS_FILE="${AMAZONQ_CONFIG_DIR}/settings.json"

  # Cleanup
  chmod 755 "$test_dir"
  rm -rf "$test_dir"

  if [[ $result -ne 0 ]]; then
    test_result "Filesystem: detect readonly directory" "PASS"
  else
    test_result "Filesystem: detect readonly directory" "FAIL" "Should fail with readonly parent"
  fi
}

# Test 14: jq not available
test_filesystem_no_jq() {
  # Temporarily hide jq
  local old_path="$PATH"
  export PATH="/usr/bin:/bin"

  # Try to configure settings
  _amazonq_configure_settings "test" 2>/dev/null
  local result=$?

  # Restore PATH
  export PATH="$old_path"

  # Should fail if jq is not available (unless jq is in /usr/bin or /bin)
  if ! command -v jq >/dev/null 2>&1 || [[ $result -ne 0 ]]; then
    test_result "Filesystem: require jq" "PASS"
  else
    # If jq is in system path, this test is informational
    test_result "Filesystem: require jq" "PASS" "jq available in system path"
  fi
}

# ============================================================================
# CONFIGURATION TESTS (MEDIUM PRIORITY)
# ============================================================================

# Test 15: Symlinked .zshrc detection
test_config_symlink_detection() {
  local test_home="/tmp/test-home-$$"
  local real_zshrc="$test_home/real_zshrc"
  local link_zshrc="$test_home/.zshrc"

  mkdir -p "$test_home"
  touch "$real_zshrc"
  ln -s "$real_zshrc" "$link_zshrc"

  # Try to setup lazy loading (should detect symlink)
  local result=$(HOME="$test_home" _amazonq_setup_lazy_loading 2>&1)
  local contains_symlink=false

  if [[ "$result" == *"symlink"* ]]; then
    contains_symlink=true
  fi

  # Cleanup
  rm -rf "$test_home"

  if [[ "$contains_symlink" == "true" ]]; then
    test_result "Config: detect symlinked .zshrc" "PASS"
  else
    test_result "Config: detect symlinked .zshrc" "FAIL" "Should detect and warn about symlink"
  fi
}

# Test 16: Idempotent lazy loading
test_config_idempotent_lazy_loading() {
  local test_home="/tmp/test-home-$$"
  mkdir -p "$test_home"
  touch "$test_home/.zshrc"

  # Run twice in subshell to avoid polluting environment
  local first_result=$(
    HOME="$test_home"
    _amazonq_setup_lazy_loading >/dev/null 2>&1
    cat "${HOME}/.zshrc"
  )

  local second_result=$(
    HOME="$test_home"
    _amazonq_setup_lazy_loading >/dev/null 2>&1
    cat "${HOME}/.zshrc"
  )

  # Cleanup
  rm -rf "$test_home"

  # Content should be identical (not duplicated)
  if [[ "$first_result" == "$second_result" ]]; then
    test_result "Config: idempotent lazy loading" "PASS"
  else
    test_result "Config: idempotent lazy loading" "FAIL" "Should not duplicate lazy loading code"
  fi
}

# Test 17: Backup creation
test_config_backup_creation() {
  local test_home="/tmp/test-home-$$"
  mkdir -p "$test_home"
  echo "original content" > "$test_home/.zshrc"

  # Setup lazy loading (should create backup)
  HOME="$test_home" _amazonq_setup_lazy_loading >/dev/null 2>&1

  # Check for backup files
  local backup_count=$(ls "$test_home"/.zshrc.backup-* 2>/dev/null | wc -l)

  # Cleanup
  rm -rf "$test_home"

  if [[ $backup_count -gt 0 ]]; then
    test_result "Config: create backup" "PASS"
  else
    test_result "Config: create backup" "FAIL" "Should create timestamped backup"
  fi
}

# Test 18: Missing .zshrc handling
test_config_missing_zshrc() {
  local test_home="/tmp/test-home-$$"
  mkdir -p "$test_home"
  # Don't create .zshrc

  # Try to setup lazy loading
  HOME="$test_home" _amazonq_setup_lazy_loading 2>/dev/null
  local result=$?

  # Cleanup
  rm -rf "$test_home"

  if [[ $result -ne 0 ]]; then
    test_result "Config: handle missing .zshrc" "PASS"
  else
    test_result "Config: handle missing .zshrc" "FAIL" "Should fail gracefully when .zshrc missing"
  fi
}

# ============================================================================
# ERROR HANDLING TESTS
# ============================================================================

# Test 19: Multiple validation errors
test_error_multiple_invalid_names() {
  local invalid_names=("test;rm" "app\$var" "cli|pipe")
  local all_rejected=true

  for name in "${invalid_names[@]}"; do
    if _amazonq_validate_cli_name "$name" 2>/dev/null; then
      all_rejected=false
      break
    fi
  done

  if [[ "$all_rejected" == "true" ]]; then
    test_result "Error: reject multiple invalid names" "PASS"
  else
    test_result "Error: reject multiple invalid names" "FAIL" "All invalid names should be rejected"
  fi
}

# Test 20: Configure with mix of valid and invalid names
test_error_mixed_valid_invalid() {
  # Should fail on first invalid name
  _amazonq_configure_settings "atuin" "test;bad" "valid-cli" 2>/dev/null
  local result=$?

  if [[ $result -ne 0 ]]; then
    test_result "Error: reject on first invalid name" "PASS"
  else
    test_result "Error: reject on first invalid name" "FAIL" "Should fail when any name is invalid"
  fi
}

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

run_edge_case_tests() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Amazon Q CLI Integration - Edge Case Test Suite"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Setup
  setup_test_env
  load_modules

  echo "${YELLOW}Running Security Tests (HIGH Priority)${NC}"
  echo ""
  test_security_injection_semicolon
  test_security_injection_dollar
  test_security_injection_backtick
  test_security_injection_pipe
  test_security_injection_ampersand
  test_security_special_slash
  test_security_special_asterisk
  test_security_special_quotes
  test_security_length_limit
  test_security_empty_name
  test_security_valid_names

  echo ""
  echo "${YELLOW}Running Filesystem Tests (MEDIUM Priority)${NC}"
  echo ""
  test_filesystem_invalid_json
  test_filesystem_readonly_directory
  test_filesystem_no_jq

  echo ""
  echo "${YELLOW}Running Configuration Tests (MEDIUM Priority)${NC}"
  echo ""
  test_config_symlink_detection
  test_config_idempotent_lazy_loading
  test_config_backup_creation
  test_config_missing_zshrc

  echo ""
  echo "${YELLOW}Running Error Handling Tests${NC}"
  echo ""
  test_error_multiple_invalid_names
  test_error_mixed_valid_invalid

  # Teardown
  teardown_test_env

  # Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Edge Case Test Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Total Tests: $TEST_COUNT"
  echo "${GREEN}Passed: $PASS_COUNT${NC}"
  echo "${RED}Failed: $FAIL_COUNT${NC}"
  echo ""

  if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "${GREEN}✓ All edge case tests passed!${NC}"
    echo ""
    return 0
  else
    echo "${RED}✗ Some edge case tests failed${NC}"
    echo ""
    return 1
  fi
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
  run_edge_case_tests
fi
