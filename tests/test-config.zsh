#!/usr/bin/env zsh
# Stories 1.3 & 1.6: Configuration and Customization Layer Tests
# Tests for lib/install/config.zsh
# Story 1.3: Team configuration installation
# Story 1.6: Personal customization layer

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
  source "${PROJECT_ROOT}/lib/install/config.zsh"

  # Override config directory AFTER sourcing (utils.zsh sets defaults)
  TEST_TMP_DIR=$(mktemp -d)
  ZSH_TOOL_CONFIG_DIR="${TEST_TMP_DIR}/config"
  ZSH_TOOL_LOG_FILE="${ZSH_TOOL_CONFIG_DIR}/logs/zsh-tool.log"
  ZSH_TOOL_STATE_FILE="${ZSH_TOOL_CONFIG_DIR}/state.json"
  ZSH_TOOL_TEMPLATE_DIR="${PROJECT_ROOT}/templates"

  # Create test home directory
  TEST_HOME="${TEST_TMP_DIR}/home"
  mkdir -p "${TEST_HOME}"
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/logs"
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}/templates"

  # Initialize state file for tests
  echo '{"version":"1.0.0","installed":false}' > "$ZSH_TOOL_STATE_FILE"

  # Copy config.yaml and templates for testing
  cp "${PROJECT_ROOT}/templates/config.yaml" "${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  cp "${PROJECT_ROOT}/templates/zshrc.template" "${ZSH_TOOL_CONFIG_DIR}/templates/zshrc.template"

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

# Create mock .zshrc with existing content
create_mock_zshrc() {
  cat > "${HOME}/.zshrc" <<'EOF'
# User's existing configuration
export MY_CUSTOM_VAR="custom_value"
alias mycmd="echo hello"

# Some important path
export PATH="/my/custom/path:$PATH"
EOF
}

# Create mock .zshrc with managed section
create_mock_zshrc_with_managed() {
  cat > "${HOME}/.zshrc" <<'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
# Old managed content
export OLD_MANAGED="value"
# ===== ZSH-TOOL MANAGED SECTION END =====

# User's custom config outside managed section
export OUTSIDE_MANAGED="preserved"
EOF
}

# ============================================
# TEST CASES - FUNCTION EXISTENCE
# ============================================

# Test: All required config functions are defined
test_all_config_functions_defined() {
  typeset -f _zsh_tool_load_config >/dev/null 2>&1 && \
  typeset -f _zsh_tool_parse_plugins >/dev/null 2>&1 && \
  typeset -f _zsh_tool_parse_theme >/dev/null 2>&1 && \
  typeset -f _zsh_tool_parse_aliases >/dev/null 2>&1 && \
  typeset -f _zsh_tool_parse_exports >/dev/null 2>&1 && \
  typeset -f _zsh_tool_parse_paths >/dev/null 2>&1 && \
  typeset -f _zsh_tool_generate_zshrc >/dev/null 2>&1 && \
  typeset -f _zsh_tool_install_config >/dev/null 2>&1 && \
  typeset -f _zsh_tool_setup_custom_layer >/dev/null 2>&1
}

# Test: Advanced config functions are defined
test_advanced_config_functions_defined() {
  typeset -f _zsh_tool_extract_yaml_section >/dev/null 2>&1 && \
  typeset -f _zsh_tool_parse_amazon_q_enabled >/dev/null 2>&1 && \
  typeset -f _zsh_tool_parse_atuin_enabled >/dev/null 2>&1
}

# Test: Functions follow naming convention
test_config_naming_convention() {
  local funcs=$(typeset -f | grep "^_zsh_tool_.*\(config\|parse\|generate\)" | wc -l)
  [[ $funcs -ge 5 ]]
}

# ============================================
# TEST CASES - CONFIG LOADING (Task 4.1)
# ============================================

# Test: Config loading with valid file
test_config_load_valid() {
  local config=$(_zsh_tool_load_config 2>/dev/null)
  [[ -n "$config" ]] && echo "$config" | grep -q "version:"
}

