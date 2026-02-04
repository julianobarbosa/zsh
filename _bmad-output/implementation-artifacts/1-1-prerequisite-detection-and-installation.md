# Story 1.1: Prerequisite Detection and Installation

Status: review

## Story

As a **new developer**,
I want **the tool to automatically detect and install missing prerequisites**,
so that **I don't have to manually install Homebrew, git, or other dependencies**.

## Acceptance Criteria

1. **AC1**: Tool detects if Homebrew is installed via `command -v brew`
2. **AC2**: If Homebrew missing, prompts user and runs official install script
3. **AC3**: Tool detects if git is installed via `command -v git`
4. **AC4**: If git missing and Homebrew available, installs via `brew install git`
5. **AC5**: Tool detects Xcode CLI tools via `xcode-select -p`
6. **AC6**: If Xcode CLI missing, prompts user (optional, not blocking)
7. **AC7**: Tool detects jq for state management (optional enhancement)
8. **AC8**: All prerequisite states are tracked in `state.json`
9. **AC9**: Failed installations trigger rollback of state changes
10. **AC10**: Apple Silicon Homebrew PATH handling (`/opt/homebrew/bin`)

## Tasks / Subtasks

- [x] Task 1: Core prerequisite detection functions (AC: 1,3,5,7)
  - [x] `_zsh_tool_check_homebrew()` - Detect Homebrew installation
  - [x] `_zsh_tool_check_git()` - Detect git installation
  - [x] `_zsh_tool_check_xcode_cli()` - Detect Xcode CLI tools
  - [x] `_zsh_tool_check_jq()` - Detect jq for JSON manipulation
- [x] Task 2: Installation functions with rollback (AC: 2,4,6,7,9)
  - [x] `_zsh_tool_install_homebrew()` - Install with rollback support
  - [x] `_zsh_tool_install_git()` - Install via Homebrew with rollback
  - [x] `_zsh_tool_install_xcode_cli()` - Prompt-based optional install
  - [x] `_zsh_tool_install_jq()` - Optional JSON tool install
- [x] Task 3: State management integration (AC: 8)
  - [x] Update `state.json` with prerequisite statuses
  - [x] Support both jq and sed-based state updates
- [x] Task 4: Apple Silicon support (AC: 10)
  - [x] Detect arm64 architecture
  - [x] Set Homebrew PATH for Apple Silicon
- [x] Task 5: Testing and verification
  - [x] Unit tests in `tests/test-prerequisites.zsh` (24 tests - zsh-based test suite)
  - [x] Integration test for full prerequisite flow (included in test suite)
  - [x] shellcheck validation (SC2155 warnings fixed, only SC2001 style suggestions remain for sed)
  - [x] Testing on macOS (current version - Tahoe/arm64)

### Review Follow-ups (AI)

- [x] [AI-Review][Medium] Add rollback mechanism to `_zsh_tool_install_jq()` for AC9 consistency [lib/install/prerequisites.zsh:138-162]
- [x] [AI-Review][Medium] Fix stale Dev Notes - update File Structure to reference actual test file [story file:73-77]
- [x] [AI-Review][Medium] Improve test skip handling with explicit skip tracking [tests/test-prerequisites.zsh]
- [x] [AI-Review][Low] Fix inconsistent log message in `_zsh_tool_check_jq()` [lib/install/prerequisites.zsh:129]
- [x] [AI-Review][Low] Document fragile sed JSON fallback with comment [lib/install/prerequisites.zsh:219-226]
- [x] [AI-Review][Low] Add comment about Apple Silicon test coverage limitation [tests/test-prerequisites.zsh]

## Dev Notes

### Current Implementation Status

**IMPORTANT**: This story has significant implementation already completed. The file `lib/install/prerequisites.zsh` (233 lines) contains:

- All core detection functions implemented
- All installation functions with rollback support
- State management with both jq and sed fallback
- Apple Silicon PATH handling

**Primary work remaining**: Testing, validation, and potential refinements.

### Relevant Architecture Patterns

**Source:** [docs/solution-architecture.md]

- **Technology Stack**: zsh 5.8+, Homebrew 4.0+, git 2.30+, bats-core 1.10.0
- **Module Location**: `lib/install/prerequisites.zsh`
- **State File**: `~/.config/zsh-tool/state.json`
- **Error Handling**: Fail-fast with rollback on failure
- **Idempotency**: Check-then-act pattern throughout

### File Structure

```
lib/install/prerequisites.zsh    # Main implementation (EXISTS)
lib/core/utils.zsh               # Shared utilities (EXISTS)
tests/test-prerequisites.zsh     # Unit tests - zsh-based (EXISTS - 24 tests)
```

