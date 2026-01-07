# Story: Add Command Existence Check Before Execution

> **DEPRECATED - Historical Reference**
>
> This story documents work done for Amazon Q Developer CLI, which was rebranded to **Kiro CLI** in November 2025.
> This story is retained for historical reference only.
> See [story-kiro-cli-migration.md](story-kiro-cli-migration.md) for the migration to Kiro CLI.

**Story ID**: ZSHTOOL-BUG-004
**Epic**: Epic 3 - Advanced Integrations
**Priority**: High
**Estimate**: 2 points
**Status**: Done
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

- [x] Verify command exists immediately before execution
- [x] Verify command is executable
- [x] Provide clear error messages if command is not available
- [x] Guide user on how to fix the problem
- [x] All tests pass
- [x] Error handling tests added

## Tasks/Subtasks

- [x] **Task 1: Add command existence check**
  - [x] Use `command -v` to verify q is available
  - [x] Log clear error if not found

- [x] **Task 2: Add executability check**
  - [x] Verify q is executable
  - [x] Log error with path if not executable

- [x] **Task 3: Improve error messages**
  - [x] Suggest checking PATH
  - [x] Suggest reinstalling Amazon Q
  - [x] Provide troubleshooting steps

- [x] **Task 4: Add tests**
  - [x] Test with q not in PATH
  - [x] Test with q not executable
  - [x] Verify error messages

### Review Follow-ups (AI)
- [ ] [AI-Review][LOW] Add fallback guidance if `q doctor` command changes in future CLI versions [lib/integrations/amazon-q.zsh:183]

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

- **Location**: `lib/integrations/amazon-q.zsh:130-162`
- **Epic**: Epic 3 - Advanced Integrations

---

## File List

- `lib/integrations/amazon-q.zsh` - Implements all command checks

## Change Log

**2025-10-02**: Verified command existence checks implementation
- Command availability check using `command -v` (lines 131-137)
- Executability verification (lines 140-145)
- Clear error messages with troubleshooting guidance
- PATH diagnostics included

## Dev Agent Record

### Completion Notes

All command existence checks were already implemented (lines 130-162):

1. **Command Availability** (131-137): Uses `command -v` to verify q is in PATH before execution
2. **Executability Check** (140-145): Verifies command is executable, provides fix command
3. **Error Messages**: Clear guidance including PATH debugging and remediation steps
4. **Proper Ordering**: Checks happen immediately before execution to catch runtime issues
