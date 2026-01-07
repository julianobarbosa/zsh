#!/usr/bin/env zsh
# Story 2.4: Configuration Restore from Backup Tests
# Tests for lib/restore/restore.zsh

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
  echo "${GREEN}  [PASS] $1${NC}"
}

test_fail() {
  ((TESTS_FAILED++))
  echo "${RED}  [FAIL] $1${NC}"
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
  source "${PROJECT_ROOT}/lib/restore/backup-mgmt.zsh"
  source "${PROJECT_ROOT}/lib/restore/restore.zsh"

  # Override config directory AFTER sourcing (utils.zsh sets defaults)
  TEST_TMP_DIR=$(mktemp -d)
  ZSH_TOOL_CONFIG_DIR="${TEST_TMP_DIR}/config"
  ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/zsh-tool.log"
  ZSH_TOOL_STATE_FILE="${ZSH_TOOL_CONFIG_DIR}/state.json"
  ZSH_TOOL_BACKUP_DIR="${ZSH_TOOL_CONFIG_DIR}/backups"
  ZSH_TOOL_BACKUP_RETENTION=10

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

create_mock_zshrc_local() {
  echo "# Test .zshrc.local content" > "${HOME}/.zshrc.local"
  echo "alias test='echo test'" >> "${HOME}/.zshrc.local"
}

# Create mock backups with proper content
create_mock_backups() {
  local count=${1:-3}
  for i in $(seq 1 $count); do
    local ts="2026-01-0${i}-12000${i}"
    mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts}"
    cat > "${ZSH_TOOL_BACKUP_DIR}/${ts}/manifest.json" <<EOF
{
  "timestamp": "2026-01-0${i}T12:00:0${i}Z",
  "trigger": "test-${i}",
  "files": [".zshrc", ".zsh_history"],
  "omz_version": "none",
  "tool_version": "1.0.0"
}
EOF
    echo "# Mock .zshrc backup ${i}" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/.zshrc"
    echo "# Mock .zsh_history backup ${i}" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/.zsh_history"
    sleep 0.1  # Ensure different modification times
  done
}

# Create a detailed backup for restore testing
create_detailed_backup() {
  local ts="2026-01-05-120000"
  mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts}"
  mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts}/oh-my-zsh-custom/plugins/testplugin"

  cat > "${ZSH_TOOL_BACKUP_DIR}/${ts}/manifest.json" <<EOF
{
  "timestamp": "2026-01-05T12:00:00Z",
  "trigger": "detailed-test",
  "files": [".zshrc", ".zsh_history", "oh-my-zsh-custom", ".zshrc.local"],
  "omz_version": "none",
  "tool_version": "1.0.0"
}
EOF
  echo "# Backup .zshrc content for restore" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/.zshrc"
  echo ": 9999999999:0;backup command" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/.zsh_history"
  echo "# Backup plugin" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/oh-my-zsh-custom/plugins/testplugin/testplugin.plugin.zsh"
  echo "# Backup .zshrc.local" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/.zshrc.local"

  echo "${ts}"
}

# ============================================
# TEST CASES - FUNCTION EXISTENCE
# ============================================

# Test: All required functions are defined
test_all_functions_defined() {
  typeset -f _zsh_tool_parse_manifest >/dev/null 2>&1 && \
  typeset -f _zsh_tool_display_backup_contents >/dev/null 2>&1 && \
  typeset -f _zsh_tool_restore_file >/dev/null 2>&1 && \
  typeset -f _zsh_tool_verify_restore >/dev/null 2>&1 && \
  typeset -f _zsh_tool_rollback_restore >/dev/null 2>&1 && \
  typeset -f _zsh_tool_restore_from_backup >/dev/null 2>&1
}

# Test: Functions follow naming convention
test_naming_convention() {
  local funcs=$(typeset -f | grep "^_zsh_tool_.*restore\|^_zsh_tool_.*manifest" | wc -l)
  [[ $funcs -ge 4 ]]
}

# ============================================
# TEST CASES - RESTORE LIST (AC1)
# ============================================

