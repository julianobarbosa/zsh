# Story: Fix Test Environment Pollution

**Story ID**: ZSHTOOL-TEST-008
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Medium
**Estimate**: 2 points
**Status**: Ready for Review
**Created**: 2025-10-02
**Labels**: testing, medium-priority, bug

## Story

As a developer, I want tests to run in isolation without polluting the global environment, so that tests don't interfere with each other and leave no artifacts.

## Context

`test_lazy_loading_setup` modifies the global HOME variable and creates temporary files that may not be cleaned up on failure, causing test pollution and potential interference with other tests.

### Current Code
```zsh
test_lazy_loading_setup() {
  local test_zshrc="/tmp/test-zshrc-$$"
  export HOME="/tmp"  # Modifies global HOME!
  mkdir -p "/tmp"
  touch "$test_zshrc"
  # ...
}
```

### Problems
- Modifies global HOME variable
- May not clean up on test failure
- Could interfere with parallel tests
- Leaves temporary files

## Acceptance Criteria

- [x] Tests run in isolated subshells
- [x] Global variables are not modified
- [x] Cleanup happens even on failure (trap)
- [x] Tests can run in parallel safely
- [x] All tests pass
- [x] No artifacts left behind

## Tasks/Subtasks

- [x] **Task 1: Isolate test execution**
  - [x] Run test logic in subshell
  - [x] Use local HOME variable in subshell

- [x] **Task 2: Add cleanup traps**
  - [x] Use trap to ensure cleanup
  - [x] Clean up on success and failure

- [x] **Task 3: Verify isolation**
  - [x] Check HOME unchanged after test
  - [x] Verify no temp files remain
  - [x] Test parallel execution

## Technical Implementation

```zsh
test_lazy_loading_setup() {
  local test_home="/tmp/test-home-$$"
  local result="FAIL"

  # Setup with automatic cleanup
  mkdir -p "$test_home"
  trap "rm -rf '$test_home'" EXIT INT TERM

  # Run in subshell for isolation
  result=$(
    export HOME="$test_home"
    touch "${HOME}/.zshrc"

    # Run function under test
    _amazonq_setup_lazy_loading >/dev/null 2>&1

    # Check result
    if grep -q "Amazon Q lazy loading" "${HOME}/.zshrc"; then
      echo "PASS"
    else
      echo "FAIL"
    fi
  )

  # Cleanup (trap will also handle this)
  rm -rf "$test_home"
  trap - EXIT INT TERM

  # Verify
  if [[ "$result" == "PASS" ]]; then
    test_result "Lazy loading: setup" "PASS"
  else
    test_result "Lazy loading: setup" "FAIL" "Lazy loading marker not found"
  fi
}
```

## Definition of Done

- All tasks checked off
- Tests properly isolated
- Cleanup guaranteed
- No environment pollution
- Tests pass
- Code reviewed

## References

- **Location**: `tests/test-amazon-q.zsh:202-239`
- **Related**: ZSHTOOL-TEST-001 (Broken test logic)

---

## File List

- `tests/test-amazon-q.zsh` - Added cleanup traps and enhanced isolation

## Change Log

**2025-10-02**: Fixed test environment pollution
- Added trap-based cleanup to ensure temp files are removed even on failure
- Verified HOME variable isolation (unchanged after tests)
- Verified no temp file artifacts remain after test execution
- Tested parallel execution safety (3 concurrent test runs)
- Updated global teardown to clean additional temp directories

## Dev Agent Record

### Debug Log

**Implementation Approach:**
1. Added trap `EXIT INT TERM` to ensure cleanup on success, failure, or interrupt
2. Verified existing subshell isolation for HOME variable was working correctly
3. Enhanced global teardown function to clean all potential temp directories
4. Tested isolation: HOME unchanged after tests, no temp files remain
5. Tested parallel execution: 3 concurrent runs completed successfully with no artifacts

### Completion Notes

Successfully fixed test environment pollution issues. The test already used subshell isolation for HOME, but lacked trap-based cleanup. Added robust cleanup guarantees to prevent test artifacts even during failures or interrupts.

Key achievements:
- **Trap-based cleanup** ensures no artifacts even on failure
- **HOME isolation** verified (unchanged after test runs)
- **No temp file leakage** confirmed
- **Parallel execution safe** (tested 3 concurrent runs)
- **All tests pass** with proper isolation
