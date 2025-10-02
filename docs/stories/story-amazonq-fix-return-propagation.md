# Story: Propagate Health Check Return Values

**Story ID**: ZSHTOOL-BUG-007
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Medium
**Estimate**: 1 point
**Status**: To Do
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

- [ ] Check health check return value
- [ ] Propagate failure to caller
- [ ] Provide clear messaging on failure
- [ ] Allow user to override if desired
- [ ] All tests pass

## Tasks/Subtasks

- [ ] **Task 1: Check return value**
  - [ ] Capture health check exit code
  - [ ] Handle failure case

- [ ] **Task 2: Improve error messaging**
  - [ ] Log warning on health check failure
  - [ ] Provide troubleshooting guidance
  - [ ] Suggest next steps

- [ ] **Task 3: Add user choice**
  - [ ] Optional: ask user if they want to continue despite failure
  - [ ] OR: strictly fail on health check failure

- [ ] **Task 4: Update tests**
  - [ ] Test with health check failure
  - [ ] Verify return code propagation

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

- **Location**: `lib/integrations/amazon-q.zsh:263`
- **Epic**: Epic 3 - Advanced Integrations