# Test: Config loading with missing file fails gracefully
test_config_load_missing() {
  # Temporarily remove config file
  local orig_config="${ZSH_TOOL_CONFIG_DIR}/config.yaml"
  mv "$orig_config" "${orig_config}.bak" 2>/dev/null

  local config=$(_zsh_tool_load_config 2>/dev/null)
  local result=$?

  # Restore config file
  mv "${orig_config}.bak" "$orig_config" 2>/dev/null

  [[ $result -ne 0 ]] || [[ -z "$config" ]]
}

# ============================================
# TEST CASES - YAML PARSING (Tasks 4.2-4.6)
# ============================================

# Test: Plugin parsing from YAML
test_parse_plugins() {
  local plugins=$(_zsh_tool_parse_plugins 2>/dev/null)
  # Should contain git and docker from default config
  echo "$plugins" | grep -q "git" && echo "$plugins" | grep -q "docker"
}

# Test: Theme parsing from YAML
test_parse_theme() {
  local theme=$(_zsh_tool_parse_theme 2>/dev/null)
  [[ "$theme" == "robbyrussell" ]]
}

# Test: Alias parsing and command generation
test_parse_aliases() {
  local aliases=$(_zsh_tool_parse_aliases 2>/dev/null)
  # Should generate alias statements
  echo "$aliases" | grep -q 'alias gs="git status"' && \
  echo "$aliases" | grep -q 'alias gp="git pull"'
}

# Test: Export parsing and statement generation
test_parse_exports() {
  local exports=$(_zsh_tool_parse_exports 2>/dev/null)
  # Should generate export statements
  echo "$exports" | grep -q 'export EDITOR="vim"'
}

# Test: PATH parsing with paths section
test_parse_paths() {
  local paths=$(_zsh_tool_parse_paths 2>/dev/null)
  # Should generate PATH modifications (note: variable expansion happens)
  [[ -n "$paths" ]] && echo "$paths" | grep -q "export PATH="
}

# ============================================
# TEST CASES - YAML SECTION EXTRACTION
# ============================================

# Test: Extract YAML section helper
test_extract_yaml_section() {
  local config=$(_zsh_tool_load_config 2>/dev/null)
  local section=$(_zsh_tool_extract_yaml_section "atuin" "$config")
  echo "$section" | grep -q "enabled:" && echo "$section" | grep -q "search_mode:"
}

# Test: Atuin configuration parsing
test_parse_atuin_config() {
  local enabled=$(_zsh_tool_parse_atuin_enabled 2>/dev/null)
  local search_mode=$(_zsh_tool_parse_atuin_search_mode 2>/dev/null)
  [[ "$enabled" == "true" ]] && [[ "$search_mode" == "fuzzy" ]]
}

# Test: Amazon Q configuration parsing
test_parse_amazon_q_config() {
  local enabled=$(_zsh_tool_parse_amazon_q_enabled 2>/dev/null)
  local lazy=$(_zsh_tool_parse_amazon_q_lazy_loading 2>/dev/null)
  [[ "$enabled" == "false" ]] && [[ "$lazy" == "true" ]]
}

# Test: Amazon Q disabled_clis parsing
test_parse_amazon_q_disabled_clis() {
  local disabled=$(_zsh_tool_parse_amazon_q_disabled_clis 2>/dev/null)
  # Should contain 'atuin' from default config
  echo "$disabled" | grep -q "atuin"
}

# Test: Config cache mtime validation
test_config_cache_mtime_validation() {
  # Load config to populate cache
  _zsh_tool_load_config >/dev/null 2>&1

  # Modify config file (touch changes mtime)
  sleep 1  # Ensure different mtime
  touch "${ZSH_TOOL_CONFIG_DIR}/config.yaml"

  # Cache should be invalidated and reload
  local config=$(_zsh_tool_load_config 2>/dev/null)
  [[ -n "$config" ]] && echo "$config" | grep -q "version:"
}

# ============================================
# TEST CASES - ZSHRC GENERATION (Task 4.7)
# ============================================

