#!/usr/bin/env zsh
# Story 2.5: Git Integration for Dotfiles Tests
# Tests for lib/git/integration.zsh

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
  source "${PROJECT_ROOT}/lib/git/integration.zsh"

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

  # Override DOTFILES_REPO to use test directory
  DOTFILES_REPO="${TEST_HOME}/.dotfiles"
  DOTFILES_GITIGNORE="${ZSH_TOOL_CONFIG_DIR}/dotfiles.gitignore"

  # Initialize state file for tests
  echo '{"version":"1.0.0","installed":false}' > "$ZSH_TOOL_STATE_FILE"

  # Save original HOME and set test HOME
  ORIG_HOME="$HOME"
  export HOME="$TEST_HOME"

  # Setup test-scoped git config (avoids modifying global config)
  TEST_GIT_CONFIG="${TEST_TMP_DIR}/gitconfig"
  export GIT_CONFIG_GLOBAL="$TEST_GIT_CONFIG"
  git config --global user.name "Test User"
  git config --global user.email "test@example.com"
}

# Cleanup test environment
cleanup_test_env() {
  # Restore original HOME and git config
  export HOME="$ORIG_HOME"
  unset GIT_CONFIG_GLOBAL
  [[ -d "$TEST_TMP_DIR" ]] && rm -rf "$TEST_TMP_DIR"
}

# Create mock .zshrc for testing
create_mock_zshrc() {
  echo "# Test .zshrc content" > "${HOME}/.zshrc"
  echo "export TEST_VAR=1" >> "${HOME}/.zshrc"
}

# Create mock .zshrc.local for testing
create_mock_zshrc_local() {
  echo "# Test .zshrc.local content" > "${HOME}/.zshrc.local"
  echo "alias test='echo test'" >> "${HOME}/.zshrc.local"
}

# Initialize a test dotfiles repo
init_test_dotfiles_repo() {
  _zsh_tool_git_init_repo >/dev/null 2>&1
}

# ============================================
# TEST CASES - FUNCTION EXISTENCE
# ============================================

# Test: All required functions are defined
test_all_functions_defined() {
  typeset -f _zsh_tool_create_dotfiles_gitignore >/dev/null 2>&1 && \
  typeset -f _zsh_tool_check_git_config >/dev/null 2>&1 && \
  typeset -f _zsh_tool_git_init_repo >/dev/null 2>&1 && \
  typeset -f _zsh_tool_git_setup_remote >/dev/null 2>&1 && \
  typeset -f _zsh_tool_git_status >/dev/null 2>&1 && \
  typeset -f _zsh_tool_git_add >/dev/null 2>&1 && \
  typeset -f _zsh_tool_git_commit >/dev/null 2>&1 && \
  typeset -f _zsh_tool_git_push >/dev/null 2>&1 && \
  typeset -f _zsh_tool_git_pull >/dev/null 2>&1 && \
  typeset -f _zsh_tool_git_integration >/dev/null 2>&1
}

# Test: Functions follow naming convention
test_naming_convention() {
  local funcs=$(typeset -f | grep "^_zsh_tool_git" | wc -l)
  [[ $funcs -ge 8 ]]
}

# Test: Main dispatcher exists
test_main_dispatcher_exists() {
  typeset -f _zsh_tool_git_integration >/dev/null 2>&1
}

# ============================================
# TEST CASES - INIT (AC1, AC2, AC3)
# ============================================

# Test: Init creates bare repository (AC1)
test_init_creates_bare_repo() {
  _zsh_tool_git_init_repo >/dev/null 2>&1
  local result=$?

  [[ $result -eq 0 ]] && \
  [[ -d "${DOTFILES_REPO}" ]] && \
  [[ -f "${DOTFILES_REPO}/HEAD" ]]
}

