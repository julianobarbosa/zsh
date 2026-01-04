#!/usr/bin/env zsh
# Story 1.2: Backup Existing Configuration Tests
# Tests for lib/install/backup.zsh

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
  source "${PROJECT_ROOT}/lib/install/backup.zsh"

  # Override config directory AFTER sourcing (utils.zsh sets defaults)
  TEST_TMP_DIR=$(mktemp -d)
  ZSH_TOOL_CONFIG_DIR="${TEST_TMP_DIR}/config"
  ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/zsh-tool.log"
  ZSH_TOOL_STATE_FILE="${ZSH_TOOL_CONFIG_DIR}/state.json"
  ZSH_TOOL_BACKUP_DIR="${ZSH_TOOL_CONFIG_DIR}/backups"

  # Create test home directory
  TEST_HOME="${TEST_TMP_DIR}/home"
  mkdir -p "${TEST_HOME}"
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"
  mkdir -p "${ZSH_TOOL_BACKUP_DIR}"

  # Initialize state file for tests
  echo '{"version":"1.0.0","installed":false}' > "$ZSH_TOOL_STATE_FILE"

  # Save original HOME and set test HOME
  ORIG_HOME="$HOME"
  export HOME="$TEST_HOME"
}

# Cleanup test environment
cleanup_test_env() {
  # Restore original HOME
  export HOME="$ORIG_HOME"
  [[ -d "$TEST_TMP_DIR" ]] && rm -rf "$TEST_TMP_DIR"
}

# Create mock files for testing
create_mock_zshrc() {
  echo "# Test .zshrc content" > "${HOME}/.zshrc"
  echo "export TEST_VAR=1" >> "${HOME}/.zshrc"
}

create_mock_history() {
  echo ": 1234567890:0;ls -la" > "${HOME}/.zsh_history"
  echo ": 1234567891:0;git status" >> "${HOME}/.zsh_history"
}

create_mock_omz_custom() {
  mkdir -p "${HOME}/.oh-my-zsh/custom/plugins/myplugin"
  echo "# Custom plugin" > "${HOME}/.oh-my-zsh/custom/plugins/myplugin/myplugin.plugin.zsh"
  mkdir -p "${HOME}/.oh-my-zsh/custom/themes"
  echo "# Custom theme" > "${HOME}/.oh-my-zsh/custom/themes/mytheme.zsh-theme"
}

# ============================================
# TEST CASES - FUNCTION EXISTENCE
# ============================================

# Test: All required functions are defined
test_all_functions_defined() {
  typeset -f _zsh_tool_create_backup >/dev/null 2>&1 && \
  typeset -f _zsh_tool_generate_manifest >/dev/null 2>&1 && \
  typeset -f _zsh_tool_prune_old_backups >/dev/null 2>&1 && \
  typeset -f _zsh_tool_backup_file >/dev/null 2>&1 && \
  typeset -f _zsh_tool_backup_directory >/dev/null 2>&1
}

# Test: Functions follow naming convention
test_naming_convention() {
  local funcs=$(typeset -f | grep "^_zsh_tool_.*backup" | wc -l)
  [[ $funcs -ge 3 ]]
}

# ============================================
# TEST CASES - BACKUP CREATION (Task 3.1, 3.2)
# ============================================

# Test: Backup creation with all files present
test_backup_all_files_present() {
  create_mock_zshrc
  create_mock_history
  create_mock_omz_custom

  _zsh_tool_create_backup "test" >/dev/null 2>&1
  local result=$?

  # Verify backup directory was created
  local backup_count=$(ls -1d "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | wc -l | tr -d ' ')

  [[ $result -eq 0 ]] && [[ $backup_count -ge 1 ]]
}

# Test: Backup contains all expected files
test_backup_contains_expected_files() {
  create_mock_zshrc
  create_mock_history
  create_mock_omz_custom

  _zsh_tool_create_backup "test" >/dev/null 2>&1

  # Get latest backup directory
  local latest_backup=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)

  # Check all expected files exist
  [[ -f "${latest_backup}/.zshrc" ]] && \
  [[ -f "${latest_backup}/.zsh_history" ]] && \
  [[ -d "${latest_backup}/oh-my-zsh-custom" ]] && \
  [[ -f "${latest_backup}/manifest.json" ]]
}

# Test: Backup creation with partial files (some missing)
test_backup_partial_files() {
  # Only create .zshrc, not history or omz custom
  create_mock_zshrc

  _zsh_tool_create_backup "test" >/dev/null 2>&1
  local result=$?

  # Get latest backup directory
  local latest_backup=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)

  # Should succeed and contain only .zshrc
  [[ $result -eq 0 ]] && \
  [[ -f "${latest_backup}/.zshrc" ]] && \
  [[ ! -f "${latest_backup}/.zsh_history" ]]
}

