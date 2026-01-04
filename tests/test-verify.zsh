#!/usr/bin/env zsh
# Story 1.7: Installation Verification and Summary Tests
# Tests for lib/install/verify.zsh

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
  # Source required modules
  source "${PROJECT_ROOT}/lib/core/utils.zsh"
  source "${PROJECT_ROOT}/lib/install/verify.zsh"

  # Override config directory AFTER sourcing
  ZSH_TOOL_CONFIG_DIR=$(mktemp -d)
  ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/zsh-tool.log"
  ZSH_TOOL_STATE_FILE="${ZSH_TOOL_CONFIG_DIR}/state.json"
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"

  # Initialize state file for tests
  echo '{"version":"1.0.0","installed":false}' > "$ZSH_TOOL_STATE_FILE"

  # Create test config.yaml
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
plugins:
  - git
  - zsh-syntax-highlighting
  - zsh-autosuggestions

theme: robbyrussell
EOF
}

# Cleanup test environment
cleanup_test_env() {
  [[ -d "$ZSH_TOOL_CONFIG_DIR" ]] && rm -rf "$ZSH_TOOL_CONFIG_DIR"
}

# ============================================
# TEST CASES - Oh My Zsh Verification
# ============================================

# Test: OMZ check succeeds when $ZSH is set
test_omz_check_with_zsh_set() {
  # Save real ZSH if it exists
  local orig_zsh="$ZSH"

  # Set ZSH to a test location
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test"
  mkdir -p "$ZSH"

  # Create oh-my-zsh.sh
  echo "# test oh-my-zsh" > "$ZSH/oh-my-zsh.sh"

  # Define omz function
  omz() { echo "test omz"; }

  # Run check
  _zsh_tool_check_omz_loaded >/dev/null 2>&1
  local result=$?

  # Cleanup
  rm -rf "$ZSH"
  unset -f omz

  # Restore
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH

  return $result
}

# Test: OMZ check fails when $ZSH not set
test_omz_check_without_zsh() {
  # Save and unset ZSH
  local orig_zsh="$ZSH"
  unset ZSH

  # Run check (should fail)
  _zsh_tool_check_omz_loaded >/dev/null 2>&1
  local result=$?

  # Restore
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh"

  # Check should have failed
  [[ $result -ne 0 ]]
}

# Test: OMZ check fails when oh-my-zsh.sh missing
test_omz_check_without_omz_sh() {
  local orig_zsh="$ZSH"

  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-nofile"
  mkdir -p "$ZSH"

  # Don't create oh-my-zsh.sh

  _zsh_tool_check_omz_loaded >/dev/null 2>&1
  local result=$?

  rm -rf "$ZSH"
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH

  # Check should have failed
  [[ $result -ne 0 ]]
}

# Test: OMZ check fails when omz function not defined
test_omz_check_without_omz_function() {
  local orig_zsh="$ZSH"

  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-nofunc"
  mkdir -p "$ZSH"
  echo "# test" > "$ZSH/oh-my-zsh.sh"

  # Make sure omz function is NOT defined
  unset -f omz 2>/dev/null

  _zsh_tool_check_omz_loaded >/dev/null 2>&1
  local result=$?

  rm -rf "$ZSH"
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH

  # Check should have failed
  [[ $result -ne 0 ]]
}

# ============================================
# TEST CASES - Plugin Verification
# ============================================

# Test: Plugin check succeeds with no plugins configured
test_plugin_check_no_plugins() {
  # Create config with no plugins
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
plugins:

theme: robbyrussell
EOF

  _zsh_tool_check_plugins_loaded >/dev/null 2>&1
  return $?
}

# Test: Plugin check fails when config file missing
test_plugin_check_no_config() {
  rm -f "${ZSH_TOOL_CONFIG_DIR}/config.yaml"

  _zsh_tool_check_plugins_loaded >/dev/null 2>&1
  local result=$?

  # Recreate config for other tests
  setup_test_env

  # Check should have failed
  [[ $result -ne 0 ]]
}