# Test: Init configures showUntrackedFiles to no
test_init_configures_showUntrackedFiles() {
  init_test_dotfiles_repo

  local config_val=$(git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" config status.showUntrackedFiles 2>/dev/null)
  [[ "$config_val" == "no" ]]
}

# Test: Init creates dotfiles alias in .zshrc.local (AC2)
test_init_creates_dotfiles_alias() {
  init_test_dotfiles_repo

  [[ -f "${HOME}/.zshrc.local" ]] && \
  grep -q "dotfiles=" "${HOME}/.zshrc.local"
}

# Test: Init creates gitignore template (AC3)
test_init_creates_gitignore_template() {
  init_test_dotfiles_repo

  [[ -f "${DOTFILES_GITIGNORE}" ]] && \
  grep -q ".ssh/" "${DOTFILES_GITIGNORE}" && \
  grep -q ".gnupg/" "${DOTFILES_GITIGNORE}" && \
  grep -q ".aws/" "${DOTFILES_GITIGNORE}"
}

# Test: Init updates state.json (AC11)
test_init_updates_state_json() {
  init_test_dotfiles_repo

  local state=$(cat "$ZSH_TOOL_STATE_FILE")
  # Handle both compact and pretty-printed JSON formats
  echo "$state" | grep -q "git_integration" && \
  echo "$state" | grep -qE '"enabled":\s*true' && \
  echo "$state" | grep -qE '"repo_type":\s*"bare"'
}

# Test: Init fails if repo already exists
test_init_fails_if_already_exists() {
  init_test_dotfiles_repo

  # Try to init again
  local output
  output=$(_zsh_tool_git_init_repo 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "already exists"
}

# ============================================
# TEST CASES - GIT CONFIG VALIDATION (AC10)
# ============================================

# Test: Check git config passes when configured
test_check_git_config_passes_when_configured() {
  _zsh_tool_check_git_config >/dev/null 2>&1
  local result=$?
  [[ $result -eq 0 ]]
}

# Test: Check git config fails when not configured
test_check_git_config_fails_when_not_configured() {
  # Use empty test-scoped git config (GIT_CONFIG_GLOBAL isolates from real config)
  local empty_config="${TEST_TMP_DIR}/empty_gitconfig"
  touch "$empty_config"
  export GIT_CONFIG_GLOBAL="$empty_config"

  local output
  output=$(_zsh_tool_check_git_config 2>&1)
  local result=$?

  # Restore test config
  export GIT_CONFIG_GLOBAL="$TEST_GIT_CONFIG"

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "not configured"
}

# ============================================
# TEST CASES - REMOTE SETUP (AC4)
# ============================================

# Test: Setup remote adds origin (AC4)
test_setup_remote_adds_origin() {
  init_test_dotfiles_repo

  echo "git@github.com:test/dotfiles.git" | _zsh_tool_git_setup_remote >/dev/null 2>&1

  local remote=$(git --git-dir="$DOTFILES_REPO" remote get-url origin 2>/dev/null)
  [[ "$remote" == "git@github.com:test/dotfiles.git" ]]
}

# Test: Setup remote with argument
test_setup_remote_with_arg() {
  init_test_dotfiles_repo

  _zsh_tool_git_setup_remote "git@github.com:test/dotfiles2.git" >/dev/null 2>&1

  local remote=$(git --git-dir="$DOTFILES_REPO" remote get-url origin 2>/dev/null)
  [[ "$remote" == "git@github.com:test/dotfiles2.git" ]]
}

# Test: Setup remote updates state (AC11)
test_setup_remote_updates_state() {
  init_test_dotfiles_repo
  _zsh_tool_git_setup_remote "git@github.com:test/dotfiles.git" >/dev/null 2>&1

  local state=$(cat "$ZSH_TOOL_STATE_FILE")
  echo "$state" | grep -q "remote_url"
}

# Test: Setup remote requires repo (AC12)
test_setup_remote_requires_repo() {
  # Don't init repo
  local output
  output=$(_zsh_tool_git_setup_remote "git@github.com:test/dotfiles.git" 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "not initialized"
}

# ============================================
# TEST CASES - STATUS (AC5)
# ============================================

# Test: Status shows dotfiles status (AC5)
test_status_shows_dotfiles_status() {
  init_test_dotfiles_repo
  create_mock_zshrc

  local output
  output=$(_zsh_tool_git_status 2>&1)
  local result=$?

  # Status should succeed (even if no commits yet)
  [[ $result -eq 0 ]] || echo "$output" | grep -qi "branch\|commit\|nothing"
}

# Test: Status requires repo (AC12)
test_status_requires_repo() {
  local output
  output=$(_zsh_tool_git_status 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "not initialized"
}

# ============================================
# TEST CASES - ADD (AC6)
# ============================================

# Test: Add stages files (AC6)
test_add_stages_files() {
  init_test_dotfiles_repo
  create_mock_zshrc

  _zsh_tool_git_add "${HOME}/.zshrc" >/dev/null 2>&1
  local result=$?

  # Check if file is staged
  local staged=$(git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" diff --cached --name-only 2>/dev/null)
  [[ $result -eq 0 ]] && echo "$staged" | grep -q ".zshrc"
}

# Test: Add requires repo (AC12)
test_add_requires_repo() {
  local output
  output=$(_zsh_tool_git_add "${HOME}/.zshrc" 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "not initialized"
}

# ============================================
# TEST CASES - COMMIT (AC7)
# ============================================

# Test: Commit creates commit (AC7)
test_commit_creates_commit() {
  init_test_dotfiles_repo
  create_mock_zshrc

  _zsh_tool_git_add "${HOME}/.zshrc" >/dev/null 2>&1

  echo "Test commit" | _zsh_tool_git_commit >/dev/null 2>&1
  local result=$?

  # Check commit exists
  local log=$(git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" log --oneline 2>/dev/null | head -1)
  [[ $result -eq 0 ]] && echo "$log" | grep -q "Test commit"
}

# Test: Commit with message argument
test_commit_with_arg() {
  init_test_dotfiles_repo
  create_mock_zshrc

  _zsh_tool_git_add "${HOME}/.zshrc" >/dev/null 2>&1
  _zsh_tool_git_commit "Commit with arg" >/dev/null 2>&1
  local result=$?

  local log=$(git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" log --oneline 2>/dev/null | head -1)
  [[ $result -eq 0 ]] && echo "$log" | grep -q "Commit with arg"
}

# Test: Commit updates state (AC11)
test_commit_updates_state() {
  init_test_dotfiles_repo
  create_mock_zshrc

  _zsh_tool_git_add "${HOME}/.zshrc" >/dev/null 2>&1
  _zsh_tool_git_commit "State test" >/dev/null 2>&1

  local state=$(cat "$ZSH_TOOL_STATE_FILE")
  echo "$state" | grep -q "last_commit"
}

# Test: Commit requires repo (AC12)
test_commit_requires_repo() {
  local output
  output=$(_zsh_tool_git_commit "Test" 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "not initialized"
}

# ============================================
# TEST CASES - PUSH (AC8)
# ============================================

# Test: Push requires repo (AC12)
test_push_requires_repo() {
  local output
  output=$(_zsh_tool_git_push 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "not initialized"
}

# Test: Push updates state on success (AC11)
# Note: Can't test actual push without a real remote, so we test the function exists
test_push_function_exists() {
  typeset -f _zsh_tool_git_push >/dev/null 2>&1
}

# ============================================
# TEST CASES - PULL (AC9)
# ============================================

# Test: Pull requires repo (AC12)
test_pull_requires_repo() {
  local output
  output=$(_zsh_tool_git_pull 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -qi "not initialized"
}

# Test: Pull function exists and calls backup
test_pull_function_exists() {
  typeset -f _zsh_tool_git_pull >/dev/null 2>&1 && \
  typeset -f _zsh_tool_git_pull | grep -q "_zsh_tool_create_backup"
}

# Test: Pull creates backup (AC9)
test_pull_calls_backup() {
  init_test_dotfiles_repo
  create_mock_zshrc

  # Setup remote (fake, will fail but backup should still be created)
  _zsh_tool_git_setup_remote "git@github.com:test/dotfiles.git" >/dev/null 2>&1

  # Add initial commit so we have something to pull
  _zsh_tool_git_add "${HOME}/.zshrc" >/dev/null 2>&1
  _zsh_tool_git_commit "Initial" >/dev/null 2>&1

  local backup_count_before=$(ls -1 "${ZSH_TOOL_BACKUP_DIR}" 2>/dev/null | wc -l)

  # Pull will fail (no actual remote) but should still create backup
  _zsh_tool_git_pull 2>&1 || true

  local backup_count_after=$(ls -1 "${ZSH_TOOL_BACKUP_DIR}" 2>/dev/null | wc -l)

  # Backup should have been created
  [[ $backup_count_after -gt $backup_count_before ]]
}

# ============================================
# TEST CASES - DISPATCHER
# ============================================

# Test: Dispatcher routes init
test_dispatcher_routes_init() {
  local output
  output=$(_zsh_tool_git_integration init 2>&1)
  local result=$?

  [[ $result -eq 0 ]] && [[ -d "$DOTFILES_REPO" ]]
}

# Test: Dispatcher routes status
test_dispatcher_routes_status() {
  init_test_dotfiles_repo

  local output
  output=$(_zsh_tool_git_integration status 2>&1)
  local result=$?

  [[ $result -eq 0 ]] || echo "$output" | grep -qi "branch\|commit\|nothing"
}

# Test: Dispatcher shows usage on unknown command
test_dispatcher_shows_usage_on_unknown() {
  local output
  output=$(_zsh_tool_git_integration unknown_cmd 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -q "Usage"
}

# Test: Dispatcher shows usage with no args
test_dispatcher_shows_usage_no_args() {
  local output
  output=$(_zsh_tool_git_integration 2>&1)
  local result=$?

  [[ $result -eq 1 ]] && \
  echo "$output" | grep -q "Usage"
}

# ============================================
# TEST CASES - GITIGNORE TEMPLATE
# ============================================

# Test: Gitignore excludes sensitive directories
test_gitignore_excludes_sensitive() {
  init_test_dotfiles_repo

  [[ -f "${DOTFILES_GITIGNORE}" ]] && \
  grep -q ".ssh/" "${DOTFILES_GITIGNORE}" && \
  grep -q ".gnupg/" "${DOTFILES_GITIGNORE}" && \
  grep -q ".aws/" "${DOTFILES_GITIGNORE}" && \
  grep -q ".config/gcloud/" "${DOTFILES_GITIGNORE}"
}

# Test: Gitignore excludes credentials
test_gitignore_excludes_credentials() {
  init_test_dotfiles_repo

  [[ -f "${DOTFILES_GITIGNORE}" ]] && \
  grep -q ".netrc" "${DOTFILES_GITIGNORE}" && \
  grep -q "credentials.json" "${DOTFILES_GITIGNORE}" && \
  grep -q "*.pem" "${DOTFILES_GITIGNORE}" && \
  grep -q "*.key" "${DOTFILES_GITIGNORE}"
}

# Test: Gitignore excludes tool state
test_gitignore_excludes_tool_state() {
  init_test_dotfiles_repo

  [[ -f "${DOTFILES_GITIGNORE}" ]] && \
  grep -q ".config/zsh-tool/state.json" "${DOTFILES_GITIGNORE}" && \
  grep -q ".config/zsh-tool/backups/" "${DOTFILES_GITIGNORE}"
}

# Test: Gitignore excludes large files
test_gitignore_excludes_large_files() {
  init_test_dotfiles_repo

  [[ -f "${DOTFILES_GITIGNORE}" ]] && \
  grep -q ".zsh_history" "${DOTFILES_GITIGNORE}" && \
  grep -q ".cache/" "${DOTFILES_GITIGNORE}" && \
  grep -q "node_modules/" "${DOTFILES_GITIGNORE}"
}

# ============================================
# RUN ALL TESTS
# ============================================

echo ""
echo "${BLUE}=====================================================${NC}"
echo "${BLUE}  Story 2.5: Git Integration for Dotfiles Tests${NC}"
echo "${BLUE}=====================================================${NC}"
echo ""

# Setup
echo "${YELLOW}Setting up test environment...${NC}"
setup_test_env
echo ""

# Function existence tests
echo "${YELLOW}[1/13] Testing Function Existence...${NC}"
run_test "All required functions are defined" test_all_functions_defined
run_test "Functions follow _zsh_tool_git naming convention" test_naming_convention
run_test "Main dispatcher exists" test_main_dispatcher_exists
echo ""

# Init tests (AC1, AC2, AC3)
echo "${YELLOW}[2/13] Testing Init - Bare Repository (AC1)...${NC}"
cleanup_test_env; setup_test_env
run_test "Init creates bare repository" test_init_creates_bare_repo
cleanup_test_env; setup_test_env
run_test "Init configures showUntrackedFiles to no" test_init_configures_showUntrackedFiles
cleanup_test_env; setup_test_env
run_test "Init fails if repo already exists" test_init_fails_if_already_exists
echo ""

echo "${YELLOW}[3/13] Testing Init - Alias Creation (AC2)...${NC}"
cleanup_test_env; setup_test_env
run_test "Init creates dotfiles alias in .zshrc.local" test_init_creates_dotfiles_alias
echo ""

echo "${YELLOW}[4/13] Testing Init - Gitignore Template (AC3)...${NC}"
cleanup_test_env; setup_test_env
run_test "Init creates gitignore template" test_init_creates_gitignore_template
echo ""

# Remote tests (AC4)
echo "${YELLOW}[5/13] Testing Remote Setup (AC4)...${NC}"
cleanup_test_env; setup_test_env
run_test "Setup remote adds origin" test_setup_remote_adds_origin
cleanup_test_env; setup_test_env
run_test "Setup remote with argument" test_setup_remote_with_arg
cleanup_test_env; setup_test_env
run_test "Setup remote updates state" test_setup_remote_updates_state
cleanup_test_env; setup_test_env
run_test "Setup remote requires repo" test_setup_remote_requires_repo
echo ""

# Status tests (AC5)
echo "${YELLOW}[6/13] Testing Status (AC5)...${NC}"
cleanup_test_env; setup_test_env
run_test "Status shows dotfiles status" test_status_shows_dotfiles_status
cleanup_test_env; setup_test_env
run_test "Status requires repo" test_status_requires_repo
echo ""

# Add tests (AC6)
echo "${YELLOW}[7/13] Testing Add (AC6)...${NC}"
cleanup_test_env; setup_test_env
run_test "Add stages files" test_add_stages_files
cleanup_test_env; setup_test_env
run_test "Add requires repo" test_add_requires_repo
echo ""

# Commit tests (AC7)
echo "${YELLOW}[8/13] Testing Commit (AC7)...${NC}"
cleanup_test_env; setup_test_env
run_test "Commit creates commit" test_commit_creates_commit
cleanup_test_env; setup_test_env
run_test "Commit with message argument" test_commit_with_arg
cleanup_test_env; setup_test_env
run_test "Commit updates state" test_commit_updates_state
cleanup_test_env; setup_test_env
run_test "Commit requires repo" test_commit_requires_repo
echo ""

# Push tests (AC8)
echo "${YELLOW}[9/13] Testing Push (AC8)...${NC}"
cleanup_test_env; setup_test_env
run_test "Push function exists" test_push_function_exists
cleanup_test_env; setup_test_env
run_test "Push requires repo" test_push_requires_repo
echo ""

# Pull tests (AC9)
echo "${YELLOW}[10/13] Testing Pull (AC9)...${NC}"
cleanup_test_env; setup_test_env
run_test "Pull function exists and calls backup" test_pull_function_exists
cleanup_test_env; setup_test_env
run_test "Pull requires repo" test_pull_requires_repo
cleanup_test_env; setup_test_env
run_test "Pull creates backup before pulling" test_pull_calls_backup
echo ""

# Git config tests (AC10)
echo "${YELLOW}[11/13] Testing Git Config Validation (AC10)...${NC}"
cleanup_test_env; setup_test_env
run_test "Check git config passes when configured" test_check_git_config_passes_when_configured
run_test "Check git config fails when not configured" test_check_git_config_fails_when_not_configured
echo ""

# State tracking tests (AC11)
echo "${YELLOW}[12/13] Testing State Tracking (AC11)...${NC}"
cleanup_test_env; setup_test_env
run_test "Init updates state.json" test_init_updates_state_json
echo ""

# Dispatcher tests
echo "${YELLOW}[13/13] Testing Dispatcher and Gitignore...${NC}"
cleanup_test_env; setup_test_env
run_test "Dispatcher routes init" test_dispatcher_routes_init
cleanup_test_env; setup_test_env
run_test "Dispatcher routes status" test_dispatcher_routes_status
cleanup_test_env; setup_test_env
run_test "Dispatcher shows usage on unknown command" test_dispatcher_shows_usage_on_unknown
cleanup_test_env; setup_test_env
run_test "Dispatcher shows usage with no args" test_dispatcher_shows_usage_no_args
cleanup_test_env; setup_test_env
run_test "Gitignore excludes sensitive directories" test_gitignore_excludes_sensitive
cleanup_test_env; setup_test_env
run_test "Gitignore excludes credentials" test_gitignore_excludes_credentials
cleanup_test_env; setup_test_env
run_test "Gitignore excludes tool state" test_gitignore_excludes_tool_state
cleanup_test_env; setup_test_env
run_test "Gitignore excludes large files" test_gitignore_excludes_large_files
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
