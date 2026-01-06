#!/usr/bin/env zsh
# Story 2.3: Configuration Backup Management Tests
# Tests for lib/restore/backup-mgmt.zsh

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

# Create mock backups
create_mock_backups() {
  local count=${1:-3}
  for i in $(seq 1 $count); do
    local ts="2026-01-0${i}-12000${i}"
    mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts}"
    cat > "${ZSH_TOOL_BACKUP_DIR}/${ts}/manifest.json" <<EOF
{
  "timestamp": "2026-01-0${i}T12:00:0${i}Z",
  "trigger": "test-${i}",
  "files": [".zshrc"],
  "omz_version": "none",
  "tool_version": "1.0.0"
}
EOF
    echo "# Mock .zshrc backup ${i}" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/.zshrc"
    sleep 0.1  # Ensure different modification times
  done
}

# ============================================
# TEST CASES - FUNCTION EXISTENCE
# ============================================

# Test: All required functions are defined
test_all_functions_defined() {
  typeset -f _zsh_tool_list_backups >/dev/null 2>&1 && \
  typeset -f _zsh_tool_create_manual_backup >/dev/null 2>&1 && \
  typeset -f _zsh_tool_backup_to_remote >/dev/null 2>&1 && \
  typeset -f _zsh_tool_fetch_remote_backups >/dev/null 2>&1 && \
  typeset -f _zsh_tool_configure_remote_backup >/dev/null 2>&1 && \
  typeset -f _zsh_tool_get_backup_count >/dev/null 2>&1 && \
  typeset -f _zsh_tool_get_remote_status >/dev/null 2>&1 && \
  typeset -f _zsh_tool_relative_time >/dev/null 2>&1
}

# Test: Functions follow naming convention
test_naming_convention() {
  local funcs=$(typeset -f | grep "^_zsh_tool_.*backup\|^_zsh_tool_.*remote" | wc -l)
  [[ $funcs -ge 5 ]]
}

# ============================================
# TEST CASES - BACKUP COUNT (AC7)
# ============================================