# Test: Plugin check detects zsh-syntax-highlighting
test_plugin_check_syntax_highlighting() {
  # Set both plugin versions (config has both configured)
  export ZSH_HIGHLIGHT_VERSION="0.8.0"
  export ZSH_AUTOSUGGEST_VERSION="0.7.0"

  # Set up ZSH with git plugin directory (also in config)
  local orig_zsh="$ZSH"
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-plugin-check"
  mkdir -p "$ZSH/plugins/git"

  _zsh_tool_check_plugins_loaded >/dev/null 2>&1
  local result=$?

  # Cleanup
  rm -rf "$ZSH"
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH
  unset ZSH_HIGHLIGHT_VERSION
  unset ZSH_AUTOSUGGEST_VERSION

  return $result
}

# Test: Plugin check fails without zsh-syntax-highlighting version
test_plugin_check_missing_syntax_highlighting() {
  # Make sure version is not set
  unset ZSH_HIGHLIGHT_VERSION

  _zsh_tool_check_plugins_loaded >/dev/null 2>&1
  local result=$?

  # Check should have failed (plugin configured but not loaded)
  [[ $result -ne 0 ]]
}

# Test: Plugin check detects zsh-autosuggestions
test_plugin_check_autosuggestions() {
  # Set both required plugin versions
  export ZSH_HIGHLIGHT_VERSION="0.8.0"
  export ZSH_AUTOSUGGEST_VERSION="0.7.0"

  # Set up ZSH with git plugin directory (also in config)
  local orig_zsh="$ZSH"
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-autosuggestions"
  mkdir -p "$ZSH/plugins/git"

  _zsh_tool_check_plugins_loaded >/dev/null 2>&1
  local result=$?

  # Cleanup
  rm -rf "$ZSH"
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH
  unset ZSH_HIGHLIGHT_VERSION
  unset ZSH_AUTOSUGGEST_VERSION

  return $result
}

# Test: Plugin check handles generic plugins (directory check)
test_plugin_check_generic_plugin() {
  local orig_zsh="$ZSH"

  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-plugins"
  mkdir -p "$ZSH/plugins/git"

  # Create config with just git plugin
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
plugins:
  - git

theme: robbyrussell
EOF

  _zsh_tool_check_plugins_loaded >/dev/null 2>&1
  local result=$?

  rm -rf "$ZSH"
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH

  # Restore original config
  setup_test_env

  return $result
}

# ============================================
# TEST CASES - Theme Verification
# ============================================

# Test: Theme check succeeds when theme matches
test_theme_check_matches() {
  export ZSH_THEME="robbyrussell"

  local orig_zsh="$ZSH"
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-theme"
  mkdir -p "$ZSH/themes"
  echo "# theme" > "$ZSH/themes/robbyrussell.zsh-theme"

  _zsh_tool_check_theme_applied >/dev/null 2>&1
  local result=$?

  rm -rf "$ZSH"
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH
  unset ZSH_THEME

  return $result
}

# Test: Theme check fails when theme mismatch
test_theme_check_mismatch() {
  export ZSH_THEME="af-magic"  # Different from config

  _zsh_tool_check_theme_applied >/dev/null 2>&1
  local result=$?

  unset ZSH_THEME

  # Check should have failed
  [[ $result -ne 0 ]]
}

# Test: Theme check fails when config missing
test_theme_check_no_config() {
  rm -f "${ZSH_TOOL_CONFIG_DIR}/config.yaml"

  _zsh_tool_check_theme_applied >/dev/null 2>&1
  local result=$?

  # Recreate config
  setup_test_env

  # Check should have failed
  [[ $result -ne 0 ]]
}

# Test: Theme check succeeds with no theme configured
test_theme_check_no_theme() {
  # Create config with no theme
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
plugins:
  - git
EOF

  _zsh_tool_check_theme_applied >/dev/null 2>&1
  local result=$?

  # Restore config
  setup_test_env

  return $result
}