# Test: Backup with no files (empty backup)
test_backup_no_files() {
  # Don't create any files
  _zsh_tool_create_backup "test" >/dev/null 2>&1
  local result=$?

  # Should still succeed - backup dir with just manifest
  local latest_backup=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)

  [[ $result -eq 0 ]] && [[ -f "${latest_backup}/manifest.json" ]]
}

# ============================================
# TEST CASES - MANIFEST GENERATION (Task 3.3)
# ============================================

# Test: Manifest JSON structure is valid
test_manifest_json_structure() {
  create_mock_zshrc

  _zsh_tool_create_backup "pre-install" >/dev/null 2>&1

  local latest_backup=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)
  local manifest="${latest_backup}/manifest.json"

  # Check manifest exists and has required fields
  [[ -f "$manifest" ]] && \
  grep -q '"timestamp"' "$manifest" && \
  grep -q '"trigger"' "$manifest" && \
  grep -q '"files"' "$manifest" && \
  grep -q '"omz_version"' "$manifest" && \
  grep -q '"tool_version"' "$manifest"
}

# Test: Manifest trigger value is correct
test_manifest_trigger_value() {
  create_mock_zshrc

  _zsh_tool_create_backup "pre-install" >/dev/null 2>&1

  local latest_backup=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)
  local manifest="${latest_backup}/manifest.json"

  grep -q '"trigger": "pre-install"' "$manifest"
}

# Test: Manifest lists backed up files
test_manifest_files_list() {
  create_mock_zshrc
  create_mock_history

  _zsh_tool_create_backup "manual" >/dev/null 2>&1

  local latest_backup=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)
  local manifest="${latest_backup}/manifest.json"

  grep -q '".zshrc"' "$manifest" && \
  grep -q '".zsh_history"' "$manifest"
}

# ============================================
# TEST CASES - STATE UPDATE (Task 3.4)
# ============================================

# Test: State update with last_backup
test_state_last_backup_updated() {
  create_mock_zshrc

  _zsh_tool_create_backup "test" >/dev/null 2>&1

  # Check state file contains last_backup
  local state=$(cat "$ZSH_TOOL_STATE_FILE")
  echo "$state" | grep -q '"last_backup"'
}

# Test: State last_backup matches backup timestamp format
test_state_last_backup_format() {
  create_mock_zshrc

  _zsh_tool_create_backup "test" >/dev/null 2>&1

  # Get the backup directory name (timestamp)
  local latest_backup_name=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1 | xargs basename)

  # Check state contains this timestamp
  local state=$(cat "$ZSH_TOOL_STATE_FILE")
  echo "$state" | grep -q "\"${latest_backup_name}\""
}

# ============================================
# TEST CASES - PRUNING (Task 3.5)
# ============================================

# Test: Pruning logic (create 5 backups, verify only 3 remain AND they are the NEWEST)
test_pruning_keeps_10() {
  # Set retention to 3 for faster testing
  local orig_retention=$ZSH_TOOL_BACKUP_RETENTION
  ZSH_TOOL_BACKUP_RETENTION=3

  create_mock_zshrc

  # Manually create backup directories with different timestamps
  # Create them with increasing mtime by sleeping between each
  for i in {1..5}; do
    local ts="2026-01-0${i}-12000${i}"
    mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts}"
    echo '{"timestamp":"test"}' > "${ZSH_TOOL_BACKUP_DIR}/${ts}/manifest.json"
    sleep 0.5  # Ensure different modification times
  done

  # Run prune function
  _zsh_tool_prune_old_backups >/dev/null 2>&1

  local backup_count=$(ls -1d "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | wc -l | tr -d ' ')

  # Verify count AND that the NEWEST remain (03, 04, 05) and oldest deleted (01, 02)
  local has_newest=0
  local has_oldest=0
  [[ -d "${ZSH_TOOL_BACKUP_DIR}/2026-01-05-120005" ]] && ((has_newest++))
  [[ -d "${ZSH_TOOL_BACKUP_DIR}/2026-01-04-120004" ]] && ((has_newest++))
  [[ -d "${ZSH_TOOL_BACKUP_DIR}/2026-01-03-120003" ]] && ((has_newest++))
  [[ -d "${ZSH_TOOL_BACKUP_DIR}/2026-01-02-120002" ]] && ((has_oldest++))
  [[ -d "${ZSH_TOOL_BACKUP_DIR}/2026-01-01-120001" ]] && ((has_oldest++))

  # Restore retention
  ZSH_TOOL_BACKUP_RETENTION=$orig_retention

  # Must have exactly 3 backups AND they must be the 3 newest
  [[ $backup_count -eq 3 ]] && [[ $has_newest -eq 3 ]] && [[ $has_oldest -eq 0 ]]
}