### Dependencies

**Internal Dependencies:**
- `lib/core/utils.zsh` - Provides:
  - `_zsh_tool_log()` - Logging function
  - `_zsh_tool_is_installed()` - Command existence check
  - `_zsh_tool_prompt_confirm()` - User confirmation prompts
  - `_zsh_tool_load_state()` / `_zsh_tool_save_state()` - State management

**External Dependencies:**
- Homebrew official install script: `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh`
- curl (pre-installed on macOS)

### Technical Requirements

**Source:** [docs/tech-spec-epic-1.md#Story 1.1]

**State Tracking Structure:**
```json
{
  "prerequisites": {
    "homebrew": true,
    "git": true,
    "jq": true,
    "xcode_cli": false
  }
}
```

**Homebrew Installation:**
- Run via: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Apple Silicon requires: `eval "$(/opt/homebrew/bin/brew shellenv)"`

**Error Handling:**
- If Homebrew install fails: Display manual instructions, exit 1
- If git install fails: Rollback state, exit 1
- If Xcode CLI missing: Warn user, continue (git via Homebrew works without)

### Testing Requirements

**Unit Tests (bats-core):**
```bash
@test "prerequisites: detects installed Homebrew" { ... }
@test "prerequisites: installs Homebrew if missing" { ... }
@test "prerequisites: detects installed git" { ... }
@test "prerequisites: installs git via Homebrew" { ... }
@test "prerequisites: handles Apple Silicon PATH" { ... }
@test "prerequisites: state tracking works" { ... }
```

**Integration Test:**
- Full prerequisite check flow
- Verify state.json updated correctly
- Verify rollback on failure

### Project Structure Notes

**Alignment with unified project structure:**
- Module follows `lib/{category}/{function}.zsh` pattern
- Uses `_zsh_tool_` prefix for internal functions
- State stored in XDG-compliant `~/.config/zsh-tool/`

**Existing Patterns to Follow:**
- Logging via `_zsh_tool_log {level} {message}`
- Confirmations via `_zsh_tool_prompt_confirm {message}`
- State via `_zsh_tool_load_state` / `_zsh_tool_save_state`

### References

- [Source: docs/solution-architecture.md#Section 7.3 Idempotency]
- [Source: docs/tech-spec-epic-1.md#Story 1.1]
- [Source: docs/project-context.md]
- [Existing Implementation: lib/install/prerequisites.zsh]
- [Utilities: lib/core/utils.zsh]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- Test run: 2026-02-04, all 24 tests passed (added jq rollback test after code review)
- Code review: 2026-02-04, 6 findings resolved (3 Medium, 3 Low)
- shellcheck validation: Fixed SC2155 warnings (declare and assign separately)
- Remaining SC2001 style suggestions are acceptable (sed for JSON regex manipulation)

### Completion Notes List

- ✅ All core detection functions verified working (Homebrew, git, Xcode CLI, jq)
- ✅ All installation functions have rollback support (including jq - fixed in review)
- ✅ State management works with both jq and sed fallback (with fragility documented)
- ✅ Apple Silicon PATH handling confirmed (`/opt/homebrew/bin`) with test coverage note
- ✅ 24 unit tests all passing (added jq rollback test)
- ✅ shellcheck warnings fixed (SC2155 - separate declare/assign)
- ✅ Code quality improved while maintaining all functionality
- ✅ All 6 code review action items resolved (3 Medium, 3 Low)

### Change Log

- 2026-02-04: Fixed all 6 code review action items (3 Medium, 3 Low)
- 2026-02-04: Added rollback mechanism to `_zsh_tool_install_jq()` for AC9 consistency
- 2026-02-04: Added explicit skip tracking (TESTS_SKIPPED counter, test_skip function)
- 2026-02-04: Fixed inconsistent log message in `_zsh_tool_check_jq()` - now says "jq $version"
- 2026-02-04: Added comment documenting fragile sed JSON fallback
- 2026-02-04: Added comment about Apple Silicon test coverage limitation
- 2026-02-04: Updated File Structure in Dev Notes to reference actual test file
- 2026-02-04: Fixed shellcheck SC2155 warnings - separate variable declarations from assignments
- 2026-02-04: Removed unused variables (homebrew_needed, git_needed, jq_needed)
- 2026-02-04: Renamed `path` variable to `xcode_path` to avoid shadowing

### File List

**Modified Files:**
- `lib/install/prerequisites.zsh` - Fixed shellcheck warnings (SC2155), removed unused variables

**Test Files (Existing):**
- `tests/test-prerequisites.zsh` - Comprehensive test suite (24 tests)
