# Story: Fix Test Environment Pollution

**Story ID**: ZSHTOOL-TEST-008
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Medium
**Estimate**: 2 points
**Status**: To Do
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

- [ ] Tests run in isolated subshells
- [ ] Global variables are not modified
- [ ] Cleanup happens even on failure (trap)
- [ ] Tests can run in parallel safely
- [ ] All tests pass
- [ ] No artifacts left behind

## Tasks/Subtasks

- [ ] **Task 1: Isolate test execution**
  - [ ] Run test logic in subshell
  - [ ] Use local HOME variable in subshell

- [ ] **Task 2: Add cleanup traps**
  - [ ] Use trap to ensure cleanup
  - [ ] Clean up on success and failure

- [ ] **Task 3: Verify isolation**
  - [ ] Check HOME unchanged after test
  - [ ] Verify no temp files remain
  - [ ] Test parallel execution

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

- **Location**: `tests/test-amazon-q.zsh:207-226`
- **Related**: ZSHTOOL-TEST-001 (Broken test logic)