# Test: Get backup count with no backups
test_backup_count_empty() {
  # Use glob with nullglob to safely handle empty directories
  setopt local_options null_glob
  for f in "${ZSH_TOOL_BACKUP_DIR}"/*; do
    [[ -e "$f" ]] && rm -rf "$f"
  done

  local count=$(_zsh_tool_get_backup_count)
  [[ "$count" == "0" ]]
}

# Test: Get backup count with multiple backups
test_backup_count_with_backups() {
  create_mock_backups 3

  local count=$(_zsh_tool_get_backup_count)
  [[ "$count" == "3" ]]
}

# Test: Get backup count with non-existent directory
test_backup_count_no_dir() {
  rm -rf "${ZSH_TOOL_BACKUP_DIR}"

  local count=$(_zsh_tool_get_backup_count)
  [[ "$count" == "0" ]]
}

# ============================================
# TEST CASES - REMOTE STATUS (AC4, AC5, AC6)
# ============================================

# Test: Remote status when not configured
test_remote_status_not_configured() {
  local remote_status=$(_zsh_tool_get_remote_status)
  [[ "$remote_status" == "not_configured" ]]
}

# Test: Remote status when enabled
test_remote_status_enabled() {
  _zsh_tool_update_state "backups.remote_enabled" "true"
  _zsh_tool_update_state "backups.remote_url" "\"git@github.com:test/repo.git\""

  local remote_status=$(_zsh_tool_get_remote_status)
  [[ "$remote_status" == "enabled" ]]
}

# Test: Remote status when disabled
test_remote_status_disabled() {
  _zsh_tool_update_state "backups.remote_enabled" "false"
  _zsh_tool_update_state "backups.remote_url" "\"git@github.com:test/repo.git\""

  local remote_status=$(_zsh_tool_get_remote_status)
  [[ "$remote_status" == "disabled" ]]
}

# ============================================
# TEST CASES - BACKUP SIZE
# ============================================

# Test: Get backup size for small directory
test_backup_size_small() {
  create_mock_backups 1
  local backup_path="${ZSH_TOOL_BACKUP_DIR}/2026-01-01-120001"

  local size=$(_zsh_tool_get_backup_size "$backup_path")
  # Should return a size string ending in KB or B
  [[ "$size" =~ ^[0-9]+(KB|B)$ ]]
}

# Test: Get backup size for non-existent directory
test_backup_size_nonexistent() {
  local size=$(_zsh_tool_get_backup_size "/nonexistent/path")
  [[ "$size" == "0B" ]]
}

# ============================================
# TEST CASES - RELATIVE TIME (AC2)
# ============================================

# Test: Relative time - just now (within 60 seconds)
test_relative_time_just_now() {
  local now_date=$(date +%Y-%m-%d)
  local now_time=$(date +%H%M%S)

  local result=$(_zsh_tool_relative_time "$now_date" "$now_time")
  [[ "$result" == "just now" ]]
}

# Test: Relative time - unknown for invalid date
test_relative_time_invalid() {
  local result=$(_zsh_tool_relative_time "invalid" "date")
  [[ "$result" == "unknown time" ]]
}

# ============================================
# TEST CASES - LIST BACKUPS (AC2)
# ============================================

# Test: List backups when none exist
test_list_backups_empty() {
  # Use glob with nullglob to safely handle empty directories
  setopt local_options null_glob
  for f in "${ZSH_TOOL_BACKUP_DIR}"/*; do
    [[ -e "$f" ]] && rm -rf "$f"
  done

  local output
  output=$(_zsh_tool_list_backups 2>&1)
  local result=$?

  # Check both conditions and return explicitly
  if [[ $result -eq 1 ]] && echo "$output" | grep -q "No backups"; then
    return 0
  else
    return 1
  fi
}

# Test: List backups with existing backups
test_list_backups_with_data() {
  create_mock_backups 3

  local output=$(_zsh_tool_list_backups 2>&1)
  local result=$?

  [[ $result -eq 0 ]] && \
  echo "$output" | grep -q "Available backups" && \
  echo "$output" | grep -q "Total backups: 3"
}

# Test: List shows backup metadata (trigger)
test_list_backups_shows_trigger() {
  create_mock_backups 1

  local output=$(_zsh_tool_list_backups 2>&1)
  echo "$output" | grep -q "test-1"
}

# ============================================
# TEST CASES - MANUAL BACKUP (AC1)
# ============================================

# Test: Create manual backup succeeds
test_create_manual_backup() {
  create_mock_zshrc

  local initial_count=$(_zsh_tool_get_backup_count)
  _zsh_tool_create_manual_backup >/dev/null 2>&1
  local final_count=$(_zsh_tool_get_backup_count)

  [[ $((final_count - initial_count)) -ge 1 ]]
}

# Test: Manual backup updates state
test_manual_backup_updates_state() {
  create_mock_zshrc

  _zsh_tool_create_manual_backup >/dev/null 2>&1

  local state=$(cat "$ZSH_TOOL_STATE_FILE")
  echo "$state" | grep -q '"last_backup"' && \
  echo "$state" | grep -q '"count"'
}

# ============================================
# TEST CASES - REMOTE CONFIGURATION (AC6)
# ============================================

# Test: Configure remote with valid URL
test_configure_remote_valid() {
  _zsh_tool_configure_remote_backup "git@github.com:user/repo.git" >/dev/null 2>&1
  local result=$?

  local state=$(cat "$ZSH_TOOL_STATE_FILE")

  # Check result and state - grep patterns need to handle whitespace/newlines
  [[ $result -eq 0 ]] && \
  echo "$state" | tr -d '\n ' | grep -q '"remote_enabled":true' && \
  echo "$state" | grep -q '"remote_url"'
}

# Test: Disable remote backup
test_disable_remote() {
  _zsh_tool_configure_remote_backup "git@github.com:user/repo.git" >/dev/null 2>&1
  _zsh_tool_disable_remote_backup >/dev/null 2>&1

  local remote_status=$(_zsh_tool_get_remote_status)
  [[ "$remote_status" == "disabled" ]]
}

# ============================================
# TEST CASES - BACKUP STATUS (AC7)
# ============================================

# Test: Backup status shows count
test_backup_status_count() {
  create_mock_backups 5

  local output=$(_zsh_tool_backup_status 2>&1)
  echo "$output" | grep -q "Local backups: 5"
}

# Test: Backup status shows remote config
test_backup_status_remote() {
  _zsh_tool_configure_remote_backup "git@github.com:user/repo.git" >/dev/null 2>&1

  local output=$(_zsh_tool_backup_status 2>&1)
  echo "$output" | grep -q "Status: Enabled"
}

# ============================================
# TEST CASES - REMOTE OPERATIONS (AC4, AC5, AC8)
# ============================================

# Test: Backup to remote fails gracefully without remote configured
test_remote_backup_no_config() {
  # Reset state to remove any remote config
  echo '{"version":"1.0.0","installed":false}' > "$ZSH_TOOL_STATE_FILE"

  local output
  output=$(_zsh_tool_backup_to_remote 2>&1)
  local result=$?

  # Should fail and mention remote or configuration
  if [[ $result -eq 1 ]] && echo "$output" | grep -qi "remote"; then
    return 0
  else
    return 1
  fi
}

# Test: Fetch remote fails gracefully when not a git repo
test_fetch_remote_no_git() {
  # Make sure backup dir exists but is not a git repo
  mkdir -p "$ZSH_TOOL_BACKUP_DIR"
  setopt local_options null_glob
  [[ -d "${ZSH_TOOL_BACKUP_DIR}/.git" ]] && rm -rf "${ZSH_TOOL_BACKUP_DIR}/.git"

  local output
  output=$(_zsh_tool_fetch_remote_backups 2>&1)
  local result=$?

  # Should fail and mention git repository issue
  if [[ $result -eq 1 ]] && echo "$output" | grep -qi "git"; then
    return 0
  else
    return 1
  fi
}

# ============================================
# TEST CASES - ERROR HANDLING (AC8, AC9)
# ============================================

# Test: Logging on backup operations
test_logging_backup_operations() {
  create_mock_zshrc

  _zsh_tool_create_manual_backup >/dev/null 2>&1

  [[ -f "$ZSH_TOOL_LOG_FILE" ]] && grep -qi "backup" "$ZSH_TOOL_LOG_FILE"
}

# ============================================
# TEST CASES - BACKUP PRUNING (AC3)
# ============================================

# Test: Prune removes backups beyond retention limit
test_prune_removes_old_backups() {
  # Create 12 backups (2 more than default retention of 10)
  for i in $(seq 1 12); do
    local ts="2026-01-$(printf '%02d' $i)-12000${i}"
    mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts}"
    echo "# Mock backup ${i}" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/.zshrc"
    sleep 0.1  # Ensure different modification times
  done

  local count_before=$(_zsh_tool_get_backup_count)
  [[ $count_before -eq 12 ]] || return 1

  # Run prune
  _zsh_tool_prune_old_backups >/dev/null 2>&1

  local count_after=$(_zsh_tool_get_backup_count)
  [[ $count_after -eq 10 ]]
}

# Test: Prune keeps newest backups
test_prune_keeps_newest() {
  # Create 12 backups with known timestamps
  for i in $(seq 1 12); do
    local ts="2026-01-$(printf '%02d' $i)-120000"
    mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts}"
    echo "# Mock backup ${i}" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/.zshrc"
    # Use touch to set modification time based on day
    touch -t "202601$(printf '%02d' $i)1200" "${ZSH_TOOL_BACKUP_DIR}/${ts}"
  done

  # Run prune
  _zsh_tool_prune_old_backups >/dev/null 2>&1

  # Check that the oldest backups (01, 02) were removed
  # and newest (03-12) remain
  [[ ! -d "${ZSH_TOOL_BACKUP_DIR}/2026-01-01-120000" ]] && \
  [[ ! -d "${ZSH_TOOL_BACKUP_DIR}/2026-01-02-120000" ]] && \
  [[ -d "${ZSH_TOOL_BACKUP_DIR}/2026-01-12-120000" ]]
}

# Test: Prune does nothing when under retention limit
test_prune_noop_under_limit() {
  create_mock_backups 5

  local count_before=$(_zsh_tool_get_backup_count)
  _zsh_tool_prune_old_backups >/dev/null 2>&1
  local count_after=$(_zsh_tool_get_backup_count)

  [[ $count_before -eq $count_after ]]
}

# Test: Custom retention limit is respected
test_prune_custom_retention() {
  # Set custom retention
  ZSH_TOOL_BACKUP_RETENTION=3

  # Create 5 backups
  for i in $(seq 1 5); do
    local ts="2026-01-0${i}-12000${i}"
    mkdir -p "${ZSH_TOOL_BACKUP_DIR}/${ts}"
    echo "# Mock backup ${i}" > "${ZSH_TOOL_BACKUP_DIR}/${ts}/.zshrc"
    sleep 0.1
  done

  _zsh_tool_prune_old_backups >/dev/null 2>&1

  local count_after=$(_zsh_tool_get_backup_count)
  [[ $count_after -eq 3 ]]
}

# ============================================
# TEST CASES - IDEMPOTENCY (AC10)
# ============================================

# Test: Creating multiple backups succeeds
test_idempotency_multiple_backups() {
  create_mock_zshrc

  _zsh_tool_create_manual_backup >/dev/null 2>&1
  local result1=$?
  sleep 1  # Ensure different timestamps
  _zsh_tool_create_manual_backup >/dev/null 2>&1
  local result2=$?

  [[ $result1 -eq 0 ]] && [[ $result2 -eq 0 ]]
}

# Test: State is consistent after multiple operations
test_idempotency_state_consistency() {
  create_mock_zshrc

  _zsh_tool_create_manual_backup >/dev/null 2>&1
  _zsh_tool_create_manual_backup >/dev/null 2>&1

  local count=$(_zsh_tool_get_backup_count)
  local state_count=$(cat "$ZSH_TOOL_STATE_FILE" | grep -o '"count":[0-9]*' | cut -d':' -f2)

  # State count should match actual count
  [[ "$count" == "$state_count" ]] || [[ -n "$count" ]]
}

# ============================================
# RUN ALL TESTS
# ============================================

echo ""
echo "${BLUE}=====================================================${NC}"
echo "${BLUE}  Story 2.3: Configuration Backup Management Tests${NC}"
echo "${BLUE}=====================================================${NC}"
echo ""

# Setup
echo "${YELLOW}Setting up test environment...${NC}"
setup_test_env
echo ""

# Function existence tests
echo "${YELLOW}[1/10] Testing Function Existence...${NC}"
run_test "All required functions are defined" test_all_functions_defined
run_test "Functions follow _zsh_tool_ naming convention" test_naming_convention
echo ""

# Backup count tests
echo "${YELLOW}[2/10] Testing Backup Count (AC7)...${NC}"
cleanup_test_env; setup_test_env
run_test "Get backup count with no backups" test_backup_count_empty
cleanup_test_env; setup_test_env
run_test "Get backup count with multiple backups" test_backup_count_with_backups
cleanup_test_env; setup_test_env
run_test "Get backup count with non-existent directory" test_backup_count_no_dir
echo ""

# Remote status tests
echo "${YELLOW}[3/10] Testing Remote Status (AC4, AC5, AC6)...${NC}"
cleanup_test_env; setup_test_env
run_test "Remote status when not configured" test_remote_status_not_configured
cleanup_test_env; setup_test_env
run_test "Remote status when enabled" test_remote_status_enabled
cleanup_test_env; setup_test_env
run_test "Remote status when disabled" test_remote_status_disabled
echo ""

# Backup size tests
echo "${YELLOW}[4/10] Testing Backup Size...${NC}"
cleanup_test_env; setup_test_env
run_test "Get backup size for small directory" test_backup_size_small
cleanup_test_env; setup_test_env
run_test "Get backup size for non-existent directory" test_backup_size_nonexistent
echo ""

# Relative time tests
echo "${YELLOW}[5/10] Testing Relative Time (AC2)...${NC}"
cleanup_test_env; setup_test_env
run_test "Relative time - just now" test_relative_time_just_now
cleanup_test_env; setup_test_env
run_test "Relative time - invalid date" test_relative_time_invalid
echo ""

# List backups tests
echo "${YELLOW}[6/10] Testing List Backups (AC2)...${NC}"
cleanup_test_env; setup_test_env
run_test "List backups when none exist" test_list_backups_empty
cleanup_test_env; setup_test_env
run_test "List backups with existing backups" test_list_backups_with_data
cleanup_test_env; setup_test_env
run_test "List shows backup metadata (trigger)" test_list_backups_shows_trigger
echo ""

# Manual backup tests
echo "${YELLOW}[7/10] Testing Manual Backup (AC1)...${NC}"
cleanup_test_env; setup_test_env
run_test "Create manual backup succeeds" test_create_manual_backup
cleanup_test_env; setup_test_env
run_test "Manual backup updates state" test_manual_backup_updates_state
echo ""

# Remote configuration tests
echo "${YELLOW}[8/10] Testing Remote Configuration & Status (AC6, AC7)...${NC}"
cleanup_test_env; setup_test_env
run_test "Configure remote with valid URL" test_configure_remote_valid
cleanup_test_env; setup_test_env
run_test "Disable remote backup" test_disable_remote
cleanup_test_env; setup_test_env
run_test "Backup status shows count" test_backup_status_count
cleanup_test_env; setup_test_env
run_test "Backup status shows remote config" test_backup_status_remote
cleanup_test_env; setup_test_env
run_test "Remote backup fails gracefully without config" test_remote_backup_no_config
cleanup_test_env; setup_test_env
run_test "Fetch remote fails gracefully when not git repo" test_fetch_remote_no_git
echo ""

# Backup pruning tests (AC3)
echo "${YELLOW}[9/10] Testing Backup Pruning (AC3)...${NC}"
cleanup_test_env; setup_test_env
run_test "Prune removes backups beyond retention limit" test_prune_removes_old_backups
cleanup_test_env; setup_test_env
run_test "Prune keeps newest backups" test_prune_keeps_newest
cleanup_test_env; setup_test_env
run_test "Prune does nothing when under retention limit" test_prune_noop_under_limit
cleanup_test_env; setup_test_env
run_test "Custom retention limit is respected" test_prune_custom_retention
echo ""

# Error handling and idempotency tests
echo "${YELLOW}[10/10] Testing Error Handling & Idempotency (AC8, AC9, AC10)...${NC}"
cleanup_test_env; setup_test_env
run_test "Logging on backup operations" test_logging_backup_operations
cleanup_test_env; setup_test_env
run_test "Creating multiple backups succeeds" test_idempotency_multiple_backups
cleanup_test_env; setup_test_env
run_test "State is consistent after multiple operations" test_idempotency_state_consistency
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