# Test: Theme check fails when theme file missing
test_theme_check_theme_file_missing() {
  export ZSH_THEME="robbyrussell"

  local orig_zsh="$ZSH"
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-notheme"
  mkdir -p "$ZSH/themes"
  # Don't create theme file

  _zsh_tool_check_theme_applied >/dev/null 2>&1
  local result=$?

  rm -rf "$ZSH"
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH
  unset ZSH_THEME

  # Check should have failed
  [[ $result -ne 0 ]]
}

# ============================================
# TEST CASES - Summary Display
# ============================================

# Test: Summary displays without errors
test_summary_display_succeeds() {
  # Set up minimal environment
  export ZSH="${HOME}/.oh-my-zsh"

  # Add state with backup info
  cat > "$ZSH_TOOL_STATE_FILE" <<EOF
{
  "version": "1.0.0",
  "installed": true,
  "backup_location": "${ZSH_TOOL_CONFIG_DIR}/backups/2024-01-01_120000",
  "backup_timestamp": "2024-01-01T12:00:00-08:00"
}
EOF

  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/backups/2024-01-01_120000"
  touch "${ZSH_TOOL_CONFIG_DIR}/backups/2024-01-01_120000/test.zshrc"

  _zsh_tool_display_summary >/dev/null 2>&1
  local result=$?

  return $result
}

# Test: Summary displays installation timing
test_summary_display_timing() {
  cat > "$ZSH_TOOL_STATE_FILE" <<EOF
{
  "version": "1.0.0",
  "installed": true,
  "installation_start": "2024-01-01T12:00:00-08:00",
  "installation_end": "2024-01-01T12:01:30-08:00",
  "installation_duration_seconds": 90
}
EOF

  local output=$(_zsh_tool_display_summary 2>/dev/null)

  # Check output contains timing info
  [[ "$output" == *"Installation Timing"* && "$output" == *"Duration: 90s"* ]]
}

# Test: Summary displays backup information
test_summary_display_backup() {
  cat > "$ZSH_TOOL_STATE_FILE" <<EOF
{
  "version": "1.0.0",
  "installed": true,
  "backup_location": "${ZSH_TOOL_CONFIG_DIR}/backups/test",
  "backup_timestamp": "2024-01-01T12:00:00-08:00"
}
EOF

  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/backups/test"
  touch "${ZSH_TOOL_CONFIG_DIR}/backups/test/file1"
  touch "${ZSH_TOOL_CONFIG_DIR}/backups/test/file2"

  local output=$(_zsh_tool_display_summary 2>/dev/null)

  # Check output contains backup info
  [[ "$output" == *"Backup:"* && "$output" == *"Files backed up: 2"* ]]
}

# Test: Summary displays configured plugins
test_summary_display_plugins() {
  local output=$(_zsh_tool_display_summary 2>/dev/null)

  # Check output contains plugin list
  [[ "$output" == *"git"* && "$output" == *"zsh-syntax-highlighting"* && "$output" == *"zsh-autosuggestions"* ]]
}

# Test: Summary displays theme
test_summary_display_theme() {
  local output=$(_zsh_tool_display_summary 2>/dev/null)

  # Check output contains theme
  [[ "$output" == *"Theme: robbyrussell"* ]]
}

# Test: Summary displays custom layer when exists
test_summary_display_custom_layer() {
  touch "${HOME}/.zshrc.local"

  local output=$(_zsh_tool_display_summary 2>/dev/null)

  # Cleanup
  rm -f "${HOME}/.zshrc.local"

  # Check output contains custom layer
  [[ "$output" == *"Custom layer: ~/.zshrc.local"* ]]
}

# ============================================
# TEST CASES - Verification Integration
# ============================================

