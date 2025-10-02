# Story: Add Input Validation for CLI Names

**Story ID**: ZSHTOOL-SECURITY-005
**Epic**: Epic 3 - Advanced Integrations
**Priority**: High
**Estimate**: 2 points
**Status**: To Do
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

- [ ] Validate CLI names match expected pattern
- [ ] Reject names with special characters
- [ ] Enforce reasonable length limits
- [ ] Reject empty names
- [ ] Log clear errors for invalid input
- [ ] Security tests verify protection
- [ ] All existing tests pass

## Tasks/Subtasks

- [ ] **Task 1: Implement validation function**
  - [ ] Check for alphanumeric + hyphen + underscore only
  - [ ] Check length limits (max 64 characters)
  - [ ] Check for non-empty names

- [ ] **Task 2: Add to configure_settings**
  - [ ] Validate each CLI name before processing
  - [ ] Return error on invalid input
  - [ ] Log which name failed validation

- [ ] **Task 3: Add security tests**
  - [ ] Test with shell metacharacters
  - [ ] Test with special characters
  - [ ] Test with very long names
  - [ ] Test with empty strings

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

- **Location**: `lib/integrations/amazon-q.zsh:148`
- **Related**: ZSHTOOL-SECURITY-001 (Command injection)
