# System-Level Testability Review

**Date:** 2025-12-30
**Author:** Barbosa (Test Architect)
**Status:** Draft
**Mode:** System-Level (Phase 3 Solutioning)

---

## Executive Summary

**Project:** zsh configuration and maintenance tool (macOS CLI)
**Technology Stack:** Pure zsh scripting, Homebrew, Oh My Zsh, git
**Testing Framework:** bats-core (planned), custom zsh framework (existing)

**Testability Assessment:**

| Dimension | Score | Notes |
|-----------|-------|-------|
| Controllability | 7/10 | Shell state manageable via env vars; external deps need mocking |
| Observability | 6/10 | Exit codes + stdout; limited internal state visibility |
| Reliability | 8/10 | Stateless functions; deterministic when mocked properly |

**Key Findings:**
- Existing custom test framework (16 tests for Amazon Q) demonstrates solid patterns
- bats-core adoption will standardize and scale testing
- External dependency mocking is the primary testability challenge
- Idempotency testing requires careful state management

---

## Component Testability Analysis

### Core Modules (lib/core/)

| Module | Controllability | Observability | Testability Risk |
|--------|-----------------|---------------|------------------|
| utils.zsh | High | High | Low |
| logging.zsh | High | High | Low |
| errors.zsh | Medium | High | Medium - trap handling |

**Assessment:** Core utilities are pure functions with minimal side effects. Highly testable at unit level.

### Installation Modules (lib/install/)

| Module | Controllability | Observability | Testability Risk |
|--------|-----------------|---------------|------------------|
| homebrew.zsh | Low | Medium | High - external dep |
| ohmyzsh.zsh | Low | Medium | High - network/fs ops |
| config.zsh | High | High | Low |
| plugins.zsh | Medium | Medium | Medium - OMZ state |
| themes.zsh | Medium | Medium | Medium - OMZ state |

**Assessment:** Installation modules have external dependencies that require mocking. Config parsing is highly testable.

### Update Modules (lib/update/)

| Module | Controllability | Observability | Testability Risk |
|--------|-----------------|---------------|------------------|
| self-update.zsh | Low | Medium | High - git/network |
| plugin-update.zsh | Medium | Medium | Medium - OMZ state |

**Assessment:** Self-update requires git mocking. Plugin updates depend on OMZ internals.

### Restore Modules (lib/restore/)

| Module | Controllability | Observability | Testability Risk |
|--------|-----------------|---------------|------------------|
| backup.zsh | High | High | Medium - fs operations |
| restore.zsh | High | High | Medium - fs operations |

**Assessment:** File system operations are controllable via temp directories. Testable with proper setup/teardown.

### Git Integration (lib/git/)

| Module | Controllability | Observability | Testability Risk |
|--------|-----------------|---------------|------------------|
| dotfile-sync.zsh | Low | Medium | High - git operations |
| version-control.zsh | Medium | Medium | Medium - git state |

**Assessment:** Git operations require careful mocking. Consider test repos for integration tests.

### Advanced Integrations (lib/integrations/)

| Module | Controllability | Observability | Testability Risk |
|--------|-----------------|---------------|------------------|
| atuin.zsh | Medium | Medium | Medium - external CLI |
| amazon-q.zsh | Medium | Medium | Medium - external CLI |

**Assessment:** Already has 16 existing tests. Pattern established for mocking external CLIs.

---

## Risk Assessment

### High-Priority Risks (Score >= 6)

| Risk ID | Category | Description | P | I | Score | Mitigation |
|---------|----------|-------------|---|---|-------|------------|
| R-001 | TECH | External dependency mocking complexity (Homebrew, OMZ, git) | 3 | 3 | 9 | Create mock library with standardized stubs |
| R-002 | TECH | Shell state isolation between tests | 2 | 3 | 6 | Use subshells; explicit env reset in setup/teardown |
| R-003 | PERF | NFR validation (<5 min install) hard to test deterministically | 2 | 3 | 6 | Timeout-based assertions; CI benchmarking |

### Medium-Priority Risks (Score 3-5)

| Risk ID | Category | Description | P | I | Score | Mitigation |
|---------|----------|-------------|---|---|-------|------------|
| R-004 | TECH | Idempotency verification requires multiple run assertions | 2 | 2 | 4 | Dedicated idempotency test suite |
| R-005 | DATA | Backup/restore path handling edge cases | 2 | 2 | 4 | Parameterized tests with varied paths |
| R-006 | OPS | CI environment differs from local (Intel vs ARM) | 2 | 2 | 4 | Matrix testing on GitHub Actions |

### Low-Priority Risks (Score 1-2)

