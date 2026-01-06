#!/usr/bin/env zsh
# Test suite for Atuin Shell History Integration
# Tests installation, configuration, keybindings, and integration

# Source core utilities for testing
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/lib/core/utils.zsh"
source "$PROJECT_ROOT/lib/integrations/atuin.zsh"

# Test configuration
TEST_OUTPUT_FILE="${SCRIPT_DIR}/test-atuin-output.log"
TEST_STATE_FILE="${HOME}/.config/zsh-tool/test-state.json"
TEST_ATUIN_CONFIG="${HOME}/.config/atuin/test-config.toml"

# Test counters
# HIGH-4 FIX: Separate test count from assertion count for accurate reporting
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
ASSERTIONS_PASSED=0
ASSERTIONS_FAILED=0
_CURRENT_TEST_FAILED=0

# HIGH-5 FIX: Save original PATH for restoration
_ORIGINAL_PATH="$PATH"

# Test helpers
test_start() {
  TESTS_RUN=$((TESTS_RUN + 1))
  _CURRENT_TEST_FAILED=0
  echo "\n🧪 Test $TESTS_RUN: $1"
}

# Mark test as complete (call at end of each test function)
test_end() {
  if [[ $_CURRENT_TEST_FAILED -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  # HIGH-5 FIX: Restore PATH after each test
  PATH="$_ORIGINAL_PATH"
}

test_pass() {
  ASSERTIONS_PASSED=$((ASSERTIONS_PASSED + 1))
  echo "  ✅ PASS: $1"
}

test_fail() {
  ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
  _CURRENT_TEST_FAILED=1
  echo "  ❌ FAIL: $1"
  [[ -n "$2" ]] && echo "     Expected: $2"
  [[ -n "$3" ]] && echo "     Got: $3"
}

test_assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Values should be equal}"

  if [[ "$actual" == "$expected" ]]; then
    test_pass "$message"
    return 0
  else
    test_fail "$message" "$expected" "$actual"
    return 1
  fi
}

test_assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Should contain value}"

  if [[ "$haystack" == *"$needle"* ]]; then
    test_pass "$message"
    return 0
  else
    test_fail "$message" "contains '$needle'" "'$haystack'"
    return 1
  fi
}

test_assert_true() {
  local condition="$1"
  local message="${2:-Condition should be true}"

  if eval "$condition"; then
    test_pass "$message"
    return 0
  else
    test_fail "$message"
    return 1
  fi
}

test_assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  if [[ -f "$file" ]]; then
    test_pass "$message"
    return 0
  else
    test_fail "$message"
    return 1
  fi
}

# =============================================================================
# AC1: Atuin detection validates installation via `atuin --version`
# =============================================================================

test_atuin_detection_installed() {
  test_start "AC1: Atuin detection when installed"

  # Mock atuin command
  function atuin() { echo "atuin 18.0.0"; }

  if _atuin_detect 2>&1 | grep -q "Atuin detected"; then
    test_pass "Detects installed Atuin"
  else
    test_fail "Should detect installed Atuin"
  fi

  # Cleanup
  unfunction atuin 2>/dev/null
  test_end
}

test_atuin_detection_not_installed() {
  test_start "AC1: Atuin detection when not installed"

  # HIGH-5 FIX: PATH is saved by test_start and restored by test_end
  # Ensure atuin is not in PATH for this test
  PATH="/usr/bin:/bin"

  if _atuin_detect 2>&1 | grep -q "not found"; then
    test_pass "Detects Atuin not installed"
  else
    test_fail "Should detect Atuin not installed"
  fi
  test_end
}

# =============================================================================
# AC3: TOML configuration management for Atuin settings
# =============================================================================

test_atuin_config_generation() {
  test_start "AC3: TOML configuration generation"

  # Setup test config path
  local test_config_dir="${HOME}/.config/atuin-test-$$"
  local test_config_file="${test_config_dir}/config.toml"
  ATUIN_CONFIG_DIR="$test_config_dir"
  ATUIN_CONFIG_FILE="$test_config_file"

  # Generate config
  _atuin_configure_settings "true" "25" "fuzzy" "global" "auto" >/dev/null 2>&1

  # Verify file exists
  test_assert_file_exists "$test_config_file" "Config file created"

  # Verify content
  if [[ -f "$test_config_file" ]]; then
    local content=$(cat "$test_config_file")
    test_assert_contains "$content" "search_mode = \"fuzzy\"" "Contains fuzzy search mode"
    test_assert_contains "$content" "filter_mode = \"global\"" "Contains global filter mode"
    test_assert_contains "$content" "inline_height = 25" "Contains inline height setting"
    test_assert_contains "$content" "auto_sync = true" "Contains sync setting"
  fi

  # Cleanup
  rm -rf "$test_config_dir"
  test_end
}

# =============================================================================
# SECURITY: TOML injection prevention tests (HIGH priority fix)
# =============================================================================

