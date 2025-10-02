# Story: Fix Command Injection Risk in Amazon Q Settings

**Story ID**: ZSHTOOL-SECURITY-001
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Critical
**Estimate**: 3 points
**Status**: To Do
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

- [ ] Replace sed-based JSON manipulation with jq or proper JSON parser
- [ ] Add input validation for CLI names before processing
- [ ] Add error handling for jq not being available
- [ ] Add security tests with malicious input patterns
- [ ] Document security considerations in code comments
- [ ] All existing tests continue to pass
- [ ] New security tests verify protection against injection

## Tasks/Subtasks

- [ ] **Task 1: Add jq dependency check**
  - [ ] Add function to check if jq is installed
  - [ ] Provide clear error message if jq is not available
  - [ ] Add jq to prerequisites documentation

- [ ] **Task 2: Refactor settings manipulation**
  - [ ] Replace sed usage with jq for JSON manipulation
  - [ ] Implement proper error handling for jq operations
  - [ ] Maintain backwards compatibility with existing settings files

- [ ] **Task 3: Add input validation**
  - [ ] Validate CLI names match expected pattern (alphanumeric + hyphen)
  - [ ] Add length limits for CLI names
  - [ ] Reject empty or whitespace-only names

- [ ] **Task 4: Add security tests**
  - [ ] Test with sed metacharacters
  - [ ] Test with shell command injection attempts
  - [ ] Test with special characters and escape sequences
  - [ ] Test with edge cases (very long names, unicode, etc.)

- [ ] **Task 5: Update documentation**
  - [ ] Document security considerations
  - [ ] Add jq requirement to README
  - [ ] Update installation guide

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
