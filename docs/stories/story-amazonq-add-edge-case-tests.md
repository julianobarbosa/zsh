# Story: Add Edge Case Test Coverage

**Story ID**: ZSHTOOL-TEST-009
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Medium
**Estimate**: 5 points
**Status**: To Do
**Created**: 2025-10-02
**Labels**: testing, enhancement, medium-priority

## Story

As a developer, I want comprehensive edge case tests for Amazon Q integration, so that common failure scenarios are caught before reaching production.

## Context

The current test suite lacks coverage for edge cases that could cause security issues, configuration corruption, or silent failures in production environments.

## Missing Test Coverage

### 1. Invalid JSON Handling
- Malformed JSON in settings file
- Missing closing braces
- Invalid escaping
- Verify error handling

### 2. Special Characters in CLI Names
- Sed metacharacters (/, *, ., [, ])
- Shell metacharacters ($, `, |, &, ;)
- Quotes (' and ")
- Newlines and tabs
- Unicode characters

### 3. Permission Scenarios
- Read-only config directory
- Unwritable settings file
- Read-only .zshrc
- Verify graceful failure

### 4. Concurrent Execution
- Simultaneous configure_settings calls
- Race conditions
- File corruption

### 5. Disk Space Issues
- Full disk during mkdir
- Full disk during file write

### 6. PATH Edge Cases
- q command not in PATH
- q shadowed by alias
- q in non-standard location

### 7. Symlink Edge Cases
- Symlinked .zshrc
- Symlinked config directory

### 8. Existing Configuration
- Partial installation
- Conflicting shell integration
- Multiple lazy loading blocks

## Acceptance Criteria

- [ ] All edge case categories have tests
- [ ] Security-related tests prioritized
- [ ] Tests verify proper error handling
- [ ] Tests verify error messages are clear
- [ ] All tests pass
- [ ] Test suite runs in reasonable time

## Tasks/Subtasks

- [ ] **Task 1: Create edge case test file**
  - [ ] Create `tests/test-amazon-q-edge-cases.zsh`
  - [ ] Setup test framework and helpers

- [ ] **Task 2: Add security tests (HIGH priority)**
  - [ ] Test command injection attempts
  - [ ] Test special characters in CLI names
  - [ ] Test sed/shell metacharacters
  - [ ] Verify proper rejection/escaping

- [ ] **Task 3: Add file system tests (MEDIUM priority)**
  - [ ] Test invalid JSON handling
  - [ ] Test permission denied scenarios
  - [ ] Test with read-only filesystem
  - [ ] Test disk full scenarios (mocked)

- [ ] **Task 4: Add configuration tests (MEDIUM priority)**
  - [ ] Test partial installations
  - [ ] Test conflicting configurations
  - [ ] Test symlinked files
  - [ ] Test idempotent behavior

- [ ] **Task 5: Add concurrent execution tests (LOW priority)**
  - [ ] Test parallel configure_settings
  - [ ] Verify no race conditions
  - [ ] Verify no file corruption

- [ ] **Task 6: Integrate into test suite**
  - [ ] Add to main test runner
  - [ ] Update CI/CD to run edge case tests
  - [ ] Document test categories

## Technical Implementation

### Edge Case Test File Structure

```zsh
#!/usr/bin/env zsh
# Edge case tests for Amazon Q integration

# Security Tests
test_security_command_injection() {
  local malicious_inputs=(
    'atuin; rm -rf /'
    'test$(whoami)'
    'cli`id`'
    'name|cat /etc/passwd'
    'app&& echo pwned'
  )

  for input in "${malicious_inputs[@]}"; do
    _amazonq_configure_settings "$input" 2>/dev/null
    if [[ $? -eq 0 ]]; then
      test_result "Security: injection '$input'" "FAIL"
    else
      test_result "Security: injection '$input'" "PASS"
    fi
  done
}

test_security_special_characters() {
  local special_chars=(
    'test/slash'
    'test*star'
    'test.dot'
    'test[bracket'
    'test$dollar'
    'test`backtick'
    "test'quote"
    'test"doublequote'
  )

  for input in "${special_chars[@]}"; do
    _amazonq_configure_settings "$input" 2>/dev/null
    if [[ $? -eq 0 ]]; then
      test_result "Special char: $input" "FAIL"
    else
      test_result "Special char: $input" "PASS"
    fi
  done
}

# Filesystem Tests
test_filesystem_invalid_json() {
  mkdir -p "$AMAZONQ_CONFIG_DIR"
  echo '{"disabledClis": [' > "$AMAZONQ_SETTINGS_FILE"  # Invalid JSON

  _amazonq_configure_settings "atuin" 2>/dev/null
  local result=$?

  if [[ $result -ne 0 ]]; then
    test_result "Invalid JSON: handling" "PASS"
  else
    test_result "Invalid JSON: handling" "FAIL"
  fi
}

test_filesystem_readonly_directory() {
  local test_dir="/tmp/amazonq-readonly-$$"
  mkdir -p "$test_dir"
  chmod 555 "$test_dir"

  AMAZONQ_CONFIG_DIR="$test_dir/config"
  _amazonq_configure_settings "test" 2>/dev/null
  local result=$?

  chmod 755 "$test_dir"
  rm -rf "$test_dir"

  if [[ $result -ne 0 ]]; then
    test_result "Readonly dir: error handling" "PASS"
  else
    test_result "Readonly dir: error handling" "FAIL"
  fi
}

# Configuration Tests
test_config_symlinked_zshrc() {
  local test_home="/tmp/test-home-$$"
  local real_zshrc="$test_home/real_zshrc"
  local link_zshrc="$test_home/.zshrc"

  mkdir -p "$test_home"
  touch "$real_zshrc"
  ln -s "$real_zshrc" "$link_zshrc"

  # Test should detect symlink
  local result=$(HOME="$test_home" _amazonq_setup_lazy_loading 2>&1)

  rm -rf "$test_home"

  if [[ "$result" == *"symlink"* ]]; then
    test_result "Symlink: detection" "PASS"
  else
    test_result "Symlink: detection" "FAIL"
  fi
}

test_config_idempotent_lazy_loading() {
  local test_home="/tmp/test-home-$$"
  mkdir -p "$test_home"
  touch "$test_home/.zshrc"

  # Run twice
  HOME="$test_home" _amazonq_setup_lazy_loading >/dev/null 2>&1
  local first_content=$(cat "$test_home/.zshrc")

  HOME="$test_home" _amazonq_setup_lazy_loading >/dev/null 2>&1
  local second_content=$(cat "$test_home/.zshrc")

  rm -rf "$test_home"

  # Content should be identical (not duplicated)
  if [[ "$first_content" == "$second_content" ]]; then
    test_result "Idempotent: lazy loading" "PASS"
  else
    test_result "Idempotent: lazy loading" "FAIL"
  fi
}

# Main test runner for edge cases
run_edge_case_tests() {
  echo "Running Amazon Q Edge Case Tests..."

  setup_test_env
  load_modules

  # Security tests (HIGH priority)
  test_security_command_injection
  test_security_special_characters

  # Filesystem tests (MEDIUM priority)
  test_filesystem_invalid_json
  test_filesystem_readonly_directory

  # Configuration tests (MEDIUM priority)
  test_config_symlinked_zshrc
  test_config_idempotent_lazy_loading

  teardown_test_env

  echo "Edge case tests complete"
}
```

## Definition of Done

- All tasks checked off
- Edge case test file created
- All test categories implemented
- Tests pass
- Integrated into CI/CD
- Code reviewed

## References

- **Location**: `tests/test-amazon-q.zsh`
- **Related**:
  - ZSHTOOL-SECURITY-001 (Command injection)
  - ZSHTOOL-SECURITY-005 (Input validation)
  - ZSHTOOL-BUG-003 (File operations)
  - ZSHTOOL-TEST-001 (Broken test)
  - ZSHTOOL-TEST-008 (Test pollution)

## Test Priority

1. **HIGH**: Security tests (injection, special characters)
2. **MEDIUM**: Filesystem tests (permissions, invalid JSON)
3. **MEDIUM**: Configuration tests (symlinks, idempotency)
4. **LOW**: Concurrent execution tests