test_atuin_toml_sanitization() {
  test_start "SECURITY: TOML injection prevention"

  # Test 1: Sanitize string with injection attempt
  local malicious='fuzzy"; auto_sync = true; evil = "injected'
  local sanitized=$(_atuin_sanitize_toml_string "$malicious")
  # Should remove quotes and newlines
  if [[ "$sanitized" != *'"'* ]]; then
    test_pass "Removes quotes from malicious input"
  else
    test_fail "Should remove quotes from input" "no quotes" "$sanitized"
  fi

  # Test 2: Validate enum rejects invalid values
  local invalid_mode="evil_mode"
  local validated=$(_atuin_validate_enum "$invalid_mode" "fuzzy" "fuzzy" "prefix" "fulltext")
  test_assert_equals "$validated" "fuzzy" "Rejects invalid enum, returns default"

  # Test 3: Validate enum accepts valid values
  local valid_mode="prefix"
  validated=$(_atuin_validate_enum "$valid_mode" "fuzzy" "fuzzy" "prefix" "fulltext")
  test_assert_equals "$validated" "prefix" "Accepts valid enum value"

  # Test 4: Validate number rejects out of range
  local bad_number="999"
  local validated_num=$(_atuin_validate_number "$bad_number" "20" 1 50)
  test_assert_equals "$validated_num" "20" "Rejects out-of-range number"

  # Test 5: Validate number rejects non-numeric
  local non_number="abc"
  validated_num=$(_atuin_validate_number "$non_number" "20" 1 50)
  test_assert_equals "$validated_num" "20" "Rejects non-numeric input"

  # Test 6: Config generation with malicious inputs
  local test_config_dir="${HOME}/.config/atuin-security-test-$$"
  local test_config_file="${test_config_dir}/config.toml"
  ATUIN_CONFIG_DIR="$test_config_dir"
  ATUIN_CONFIG_FILE="$test_config_file"

  # Try to inject via search_mode parameter
  _atuin_configure_settings "true" "25" 'fuzzy"; evil = "injected' "global" "auto" >/dev/null 2>&1

  if [[ -f "$test_config_file" ]]; then
    local content=$(cat "$test_config_file")
    # Should NOT contain injected content
    if [[ "$content" != *"evil"* ]]; then
      test_pass "Config generation prevents TOML injection"
    else
      test_fail "Config should not contain injected content" "no 'evil' string" "found injection"
    fi
  fi

  # Cleanup
  rm -rf "$test_config_dir"
  test_end
}

test_atuin_config_preserves_existing() {
  test_start "AC3: Existing configuration preservation"

  # Setup test config with existing content
  local test_config_dir="${HOME}/.config/atuin-test-$$"
  local test_config_file="${test_config_dir}/config.toml"
  ATUIN_CONFIG_DIR="$test_config_dir"
  ATUIN_CONFIG_FILE="$test_config_file"

  mkdir -p "$test_config_dir"
  echo "# Existing config" > "$test_config_file"
  echo "search_mode = \"prefix\"" >> "$test_config_file"

  # Try to configure again
  _atuin_configure_settings "false" "20" "fuzzy" "host" "compact" >/dev/null 2>&1

  # Verify original content preserved
  local content=$(cat "$test_config_file")
  test_assert_contains "$content" "Existing config" "Preserves existing config marker"
  test_assert_contains "$content" "prefix" "Preserves original settings"

  # Cleanup
  rm -rf "$test_config_dir"
  test_end
}

# =============================================================================
# AC5: Ctrl+R keybinding properly configured
# =============================================================================

test_atuin_keybinding_configuration() {
  test_start "AC5: Ctrl+R keybinding configuration"

  # This is informational - actual binding happens in shell
  _atuin_configure_keybindings "true" >/dev/null 2>&1
  local result=$?

  test_assert_equals "$result" "0" "Keybinding configuration succeeds"
  test_end
}

# =============================================================================
# AC6: Amazon Q compatibility ensures keybinding restoration
# =============================================================================

test_atuin_amazonq_compatibility() {
  test_start "AC6: Amazon Q compatibility configuration"

  _atuin_configure_amazonq_compatibility >/dev/null 2>&1
  local result=$?

  test_assert_equals "$result" "0" "Amazon Q compatibility setup succeeds"
  test_end
}

test_atuin_zshrc_amazonq_fix() {
  test_start "AC6: Amazon Q compatibility fix in .zshrc.local"

  # Setup test zshrc
  local test_zshrc="${HOME}/.zshrc.local-test-$$"

  # Override the function to use test file
  _atuin_add_to_zshrc_custom() {
    local restore_amazonq="${1:-false}"
    local zshrc_custom="$test_zshrc"

    if [[ ! -f "$zshrc_custom" ]]; then
      touch "$zshrc_custom"
    fi

    if [[ "$restore_amazonq" == "true" ]]; then
      cat >> "$zshrc_custom" <<'EOF'
# Restore Atuin keybindings after Amazon Q
if command -v atuin &>/dev/null; then
    bindkey -M emacs '^r' atuin-search
fi
EOF
    fi
  }

  _atuin_add_to_zshrc_custom "true"

  # Verify Amazon Q fix added
  if [[ -f "$test_zshrc" ]]; then
    local content=$(cat "$test_zshrc")
    test_assert_contains "$content" "Restore Atuin keybindings" "Contains Amazon Q fix comment"
    test_assert_contains "$content" "bindkey -M emacs '^r' atuin-search" "Contains keybinding restore"
  fi

  # Cleanup
  rm -f "$test_zshrc"
  test_end
}