# Test: Verification passes with all checks passing
test_verification_passes() {
  # Set up complete environment
  local orig_zsh="$ZSH"
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-verify"
  mkdir -p "$ZSH/plugins/git"
  mkdir -p "$ZSH/themes"
  echo "# omz" > "$ZSH/oh-my-zsh.sh"
  echo "# theme" > "$ZSH/themes/robbyrussell.zsh-theme"

  # Define omz function
  omz() { echo "test"; }

  # Set plugin versions
  export ZSH_HIGHLIGHT_VERSION="0.8.0"
  export ZSH_AUTOSUGGEST_VERSION="0.7.0"

  # Set theme
  export ZSH_THEME="robbyrussell"

  # Skip subshell verification for this test (we're in a mock environment)
  export ZSH_TOOL_SKIP_SUBSHELL_VERIFY=1

  _zsh_tool_verify_installation >/dev/null 2>&1
  local result=$?

  # Cleanup
  rm -rf "$ZSH"
  unset -f omz
  unset ZSH_HIGHLIGHT_VERSION
  unset ZSH_AUTOSUGGEST_VERSION
  unset ZSH_THEME
  unset ZSH_TOOL_SKIP_SUBSHELL_VERIFY
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH

  return $result
}

# Test: Verification fails when OMZ not loaded
test_verification_fails_omz() {
  # Unset ZSH
  local orig_zsh="$ZSH"
  unset ZSH

  # Set up plugins and theme correctly
  export ZSH_HIGHLIGHT_VERSION="0.8.0"
  export ZSH_AUTOSUGGEST_VERSION="0.7.0"
  export ZSH_THEME="robbyrussell"

  _zsh_tool_verify_installation >/dev/null 2>&1
  local result=$?

  # Cleanup
  unset ZSH_HIGHLIGHT_VERSION
  unset ZSH_AUTOSUGGEST_VERSION
  unset ZSH_THEME
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh"

  # Check should have failed
  [[ $result -ne 0 ]]
}

# Test: Verification fails when plugins not loaded
test_verification_fails_plugins() {
  # Set up OMZ
  local orig_zsh="$ZSH"
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-verify-plugins"
  mkdir -p "$ZSH"
  echo "# omz" > "$ZSH/oh-my-zsh.sh"
  omz() { echo "test"; }

  # Don't set plugin versions (plugins not loaded)
  unset ZSH_HIGHLIGHT_VERSION
  unset ZSH_AUTOSUGGEST_VERSION

  # Set theme correctly
  export ZSH_THEME="robbyrussell"
  mkdir -p "$ZSH/themes"
  echo "# theme" > "$ZSH/themes/robbyrussell.zsh-theme"

  _zsh_tool_verify_installation >/dev/null 2>&1
  local result=$?

  # Cleanup
  rm -rf "$ZSH"
  unset -f omz
  unset ZSH_THEME
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH

  # Check should have failed
  [[ $result -ne 0 ]]
}

# Test: Verification fails when theme not applied
test_verification_fails_theme() {
  # Set up OMZ
  local orig_zsh="$ZSH"
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-verify-theme"
  mkdir -p "$ZSH"
  echo "# omz" > "$ZSH/oh-my-zsh.sh"
  omz() { echo "test"; }

  # Set plugins correctly
  export ZSH_HIGHLIGHT_VERSION="0.8.0"
  export ZSH_AUTOSUGGEST_VERSION="0.7.0"

  # Set wrong theme
  export ZSH_THEME="af-magic"

  _zsh_tool_verify_installation >/dev/null 2>&1
  local result=$?

  # Cleanup
  rm -rf "$ZSH"
  unset -f omz
  unset ZSH_HIGHLIGHT_VERSION
  unset ZSH_AUTOSUGGEST_VERSION
  unset ZSH_THEME
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH

  # Check should have failed
  [[ $result -ne 0 ]]
}

# Test: Verification displays remediation on failure
test_verification_remediation_display() {
  # Cause verification to fail (no ZSH set)
  local orig_zsh="$ZSH"
  unset ZSH

  local output=$(_zsh_tool_verify_installation 2>/dev/null)

  # Restore
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh"

  # Check output contains remediation
  [[ "$output" == *"Remediation options"* && "$output" == *"Re-run installation"* ]]
}

