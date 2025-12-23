# Story: Fix Command Injection Risk in Amazon Q Settings

**Story ID**: ZSHTOOL-SECURITY-001
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Critical
**Estimate**: 3 points
**Status**: Done
**Created**: 2025-10-02
**Labels**: security, critical, bug

## Story

As a developer, I want the Amazon Q settings configuration to be secure against command injection attacks, so that malicious input cannot compromise my system or corrupt configuration files.

## Context

The `_amazonq_configure_settings` function currently uses `sed` with unquoted variable expansion to manipulate JSON settings. This creates a command injection vulnerability where specially crafted CLI names could execute arbitrary commands or corrupt the settings file.

### Current Code (Vulnerable)
```zsh
local disabled_list=$(printf ',"%s"' "${disabled_clis[@]}")
settings_content=$(echo "$settings_content" | sed "s/\"disabledClis\":\[.*\]/\"disabledClis\":${disabled_list}/")
```

### Security Risk
- **Attack Vector**: User-controlled CLI names passed to sed without sanitization
- **Impact**: Command execution, JSON corruption, settings file manipulation
- **Severity**: Critical - Could allow arbitrary command execution

## Acceptance Criteria

- [x] Replace sed-based JSON manipulation with jq or proper JSON parser
- [x] Add input validation for CLI names before processing
- [x] Add error handling for jq not being available
- [x] Add security tests with malicious input patterns
- [x] Document security considerations in code comments
- [x] All existing tests continue to pass
- [x] New security tests verify protection against injection

## Tasks/Subtasks

- [x] **Task 1: Add jq dependency check**
  - [x] Add function to check if jq is installed
  - [x] Provide clear error message if jq is not available
  - [x] Add jq to prerequisites documentation

- [x] **Task 2: Refactor settings manipulation**
  - [x] Replace sed usage with jq for JSON manipulation
  - [x] Implement proper error handling for jq operations
  - [x] Maintain backwards compatibility with existing settings files

- [x] **Task 3: Add input validation**
  - [x] Validate CLI names match expected pattern (alphanumeric + hyphen)
  - [x] Add length limits for CLI names
  - [x] Reject empty or whitespace-only names

- [x] **Task 4: Add security tests**
  - [x] Test with sed metacharacters
  - [x] Test with shell command injection attempts
  - [x] Test with special characters and escape sequences
  - [x] Test with edge cases (very long names, unicode, etc.)

- [x] **Task 5: Update documentation**
  - [x] Document security considerations
  - [x] Add jq requirement to README
  - [x] Update installation guide

### Review Follow-ups (AI)
- [x] [AI-Review][HIGH] Add explicit umask for settings file creation: `(umask 077; echo '...' > "$file")` [lib/integrations/amazon-q.zsh:269,277] **FIXED**
- [ ] [AI-Review][MEDIUM] Tighten input validation to require alphanumeric start: `^[a-zA-Z0-9][a-zA-Z0-9_-]*$` [lib/integrations/amazon-q.zsh:212]

## Technical Implementation

### Proposed Solution

```zsh
_amazonq_configure_settings() {
  local disabled_clis=("$@")

  _zsh_tool_log INFO "Configuring Amazon Q settings..."

  # Validate jq is available
  if ! command -v jq >/dev/null 2>&1; then
    _zsh_tool_log ERROR "jq is required for safe JSON manipulation"
    _zsh_tool_log ERROR "Install with: brew install jq"
    return 1
  fi

  # Validate input
  for cli in "${disabled_clis[@]}"; do
    if [[ ! "$cli" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      _zsh_tool_log ERROR "Invalid CLI name: '$cli'"
      return 1
    fi
    if [[ ${#cli} -gt 64 ]]; then
      _zsh_tool_log ERROR "CLI name too long: '$cli'"
      return 1
    fi
  done

  # Ensure config directory exists
  if ! mkdir -p "$AMAZONQ_CONFIG_DIR"; then
    _zsh_tool_log ERROR "Failed to create config directory"
    return 1
  fi

  # Create or update settings using jq
  local settings_file="$AMAZONQ_SETTINGS_FILE"
  local temp_file="${settings_file}.tmp"

  # Initialize if doesn't exist
  if [[ ! -f "$settings_file" ]]; then
    echo '{"disabledClis":[]}' > "$settings_file"
  fi

  # Build jq array from disabled_clis
  local jq_array=$(printf '%s\n' "${disabled_clis[@]}" | jq -R . | jq -s .)

  # Update settings file
  if jq ".disabledClis = $jq_array" "$settings_file" > "$temp_file"; then
    mv "$temp_file" "$settings_file"
    _zsh_tool_log INFO "✓ Amazon Q settings configured"
    _zsh_tool_log DEBUG "Disabled CLIs: ${disabled_clis[*]}"
    return 0
  else
    _zsh_tool_log ERROR "Failed to update settings file"
    rm -f "$temp_file"
    return 1
  fi
}
```

