# Story 3.2: Kiro CLI Integration

Status: done

---

## Story

**As a** developer using zsh-tool
**I want** to integrate Kiro CLI (formerly Amazon Q Developer CLI) into my zsh environment
**So that** I can leverage AI-powered command line assistance while maintaining my existing workflow tools

---

## Acceptance Criteria

1. **AC1:** Kiro CLI detection validates actual Kiro CLI (not other `q` or `kiro-cli` commands)
2. **AC2:** Guided installation via official installer or Homebrew
3. **AC3:** Shell integration configured with lazy loading
4. **AC4:** Atuin compatibility through disabled CLIs list
5. **AC5:** Performance optimization via lazy loading (reduces startup time to near-zero)
6. **AC6:** Configuration management for Kiro CLI settings
7. **AC7:** Secure .zshrc injection without command injection vulnerabilities
8. **AC8:** Health check via `kiro-cli doctor` or `q doctor`
9. **AC9:** Comprehensive test coverage

---

## Tasks / Subtasks

- [x] Task 1: Create `lib/integrations/kiro-cli.zsh` module (AC: 1-9)
  - [x] 1.1 Implement `kiro_install_integration()` - main installation command
  - [x] 1.2 Implement `_kiro_is_installed()` - validates Kiro CLI installation (not generic `q`)
  - [x] 1.3 Implement `_kiro_detect()` - detection with version info
  - [x] 1.4 Implement `_kiro_install()` - displays installation instructions
  - [x] 1.5 Implement `_kiro_configure_shell_integration()` - shell setup
  - [x] 1.6 Implement `_kiro_setup_lazy_loading()` - lazy loading for performance

- [x] Task 2: Detection and validation (AC: 1, 8)
  - [x] 2.1 Detect Kiro CLI vs other `q` commands (check for version string)
  - [x] 2.2 Support both `kiro-cli` and legacy `q` commands
  - [x] 2.3 Run `kiro-cli doctor` / `q doctor` health check

- [x] Task 3: Installation guidance (AC: 2)
  - [x] 3.1 Homebrew: `brew install --cask kiro-cli`
  - [x] 3.2 Direct install: `curl -fsSL https://cli.kiro.dev/install | bash`
  - [x] 3.3 Manual download instructions
  - [x] 3.4 Verify installation after user confirmation

- [x] Task 4: Shell integration with lazy loading (AC: 3, 5)
  - [x] 4.1 Create lazy loading wrapper to defer initialization
  - [x] 4.2 Create backup before modifying .zshrc
  - [x] 4.3 Handle first-invocation initialization
  - [x] 4.4 Support both `kiro-cli` and `q` aliases

- [x] Task 5: Atuin compatibility (AC: 4)
  - [x] 5.1 Configure Kiro CLI's disabledClis list
  - [x] 5.2 Use jq for safe JSON manipulation
  - [x] 5.3 Validate CLI names before adding to settings

- [x] Task 6: Secure configuration (AC: 6, 7)
  - [x] 6.1 Validate all user inputs (`_kiro_validate_cli_name`)
  - [x] 6.2 Use safe heredoc patterns for multiline strings
  - [x] 6.3 Atomic file operations with temp files
  - [x] 6.4 Rollback on configuration failure

- [x] Task 7: State tracking
  - [x] 7.1 Update state.json integration

- [x] Task 8: Write unit tests (AC: 9)
  - [x] 8.1 Test Kiro CLI detection (installed/not installed/wrong q)
  - [x] 8.2 Test lazy loading configuration
  - [x] 8.3 Test Atuin compatibility setup
  - [x] 8.4 Test secure settings file manipulation
  - [x] 8.5 Test health check validation
  - [x] 8.6 Test edge cases (test-kiro-cli-edge-cases.zsh)

---

## Dev Notes

### Component Location

**File:** `lib/integrations/kiro-cli.zsh` (510 lines)

**Dependencies:**
- `lib/core/utils.zsh` - Logging, state management, prompts
- `jq` - Required for safe JSON manipulation

### Implementation Details

**Detection Pattern:**
```zsh
_kiro_is_installed() {
  # Check for kiro-cli or q command
  # Verify it's actually Kiro CLI by checking version output
  # Handles: Kiro CLI vX.X.X format
}
```

**Installation Options:**
1. Homebrew: `brew install --cask kiro-cli`
2. Direct: `curl -fsSL https://cli.kiro.dev/install | bash`
3. Manual download from kiro.dev

**Lazy Loading:**
- Creates aliases for `kiro-cli` and `q`
- Defers shell integration until first use
- Reduces shell startup time significantly

**Atuin Compatibility:**
- Adds `atuin` to `~/.kiro/settings/cli.json` disabledClis array
- Prevents keybinding conflicts with Ctrl+R

### File Structure

```
lib/integrations/
├── atuin.zsh       ← Atuin integration (39KB)
├── kiro-cli.zsh    ← THIS STORY (16KB)
└── (no amazon-q.zsh - Kiro CLI is the rebranded version)

tests/
├── test-kiro-cli.zsh           ← Unit tests (12KB)
└── test-kiro-cli-edge-cases.zsh ← Edge case tests (23KB)
```

### Note on Naming

**Amazon Q Developer CLI was rebranded to Kiro CLI in November 2025:**
- The `q` command is still supported for backwards compatibility
- New installations use `kiro-cli` command
- Configuration moved from `~/.amazonq/` to `~/.kiro/`

---

## References

- [Kiro CLI Documentation](https://kiro.dev/docs/cli/)
- [Kiro CLI Installation](https://kiro.dev/docs/cli/installation/)
- [Upgrading from Amazon Q Developer CLI](https://kiro.dev/docs/cli/migrating-from-q/)
- [Source: docs/solution-architecture.md#Section 3.2 - Epic 3 Modules]
- [Source: docs/epic-stories.md#Story 3.2]
- [Source: lib/integrations/atuin.zsh - Reference implementation]

---

## Dev Agent Record

### Agent Model Used

Claude (multiple sessions)

### Debug Log References

- Tests run: 2026-01-05
- test-kiro-cli.zsh - All tests passing
- test-kiro-cli-edge-cases.zsh - Edge cases covered

### Completion Notes List

1. **Implementation complete:** Full Kiro CLI integration in `lib/integrations/kiro-cli.zsh`
2. **Detection:** Supports both `kiro-cli` and legacy `q` commands with version validation
3. **Installation:** Three installation paths (Homebrew, curl, manual)
4. **Lazy loading:** Performance optimization implemented with backup/restore
5. **Atuin compatibility:** Proper disabledClis configuration via jq
6. **Security:** Input validation, atomic file ops, temp file cleanup
7. **Tests:** Comprehensive test suite with edge cases

### File List

**Implementation:**
- `lib/integrations/kiro-cli.zsh` - Main implementation (510 lines)

**Tests:**
- `tests/test-kiro-cli.zsh` - Unit tests
- `tests/test-kiro-cli-edge-cases.zsh` - Edge case tests