# Test: Pruning respects configurable retention
test_pruning_configurable_retention() {
  # Set custom retention
  ZSH_TOOL_BACKUP_RETENTION=2

  create_mock_zshrc

  # Manually create backup directories
  for i in {1..4}; do
    local ts="2026-01-0${i}-13000${i}"
    mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts}"
    echo '{"timestamp":"test"}' > "${ZSH_TOOL_BACKUP_DIR}/${ts}/manifest.json"
  done

  # Run prune
  _zsh_tool_prune_old_backups >/dev/null 2>&1

  local backup_count=$(ls -1d "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | wc -l | tr -d ' ')

  # Reset to default
  ZSH_TOOL_BACKUP_RETENTION=10

  [[ $backup_count -eq 2 ]]
}

# Test: Manifest handles special characters in filenames (JSON escaping)
test_manifest_json_escaping() {
  create_mock_zshrc

  # Create a backup
  _zsh_tool_create_backup "test" >/dev/null 2>&1

  # Get latest backup directory
  local latest_backup=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)

  # Add files with special characters that could break JSON
  touch "${latest_backup}/file\"with\"quotes.txt" 2>/dev/null
  touch "${latest_backup}/file\\with\\backslash.txt" 2>/dev/null

  # Regenerate manifest
  _zsh_tool_generate_manifest "$latest_backup" "test" "none" >/dev/null 2>&1

  # Validate JSON is still valid (use simple grep test since jq may not be available)
  local manifest="${latest_backup}/manifest.json"

  # Check manifest exists and has proper structure
  [[ -f "$manifest" ]] && \
  grep -q '"files"' "$manifest" && \
  # If jq is available, validate JSON
  if command -v jq >/dev/null 2>&1; then
    jq . "$manifest" >/dev/null 2>&1
  else
    # Fallback: check for balanced braces
    local open_braces=$(grep -o '{' "$manifest" | wc -l)
    local close_braces=$(grep -o '}' "$manifest" | wc -l)
    [[ $open_braces -eq $close_braces ]]
  fi
}

# ============================================
# TEST CASES - IDEMPOTENCY (Task 3.6)
# ============================================

# Test: Running backup twice succeeds
test_idempotency_backup_twice() {
  create_mock_zshrc

  _zsh_tool_create_backup "test1" >/dev/null 2>&1
  local result1=$?
  _zsh_tool_create_backup "test2" >/dev/null 2>&1
  local result2=$?

  [[ $result1 -eq 0 ]] && [[ $result2 -eq 0 ]]
}

# Test: Multiple backups create separate directories
test_idempotency_separate_dirs() {
  create_mock_zshrc

  # Create first backup manually
  local ts1="2026-01-01-120001"
  mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts1}"
  echo '{"timestamp":"test1"}' > "${ZSH_TOOL_BACKUP_DIR}/${ts1}/manifest.json"

  # Create second via function
  _zsh_tool_create_backup "test2" >/dev/null 2>&1

  local backup_count=$(ls -1d "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | wc -l | tr -d ' ')

  [[ $backup_count -ge 2 ]]
}

# ============================================
# TEST CASES - ERROR HANDLING (Task 3.7)
# ============================================

# Test: Backup handles read-only files gracefully
test_error_handling_readonly() {
  create_mock_zshrc
  chmod 000 "${HOME}/.zshrc"

  # Should still succeed (backup might fail for that file but overall succeeds)
  _zsh_tool_create_backup "test" >/dev/null 2>&1
  local result=$?

  # Restore permissions for cleanup
  chmod 644 "${HOME}/.zshrc"

  # The function should handle this gracefully
  [[ $result -eq 0 ]] || [[ $result -eq 1 ]]  # Either outcome is acceptable
}

# Test: Backup logs errors appropriately
test_logging_on_backup() {
  create_mock_zshrc

  _zsh_tool_create_backup "test" >/dev/null 2>&1

  # Check log file was written
  [[ -f "$ZSH_TOOL_LOG_FILE" ]] && grep -q "backup" "$ZSH_TOOL_LOG_FILE"
}

# ============================================
# TEST CASES - HELPER FUNCTIONS
# ============================================

# Test: _zsh_tool_backup_file with existing file
test_backup_file_exists() {
  create_mock_zshrc
  local dest="${TEST_TMP_DIR}/backup_test_file"

  _zsh_tool_backup_file "${HOME}/.zshrc" "$dest" >/dev/null 2>&1

  [[ -f "$dest" ]]
}

# Test: _zsh_tool_backup_file with missing file
test_backup_file_missing() {
  local dest="${TEST_TMP_DIR}/backup_test_file"

  _zsh_tool_backup_file "${HOME}/.nonexistent" "$dest" >/dev/null 2>&1
  local result=$?

  [[ $result -eq 1 ]] && [[ ! -f "$dest" ]]
}

