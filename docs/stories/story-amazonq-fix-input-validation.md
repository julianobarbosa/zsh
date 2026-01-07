# Story: Add Input Validation for CLI Names

> **DEPRECATED - Historical Reference**
>
> This story documents work done for Amazon Q Developer CLI, which was rebranded to **Kiro CLI** in November 2025.
> This story is retained for historical reference only.
> See [story-kiro-cli-migration.md](story-kiro-cli-migration.md) for the migration to Kiro CLI.

**Story ID**: ZSHTOOL-SECURITY-005
**Epic**: Epic 3 - Advanced Integrations
**Priority**: High
**Estimate**: 2 points
**Status**: Done
**Created**: 2025-10-02
**Labels**: security, high-priority, bug

## Story

As a developer, I want CLI names to be validated before being used in configuration, so that malicious or malformed input cannot corrupt settings or create security vulnerabilities.

## Context

`_amazonq_configure_settings` accepts CLI names without validation, which could lead to invalid JSON, configuration corruption, or security issues when combined with the sed-based manipulation.

### Current Code
```zsh
_amazonq_configure_settings() {
  local disabled_clis=("$@")
  # No validation - directly used in sed/JSON
}
```

### Security Risks
- Special characters could break JSON
- Shell metacharacters could be exploited
- Very long names could cause buffer issues
- Empty names could create invalid configuration

## Acceptance Criteria

- [x] Validate CLI names match expected pattern
- [x] Reject names with special characters
- [x] Enforce reasonable length limits
- [x] Reject empty names
- [x] Log clear errors for invalid input
- [x] Security tests verify protection
- [x] All existing tests pass

## Tasks/Subtasks

- [x] **Task 1: Implement validation function**
  - [x] Check for alphanumeric + hyphen + underscore only
  - [x] Check length limits (max 64 characters)
  - [x] Check for non-empty names

- [x] **Task 2: Add to configure_settings**
  - [x] Validate each CLI name before processing
  - [x] Return error on invalid input
  - [x] Log which name failed validation

- [x] **Task 3: Add security tests**
  - [x] Test with shell metacharacters
  - [x] Test with special characters
  - [x] Test with very long names
  - [x] Test with empty strings

### Review Follow-ups (AI)
- [ ] [AI-Review][MEDIUM] Tighten regex to require alphanumeric start character: `^[a-zA-Z0-9][a-zA-Z0-9_-]*$` [lib/integrations/amazon-q.zsh:212]

## Technical Implementation

```zsh
_amazonq_validate_cli_name() {
  local cli_name="$1"

  # Check for empty
  if [[ -z "$cli_name" ]]; then
    _zsh_tool_log ERROR "CLI name cannot be empty"
    return 1
  fi

  # Check length
  if [[ ${#cli_name} -gt 64 ]]; then
    _zsh_tool_log ERROR "CLI name too long: '$cli_name' (max 64 chars)"
    return 1
  fi

  # Check pattern (alphanumeric, hyphen, underscore only)
  if [[ ! "$cli_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    _zsh_tool_log ERROR "Invalid CLI name: '$cli_name'"
    _zsh_tool_log ERROR "Only alphanumeric, hyphen, and underscore allowed"
    return 1
  fi

  return 0
}

_amazonq_configure_settings() {
  local disabled_clis=("$@")

  _zsh_tool_log INFO "Configuring Amazon Q settings..."

  # Validate all CLI names first
  for cli in "${disabled_clis[@]}"; do
    if ! _amazonq_validate_cli_name "$cli"; then
      return 1
    fi
  done

  # ... rest of function ...
}
```

## Definition of Done

- All tasks checked off
- Input validation implemented
- Security tests passing
- Code reviewed

## References

- **Location**: `lib/integrations/amazon-q.zsh:165-201`
- **Related**: ZSHTOOL-SECURITY-001 (Command injection), ZSHTOOL-TEST-009 (Edge case tests)

---

## File List

- `lib/integrations/amazon-q.zsh` - Already implements complete input validation
- `tests/test-amazon-q-edge-cases.zsh` - Security tests cover all validation scenarios

## Change Log

**2025-10-02**: Verified input validation implementation
- Validation function `_amazonq_validate_cli_name` implemented (lines 165-188)
- Empty name check (lines 169-172)
- Length limit enforcement (lines 174-178) - max 64 characters
- Pattern validation (lines 180-185) - alphanumeric, hyphen, underscore only
- Integration into `_amazonq_configure_settings` (lines 196-201)
- Comprehensive security tests in edge case test suite (26 tests including 13 security tests)

## Dev Agent Record

### Debug Log

**Verification:**
- Reviewed `_amazonq_validate_cli_name` function (lines 165-188)
- Reviewed integration in `_amazonq_configure_settings` (lines 196-201)
- Verified edge case test coverage includes all validation scenarios
- All security tests passing (13/13 in edge case suite)

### Completion Notes

Input validation was already fully implemented. The implementation includes:

1. **Empty Name Check** (lines 169-172):
   - Rejects empty strings
   - Clear error message

2. **Length Validation** (lines 174-178):
   - Maximum 64 characters
   - Prevents buffer issues
   - Reports name and limit in error

3. **Pattern Validation** (lines 180-185):
   - Only allows: `a-zA-Z0-9_-`
   - Rejects shell metacharacters (`;`, `$`, `` ` ``, `|`, `&`)
   - Rejects special characters (`/`, `*`, `.`, `[`, `'`, `"`)
   - Clear error explaining allowed characters

4. **Integration** (lines 196-201):
   - All CLI names validated before processing
   - Early return on first invalid name
   - Prevents invalid data from reaching JSON manipulation

5. **Test Coverage** (edge case test suite):
   - 13 security tests covering injection, special chars, unicode, whitespace
   - All validation rules verified
   - 100% pass rate
