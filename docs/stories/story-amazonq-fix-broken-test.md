# Story: Fix Broken Test Logic in Lazy Loading Test

**Story ID**: ZSHTOOL-TEST-001
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Critical
**Estimate**: 2 points
**Status**: To Do
**Created**: 2025-10-02
**Labels**: testing, critical, bug

## Story

As a developer, I want the lazy loading test to execute correctly without hanging, so that the test suite can run reliably and verify Amazon Q functionality.

## Context

The `test_lazy_loading_setup` function contains a critical bug where it attempts to read from stdin using `cat` without any input, causing the test to hang indefinitely and block test suite execution.

### Current Code (Broken)
```zsh
local result=$?

if [[ $(cat) == "PASS" ]]; then  # <- BUG: cat waits for stdin
  test_result "Lazy loading: setup" "PASS"
else
  test_result "Lazy loading: setup" "FAIL" "Lazy loading marker not found in .zshrc"
fi
```

### Problem
- `cat` without arguments reads from stdin and blocks
- Subshell output (lines 212-226) is not being captured
- Test never completes, blocking entire test suite
- Makes CI/CD pipelines hang

## Acceptance Criteria

- [ ] Test executes without hanging
- [ ] Test correctly captures subshell output
- [ ] Test passes when lazy loading is properly configured
- [ ] Test fails appropriately when configuration is incorrect
- [ ] Test completes in reasonable time (< 5 seconds)
- [ ] Test does not pollute global environment
- [ ] All other tests continue to pass

## Tasks/Subtasks

- [ ] **Task 1: Fix output capture logic**
  - [ ] Remove incorrect `cat` usage
  - [ ] Properly capture subshell output
  - [ ] Verify result variable contains expected value

- [ ] **Task 2: Improve test isolation**
  - [ ] Run test in proper subshell
  - [ ] Ensure HOME variable is not modified globally
  - [ ] Add trap for cleanup on test failure

- [ ] **Task 3: Add timeout protection**
  - [ ] Add timeout mechanism to prevent hanging
  - [ ] Fail test gracefully if timeout is reached

- [ ] **Task 4: Verify test suite execution**
  - [ ] Run full test suite to ensure no hanging
  - [ ] Verify test timing is reasonable
  - [ ] Check for any side effects on other tests

## Technical Implementation

### Proposed Solution

```zsh
test_lazy_loading_setup() {
  local test_home="/tmp/test-home-$$"
  local result="FAIL"

  # Create test environment
  mkdir -p "$test_home"

  # Run test in isolated subshell and capture output
  result=$(
    HOME="$test_home"
    touch "${HOME}/.zshrc"

    # Source required functions
    _amazonq_setup_lazy_loading >/dev/null 2>&1

    # Check result
    if grep -q "Amazon Q lazy loading" "${HOME}/.zshrc"; then
      echo "PASS"
    else
      echo "FAIL"
    fi
  )

  # Cleanup
  rm -rf "$test_home"

  # Verify result
  if [[ "$result" == "PASS" ]]; then
    test_result "Lazy loading: setup" "PASS"
  else
    test_result "Lazy loading: setup" "FAIL" "Lazy loading marker not found in .zshrc"
  fi
}
```

### Alternative with Timeout

```zsh
test_lazy_loading_setup() {
  local test_home="/tmp/test-home-$$"
  local result="FAIL"
  local timeout=5

  # Create test environment
  mkdir -p "$test_home"

  # Run test with timeout
  result=$(timeout ${timeout} bash -c "
    HOME='$test_home'
    touch \"\${HOME}/.zshrc\"
    source lib/integrations/amazon-q.zsh
    _amazonq_setup_lazy_loading >/dev/null 2>&1
    if grep -q 'Amazon Q lazy loading' \"\${HOME}/.zshrc\"; then
      echo 'PASS'
    else
      echo 'FAIL'
    fi
  " 2>/dev/null)

  # Handle timeout
  if [[ $? -eq 124 ]]; then
    result="TIMEOUT"
  fi

  # Cleanup
  rm -rf "$test_home"

  # Verify result
  case "$result" in
    PASS)
      test_result "Lazy loading: setup" "PASS"
      ;;
    TIMEOUT)
      test_result "Lazy loading: setup" "FAIL" "Test timed out after ${timeout}s"
      ;;
    *)
      test_result "Lazy loading: setup" "FAIL" "Lazy loading marker not found"
      ;;
  esac
}
```

## Testing Verification

After fix, verify:
1. Test completes quickly (< 2 seconds normally)
2. Test passes with valid lazy loading setup
3. Test fails with missing lazy loading marker
4. Full test suite runs without hanging
5. No environment pollution (HOME is unchanged after test)

## Definition of Done

- All tasks checked off
- Test executes without hanging
- Test has proper timeout protection
- Test properly captures and evaluates output
- Full test suite passes
- Code reviewed and approved
- CI/CD pipeline runs successfully

## References

- **Location**: `tests/test-amazon-q.zsh:230`
- **Epic**: Epic 3 - Advanced Integrations
- **Related Story**: ZSHTOOL-003 (Amazon Q Integration)
- **Related Issue**: Test environment pollution (ZSHTOOL-TEST-008)

## Related Issues

- Test environment pollution (ZSHTOOL-TEST-008)
- Missing edge case tests (ZSHTOOL-TEST-009)
