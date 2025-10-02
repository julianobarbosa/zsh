# Story: Add Command Existence Check Before Execution

**Story ID**: ZSHTOOL-BUG-004
**Epic**: Epic 3 - Advanced Integrations
**Priority**: High
**Estimate**: 2 points
**Status**: To Do
**Created**: 2025-10-02
**Labels**: bug, high-priority

## Story

As a developer, I want the health check function to verify commands exist before executing them, so that I receive clear error messages instead of confusing command-not-found errors.

## Context

`_amazonq_health_check` executes `q doctor` without verifying the command is available, leading to unclear error messages when Amazon Q is not properly installed or has been removed.

### Current Code
```zsh
_amazonq_health_check() {
  _zsh_tool_log INFO "Running Amazon Q health check..."

  if ! _amazonq_is_installed; then
    _zsh_tool_log ERROR "Amazon Q CLI not installed"
    return 1
  fi

  # ... logs ...

  q doctor  # No check if q is still available
  local exit_code=$?
```

### Problems
- Between the initial check and execution, `q` could be removed
- PATH could change
- Command could become non-executable
- Error messages are unclear to users
- Exit codes may not reflect the actual problem

## Acceptance Criteria

- [ ] Verify command exists immediately before execution
- [ ] Verify command is executable
- [ ] Provide clear error messages if command is not available
- [ ] Guide user on how to fix the problem
- [ ] All tests pass
- [ ] Error handling tests added

## Tasks/Subtasks

- [ ] **Task 1: Add command existence check**
  - [ ] Use `command -v` to verify q is available
  - [ ] Log clear error if not found

- [ ] **Task 2: Add executability check**
  - [ ] Verify q is executable
  - [ ] Log error with path if not executable

- [ ] **Task 3: Improve error messages**
  - [ ] Suggest checking PATH
  - [ ] Suggest reinstalling Amazon Q
  - [ ] Provide troubleshooting steps

- [ ] **Task 4: Add tests**
  - [ ] Test with q not in PATH
  - [ ] Test with q not executable
  - [ ] Verify error messages

## Technical Implementation

```zsh
_amazonq_health_check() {
  _zsh_tool_log INFO "Running Amazon Q health check..."

  # Initial installation check
  if ! _amazonq_is_installed; then
    _zsh_tool_log ERROR "Amazon Q CLI not installed"
    return 1
  fi

  # Verify q command is available before execution
  if ! command -v q >/dev/null 2>&1; then
    _zsh_tool_log ERROR "Amazon Q command 'q' not found in PATH"
    _zsh_tool_log ERROR "Current PATH: $PATH"
    _zsh_tool_log ERROR "Try reloading your shell: exec zsh"
    _zsh_tool_log ERROR "Or reinstall Amazon Q"
    return 1
  fi

  # Verify q is executable
  local q_path=$(command -v q)
  if [[ ! -x "$q_path" ]]; then
    _zsh_tool_log ERROR "Amazon Q command is not executable: $q_path"
    _zsh_tool_log ERROR "Fix with: chmod +x $q_path"
    return 1
  fi

  echo ""
  echo "Running 'q doctor' to check Amazon Q configuration..."
  echo ""

  # Execute with proper error handling
  if ! q doctor; then
    _zsh_tool_log WARN "Amazon Q health check reported issues"
    _zsh_tool_log INFO "Review output above and fix any reported problems"
    return 1
  fi

  echo ""
  _zsh_tool_log INFO "✓ Amazon Q health check passed"
  return 0
}
```

## Definition of Done

- All tasks checked off
- Command checks implemented
- Clear error messages
- Tests added and passing
- Code reviewed

## References

- **Location**: `lib/integrations/amazon-q.zsh:131`
- **Epic**: Epic 3 - Advanced Integrations
