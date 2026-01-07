# Story: Propagate Health Check Return Values

> **DEPRECATED - Historical Reference**
>
> This story documents work done for Amazon Q Developer CLI, which was rebranded to **Kiro CLI** in November 2025.
> This story is retained for historical reference only.
> See [story-kiro-cli-migration.md](story-kiro-cli-migration.md) for the migration to Kiro CLI.

**Story ID**: ZSHTOOL-BUG-007
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Medium
**Estimate**: 1 point
**Status**: Done
**Created**: 2025-10-02
**Labels**: bug, medium-priority

## Story

As a developer, I want the installation function to properly check health check results, so that I'm accurately informed whether the installation succeeded or failed.

## Context

`amazonq_install_integration` calls `_amazonq_health_check` but doesn't check its return value, always reporting success even when Amazon Q is not functional.

### Current Code
```zsh
# Step 5: Health check
_amazonq_health_check

_zsh_tool_log INFO "✓ Amazon Q CLI integration complete"

return 0  # Always success
```

### Problem
- Health check failures are ignored
- User sees success message even when configuration failed
- Misleading feedback
- User may not realize Amazon Q is not working

## Acceptance Criteria

- [x] Check health check return value
- [x] Propagate failure to caller
- [x] Provide clear messaging on failure
- [x] All tests pass

## Tasks/Subtasks

- [x] **Task 1: Check return value**
  - [x] Capture health check exit code
  - [x] Handle failure case

- [x] **Task 2: Improve error messaging**
  - [x] Log warning on health check failure
  - [x] Provide troubleshooting guidance
  - [x] Suggest next steps

- [x] **Task 3: Use strict approach**
  - [x] Fail on health check failure (Option 1 implemented)

## Technical Implementation

### Option 1: Strict (Fail on health check failure)
```zsh
# Step 5: Health check
if ! _amazonq_health_check; then
  _zsh_tool_log ERROR "Amazon Q health check failed"
  _zsh_tool_log ERROR "Installation incomplete - please address issues and retry"
  _zsh_tool_log INFO "Run 'zsh-tool-amazonq health' to diagnose"
  return 1
fi

_zsh_tool_log INFO "✓ Amazon Q CLI integration complete"
return 0
```

### Option 2: Warn but allow (with user confirmation)
```zsh
# Step 5: Health check
if ! _amazonq_health_check; then
  _zsh_tool_log WARN "Amazon Q health check failed"
  _zsh_tool_log WARN "Installation completed but Amazon Q may not be fully functional"
  _zsh_tool_log INFO "Run 'zsh-tool-amazonq health' to diagnose issues"

  if _zsh_tool_prompt_confirm "Mark installation as complete anyway?"; then
    _zsh_tool_log INFO "Installation marked complete with warnings"
    return 0
  else
    _zsh_tool_log ERROR "Installation marked as failed"
    return 1
  fi
fi

_zsh_tool_log INFO "✓ Amazon Q CLI integration complete"
return 0
```

### Recommended: Option 1 (Strict)
Fail on health check failure for clearer feedback and easier troubleshooting.

## Definition of Done

- All tasks checked off
- Return value checked and propagated
- Clear error messaging
- Tests verify behavior
- Code reviewed

## References

- **Location**: `lib/integrations/amazon-q.zsh:417-422`
- **Epic**: Epic 3 - Advanced Integrations

---

## File List

- `lib/integrations/amazon-q.zsh` - Already fixed with proper return value checking

## Change Log

**2025-10-02**: Verified health check return value propagation
- Health check return value is properly checked with `if ! _amazonq_health_check`
- Failures propagate correctly with `return 1`
- Clear error messaging provided on failure
- Troubleshooting guidance included
- Strict approach implemented (Option 1)

## Dev Agent Record

### Debug Log

**Verification:**
- Checked `amazonq_install_integration` function at lines 417-422
- Health check return value is properly checked
- Error messages are clear and actionable
- Return code propagated correctly

### Completion Notes

This issue was already resolved in a previous fix. The current implementation properly:
1. Checks health check return value with `if ! _amazonq_health_check`
2. Logs clear error messages on failure
3. Provides troubleshooting guidance ("Run 'zsh-tool-amazonq health' to diagnose")
4. Propagates failure with `return 1`

The strict approach (Option 1) is implemented as recommended.