# ============================================
# TEST CASES - Public Command
# ============================================

# Test: zsh-tool-verify command exists
test_public_command_exists() {
  typeset -f zsh-tool-verify >/dev/null 2>&1
  return $?
}

# Test: zsh-tool-verify runs without errors
test_public_command_runs() {
  # Set up minimal passing environment
  local orig_zsh="$ZSH"
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-cmd"
  mkdir -p "$ZSH/plugins/git"
  mkdir -p "$ZSH/themes"
  echo "# omz" > "$ZSH/oh-my-zsh.sh"
  echo "# theme" > "$ZSH/themes/robbyrussell.zsh-theme"
  omz() { echo "test"; }
  export ZSH_HIGHLIGHT_VERSION="0.8.0"
  export ZSH_AUTOSUGGEST_VERSION="0.7.0"
  export ZSH_THEME="robbyrussell"

  # Skip subshell verification for this test (we're in a mock environment)
  export ZSH_TOOL_SKIP_SUBSHELL_VERIFY=1

  zsh-tool-verify >/dev/null 2>&1
  local result=$?

  # Cleanup
  rm -rf "$ZSH"
  unset -f omz
  unset ZSH_HIGHLIGHT_VERSION
  unset ZSH_AUTOSUGGEST_VERSION
  unset ZSH_THEME
  unset ZSH_TOOL_SKIP_SUBSHELL_VERIFY
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH

  return $result
}

# Test: zsh-tool-verify returns 1 on verification failure
test_public_command_fails_on_error() {
  # Cause verification to fail
  local orig_zsh="$ZSH"
  unset ZSH

  zsh-tool-verify >/dev/null 2>&1
  local result=$?

  # Restore
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh"

  # Should have returned 1
  [[ $result -ne 0 ]]
}

# ============================================
# TEST CASES - Security Validation
# ============================================

# Test: Validate name rejects empty names
test_validate_name_rejects_empty() {
  _zsh_tool_validate_name "" "test" >/dev/null 2>&1
  local result=$?
  # Should have failed
  [[ $result -ne 0 ]]
}

# Test: Validate name accepts valid alphanumeric names
test_validate_name_accepts_valid() {
  _zsh_tool_validate_name "git" "plugin" >/dev/null 2>&1 && \
  _zsh_tool_validate_name "zsh-syntax-highlighting" "plugin" >/dev/null 2>&1 && \
  _zsh_tool_validate_name "my_plugin_123" "plugin" >/dev/null 2>&1
}

# Test: Validate name rejects path traversal attempts
test_validate_name_rejects_path_traversal() {
  _zsh_tool_validate_name "../etc/passwd" "theme" >/dev/null 2>&1
  local result=$?
  # Should have failed
  [[ $result -ne 0 ]]
}

# Test: Validate name rejects command injection characters
test_validate_name_rejects_command_injection() {
  # Test various injection attempts
  _zsh_tool_validate_name "plugin;rm -rf /" "plugin" >/dev/null 2>&1
  local result1=$?

  _zsh_tool_validate_name 'plugin$(whoami)' "plugin" >/dev/null 2>&1
  local result2=$?

  _zsh_tool_validate_name 'plugin`id`' "plugin" >/dev/null 2>&1
  local result3=$?

  _zsh_tool_validate_name 'plugin|cat /etc/passwd' "plugin" >/dev/null 2>&1
  local result4=$?

  # All should have failed
  [[ $result1 -ne 0 && $result2 -ne 0 && $result3 -ne 0 && $result4 -ne 0 ]]
}

# Test: Validate name rejects special characters
test_validate_name_rejects_special_chars() {
  _zsh_tool_validate_name "plugin&echo" "plugin" >/dev/null 2>&1
  local result1=$?

  _zsh_tool_validate_name "plugin>file" "plugin" >/dev/null 2>&1
  local result2=$?

  _zsh_tool_validate_name "plugin<file" "plugin" >/dev/null 2>&1
  local result3=$?

  # All should have failed
  [[ $result1 -ne 0 && $result2 -ne 0 && $result3 -ne 0 ]]
}