# Test: Generate zshrc replaces all placeholders
test_generate_zshrc_placeholders() {
  local content=$(_zsh_tool_generate_zshrc 2>/dev/null)

  # Verify placeholders are replaced
  [[ -n "$content" ]] && \
  echo "$content" | grep -q "ZSH_THEME=" && \
  echo "$content" | grep -q "plugins=(" && \
  ! echo "$content" | grep -q "{{.*}}"  # No unreplaced placeholders
}

# Test: Generated zshrc has managed section markers
test_generate_zshrc_markers() {
  local content=$(_zsh_tool_generate_zshrc 2>/dev/null)
  echo "$content" | grep -q "ZSH-TOOL MANAGED SECTION BEGIN" && \
  echo "$content" | grep -q "ZSH-TOOL MANAGED SECTION END"
}

# Test: Generated zshrc sources oh-my-zsh
test_generate_zshrc_omz_source() {
  local content=$(_zsh_tool_generate_zshrc 2>/dev/null)
  echo "$content" | grep -q "source \$ZSH/oh-my-zsh.sh"
}

# Test: Generated zshrc includes .zshrc.local sourcing
test_generate_zshrc_local_source() {
  local content=$(_zsh_tool_generate_zshrc 2>/dev/null)
  echo "$content" | grep -q ".zshrc.local"
}

# ============================================
# TEST CASES - INSTALLATION (Tasks 4.8-4.9)
# ============================================

# Test: Install creates .zshrc
test_install_creates_zshrc() {
  # Remove any existing .zshrc
  rm -f "${HOME}/.zshrc"

  _zsh_tool_install_config >/dev/null 2>&1
  [[ -f "${HOME}/.zshrc" ]]
}

# Test: Install preserves user content to .zshrc.local
test_install_preserves_user_content() {
  create_mock_zshrc
  rm -f "${HOME}/.zshrc.local"  # Ensure no existing .zshrc.local

  _zsh_tool_install_config >/dev/null 2>&1

  # User content should be in .zshrc.local
  [[ -f "${HOME}/.zshrc.local" ]] && \
  grep -q "MY_CUSTOM_VAR" "${HOME}/.zshrc.local"
}

# Test: Install content outside managed section is preserved
test_install_preserves_outside_managed() {
  create_mock_zshrc_with_managed
  rm -f "${HOME}/.zshrc.local"

  _zsh_tool_install_config >/dev/null 2>&1

  # Content outside managed section should be in .zshrc.local
  [[ -f "${HOME}/.zshrc.local" ]] && \
  grep -q "OUTSIDE_MANAGED" "${HOME}/.zshrc.local"
}

# ============================================
# TEST CASES - CUSTOM LAYER (Task 4.9)
# ============================================

# Test: Setup custom layer creates .zshrc.local template
test_setup_custom_layer_creates_template() {
  rm -f "${HOME}/.zshrc.local"

  _zsh_tool_setup_custom_layer >/dev/null 2>&1

  [[ -f "${HOME}/.zshrc.local" ]] && \
  grep -q "Personal zsh customizations" "${HOME}/.zshrc.local"
}

# Test: Setup custom layer skips if .zshrc.local exists
test_setup_custom_layer_skips_existing() {
  echo "# My existing customizations" > "${HOME}/.zshrc.local"

  _zsh_tool_setup_custom_layer >/dev/null 2>&1

  grep -q "My existing customizations" "${HOME}/.zshrc.local"
}

# ============================================
# TEST CASES - IDEMPOTENCY (Task 4.10)
# ============================================

# Test: Running install twice produces consistent result
test_install_idempotency() {
  rm -f "${HOME}/.zshrc"
  rm -f "${HOME}/.zshrc.local"

  # First install
  _zsh_tool_install_config >/dev/null 2>&1
  local first_content=$(cat "${HOME}/.zshrc" | grep -v "Last updated:")

  # Second install
  _zsh_tool_install_config >/dev/null 2>&1
  local second_content=$(cat "${HOME}/.zshrc" | grep -v "Last updated:")

  # Content should be same (except timestamp)
  [[ "$first_content" == "$second_content" ]]
}