| Risk ID | Category | Description | P | I | Score | Mitigation |
|---------|----------|-------------|---|---|-------|------------|
| R-007 | TECH | YAML config parsing edge cases | 1 | 2 | 2 | Unit tests with edge case fixtures |
| R-008 | BUS | Theme/plugin compatibility variations | 1 | 1 | 1 | Document supported combinations |

---

## NFR Test Strategy

### NFR001: Performance (< 5 min install)

**Test Approach:**
- Integration test with timeout assertion
- CI benchmark with baseline comparison
- Component-level timing for bottleneck identification

**Test Level:** Integration + E2E
**Automation:** GitHub Actions workflow with timing capture

```yaml
performance_test:
  scenario: "Fresh install completes within 5 minutes"
  timeout: 300s
  metrics:
    - total_duration
    - homebrew_install_duration
    - omz_install_duration
    - plugin_install_duration
```

### NFR002: Reliability (Idempotent operations)

**Test Approach:**
- Run each operation twice; assert identical end state
- Capture file checksums before/after second run
- Verify no duplicate entries in configuration files

**Test Level:** Integration
**Pattern:** Run -> Capture State -> Run Again -> Compare State

```yaml
idempotency_test:
  scenario: "Install can run multiple times safely"
  assertions:
    - exit_code equals 0 on both runs
    - config_checksum unchanged after second run
    - no duplicate PATH entries
    - no duplicate alias definitions
```

### NFR003: Compatibility (macOS 12+, Intel & ARM)

**Test Approach:**
- CI matrix testing across macOS versions
- Architecture-specific path validation
- Homebrew prefix detection (/opt/homebrew vs /usr/local)

**Test Level:** Integration
**Infrastructure:** GitHub Actions matrix

```yaml
compatibility_matrix:
  os: [macos-12, macos-13, macos-14]
  arch: [x64, arm64]
  assertions:
    - homebrew_prefix_correct
    - all_functions_load
    - paths_resolve_correctly
```

### NFR004: Security (No credential storage)

**Test Approach:**
- Static analysis for credential patterns
- File content scanning post-install
- Git config inspection

**Test Level:** Unit + Static Analysis
**Tools:** grep patterns, shellcheck

```yaml
security_test:
  scenario: "No credentials stored in config files"
  assertions:
    - no password patterns in generated files
    - no API keys in config
    - git credential helper not modified
```

### NFR005: User Experience (Clear progress + errors)

**Test Approach:**
- Capture stdout/stderr for message validation
- Error scenario testing with assertion on remediation messages
- Progress indicator presence checks

**Test Level:** Integration
**Pattern:** Capture output, regex match expected patterns

---

## Test Infrastructure Recommendations

### 1. Adopt bats-core Framework

**Rationale:** Industry standard for shell testing; integrates with CI; supports TAP output

**Migration Path:**
1. Install bats-core via Homebrew in CI
2. Create `tests/` structure following bats conventions
3. Port existing 16 tests from custom framework
4. Add new tests in bats format

**Structure:**
```
tests/
  bats/              # bats-core tests
    unit/            # Pure function tests
    integration/     # Component interaction tests
    e2e/             # Full workflow tests
  fixtures/          # Test data and configs
  helpers/           # Shared test utilities
    mocks.bash       # Mock functions for external deps
    setup.bash       # Common setup/teardown
```

### 2. Mock Library for External Dependencies

**Components to Mock:**

| Dependency | Mock Strategy | Location |
|------------|---------------|----------|
| Homebrew | Function override: `brew() { ... }` | helpers/mocks.bash |
| Oh My Zsh | Fake OMZ_DIR with minimal structure | fixtures/omz/ |
| git | Function override with canned responses | helpers/mocks.bash |
| Atuin | Function override: `atuin() { ... }` | helpers/mocks.bash |
| Amazon Q | Function override: `q() { ... }` | helpers/mocks.bash |

### 3. Test Environment Isolation

**Pattern from Existing Tests:**
```zsh
setup_test_env() {
  export TEST_MODE=true
  export ZSH_TOOL_CONFIG_DIR="/tmp/zsh-tool-test-$$"
  mkdir -p "${ZSH_TOOL_CONFIG_DIR}"
}

teardown_test_env() {
  rm -rf "/tmp/zsh-tool-test-$$" 2>/dev/null
}
```

**Enhancement for bats:**
```bash
setup() {
  export TEST_MODE=true
  TEST_DIR="$(mktemp -d)"
  export ZSH_TOOL_CONFIG_DIR="$TEST_DIR/config"
  export HOME="$TEST_DIR/home"
  mkdir -p "$ZSH_TOOL_CONFIG_DIR" "$HOME"
}

teardown() {
  rm -rf "$TEST_DIR"
}
```

### 4. CI Pipeline Integration