### Security Tests

```zsh
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
      test_result "Security: injection attempt '$input'" "FAIL" "Should reject malicious input"
    else
      test_result "Security: injection attempt '$input'" "PASS"
    fi
  done
}
```

## Definition of Done

- All tasks checked off
- jq-based implementation complete
- Input validation in place
- Security tests written and passing
- Documentation updated
- Code reviewed and approved
- No regression in existing functionality

## References

- **Location**: `lib/integrations/amazon-q.zsh:164-168`
- **Epic**: Epic 3 - Advanced Integrations
- **Related Story**: ZSHTOOL-003 (Amazon Q Integration)
- **Security Guidelines**: OWASP Command Injection Prevention

## Related Issues

- Input validation (ZSHTOOL-SECURITY-005)
- Unsafe file operations (ZSHTOOL-BUG-003)

---

## File List

- `lib/integrations/amazon-q.zsh` - Input validation + jq usage (lines 165-201, 246-273)
- `tests/test-amazon-q-edge-cases.zsh` - 13 security tests (lines 78-219)

## Change Log

**2025-10-04**: Senior Developer Review notes appended - Approved with minor recommendations

**2025-10-02**: Verified command injection protection implementation
- Input validation function `_amazonq_validate_cli_name` (lines 165-188)
- Pattern matching restricts to alphanumeric + hyphen + underscore only
- jq used for all JSON manipulation (lines 246-272) - no sed/eval
- Input validation called before any processing (lines 196-201)
- Comprehensive security test coverage (13 tests in edge case suite)
- All security tests passing (26/26 edge case tests)

## Dev Agent Record

### Completion Notes

Command injection protection was comprehensively implemented:

1. **Input Validation** (lines 165-188): Strict pattern matching prevents all injection vectors
2. **Safe JSON Manipulation** (lines 246-272): jq used exclusively, eliminating sed-based vulnerabilities  
3. **Early Validation** (lines 196-201): All inputs validated before reaching any dangerous operations
4. **jq Dependency** (lines 204-208): Clear error if jq not available
5. **Test Coverage**: 13 security tests covering:
   - Command injection (`;`, `$`, `` ` ``, `|`, `&`)
   - Special characters (`/`, `*`, `.`, `[`, `'`, `"`)
   - Unicode and whitespace
   - Length validation
   - Empty string rejection

Critical security issue fully resolved with defense-in-depth approach.

---

## Senior Developer Review (AI)

**Reviewer:** Barbosa
**Date:** 2025-10-04
**Outcome:** ✅ **Approve**

### Summary

This security fix demonstrates exemplary defensive programming and follows OWASP command injection prevention guidelines. The implementation uses a defense-in-depth approach with multiple validation layers, comprehensive test coverage, and robust error handling. The code quality is production-ready.

### Key Findings

**High Severity:** None

**Medium Severity:** None

**Low Severity:**
1. **File permissions** - Settings file created without explicit umask. Consider using `(umask 077; echo '...' > "$file")` for restrictive permissions (0600).
2. **Concurrent access** - No test coverage for simultaneous function calls. While `$$` provides process isolation, adding a concurrent access test would improve confidence.

### Acceptance Criteria Coverage

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Replace sed with jq | ✅ COMPLETE | Lines 246-272: jq used exclusively, zero sed usage |
| Add input validation | ✅ COMPLETE | Lines 165-188: Strict regex `^[a-zA-Z0-9_-]+$`, length limits |
| Error handling for jq | ✅ COMPLETE | Lines 204-208: Clear installation instructions |
| Security tests | ✅ COMPLETE | 13 tests covering all injection vectors |
| Code documentation | ✅ COMPLETE | Inline security comments throughout |
| Existing tests pass | ✅ COMPLETE | 26/26 edge case tests passing |
| New tests verify protection | ✅ COMPLETE | All injection attempts correctly rejected |

**Coverage: 7/7 (100%)**

### Test Coverage and Gaps

**Excellent Coverage:**
- ✅ Command injection (`;`, `$`, `` ` ``, `|`, `&`)
- ✅ Special characters (`/`, `*`, `.`, `[`, `'`, `"`)
- ✅ Unicode and whitespace
- ✅ Length validation (64 char limit)
- ✅ Empty string rejection
- ✅ Valid input acceptance

**Minor Gaps:**
- **Concurrent access test** - Verify behavior when multiple processes call `_amazonq_configure_settings` simultaneously
- **Filesystem edge cases** - Test behavior when disk is full or directory permissions change mid-execution

### Architectural Alignment

✅ **Aligned with project architecture:**
- Follows modular function-based design (solution-architecture.md)
- Uses consistent logging via `_zsh_tool_log` utility
- Implements idempotent operations (safe to run multiple times)
- Maintains Oh My Zsh integration pattern
- XDG-compliant storage (`~/.aws/amazonq/`)

### Security Notes

**OWASP Compliance:**
✅ **Input validation whitelist** - Pattern `^[a-zA-Z0-9_-]+$` is strict and appropriate
✅ **No shell metacharacter escaping** - Correctly rejects rather than sanitizes (per OWASP guidance)
✅ **Safe JSON manipulation** - jq eliminates eval/sed injection vectors
✅ **Atomic file operations** - Temp file + atomic move prevents corruption
✅ **Process isolation** - PID-based temp file naming (`$$`)

**Defense-in-Depth Layers:**
1. Input validation → Rejects at entry point (lines 196-201)
2. jq validation → Validates JSON structure (line 237)
3. Temp file verification → Confirms write success (lines 261-265)
4. Atomic move → Prevents partial writes (line 268)

**Recommendations:**
- **File permissions**: Add explicit umask for settings file creation
  ```zsh
  (umask 077; echo '{"disabledClis":[]}' > "$AMAZONQ_SETTINGS_FILE")
  ```
- **Logging**: Consider logging rejected inputs (at DEBUG level) for security monitoring

### Best-Practices and References

**Followed Best Practices:**
1. ✅ **Avoid shell execution** - No eval, no unquoted variables in sed/awk
2. ✅ **Never sanitize input** - Reject invalid patterns entirely
3. ✅ **Context-sensitive validation** - Whitelist appropriate for CLI names
4. ✅ **Proper quoting** - All variables properly quoted (`"$var"`, `"${arr[@]}"`)
5. ✅ **Least privilege** - No unnecessary elevated permissions

**References:**
- OWASP Command Injection Prevention: https://portswigger.net/web-security/os-command-injection
- jq Manual (secure JSON processing): https://jqlang.org/manual/
- Unix Stack Exchange - Command Injection Prevention: https://unix.stackexchange.com/questions/82643
- Shell Script Security Best Practices: https://www.shellcheck.net/wiki/

### Action Items

1. **[Low]** Add explicit umask for settings file creation (lines 231, 239)
   - **File**: `lib/integrations/amazon-q.zsh`
   - **Suggested fix**: Wrap `echo '...' > "$file"` in subshell with `umask 077`
   - **Owner**: TBD

2. **[Low]** Add concurrent access test to edge case suite
   - **File**: `tests/test-amazon-q-edge-cases.zsh`
   - **Test**: Spawn 5 background processes calling `_amazonq_configure_settings` simultaneously, verify all succeed or properly handle conflicts
   - **Owner**: TBD