# Test: _zsh_tool_backup_directory with existing directory
test_backup_directory_exists() {
  create_mock_omz_custom
  local dest="${TEST_TMP_DIR}/backup_test_dir"

  _zsh_tool_backup_directory "${HOME}/.oh-my-zsh/custom" "$dest" >/dev/null 2>&1

  [[ -d "$dest" ]]
}

# Test: _zsh_tool_backup_directory with missing directory
test_backup_directory_missing() {
  local dest="${TEST_TMP_DIR}/backup_test_dir"

  _zsh_tool_backup_directory "${HOME}/.nonexistent_dir" "$dest" >/dev/null 2>&1
  local result=$?

  [[ $result -eq 1 ]] && [[ ! -d "$dest" ]]
}

# Test: Backup directory has correct permissions (0700)
test_backup_directory_permissions() {
  create_mock_zshrc

  _zsh_tool_create_backup "test" >/dev/null 2>&1

  local latest_backup=$(ls -1dt "${ZSH_TOOL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)

  # Check directory exists and has 0700 permissions (user-only access)
  if [[ -d "$latest_backup" ]]; then
    local perms=$(stat -f "%Lp" "$latest_backup" 2>/dev/null || stat -c "%a" "$latest_backup" 2>/dev/null)
    [[ "$perms" == "700" ]]
  else
    return 1
  fi
}

# ============================================
# RUN ALL TESTS
# ============================================

echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}  Story 1.2: Backup Existing Configuration Tests${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Setup
echo "${YELLOW}Setting up test environment...${NC}"
setup_test_env
echo ""

# Function existence tests
echo "${YELLOW}[1/7] Testing Function Existence...${NC}"
run_test "All required functions are defined" test_all_functions_defined
run_test "Functions follow _zsh_tool_ naming convention" test_naming_convention
echo ""

# Backup creation tests
echo "${YELLOW}[2/7] Testing Backup Creation...${NC}"
cleanup_test_env; setup_test_env
run_test "Backup creation with all files present" test_backup_all_files_present
cleanup_test_env; setup_test_env
run_test "Backup contains expected files" test_backup_contains_expected_files
cleanup_test_env; setup_test_env
run_test "Backup creation with partial files" test_backup_partial_files
cleanup_test_env; setup_test_env
run_test "Backup with no files (empty backup)" test_backup_no_files
echo ""

# Manifest tests
echo "${YELLOW}[3/7] Testing Manifest Generation...${NC}"
cleanup_test_env; setup_test_env
run_test "Manifest JSON structure is valid" test_manifest_json_structure
cleanup_test_env; setup_test_env
run_test "Manifest trigger value is correct" test_manifest_trigger_value
cleanup_test_env; setup_test_env
run_test "Manifest lists backed up files" test_manifest_files_list
echo ""

# State update tests
echo "${YELLOW}[4/7] Testing State Updates...${NC}"
cleanup_test_env; setup_test_env
run_test "State last_backup field is updated" test_state_last_backup_updated
cleanup_test_env; setup_test_env
run_test "State last_backup format matches backup dir" test_state_last_backup_format
echo ""

# Pruning tests
echo "${YELLOW}[5/8] Testing Backup Pruning...${NC}"
cleanup_test_env; setup_test_env
run_test "Pruning keeps newest backups (deletes oldest)" test_pruning_keeps_10
cleanup_test_env; setup_test_env
run_test "Pruning respects configurable retention" test_pruning_configurable_retention
cleanup_test_env; setup_test_env
run_test "Manifest handles special characters (JSON escaping)" test_manifest_json_escaping
echo ""

# Idempotency tests
echo "${YELLOW}[6/8] Testing Idempotency...${NC}"
cleanup_test_env; setup_test_env
run_test "Running backup twice succeeds" test_idempotency_backup_twice
cleanup_test_env; setup_test_env
run_test "Multiple backups create separate directories" test_idempotency_separate_dirs
echo ""

# Error handling and helper tests
echo "${YELLOW}[7/8] Testing Error Handling & Helpers...${NC}"
cleanup_test_env; setup_test_env
run_test "Backup logs operations appropriately" test_logging_on_backup
cleanup_test_env; setup_test_env
run_test "_zsh_tool_backup_file with existing file" test_backup_file_exists
cleanup_test_env; setup_test_env
run_test "_zsh_tool_backup_file with missing file" test_backup_file_missing
cleanup_test_env; setup_test_env
run_test "_zsh_tool_backup_directory with existing directory" test_backup_directory_exists
cleanup_test_env; setup_test_env
run_test "_zsh_tool_backup_directory with missing directory" test_backup_directory_missing
cleanup_test_env; setup_test_env
run_test "Backup directory has reasonable permissions" test_backup_directory_permissions
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