**GitHub Actions Workflow:**
```yaml
test:
  runs-on: ${{ matrix.os }}
  strategy:
    matrix:
      os: [macos-12, macos-13, macos-14]
  steps:
    - uses: actions/checkout@v4
    - name: Install bats-core
      run: brew install bats-core
    - name: Run unit tests
      run: bats tests/bats/unit/
    - name: Run integration tests
      run: bats tests/bats/integration/
    - name: Run shellcheck
      run: shellcheck lib/**/*.zsh
```

---

## Test Coverage Plan (System Level)

### Epic 1: Core Installation (23 SP, 7 Stories)

| Story | Priority | Test Level | Test Count | Risk Coverage |
|-------|----------|------------|------------|---------------|
| 1.1 Homebrew Detection | P0 | Unit + Int | 5 | R-001 |
| 1.2 Oh My Zsh Installation | P0 | Integration | 8 | R-001, R-002 |
| 1.3 Config Parser | P0 | Unit | 10 | R-007 |
| 1.4 Plugin Installation | P1 | Integration | 6 | R-002 |
| 1.5 Theme Application | P1 | Integration | 4 | R-002 |
| 1.6 PATH Configuration | P0 | Unit + Int | 6 | R-002 |
| 1.7 Full Install Flow | P0 | E2E | 3 | R-001, R-003 |

**Epic 1 Total:** ~42 tests

### Epic 2: Maintenance & Lifecycle (17 SP, 5 Stories)

| Story | Priority | Test Level | Test Count | Risk Coverage |
|-------|----------|------------|------------|---------------|
| 2.1 Backup Creation | P0 | Integration | 6 | R-005 |
| 2.2 Restore Operation | P0 | Integration | 6 | R-005 |
| 2.3 Self-Update | P1 | Integration | 5 | R-001 |
| 2.4 Plugin Updates | P1 | Integration | 4 | R-002 |
| 2.5 Idempotency | P0 | Integration | 8 | R-004 |

**Epic 2 Total:** ~29 tests

### Epic 3: Advanced Integrations (13 SP, 2 Stories)

| Story | Priority | Test Level | Test Count | Risk Coverage |
|-------|----------|------------|------------|---------------|
| 3.1 Atuin Integration | P1 | Int + Unit | 8 | - |
| 3.2 Amazon Q Integration | P1 | Int + Unit | 16 (existing) | - |

**Epic 3 Total:** ~24 tests (16 already exist)

---

## Quality Gate Criteria

### Pass/Fail Thresholds

- **P0 tests:** 100% pass rate required
- **P1 tests:** >= 95% pass rate
- **P2/P3 tests:** >= 90% pass rate
- **High-risk mitigations (R-001 through R-003):** All addressed

### Coverage Targets

- **Critical paths (install, backup, restore):** >= 80%
- **Core utility functions:** >= 90%
- **Integration points:** >= 70%
- **Edge cases:** >= 50%

### Non-Negotiable Requirements

- [ ] All P0 tests pass
- [ ] No unmitigated high-risk items (score >= 6)
- [ ] shellcheck passes on all .zsh files
- [ ] bats-core framework adopted
- [ ] CI pipeline runs on all PRs

---

## Existing Test Assets

### Current State

| Asset | Location | Status |
|-------|----------|--------|
| Amazon Q tests | tests/test-amazon-q.zsh | 16 tests, custom framework |
| Edge case tests | tests/test-amazon-q-edge-cases.zsh | Additional coverage |
| Test runner | tests/run-all-tests.sh | Shell-based runner |

### Migration Priority

1. **Keep existing tests functional** during bats migration
2. **Port Amazon Q tests to bats** as reference implementation
3. **Add new tests in bats format** for remaining stories

---

## Recommendations Summary

1. **Adopt bats-core** as primary testing framework
2. **Create mock library** for Homebrew, git, OMZ, external CLIs
3. **Implement CI matrix testing** for macOS version + architecture coverage
4. **Port existing 16 tests** to bats format as foundation
5. **Add idempotency test suite** for all mutating operations
6. **Integrate shellcheck** for static analysis in CI

---

## Follow-on Workflows

- After implementation begins, run `testarch-test-design` in **Epic-Level Mode** for detailed test plans per epic
- Use `testarch-automate` after story implementation to generate test scaffolding
- Run `testarch-test-review` to validate test quality against DoD

---

## Approval

**Testability Review Approved By:**

- [ ] Tech Lead: ________ Date: ________
- [ ] QA Lead: ________ Date: ________

**Comments:**

---

**Generated by:** BMad TEA Agent - Test Architect Module
**Workflow:** `testarch-test-design` (System-Level Mode)
**Version:** 4.0 (BMad v6)
