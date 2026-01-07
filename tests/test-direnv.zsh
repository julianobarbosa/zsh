#!/usr/bin/env zsh
# Test suite for direnv + 1Password integration
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
  export DIRENV_LIB_DIR="/tmp/test-home-$$/direnv/lib"
  export DIRENV_TEMPLATE_DIR="/tmp/test-home-$$/direnv/templates"
  export DIRENV_AI_KEYS_HELPER="${DIRENV_LIB_DIR}/ai-keys.sh"
  export DIRENV_AI_KEYS_TEMPLATE="${DIRENV_TEMPLATE_DIR}/ai-keys.env.tpl"

  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"
  mkdir -p "$DIRENV_LIB_DIR"
  mkdir -p "$DIRENV_TEMPLATE_DIR"

  # Create test config
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
direnv:
  enabled: true
  onepassword_integration: true
  vault_name: "AI Keys"
  session_cache_seconds: 300
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

  # Load direnv integration
  source "${lib_dir}/integrations/direnv.zsh"
}

# Test 1: Module loading
test_module_loading() {
  if [[ $(type _direnv_detect 2>/dev/null) ]]; then
    test_result "Module loading" "PASS"
  else
    test_result "Module loading" "FAIL" "_direnv_detect function not found"
  fi
}

# Test 2: Config parsing - enabled flag
test_config_parsing_enabled() {
  local enabled=$(_zsh_tool_parse_direnv_enabled)
  if [[ "$enabled" == "true" ]]; then
    test_result "Config parsing - enabled flag" "PASS"
  else
    test_result "Config parsing - enabled flag" "FAIL" "Expected 'true', got '$enabled'"
  fi
}

# Test 3: Config parsing - vault name
test_config_parsing_vault_name() {
  local vault=$(_zsh_tool_parse_direnv_vault_name)
  if [[ "$vault" == "AI Keys" ]]; then
    test_result "Config parsing - vault name" "PASS"
  else
    test_result "Config parsing - vault name" "FAIL" "Expected 'AI Keys', got '$vault'"
  fi
}

# Test 4: Config parsing - session cache
test_config_parsing_session_cache() {
  local cache=$(_zsh_tool_parse_direnv_session_cache)
  if [[ "$cache" == "300" ]]; then
    test_result "Config parsing - session cache" "PASS"
  else
    test_result "Config parsing - session cache" "FAIL" "Expected '300', got '$cache'"
  fi
}

# Test 5: Detection function - direnv not installed
test_direnv_detection_not_installed() {
  # Mock direnv not being available
  local original_path="$PATH"
  export PATH="/nonexistent"

  if ! _direnv_is_installed; then
    test_result "direnv detection - not installed" "PASS"
  else
    test_result "direnv detection - not installed" "FAIL" "Should return false when direnv not in PATH"
  fi

  export PATH="$original_path"
}

# Test 6: Detection function - 1Password CLI not installed
test_op_detection_not_installed() {
  # Mock op not being available
  local original_path="$PATH"
  export PATH="/nonexistent"

  if ! _direnv_op_is_installed; then
    test_result "1Password CLI detection - not installed" "PASS"
  else
    test_result "1Password CLI detection - not installed" "FAIL" "Should return false when op not in PATH"
  fi

  export PATH="$original_path"
}

# Test 7: Directory structure creation
test_create_structure() {
  # Use test environment paths
  local test_lib_dir="/tmp/test-home-$$/test-structure/lib"
  local test_template_dir="/tmp/test-home-$$/test-structure/templates"

  DIRENV_LIB_DIR="$test_lib_dir"
  DIRENV_TEMPLATE_DIR="$test_template_dir"

  _direnv_create_structure

  if [[ -d "$test_lib_dir" && -d "$test_template_dir" ]]; then
    test_result "Directory structure creation" "PASS"
  else
    test_result "Directory structure creation" "FAIL" "Directories not created"
  fi
}

# Test 8: Helper installation
test_helper_installation() {
  local test_helper="/tmp/test-home-$$/helper-test/ai-keys.sh"
  mkdir -p "$(dirname "$test_helper")"

  DIRENV_AI_KEYS_HELPER="$test_helper"

  _direnv_install_ai_keys_helper

  if [[ -f "$test_helper" ]]; then
    # Check for key function
    if grep -q "load_ai_keys" "$test_helper"; then
      test_result "Helper installation" "PASS"
    else
      test_result "Helper installation" "FAIL" "load_ai_keys function not found in helper"
    fi
  else
    test_result "Helper installation" "FAIL" "Helper file not created"
  fi
}

# Test 9: Template installation
test_template_installation() {
  local test_template="/tmp/test-home-$$/template-test/ai-keys.env.tpl"
  mkdir -p "$(dirname "$test_template")"

  DIRENV_AI_KEYS_TEMPLATE="$test_template"

  _direnv_install_ai_keys_template

  if [[ -f "$test_template" ]]; then
    # Check for op:// reference pattern
    if grep -q "op://" "$test_template"; then
      test_result "Template installation" "PASS"
    else
      test_result "Template installation" "FAIL" "op:// reference not found in template"
    fi
  else
    test_result "Template installation" "FAIL" "Template file not created"
  fi
}

# Test 10: Template preservation (don't overwrite existing)
test_template_preservation() {
  local test_template="/tmp/test-home-$$/preserve-test/ai-keys.env.tpl"
  mkdir -p "$(dirname "$test_template")"

  # Create existing template with custom content
  echo "# Custom user config" > "$test_template"
  echo "MY_KEY={{ op://MyVault/MyItem/key }}" >> "$test_template"

  DIRENV_AI_KEYS_TEMPLATE="$test_template"

  _direnv_install_ai_keys_template

  # Check that original content is preserved
  if grep -q "MY_KEY" "$test_template" && grep -q "MyVault" "$test_template"; then
    test_result "Template preservation" "PASS"
  else
    test_result "Template preservation" "FAIL" "Existing template was overwritten"
  fi
}

# Test 11: Public command registration
test_public_command() {
  if [[ $(type zsh-tool-direnv 2>/dev/null) ]]; then
    test_result "Public command registration" "PASS"
  else
    test_result "Public command registration" "FAIL" "zsh-tool-direnv not found"
  fi
}

# Run all tests
run_tests() {
  echo ""
  echo "${YELLOW}direnv + 1Password Integration - Test Suite${NC}"
  echo "=============================================="
  echo ""

  setup_test_env
  load_modules

  test_module_loading
  test_config_parsing_enabled
  test_config_parsing_vault_name
  test_config_parsing_session_cache
  test_direnv_detection_not_installed
  test_op_detection_not_installed
  test_create_structure
  test_helper_installation
  test_template_installation
  test_template_preservation
  test_public_command

  teardown_test_env

  echo ""
  echo "=============================================="
  echo "Total: $TEST_COUNT | ${GREEN}Passed: $PASS_COUNT${NC} | ${RED}Failed: $FAIL_COUNT${NC}"
  echo ""

  if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "${GREEN}All tests passed!${NC}"
    return 0
  else
    echo "${RED}Some tests failed${NC}"
    return 1
  fi
}

# Execute tests
run_tests