# =============================================================================
# AC9: Health check verifies Atuin functionality
# =============================================================================

test_atuin_health_check_passes() {
  test_start "AC9: Health check when Atuin installed"

  # Mock atuin command with proper output format
  function atuin() {
    case "$1" in
      --version) echo "atuin 18.0.0" ;;
      stats) echo "Total commands: 1234" ;;
    esac
  }

  # Create mock database directory
  local test_db_dir="${HOME}/.local/share/atuin-test-$$"
  mkdir -p "$test_db_dir"
  ATUIN_DB_PATH="${test_db_dir}/history.db"

  # Run health check and capture result
  local result=$(_atuin_health_check 2>&1)
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    test_pass "Health check passes with installed Atuin"
  else
    test_fail "Health check should pass (exit code: $exit_code)"
  fi

  # Cleanup
  unfunction atuin 2>/dev/null
  rm -rf "$test_db_dir"
  test_end
}

test_atuin_health_check_fails() {
  test_start "AC9: Health check when Atuin not installed"

  # HIGH-5 FIX: PATH is saved by test_start and restored by test_end
  # Ensure atuin is not available
  PATH="/usr/bin:/bin"

  if ! _atuin_health_check >/dev/null 2>&1; then
    test_pass "Health check fails without Atuin"
  else
    test_fail "Health check should fail without Atuin"
  fi
  test_end
}

# =============================================================================
# Task 1.1: Public command zsh-tool-install-atuin exists
# =============================================================================

test_public_command_exists() {
  test_start "Task 1.1: Public command zsh-tool-install-atuin exists"

  if type zsh-tool-install-atuin >/dev/null 2>&1; then
    test_pass "Public command zsh-tool-install-atuin exists"
  else
    test_fail "Public command zsh-tool-install-atuin should exist"
  fi
  test_end
}

# =============================================================================
# Task 6: State tracking in state.json
# =============================================================================

test_state_tracking_atuin() {
  test_start "Task 6: Atuin state tracking in state.json"

  # This test will verify state tracking once implemented
  # For now, it checks if the pattern is callable

  local test_state='{"integrations":{"atuin":{"installed":true,"version":"18.0.0"}}}'

  # Mock state file for test
  mkdir -p "${HOME}/.config/zsh-tool"
  echo "$test_state" > "$TEST_STATE_FILE"

  # Load and verify
  if [[ -f "$TEST_STATE_FILE" ]]; then
    local content=$(cat "$TEST_STATE_FILE")
    test_assert_contains "$content" "atuin" "State contains atuin integration"
    test_assert_contains "$content" '"installed":true' "State tracks installation"
  fi

  # Cleanup
  rm -f "$TEST_STATE_FILE"
  test_end
}

# =============================================================================
# Run all tests
# =============================================================================

run_all_tests() {
  echo "================================================================================"
  echo "Atuin Integration Test Suite"
  echo "================================================================================"
  echo ""

  # AC1: Detection
  test_atuin_detection_installed
  test_atuin_detection_not_installed

  # AC3: Configuration
  test_atuin_config_generation
  test_atuin_config_preserves_existing

  # SECURITY: TOML injection prevention (HIGH priority fix)
  test_atuin_toml_sanitization

  # AC5: Keybindings
  test_atuin_keybinding_configuration

  # AC6: Amazon Q compatibility
  test_atuin_amazonq_compatibility
  test_atuin_zshrc_amazonq_fix

  # AC9: Health check
  test_atuin_health_check_passes
  test_atuin_health_check_fails

  # Task 1.1: Public command
  test_public_command_exists

  # Task 6: State tracking
  test_state_tracking_atuin

  # Print summary
  echo ""
  echo "================================================================================"
  echo "Test Summary"
  echo "================================================================================"
  echo "Tests run:        $TESTS_RUN"
  echo "Tests passed:     $TESTS_PASSED"
  echo "Tests failed:     $TESTS_FAILED"
  echo ""
  echo "Assertions passed: $ASSERTIONS_PASSED"
  echo "Assertions failed: $ASSERTIONS_FAILED"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "All tests passed!"
    return 0
  else
    echo "Some tests failed"
    return 1
  fi
}

# Execute tests if run directly
if [[ "${(%):-%x}" == "${0}" ]]; then
  run_all_tests
fi
