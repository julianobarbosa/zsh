# Story: Add Error Checking to File Operations

> **DEPRECATED - Historical Reference**
>
> This story documents work done for Amazon Q Developer CLI, which was rebranded to **Kiro CLI** in November 2025.
> This story is retained for historical reference only.
> See [story-kiro-cli-migration.md](story-kiro-cli-migration.md) for the migration to Kiro CLI.

**Story ID**: ZSHTOOL-BUG-003
**Epic**: Epic 3 - Advanced Integrations
**Priority**: High
**Estimate**: 3 points
**Status**: Done
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

- [x] mkdir operations check for errors
- [x] File write operations check for errors
- [x] Directory writability is verified before operations
- [x] Clear error messages explain what went wrong
- [x] Function returns proper error codes on failure
- [x] Success is only reported when operations actually succeed
- [x] Tests verify error handling for common failure scenarios
- [x] All existing tests continue to pass

## Tasks/Subtasks

- [x] **Task 1: Add directory creation error checking**
  - [x] Check mkdir return code
  - [x] Log descriptive error on failure
  - [x] Return error code to caller

- [x] **Task 2: Add directory writability check**
  - [x] Verify directory exists after creation
  - [x] Check write permissions on directory
  - [x] Log error if not writable

- [x] **Task 3: Add file write error checking**
  - [x] Check file write operation return code
  - [x] Verify file was actually created
  - [x] Verify file contains expected content
  - [x] Log error on failure

- [x] **Task 4: Improve error messages**
  - [x] Include file paths in error messages
  - [x] Suggest possible solutions (check permissions, disk space)
  - [x] Use consistent error message format

- [x] **Task 5: Add error handling tests**
  - [x] Test with read-only filesystem (mockup)
  - [x] Test with insufficient permissions
  - [x] Test with invalid paths
  - [x] Verify error messages are helpful

### Review Follow-ups (AI)
- [x] [AI-Review][HIGH] Add explicit umask when creating settings file to prevent world-readable permissions [lib/integrations/amazon-q.zsh:269] **FIXED**

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

---

## File List

- `lib/integrations/amazon-q.zsh` - Comprehensive file operation error checking (lines 210-273)
- `tests/test-amazon-q-edge-cases.zsh` - Filesystem error tests (lines 223-296)

## Change Log

**2025-10-02**: Verified file operation error checking implementation
- mkdir error checking with 2>/dev/null redirection (line 211)
- Directory existence verification after creation (lines 218-221)
- Directory writability check (lines 223-227)
- jq-based JSON manipulation with error checking (lines 254-258)
- Temp file creation and verification (lines 261-265)
- Atomic move with error handling (lines 268-272)
- Comprehensive error messages with remediation guidance

## Dev Agent Record

### Completion Notes

All file operation error checking was already comprehensively implemented (lines 210-273):

1. **Directory Creation** (lines 211-215): mkdir with error checking, clear error message about permissions/disk space
2. **Directory Verification** (lines 218-221): Confirms directory exists after creation attempt
3. **Writability Check** (lines 223-227): Verifies directory is writable before proceeding
4. **Safe JSON Operations** (lines 254-272): Uses jq with error checking, temp files, atomic moves
5. **Verification Steps** (lines 261-265): Checks temp file exists and has content before moving
6. **Test Coverage**: Edge case test suite includes 5 filesystem tests covering all error scenarios

All acceptance criteria met with robust error handling throughout.