# Test: Multiple installs don't duplicate .zshrc.local migrations
test_install_no_duplicate_migrations() {
  create_mock_zshrc
  rm -f "${HOME}/.zshrc.local"

  # First install (creates .zshrc.local)
  _zsh_tool_install_config >/dev/null 2>&1
  local first_size=$(wc -l < "${HOME}/.zshrc.local")

  # Second install (should not modify .zshrc.local)
  _zsh_tool_install_config >/dev/null 2>&1
  local second_size=$(wc -l < "${HOME}/.zshrc.local")

  [[ "$first_size" == "$second_size" ]]
}

# ============================================
# TEST CASES - STATE UPDATE (Task 4.11)
# ============================================

# Test: Install updates state with config_installed
test_install_updates_state() {
  rm -f "${HOME}/.zshrc"

  _zsh_tool_install_config >/dev/null 2>&1

  grep -q '"config_installed":true' "$ZSH_TOOL_STATE_FILE"
}

# ============================================
# TEST CASES - ERROR HANDLING
# ============================================

# Test: Generate zshrc fails with missing template
test_generate_zshrc_missing_template() {
  # Temporarily change template dir
  local orig_template_dir="$ZSH_TOOL_TEMPLATE_DIR"
  ZSH_TOOL_TEMPLATE_DIR="${TEST_TMP_DIR}/nonexistent"

  local content=$(_zsh_tool_generate_zshrc 2>/dev/null)
  local result=$?

  ZSH_TOOL_TEMPLATE_DIR="$orig_template_dir"

  [[ $result -ne 0 ]] || [[ -z "$content" ]]
}

# Test: Install fails gracefully with missing template
test_install_fails_with_missing_template() {
  local orig_template_dir="$ZSH_TOOL_TEMPLATE_DIR"
  ZSH_TOOL_TEMPLATE_DIR="${TEST_TMP_DIR}/nonexistent"

  _zsh_tool_install_config >/dev/null 2>&1
  local result=$?

  ZSH_TOOL_TEMPLATE_DIR="$orig_template_dir"

  [[ $result -ne 0 ]]
}

# ============================================
# TEST CASES - INTEGRATION
# ============================================

# Test: Full workflow - fresh install
test_full_workflow_fresh_install() {
  rm -f "${HOME}/.zshrc"
  rm -f "${HOME}/.zshrc.local"

  # Install config
  _zsh_tool_install_config >/dev/null 2>&1 || return 1

  # Setup custom layer
  _zsh_tool_setup_custom_layer >/dev/null 2>&1 || return 1

  # Verify
  [[ -f "${HOME}/.zshrc" ]] && \
  [[ -f "${HOME}/.zshrc.local" ]] && \
  grep -q "ZSH-TOOL MANAGED SECTION" "${HOME}/.zshrc" && \
  grep -q '"config_installed":true' "$ZSH_TOOL_STATE_FILE"
}

# Test: Full workflow - upgrade existing config
test_full_workflow_upgrade() {
  create_mock_zshrc
  rm -f "${HOME}/.zshrc.local"

  # Install config (should migrate existing content)
  _zsh_tool_install_config >/dev/null 2>&1 || return 1

  # Verify migration
  [[ -f "${HOME}/.zshrc.local" ]] && \
  grep -q "MY_CUSTOM_VAR" "${HOME}/.zshrc.local" && \
  grep -q "ZSH-TOOL MANAGED SECTION" "${HOME}/.zshrc"
}

# ============================================
# RUN ALL TESTS
# ============================================

echo ""
echo "${BLUE}========================================${NC}"
echo "${BLUE}  Story 1.3: Config Tests${NC}"
echo "${BLUE}========================================${NC}"
echo ""

# Setup
echo "${YELLOW}Setting up test environment...${NC}"
setup_test_env

# Function Existence Tests
echo ""
echo "${BLUE}Function Existence Tests${NC}"
run_test "All config functions defined" test_all_config_functions_defined
run_test "Advanced config functions defined" test_advanced_config_functions_defined
run_test "Functions follow naming convention" test_config_naming_convention

# Config Loading Tests
echo ""
echo "${BLUE}Config Loading Tests${NC}"
run_test "Config load with valid file" test_config_load_valid
run_test "Config load with missing file fails gracefully" test_config_load_missing

