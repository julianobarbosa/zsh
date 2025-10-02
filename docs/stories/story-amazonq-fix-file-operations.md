# Story: Add Error Checking to File Operations

**Story ID**: ZSHTOOL-BUG-003
**Epic**: Epic 3 - Advanced Integrations
**Priority**: High
**Estimate**: 3 points
**Status**: To Do
**Created**: 2025-10-02
**Labels**: bug, high-priority

## Story

As a developer, I want file operations in Amazon Q configuration to have proper error checking, so that failures are detected and reported instead of silently corrupting configuration or failing.

## Context

The `_amazonq_configure_settings` function creates directories and writes files without checking for failures. This can lead to silent failures that corrupt user configuration or provide misleading success messages.

### Current Code (No Error Checking)
```zsh
# No error checking
mkdir -p "$AMAZONQ_CONFIG_DIR"

# ... processing ...

# No error checking
echo "$settings_content" > "$AMAZONQ_SETTINGS_FILE"

_zsh_tool_log INFO "✓ Amazon Q settings configured"  # Always reports success
```

### Problems
- Fails silently if parent directory has insufficient permissions
- Fails silently if disk is full
- Fails silently if path is invalid
- Fails silently if filesystem is read-only
- Reports success even when operations failed
- No way for user to know configuration didn't work

## Acceptance Criteria

- [ ] mkdir operations check for errors
- [ ] File write operations check for errors
- [ ] Directory writability is verified before operations
- [ ] Clear error messages explain what went wrong
- [ ] Function returns proper error codes on failure
- [ ] Success is only reported when operations actually succeed
- [ ] Tests verify error handling for common failure scenarios
- [ ] All existing tests continue to pass

## Tasks/Subtasks

- [ ] **Task 1: Add directory creation error checking**
  - [ ] Check mkdir return code
  - [ ] Log descriptive error on failure
  - [ ] Return error code to caller

- [ ] **Task 2: Add directory writability check**
  - [ ] Verify directory exists after creation
  - [ ] Check write permissions on directory
  - [ ] Log error if not writable

- [ ] **Task 3: Add file write error checking**
  - [ ] Check file write operation return code
  - [ ] Verify file was actually created
  - [ ] Verify file contains expected content
  - [ ] Log error on failure

- [ ] **Task 4: Improve error messages**
  - [ ] Include file paths in error messages
  - [ ] Suggest possible solutions (check permissions, disk space)
  - [ ] Use consistent error message format

- [ ] **Task 5: Add error handling tests**
  - [ ] Test with read-only filesystem (mockup)
  - [ ] Test with insufficient permissions
  - [ ] Test with invalid paths
  - [ ] Verify error messages are helpful

## Technical Implementation

### Proposed Solution

```zsh
_amazonq_configure_settings() {
  local disabled_clis=("$@")

  _zsh_tool_log INFO "Configuring Amazon Q settings..."

  # Ensure config directory exists with error checking
  if ! mkdir -p "$AMAZONQ_CONFIG_DIR" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to create config directory: $AMAZONQ_CONFIG_DIR"
    _zsh_tool_log ERROR "Check parent directory permissions and disk space"
    return 1
  fi

  # Verify directory was created
  if [[ ! -d "$AMAZONQ_CONFIG_DIR" ]]; then
    _zsh_tool_log ERROR "Config directory not found after creation: $AMAZONQ_CONFIG_DIR"
    return 1
  fi

  # Verify directory is writable
  if [[ ! -w "$AMAZONQ_CONFIG_DIR" ]]; then
    _zsh_tool_log ERROR "Config directory not writable: $AMAZONQ_CONFIG_DIR"
    _zsh_tool_log ERROR "Check directory permissions"
    return 1
  fi

  # ... input validation and JSON processing ...

  # Write settings file with error checking
  local temp_file="${AMAZONQ_SETTINGS_FILE}.tmp.$$"

  if ! echo "$settings_content" > "$temp_file" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to write temporary settings file: $temp_file"
    _zsh_tool_log ERROR "Check disk space and permissions"
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi

  # Verify temp file was created and has content
  if [[ ! -f "$temp_file" ]]; then
    _zsh_tool_log ERROR "Temporary settings file not created: $temp_file"
    return 1
  fi

  if [[ ! -s "$temp_file" ]]; then
    _zsh_tool_log ERROR "Temporary settings file is empty: $temp_file"
    rm -f "$temp_file"
    return 1
  fi

  # Atomic move with error checking
  if ! mv "$temp_file" "$AMAZONQ_SETTINGS_FILE" 2>/dev/null; then
    _zsh_tool_log ERROR "Failed to move settings file: $temp_file -> $AMAZONQ_SETTINGS_FILE"
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi

  # Final verification
  if [[ ! -f "$AMAZONQ_SETTINGS_FILE" ]]; then
    _zsh_tool_log ERROR "Settings file not found after write: $AMAZONQ_SETTINGS_FILE"
    return 1
  fi

  _zsh_tool_log INFO "✓ Amazon Q settings configured"
  _zsh_tool_log DEBUG "Settings file: $AMAZONQ_SETTINGS_FILE"
  _zsh_tool_log DEBUG "Disabled CLIs: ${disabled_clis[*]}"

  return 0
}
```

### Error Handling Tests

```zsh
test_error_handling_readonly_dir() {
  # Create read-only directory
  local test_dir="/tmp/amazonq-test-readonly-$$"
  mkdir -p "$test_dir"
  chmod 555 "$test_dir"

  # Try to create config in read-only dir
  AMAZONQ_CONFIG_DIR="$test_dir/config"
  _amazonq_configure_settings "test" 2>/dev/null
  local result=$?

  # Cleanup
  chmod 755 "$test_dir"
  rm -rf "$test_dir"

  if [[ $result -ne 0 ]]; then
    test_result "Error handling: read-only directory" "PASS"
  else
    test_result "Error handling: read-only directory" "FAIL" "Should fail with read-only parent"
  fi
}

test_error_handling_full_disk() {
  # Mock full disk scenario (simplified)
  local test_file="/tmp/amazonq-test-$$"

  # Create function that fails on write
  fake_echo() {
    return 1
  }

  # Test would need more sophisticated mocking
  # This is a placeholder for the concept
}

test_error_handling_invalid_path() {
  # Try to write to invalid path
  AMAZONQ_CONFIG_DIR="/invalid/\0/path"
  _amazonq_configure_settings "test" 2>/dev/null
  local result=$?

  if [[ $result -ne 0 ]]; then
    test_result "Error handling: invalid path" "PASS"
  else
    test_result "Error handling: invalid path" "FAIL" "Should fail with invalid path"
  fi
}
```

## Definition of Done

- All tasks checked off
- Error checking implemented for all file operations
- Clear and helpful error messages
- Tests verify error handling
- Function returns appropriate error codes
- Code reviewed and approved
- All existing tests continue to pass

## References

- **Location**: `lib/integrations/amazon-q.zsh:153, 171`
- **Epic**: Epic 3 - Advanced Integrations
- **Related Story**: ZSHTOOL-003 (Amazon Q Integration)

## Related Issues

- Command injection (ZSHTOOL-SECURITY-001)
- Unsafe .zshrc injection (ZSHTOOL-BUG-006)