# Test: Restore list shows available backups
test_restore_list_shows_backups() {
  create_mock_backups 3

  local output=$(_zsh_tool_list_backups 2>&1)
  local result=$?

  [[ $result -eq 0 ]] && \
  echo "$output" | grep -q "Available backups"
}

# Test: Restore list with no backups shows message
test_restore_list_empty() {
  # Clear all backups
  setopt local_options null_glob
  for f in "${ZSH_TOOL_BACKUP_DIR}"/*; do
    [[ -e "$f" ]] && rm -rf "$f"
  done

  local output
  output=$(_zsh_tool_list_backups 2>&1)
  local result=$?

  if [[ $result -eq 1 ]] && echo "$output" | grep -q "No backups"; then
    return 0
  else
    return 1
  fi
}

# ============================================
# TEST CASES - RESTORE APPLY (AC2)
# ============================================

# Test: Restore from valid backup restores files
test_restore_apply_restores_files() {
  # Create current state
  create_mock_zshrc
  local original_content=$(cat "${HOME}/.zshrc")

  # Create backup to restore from
  local backup_ts=$(create_detailed_backup)

  # Create pre-restore backup manually to satisfy the function
  mkdir -p "${ZSH_TOOL_BACKUP_DIR}/pre-restore-test"
  cp "${HOME}/.zshrc" "${ZSH_TOOL_BACKUP_DIR}/pre-restore-test/" 2>/dev/null || true

  # Run restore with force flag (non-interactive)
  _zsh_tool_restore_from_backup "$backup_ts" --force >/dev/null 2>&1
  local result=$?

  # Verify .zshrc was restored with backup content
  local restored_content=$(cat "${HOME}/.zshrc" 2>/dev/null)
  [[ "$result" -eq 0 ]] && \
  [[ "$restored_content" == "# Backup .zshrc content for restore" ]]
}

# Test: Restore by backup number
test_restore_by_number() {
  create_mock_zshrc
  create_mock_backups 3

  # Backup #1 should be the most recent (2026-01-03-120003)
  local output
  output=$(_zsh_tool_restore_from_backup "1" --force 2>&1)
  local result=$?

  # Check that it succeeded or found the backup
  [[ $result -eq 0 ]] || echo "$output" | grep -qi "restoring"
}

# ============================================
# TEST CASES - MANIFEST DISPLAY (AC3)
# ============================================

# Test: Display backup contents shows files
test_display_backup_contents() {
  local backup_ts=$(create_detailed_backup)
  local backup_path="${ZSH_TOOL_BACKUP_DIR}/${backup_ts}"

  local output=$(_zsh_tool_display_backup_contents "$backup_path" 2>&1)

  echo "$output" | grep -q ".zshrc" && \
  echo "$output" | grep -q ".zsh_history"
}

# Test: Parse manifest returns content
test_parse_manifest() {
  local backup_ts=$(create_detailed_backup)
  local backup_path="${ZSH_TOOL_BACKUP_DIR}/${backup_ts}"

  local manifest=$(_zsh_tool_parse_manifest "$backup_path" 2>&1)

  echo "$manifest" | grep -q "timestamp" && \
  echo "$manifest" | grep -q "trigger"
}

# Test: Parse manifest fails for missing manifest
test_parse_manifest_missing() {
  mkdir -p "${ZSH_TOOL_BACKUP_DIR}/no-manifest"

  _zsh_tool_parse_manifest "${ZSH_TOOL_BACKUP_DIR}/no-manifest" 2>&1
  local result=$?

  [[ $result -eq 1 ]]
}

# ============================================
# TEST CASES - PRE-RESTORE BACKUP (AC4)
# ============================================

# Test: Pre-restore backup is created
test_pre_restore_backup_created() {
  create_mock_zshrc
  local backup_ts=$(create_detailed_backup)

  local backup_count_before=$(_zsh_tool_get_backup_count)

  # Run restore (will create pre-restore backup)
  _zsh_tool_restore_from_backup "$backup_ts" --force >/dev/null 2>&1

  local backup_count_after=$(_zsh_tool_get_backup_count)

  # Should have created a new backup (pre-restore)
  [[ $backup_count_after -gt $backup_count_before ]]
}

# ============================================
# TEST CASES - ATOMIC FILE OPERATIONS (AC5)
# ============================================

# Test: Atomic file restore succeeds
test_restore_file_atomic() {
  create_mock_zshrc
  local backup_ts=$(create_detailed_backup)

  # Test atomic restore of a single file
  _zsh_tool_restore_file "${ZSH_TOOL_BACKUP_DIR}/${backup_ts}/.zshrc" "${HOME}/.zshrc.test" >/dev/null 2>&1
  local result=$?

  [[ $result -eq 0 ]] && [[ -f "${HOME}/.zshrc.test" ]]
}

# Test: Atomic restore leaves no temp files on success
test_restore_file_no_temp_on_success() {
  create_mock_zshrc
  local backup_ts=$(create_detailed_backup)

  _zsh_tool_restore_file "${ZSH_TOOL_BACKUP_DIR}/${backup_ts}/.zshrc" "${HOME}/.zshrc.test" >/dev/null 2>&1

  # Check no temp files left
  local temp_files=$(ls -la "${HOME}/.zshrc.test.tmp"* 2>/dev/null | wc -l)
  [[ $temp_files -eq 0 ]]
}

# Test: Restore file fails gracefully for missing source
test_restore_file_missing_source() {
  _zsh_tool_restore_file "/nonexistent/file" "${HOME}/.test" 2>&1
  local result=$?

  [[ $result -eq 1 ]]
}

# ============================================
# TEST CASES - STATE TRACKING (AC6)
# ============================================

# Test: State updated after restore
test_restore_updates_state() {
  create_mock_zshrc
  local backup_ts=$(create_detailed_backup)

  _zsh_tool_restore_from_backup "$backup_ts" --force >/dev/null 2>&1

  local state=$(cat "$ZSH_TOOL_STATE_FILE")
  echo "$state" | grep -q "last_restore" && \
  echo "$state" | grep -q "from_backup"
}

# Test: State contains files_restored array
test_restore_state_files_restored() {
  create_mock_zshrc
  local backup_ts=$(create_detailed_backup)

  _zsh_tool_restore_from_backup "$backup_ts" --force >/dev/null 2>&1

  local state=$(cat "$ZSH_TOOL_STATE_FILE")
  echo "$state" | grep -q "files_restored"
}

# ============================================
# TEST CASES - FORCE FLAG (AC7)
# ============================================

# Test: Force flag skips confirmation
test_force_flag_skips_confirmation() {
  create_mock_zshrc
  local backup_ts=$(create_detailed_backup)

  # With --force, it should not prompt and should succeed
  local output
  output=$(_zsh_tool_restore_from_backup "$backup_ts" --force 2>&1)
  local result=$?

  [[ $result -eq 0 ]] && echo "$output" | grep -q "Force mode enabled"
}

# Test: Short force flag works
test_short_force_flag() {
  create_mock_zshrc
  local backup_ts=$(create_detailed_backup)

  local output
  output=$(_zsh_tool_restore_from_backup "$backup_ts" -f 2>&1)
  local result=$?

  [[ $result -eq 0 ]] && echo "$output" | grep -q "Force mode enabled"
}

# ============================================
# TEST CASES - BACKUP NOT FOUND (AC9)
# ============================================

# Test: Invalid backup ID shows error and list
test_invalid_backup_shows_error() {
  create_mock_backups 2

  local output
  output=$(_zsh_tool_restore_from_backup "nonexistent-backup" --force 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "not found" && \
  echo "$output" | grep -qi "available"
}

# Test: Invalid backup number shows error
test_invalid_backup_number() {
  create_mock_backups 2

  local output
  output=$(_zsh_tool_restore_from_backup "99" --force 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "invalid\|not found"
}

# ============================================
# TEST CASES - ROLLBACK (AC10)
# ============================================

# Test: Rollback function exists and is callable
test_rollback_function_exists() {
  typeset -f _zsh_tool_rollback_restore >/dev/null 2>&1
}

# Test: Rollback fails gracefully without pre-restore backup
test_rollback_no_backup() {
  local output
  output=$(_zsh_tool_rollback_restore "" 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && echo "$output" | grep -qi "cannot rollback"
}

# Test: Rollback restores from pre-restore backup
test_rollback_restores_files() {
  # Create initial state
  echo "# Original content" > "${HOME}/.zshrc"

  # Create a "pre-restore" backup
  local pre_restore_path="${ZSH_TOOL_BACKUP_DIR}/pre-restore-test"
  mkdir -p "$pre_restore_path"
  echo "# Original content" > "${pre_restore_path}/.zshrc"

  # Modify the file (simulating a failed restore)
  echo "# Modified content" > "${HOME}/.zshrc"

  # Run rollback
  _zsh_tool_rollback_restore "$pre_restore_path" >/dev/null 2>&1

  # Verify original content restored
  local restored_content=$(cat "${HOME}/.zshrc")
  [[ "$restored_content" == "# Original content" ]]
}

# ============================================
# TEST CASES - PERMISSION ERRORS (AC12)
# ============================================

# Test: Permission error handling message
test_permission_error_message() {
  # Create a read-only directory that will fail
  local readonly_dir="${TEST_TMP_DIR}/readonly"
  mkdir -p "$readonly_dir"
  chmod 000 "$readonly_dir"

  local output
  output=$(_zsh_tool_restore_file "${HOME}/.zshrc" "${readonly_dir}/test.zshrc" 2>&1)
  local result=$?

  chmod 755 "$readonly_dir"  # Cleanup

  # Should return error code 2 for permission errors or 1 for general errors
  [[ $result -ne 0 ]]
}

# ============================================
# TEST CASES - VERIFY RESTORE
# ============================================

# Test: Verify restore passes when files exist
test_verify_restore_passes() {
  local backup_ts=$(create_detailed_backup)
  local backup_path="${ZSH_TOOL_BACKUP_DIR}/${backup_ts}"

  # Create the files that should exist after restore
  echo "# Restored" > "${HOME}/.zshrc"
  echo "# Restored" > "${HOME}/.zsh_history"

  _zsh_tool_verify_restore "$backup_path" >/dev/null 2>&1
  local result=$?

  [[ $result -eq 0 ]]
}

# Test: Verify restore warns when files missing
test_verify_restore_warns() {
  local backup_ts=$(create_detailed_backup)
  local backup_path="${ZSH_TOOL_BACKUP_DIR}/${backup_ts}"

  # Remove files that should exist
  rm -f "${HOME}/.zshrc" "${HOME}/.zsh_history"

  local output
  output=$(_zsh_tool_verify_restore "$backup_path" 2>&1)
  local result=$?

  [[ $result -eq 1 ]]
}

# ============================================
# TEST CASES - USAGE AND HELP
# ============================================

# Test: No backup ID shows usage
test_no_backup_id_shows_usage() {
  local output
  output=$(_zsh_tool_restore_from_backup 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -q "Usage"
}

# ============================================
# RUN ALL TESTS
# ============================================

echo ""
echo "${BLUE}=====================================================${NC}"
echo "${BLUE}  Story 2.4: Configuration Restore from Backup Tests${NC}"
echo "${BLUE}=====================================================${NC}"
echo ""

# Setup
echo "${YELLOW}Setting up test environment...${NC}"
setup_test_env
echo ""

# Function existence tests
echo "${YELLOW}[1/12] Testing Function Existence...${NC}"
run_test "All required functions are defined" test_all_functions_defined
run_test "Functions follow _zsh_tool_ naming convention" test_naming_convention
echo ""

# Restore list tests (AC1)
echo "${YELLOW}[2/12] Testing Restore List (AC1)...${NC}"
cleanup_test_env; setup_test_env
run_test "Restore list shows available backups" test_restore_list_shows_backups
cleanup_test_env; setup_test_env
run_test "Restore list with no backups shows message" test_restore_list_empty
echo ""

# Restore apply tests (AC2)
echo "${YELLOW}[3/12] Testing Restore Apply (AC2)...${NC}"
cleanup_test_env; setup_test_env
run_test "Restore from valid backup restores files" test_restore_apply_restores_files
cleanup_test_env; setup_test_env
run_test "Restore by backup number" test_restore_by_number
echo ""

# Manifest display tests (AC3)
echo "${YELLOW}[4/12] Testing Manifest Display (AC3)...${NC}"
cleanup_test_env; setup_test_env
run_test "Display backup contents shows files" test_display_backup_contents
cleanup_test_env; setup_test_env
run_test "Parse manifest returns content" test_parse_manifest
cleanup_test_env; setup_test_env
run_test "Parse manifest fails for missing manifest" test_parse_manifest_missing
echo ""

# Pre-restore backup tests (AC4)
echo "${YELLOW}[5/12] Testing Pre-Restore Backup (AC4)...${NC}"
cleanup_test_env; setup_test_env
run_test "Pre-restore backup is created" test_pre_restore_backup_created
echo ""

# Atomic file operations tests (AC5)
echo "${YELLOW}[6/12] Testing Atomic File Operations (AC5)...${NC}"
cleanup_test_env; setup_test_env
run_test "Atomic file restore succeeds" test_restore_file_atomic
cleanup_test_env; setup_test_env
run_test "No temp files left on success" test_restore_file_no_temp_on_success
cleanup_test_env; setup_test_env
run_test "Restore file fails gracefully for missing source" test_restore_file_missing_source
echo ""

# State tracking tests (AC6)
echo "${YELLOW}[7/12] Testing State Tracking (AC6)...${NC}"
cleanup_test_env; setup_test_env
run_test "State updated after restore" test_restore_updates_state
cleanup_test_env; setup_test_env
run_test "State contains files_restored array" test_restore_state_files_restored
echo ""

# Force flag tests (AC7)
echo "${YELLOW}[8/12] Testing Force Flag (AC7)...${NC}"
cleanup_test_env; setup_test_env
run_test "Force flag skips confirmation" test_force_flag_skips_confirmation
cleanup_test_env; setup_test_env
run_test "Short force flag (-f) works" test_short_force_flag
echo ""

# Backup not found tests (AC9)
echo "${YELLOW}[9/12] Testing Backup Not Found (AC9)...${NC}"
cleanup_test_env; setup_test_env
run_test "Invalid backup ID shows error and list" test_invalid_backup_shows_error
cleanup_test_env; setup_test_env
run_test "Invalid backup number shows error" test_invalid_backup_number
echo ""

# Rollback tests (AC10)
echo "${YELLOW}[10/12] Testing Rollback (AC10)...${NC}"
cleanup_test_env; setup_test_env
run_test "Rollback function exists" test_rollback_function_exists
cleanup_test_env; setup_test_env
run_test "Rollback fails gracefully without pre-restore backup" test_rollback_no_backup
cleanup_test_env; setup_test_env
run_test "Rollback restores files from pre-restore backup" test_rollback_restores_files
echo ""

# Permission error tests (AC12)
echo "${YELLOW}[11/12] Testing Permission Errors (AC12)...${NC}"
cleanup_test_env; setup_test_env
run_test "Permission error handling" test_permission_error_message
echo ""

# Verification and usage tests
echo "${YELLOW}[12/12] Testing Verification and Usage...${NC}"
cleanup_test_env; setup_test_env
run_test "Verify restore passes when files exist" test_verify_restore_passes
cleanup_test_env; setup_test_env
run_test "Verify restore warns when files missing" test_verify_restore_warns
cleanup_test_env; setup_test_env
run_test "No backup ID shows usage" test_no_backup_id_shows_usage
echo ""

# Cleanup
cleanup_test_env

# Results
echo "${BLUE}=====================================================${NC}"
echo "${BLUE}  Test Results${NC}"
echo "${BLUE}=====================================================${NC}"
echo ""
echo "Total Tests: $TESTS_RUN"
echo "${GREEN}Passed: $TESTS_PASSED${NC}"
echo "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${GREEN}All tests passed!${NC}"
  echo ""
  exit 0
else
  echo "${RED}Some tests failed${NC}"
  echo ""
  exit 1
fi