# YAML Parsing Tests
echo ""
echo "${BLUE}YAML Parsing Tests${NC}"
run_test "Plugin parsing from YAML" test_parse_plugins
run_test "Theme parsing from YAML" test_parse_theme
run_test "Alias parsing and command generation" test_parse_aliases
run_test "Export parsing and statement generation" test_parse_exports
run_test "PATH parsing" test_parse_paths

# YAML Section Extraction Tests
echo ""
echo "${BLUE}YAML Section Extraction Tests${NC}"
run_test "Extract YAML section helper" test_extract_yaml_section
run_test "Atuin configuration parsing" test_parse_atuin_config
run_test "Amazon Q configuration parsing" test_parse_amazon_q_config
run_test "Amazon Q disabled_clis parsing" test_parse_amazon_q_disabled_clis
cleanup_test_env
setup_test_env
run_test "Config cache mtime validation" test_config_cache_mtime_validation

# ZSHRC Generation Tests
echo ""
echo "${BLUE}ZSHRC Generation Tests${NC}"
run_test "Generate zshrc replaces all placeholders" test_generate_zshrc_placeholders
run_test "Generated zshrc has managed section markers" test_generate_zshrc_markers
run_test "Generated zshrc sources oh-my-zsh" test_generate_zshrc_omz_source
run_test "Generated zshrc includes .zshrc.local sourcing" test_generate_zshrc_local_source

# Installation Tests
echo ""
echo "${BLUE}Installation Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Install creates .zshrc" test_install_creates_zshrc
cleanup_test_env
setup_test_env
run_test "Install preserves user content to .zshrc.local" test_install_preserves_user_content
cleanup_test_env
setup_test_env
run_test "Install preserves content outside managed section" test_install_preserves_outside_managed

# Custom Layer Tests
echo ""
echo "${BLUE}Custom Layer Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Setup custom layer creates .zshrc.local template" test_setup_custom_layer_creates_template
cleanup_test_env
setup_test_env
run_test "Setup custom layer skips if .zshrc.local exists" test_setup_custom_layer_skips_existing

# Idempotency Tests
echo ""
echo "${BLUE}Idempotency Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Running install twice produces consistent result" test_install_idempotency
cleanup_test_env
setup_test_env
run_test "Multiple installs don't duplicate migrations" test_install_no_duplicate_migrations

# State Update Tests
echo ""
echo "${BLUE}State Update Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Install updates state with config_installed" test_install_updates_state

# Error Handling Tests
echo ""
echo "${BLUE}Error Handling Tests${NC}"
run_test "Generate zshrc fails with missing template" test_generate_zshrc_missing_template
cleanup_test_env
setup_test_env
run_test "Install fails with missing template" test_install_fails_with_missing_template

# Integration Tests
echo ""
echo "${BLUE}Integration Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Full workflow - fresh install" test_full_workflow_fresh_install
cleanup_test_env
setup_test_env
run_test "Full workflow - upgrade existing config" test_full_workflow_upgrade

# ============================================
# TEST CASES - STORY 1.6: CUSTOM LAYER
# ============================================