# Test: Safe YAML parser skips malicious plugin names
test_yaml_parser_skips_malicious_plugins() {
  # Create config with malicious plugin names (use single quotes to prevent expansion)
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<'ENDCONFIG'
plugins:
  - git
  - ../etc/passwd
  - plugin&echo
  - zsh-autosuggestions
  - bad>file

theme: robbyrussell
ENDCONFIG

  # Parse plugins - should only return safe ones
  local plugins=()
  while IFS= read -r plugin; do
    [[ -n "$plugin" ]] && plugins+=("$plugin")
  done < <(_zsh_tool_parse_yaml_list "${ZSH_TOOL_CONFIG_DIR}/config.yaml" "plugins" 2>/dev/null)

  # Restore config for other tests
  setup_test_env

  # Should only have git and zsh-autosuggestions (the 2 valid ones)
  [[ ${#plugins[@]} -eq 2 ]] && \
  [[ "${plugins[1]}" == "git" ]] && \
  [[ "${plugins[2]}" == "zsh-autosuggestions" ]]
}

# Test: Safe theme parser rejects path traversal in theme
test_theme_parser_rejects_path_traversal() {
  # Create config with malicious theme
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
plugins:
  - git

theme: ../../../etc/passwd
EOF

  local theme
  theme=$(_zsh_tool_parse_theme "${ZSH_TOOL_CONFIG_DIR}/config.yaml" 2>/dev/null)
  local result=$?

  # Restore config
  setup_test_env

  # Should have failed or returned empty
  [[ $result -ne 0 || -z "$theme" ]]
}

# Test: Safe theme parser rejects command injection in theme
test_theme_parser_rejects_command_injection() {
  # Create config with malicious theme
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
plugins:
  - git

theme: "robbyrussell;rm -rf /"
EOF

  local theme
  theme=$(_zsh_tool_parse_theme "${ZSH_TOOL_CONFIG_DIR}/config.yaml" 2>/dev/null)
  local result=$?

  # Restore config
  setup_test_env

  # Should have failed or returned empty
  [[ $result -ne 0 || -z "$theme" ]]
}

# Test: Theme check fails with path traversal attempt
test_theme_check_rejects_path_traversal() {
  # Create config with path traversal theme
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<EOF
plugins:
  - git

theme: "../../../etc/passwd"
EOF

  export ZSH_THEME="../../../etc/passwd"

  _zsh_tool_check_theme_applied >/dev/null 2>&1
  local result=$?

  unset ZSH_THEME
  # Restore config
  setup_test_env

  # Check should have failed
  [[ $result -ne 0 ]]
}

# Test: Plugin check handles malicious config gracefully
test_plugin_check_handles_malicious_config() {
  local orig_zsh="$ZSH"
  export ZSH="${PROJECT_ROOT}/.oh-my-zsh-test-security"
  mkdir -p "$ZSH/plugins/git"

  # Create config with mix of valid and malicious plugins (use quoted heredoc)
  cat > "${ZSH_TOOL_CONFIG_DIR}/config.yaml" <<'ENDCONFIG'
plugins:
  - git
  - ../malicious
  - plugin&echo

theme: robbyrussell
ENDCONFIG

  # Should not crash and should skip malicious plugins
  _zsh_tool_check_plugins_loaded >/dev/null 2>&1
  local result=$?

  rm -rf "$ZSH"
  [[ -n "$orig_zsh" ]] && export ZSH="$orig_zsh" || unset ZSH
  # Restore config
  setup_test_env

  # Should succeed (git plugin exists, malicious ones skipped)
  return $result
}

# ============================================
# RUN TESTS
# ============================================

echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}Story 1.7: Installation Verification Tests${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Setup
echo "${YELLOW}Setting up test environment...${NC}"
setup_test_env

# Run tests
echo ""
echo "${BLUE}Oh My Zsh Verification Tests:${NC}"
run_test "OMZ check succeeds when ZSH is set" test_omz_check_with_zsh_set
run_test "OMZ check fails when ZSH not set" test_omz_check_without_zsh
run_test "OMZ check fails when oh-my-zsh.sh missing" test_omz_check_without_omz_sh
run_test "OMZ check fails when omz function not defined" test_omz_check_without_omz_function

echo ""
echo "${BLUE}Plugin Verification Tests:${NC}"
run_test "Plugin check succeeds with no plugins" test_plugin_check_no_plugins
run_test "Plugin check fails when config missing" test_plugin_check_no_config
run_test "Plugin check detects zsh-syntax-highlighting" test_plugin_check_syntax_highlighting
run_test "Plugin check fails without syntax-highlighting" test_plugin_check_missing_syntax_highlighting
run_test "Plugin check detects zsh-autosuggestions" test_plugin_check_autosuggestions
run_test "Plugin check handles generic plugins" test_plugin_check_generic_plugin

echo ""
echo "${BLUE}Theme Verification Tests:${NC}"
run_test "Theme check succeeds when theme matches" test_theme_check_matches
run_test "Theme check fails when theme mismatch" test_theme_check_mismatch
run_test "Theme check fails when config missing" test_theme_check_no_config
run_test "Theme check succeeds with no theme configured" test_theme_check_no_theme
run_test "Theme check fails when theme file missing" test_theme_check_theme_file_missing

echo ""
echo "${BLUE}Summary Display Tests:${NC}"
run_test "Summary displays without errors" test_summary_display_succeeds
run_test "Summary displays installation timing" test_summary_display_timing
run_test "Summary displays backup information" test_summary_display_backup
run_test "Summary displays configured plugins" test_summary_display_plugins
run_test "Summary displays theme" test_summary_display_theme
run_test "Summary displays custom layer when exists" test_summary_display_custom_layer

echo ""
echo "${BLUE}Verification Integration Tests:${NC}"
run_test "Verification passes with all checks passing" test_verification_passes
run_test "Verification fails when OMZ not loaded" test_verification_fails_omz
run_test "Verification fails when plugins not loaded" test_verification_fails_plugins
run_test "Verification fails when theme not applied" test_verification_fails_theme
run_test "Verification displays remediation on failure" test_verification_remediation_display

echo ""
echo "${BLUE}Public Command Tests:${NC}"
run_test "zsh-tool-verify command exists" test_public_command_exists
run_test "zsh-tool-verify runs without errors" test_public_command_runs
run_test "zsh-tool-verify returns 1 on verification failure" test_public_command_fails_on_error

echo ""
echo "${BLUE}Security Validation Tests:${NC}"
run_test "Validate name rejects empty names" test_validate_name_rejects_empty
run_test "Validate name accepts valid alphanumeric names" test_validate_name_accepts_valid
run_test "Validate name rejects path traversal" test_validate_name_rejects_path_traversal
run_test "Validate name rejects command injection" test_validate_name_rejects_command_injection
run_test "Validate name rejects special characters" test_validate_name_rejects_special_chars
run_test "YAML parser skips malicious plugins" test_yaml_parser_skips_malicious_plugins
run_test "Theme parser rejects path traversal" test_theme_parser_rejects_path_traversal
run_test "Theme parser rejects command injection" test_theme_parser_rejects_command_injection
run_test "Theme check rejects path traversal" test_theme_check_rejects_path_traversal
run_test "Plugin check handles malicious config" test_plugin_check_handles_malicious_config

# Cleanup
echo ""
echo "${YELLOW}Cleaning up test environment...${NC}"
cleanup_test_env

# Summary
echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}Test Summary:${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Total: $TESTS_RUN"
echo "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo "  ${RED}Failed: $TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo ""
  echo "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo ""
  echo "${RED}✗ Some tests failed${NC}"
  exit 1
fi