# Test: Path validation prevents path traversal
test_path_validation_traversal() {
  _zsh_tool_validate_path "../../../etc/passwd" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Path validation prevents tilde expansion attacks
test_path_validation_tilde() {
  _zsh_tool_validate_path "~root/.ssh/authorized_keys" 2>/dev/null
  [[ $? -ne 0 ]]
}

# Test: Path validation allows valid paths
test_path_validation_valid() {
  _zsh_tool_validate_path "${HOME}/.zshrc.local" 2>/dev/null
  [[ $? -eq 0 ]]
}

# Test: Preserve user config creates .zshrc.local from .zshrc content
test_preserve_user_config_creates() {
  create_mock_zshrc
  rm -f "${HOME}/.zshrc.local"

  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1

  [[ -f "${HOME}/.zshrc.local" ]] && \
  grep -q "MY_CUSTOM_VAR" "${HOME}/.zshrc.local"
}

# Test: Preserve user config merges into existing .zshrc.local
test_preserve_user_config_merges() {
  echo "# Existing custom config" > "${HOME}/.zshrc.local"
  create_mock_zshrc

  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1

  grep -q "Existing custom config" "${HOME}/.zshrc.local" && \
  grep -q "MY_CUSTOM_VAR" "${HOME}/.zshrc.local"
}

# Test: Preserve user config escapes sed patterns
test_preserve_user_config_sed_escaping() {
  cat > "${HOME}/.zshrc" <<'EOF'
# User config with special chars
export PATH="/path/with/$(command):$PATH"
alias cmd='echo "test"'
EOF

  rm -f "${HOME}/.zshrc.local"
  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1

  [[ -f "${HOME}/.zshrc.local" ]] && \
  grep -q 'echo "test"' "${HOME}/.zshrc.local"
}

# Test: Preserve user config updates state
test_preserve_user_config_state() {
  create_mock_zshrc
  rm -f "${HOME}/.zshrc.local"

  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1

  grep -q '"custom_layer_migrated":true' "$ZSH_TOOL_STATE_FILE"
}

# Test: Preserve user config with atomic write
test_preserve_user_config_atomic() {
  create_mock_zshrc
  rm -f "${HOME}/.zshrc.local"

  # Preserve should not leave temp files
  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1

  [[ ! -f "${HOME}/.zshrc.local.tmp."* ]]
}

# Test: Setup custom layer with state update
test_setup_custom_layer_state() {
  rm -f "${HOME}/.zshrc.local"

  _zsh_tool_setup_custom_layer >/dev/null 2>&1

  grep -q '"custom_layer_setup":true' "$ZSH_TOOL_STATE_FILE"
}

# Test: Setup custom layer with atomic write
test_setup_custom_layer_atomic() {
  rm -f "${HOME}/.zshrc.local"

  _zsh_tool_setup_custom_layer >/dev/null 2>&1

  [[ -f "${HOME}/.zshrc.local" ]] && \
  [[ ! -f "${HOME}/.zshrc.local.tmp."* ]]
}

# Test: Public command zsh-tool-config exists
test_public_command_exists() {
  typeset -f zsh-tool-config >/dev/null 2>&1
}

# Test: Config custom shows status
test_config_custom_shows_status() {
  rm -f "${HOME}/.zshrc.local"
  _zsh_tool_setup_custom_layer >/dev/null 2>&1

  local output=$(_zsh_tool_config_custom 2>/dev/null)
  echo "$output" | grep -q "Custom Layer Status"
}

# Test: Config show displays all sources
test_config_show_displays_sources() {
  local output=$(_zsh_tool_config_show 2>/dev/null)
  echo "$output" | grep -q "Configuration Sources" && \
  echo "$output" | grep -q ".zshrc" && \
  echo "$output" | grep -q "config.yaml"
}

# Test: Config custom returns error if no .zshrc.local
test_config_custom_error_no_local() {
  rm -f "${HOME}/.zshrc.local"

  _zsh_tool_config_custom >/dev/null 2>&1
  [[ $? -ne 0 ]]
}

# Test: Idempotency - multiple preserve calls don't duplicate
test_preserve_idempotency() {
  create_mock_zshrc
  rm -f "${HOME}/.zshrc.local"

  # First preserve
  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1
  local first_content=$(cat "${HOME}/.zshrc.local")

  # Install (which replaces .zshrc with managed content)
  _zsh_tool_install_config >/dev/null 2>&1

  # Second preserve (should skip - no user content outside managed section)
  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1
  local second_content=$(cat "${HOME}/.zshrc.local")

  # The .zshrc.local should not have new migrations appended (only first migration)
  local migration_count=$(grep -c "Migrated from .zshrc" "${HOME}/.zshrc.local" 2>/dev/null || echo "0")
  [[ "$migration_count" -le 1 ]]
}

# Test: Install config calls setup custom layer
test_install_calls_custom_layer() {
  rm -f "${HOME}/.zshrc"
  rm -f "${HOME}/.zshrc.local"

  _zsh_tool_install_config >/dev/null 2>&1

  [[ -f "${HOME}/.zshrc.local" ]]
}

# Test: Install preserves permissions on .zshrc
test_install_preserves_permissions() {
  echo "# Old config" > "${HOME}/.zshrc"
  chmod 600 "${HOME}/.zshrc"

  _zsh_tool_install_config >/dev/null 2>&1

  local perms=$(stat -f "%OLp" "${HOME}/.zshrc" 2>/dev/null || stat -c "%a" "${HOME}/.zshrc" 2>/dev/null)
  [[ "$perms" == "600" ]]
}

# Test: Template contains source line for .zshrc.local
test_template_sources_local() {
  local content=$(_zsh_tool_generate_zshrc 2>/dev/null)
  echo "$content" | grep -q '\[\[ -f ~/.zshrc.local \]\] && source ~/.zshrc.local'
}

# Test: zsh-tool-config without args defaults to show
test_config_no_args_usage() {
  local output=$(zsh-tool-config 2>&1)
  echo "$output" | grep -q "Configuration Sources"
}

# Test: zsh-tool-config with invalid subcommand shows usage
test_config_invalid_subcommand() {
  zsh-tool-config invalid-cmd >/dev/null 2>&1
  [[ $? -ne 0 ]]
}

# Story 1.6 Custom Layer Tests
echo ""
echo "${BLUE}Story 1.6: Custom Layer Security Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Path validation prevents path traversal" test_path_validation_traversal
run_test "Path validation prevents tilde expansion" test_path_validation_tilde
run_test "Path validation allows valid paths" test_path_validation_valid

echo ""
echo "${BLUE}Story 1.6: Preserve User Config Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Preserve creates .zshrc.local from .zshrc" test_preserve_user_config_creates
cleanup_test_env
setup_test_env
run_test "Preserve merges into existing .zshrc.local" test_preserve_user_config_merges
cleanup_test_env
setup_test_env
run_test "Preserve escapes sed patterns correctly" test_preserve_user_config_sed_escaping
cleanup_test_env
setup_test_env
run_test "Preserve updates state" test_preserve_user_config_state
cleanup_test_env
setup_test_env
run_test "Preserve uses atomic write" test_preserve_user_config_atomic

echo ""
echo "${BLUE}Story 1.6: Setup Custom Layer Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Setup updates state" test_setup_custom_layer_state
cleanup_test_env
setup_test_env
run_test "Setup uses atomic write" test_setup_custom_layer_atomic

echo ""
echo "${BLUE}Story 1.6: Public Command Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Public command zsh-tool-config exists" test_public_command_exists
cleanup_test_env
setup_test_env
run_test "Config custom shows status" test_config_custom_shows_status
run_test "Config show displays all sources" test_config_show_displays_sources
cleanup_test_env
setup_test_env
run_test "Config custom errors if no .zshrc.local" test_config_custom_error_no_local
run_test "Config without args defaults to show" test_config_no_args_usage
run_test "Config with invalid subcommand shows usage" test_config_invalid_subcommand

echo ""
echo "${BLUE}Story 1.6: Idempotency and Integration Tests${NC}"
cleanup_test_env
setup_test_env
run_test "Multiple preserve calls don't duplicate" test_preserve_idempotency
cleanup_test_env
setup_test_env
run_test "Install calls custom layer setup" test_install_calls_custom_layer
cleanup_test_env
setup_test_env
run_test "Install preserves .zshrc permissions" test_install_preserves_permissions
run_test "Template sources .zshrc.local" test_template_sources_local

# ============================================
# TEST CASES - ADVERSARIAL REVIEW FIXES (2026-01-04)
# ============================================

# Test: Generated zshrc has no duplicate source lines
test_no_duplicate_source_lines() {
  local content=$(_zsh_tool_generate_zshrc 2>/dev/null)
  # Count actual source command lines (not comments mentioning .zshrc.local)
  local source_count=$(echo "$content" | grep -c "source.*\.zshrc\.local")
  [[ "$source_count" -eq 1 ]]
}

# Test: Dedupe function removes duplicate source lines
test_dedupe_source_lines_function() {
  local content="line1
source ~/.zshrc.local
line2
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
line3
source \$HOME/.zshrc.local"

  local result=$(_zsh_tool_dedupe_source_lines "$content")
  local source_count=$(echo "$result" | grep -c "\.zshrc\.local")
  [[ "$source_count" -eq 1 ]]
}

# Test: Preserve handles malformed markers (missing end)
test_preserve_malformed_markers_missing_end() {
  cat > "${HOME}/.zshrc" <<'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
# Some content
export VAR="value"
# Missing end marker
EOF

  rm -f "${HOME}/.zshrc.local"
  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1
  local result=$?

  # Should succeed but not create .zshrc.local (skips to avoid data loss)
  [[ $result -eq 0 ]] && [[ ! -f "${HOME}/.zshrc.local" ]]
}

# Test: Preserve handles malformed markers (missing begin)
test_preserve_malformed_markers_missing_begin() {
  cat > "${HOME}/.zshrc" <<'EOF'
# Some content
export VAR="value"
# ===== ZSH-TOOL MANAGED SECTION END =====
EOF

  rm -f "${HOME}/.zshrc.local"
  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1
  local result=$?

  # Should succeed but not create .zshrc.local (skips to avoid data loss)
  [[ $result -eq 0 ]] && [[ ! -f "${HOME}/.zshrc.local" ]]
}

# Test: Preserve handles duplicate markers gracefully
test_preserve_duplicate_markers() {
  cat > "${HOME}/.zshrc" <<'EOF'
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
content1
# ===== ZSH-TOOL MANAGED SECTION END =====
user content
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
content2
# ===== ZSH-TOOL MANAGED SECTION END =====
EOF

  rm -f "${HOME}/.zshrc.local"
  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1
  local result=$?

  # Should succeed but not create .zshrc.local (skips due to duplicate markers)
  [[ $result -eq 0 ]] && [[ ! -f "${HOME}/.zshrc.local" ]]
}

# Test: Rollback on migration failure - verify backup is created before migration
test_preserve_rollback_on_failure() {
  # Create existing .zshrc.local with known content
  echo "# Original content" > "${HOME}/.zshrc.local"

  # Create .zshrc with user content that will trigger migration
  cat > "${HOME}/.zshrc" <<'EOF'
export USER_VAR="test"
EOF

  # Run preserve - backup should be created
  _zsh_tool_preserve_user_config "${HOME}/.zshrc" >/dev/null 2>&1

  # Check that backup was created (backup is kept on success)
  local backup_exists=false
  setopt nullglob 2>/dev/null || true
  for f in "${HOME}/.zshrc.local.backup."*; do
    if [[ -f "$f" ]]; then
      backup_exists=true
      rm -f "$f"
    fi
  done
  unsetopt nullglob 2>/dev/null || true

  # Clean up
  rm -f "${HOME}/.zshrc.local"

  $backup_exists
}

# Story 1.6 Adversarial Review Fix Tests
echo ""
echo "${BLUE}Story 1.6: Adversarial Review Fixes (2026-01-04)${NC}"
cleanup_test_env
setup_test_env
run_test "Generated zshrc has no duplicate source lines" test_no_duplicate_source_lines
run_test "Dedupe function removes duplicate source lines" test_dedupe_source_lines_function
cleanup_test_env
setup_test_env
run_test "Preserve handles malformed markers (missing end)" test_preserve_malformed_markers_missing_end
cleanup_test_env
setup_test_env
run_test "Preserve handles malformed markers (missing begin)" test_preserve_malformed_markers_missing_begin
cleanup_test_env
setup_test_env
run_test "Preserve handles duplicate markers gracefully" test_preserve_duplicate_markers
cleanup_test_env
setup_test_env
run_test "Rollback creates backup on migration" test_preserve_rollback_on_failure

# Cleanup
echo ""
echo "${YELLOW}Cleaning up test environment...${NC}"
cleanup_test_env

# Summary
echo ""
echo "${BLUE}========================================${NC}"
echo "${BLUE}  Test Summary${NC}"
echo "${BLUE}========================================${NC}"
echo ""
echo "Tests run:    ${TESTS_RUN}"
echo "${GREEN}Tests passed: ${TESTS_PASSED}${NC}"
echo "${RED}Tests failed: ${TESTS_FAILED}${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo "${RED}Some tests failed!${NC}"
  exit 1
fi
