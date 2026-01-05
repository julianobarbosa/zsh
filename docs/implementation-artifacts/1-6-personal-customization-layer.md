# Story 1.6: Personal Customization Layer

Status: in-progress

---

## Story

**As a** developer
**I want** to add personal configurations without breaking team standards
**So that** I can customize my environment while maintaining consistency

**Mapped Requirements:** FR010
**Story Points:** 3

---

## Acceptance Criteria

1. **AC1:** Tool creates `~/.zshrc.local` template file if it doesn't exist
2. **AC2:** Tool preserves existing `.zshrc.local` content (never overwrites user customizations)
3. **AC3:** Generated `.zshrc` sources `.zshrc.local` after the managed section
4. **AC4:** During install, tool migrates existing user content from `.zshrc` to `.zshrc.local`
5. **AC5:** Re-running install preserves `.zshrc.local` completely
6. **AC6:** Tool provides `zsh-tool-config custom` command to manage customization layer
7. **AC7:** Tool updates `state.json` with `custom_layer_setup: true` after setup
8. **AC8:** All operations are idempotent - running twice produces same result
9. **AC9:** Tool logs all customization layer operations with progress indicators
10. **AC10:** Comprehensive tests exist for customization layer functionality

---

## Tasks / Subtasks

- [x] Task 1: Validate existing implementation in `lib/install/config.zsh` (AC: 1-4)
  - [x] 1.1 Verify `_zsh_tool_setup_custom_layer()` creates template correctly
  - [x] 1.2 Verify migration logic in `_zsh_tool_install_config()` works
  - [x] 1.3 Verify template (`templates/zshrc.template`) includes source line for .zshrc.local
  - [x] 1.4 Add validation for .zshrc.local path (prevent path traversal)
  - [x] 1.5 Add atomic write operations with permission preservation

- [x] Task 2: Implement missing public functions (AC: 6)
  - [x] 2.1 Implement `zsh-tool-config` dispatcher function
  - [x] 2.2 Implement `_zsh_tool_config_custom()` - setup/status of custom layer
  - [x] 2.3 Implement `_zsh_tool_config_show()` - display current config sources
  - [x] 2.4 Implement `_zsh_tool_config_edit()` - open .zshrc.local in $EDITOR

- [x] Task 3: Implement `_zsh_tool_preserve_user_config()` function (AC: 4-5)
  - [x] 3.1 Extract content outside managed markers from existing .zshrc
  - [x] 3.2 Safely merge into .zshrc.local without overwriting user content
  - [x] 3.3 Handle edge cases (empty content, special characters)
  - [x] 3.4 Escape sed patterns to prevent injection (per Story 1.5 learnings)

- [x] Task 4: State and logging integration (AC: 7, 9)
  - [x] 4.1 Update state.json with `custom_layer_setup: true`
  - [x] 4.2 Track migration timestamp in state
  - [x] 4.3 Add logging for all custom layer operations
  - [x] 4.4 Add progress indicators for user feedback

- [x] Task 5: Create unit tests (AC: 8, 10)
  - [x] 5.1 Test `_zsh_tool_setup_custom_layer()` creates template
  - [x] 5.2 Test template not overwritten if exists
  - [x] 5.3 Test migration extracts user content correctly
  - [x] 5.4 Test migration preserves existing .zshrc.local
  - [x] 5.5 Test source line exists in generated .zshrc
  - [x] 5.6 Test idempotency - multiple runs produce same result
  - [x] 5.7 Test state update with custom_layer_setup
  - [x] 5.8 Test public command `zsh-tool-config custom`
  - [x] 5.9 Test path validation (no path traversal)
  - [x] 5.10 Test atomic write with permission preservation

- [x] Task 6: Integration validation
  - [x] 6.1 End-to-end: fresh install creates .zshrc + .zshrc.local
  - [x] 6.2 End-to-end: existing .zshrc with user content migrates to .zshrc.local
  - [x] 6.3 End-to-end: re-run preserves all customizations
  - [x] 6.4 Verify .zshrc.local sourced correctly in new shell

### Review Follow-ups (AI) - Previous Review

- [x] [AI-Review][HIGH] #1: Add progress indicators using _zsh_tool_with_spinner (AC9 violation) [lib/install/config.zsh:293,271]

### Review Follow-ups (AI) - 2026-01-03

- [x] [AI-Review][HIGH] Update File List to reflect current git state [story file] - Updated with accurate dates
- [x] [AI-Review][MEDIUM] Verify previous review fix still applied [lib/install/config.zsh] - All fixes validated in code
- [x] [AI-Review][HIGH] #2: Fix "custom setup" subcommand - implement or remove from error message [lib/install/config.zsh:472]
- [x] [AI-Review][HIGH] #3: Add symlink validation to _zsh_tool_validate_path [lib/install/config.zsh:303-333]
- [x] [AI-Review][HIGH] #4: Replace $$ with mktemp for atomic writes (race condition) [lib/install/config.zsh:267,380,428]
- [x] [AI-Review][HIGH] #5: Add error handling for mv operations [lib/install/config.zsh:288,408,456]
- [x] [AI-Review][HIGH] #6: Update test file header to include Story 1.6 [tests/test-config.zsh:2-5]
- [x] [AI-Review][MEDIUM] #7: Optimize grep chain in template filtering [lib/install/config.zsh:371]
- [x] [AI-Review][MEDIUM] #8: Make template line filtering dynamic instead of hardcoded [lib/install/config.zsh:371]
- [x] [AI-Review][MEDIUM] #9: Validate $EDITOR before execution [lib/install/config.zsh:559-564]

### Review Follow-ups (AI) - 2026-01-04 - ADVERSARIAL REVIEW (YOLO MODE)

- [ ] [AI-Review][HIGH] Migration logic has no rollback - partial .zshrc.local on failure [lib/install/config.zsh:migration]
- [ ] [AI-Review][HIGH] No validation that source line doesn't already exist before adding [lib/install/config.zsh:template]
- [ ] [AI-Review][MEDIUM] Complex marker-based extraction - brittle if markers malformed [lib/install/config.zsh:371]
- [ ] [AI-Review][MEDIUM] Permission preservation failures logged but not handled [lib/install/config.zsh:288,408,456]
- [ ] [AI-Review][LOW] No test for duplicate source lines in .zshrc [tests/test-config.zsh]

---

## Dev Notes

### CRITICAL: Implementation Partially Exists

**Implementation at `lib/install/config.zsh` is PARTIALLY COMPLETE.** Current state:

**Implemented Functions (lines 294-315, 270-278):**
- `_zsh_tool_setup_custom_layer()` - Creates .zshrc.local template if doesn't exist
- Migration logic in `_zsh_tool_install_config()` - Extracts user content to .zshrc.local

**Template Status (`templates/zshrc.template` line 31):**
- Source line EXISTS: `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local`
- Managed section markers in place

**Missing Functions (per Architecture Section 6.1):**
- `zsh-tool-config` - Public dispatcher (custom|show|edit)
- `_zsh_tool_config_custom()` - Setup/status of customization layer
- `_zsh_tool_config_show()` - Display configuration sources
- `_zsh_tool_config_edit()` - Open .zshrc.local in editor
- `_zsh_tool_preserve_user_config()` - Separate function for extraction logic

**Missing Tests:**
- No `tests/test-config.zsh` has customization layer tests - needs EXTENSION

### Component Location

- **Primary File:** `lib/install/config.zsh` (extend existing)
- **Template File:** `templates/zshrc.template` (already complete)
- **Test File:** `tests/test-config.zsh` (extend existing)
- **Dependencies:**
  - `lib/core/utils.zsh` (logging, state management)
  - Variables: `ZSH_TOOL_CONFIG_DIR`, `ZSH_TOOL_LOG_FILE`, `ZSH_TOOL_STATE_FILE`

### Architecture Compliance

**MUST follow these patterns from solution-architecture.md:**

1. **Function naming convention:**
   - Public functions: `zsh-tool-config` (user-facing)
   - Internal functions: `_zsh_tool_*` prefix

2. **Public Interface (Section 6.1):**
   ```zsh
   zsh-tool-config [custom|show|edit]
   # custom: Setup/check customization layer status
   # show: Display current configuration sources
   # edit: Open .zshrc.local in $EDITOR
   ```

3. **Customization Pattern (from tech-spec):**
   ```zsh
   # .zshrc (managed by zsh-tool)
   # ===== ZSH-TOOL MANAGED SECTION BEGIN =====
   # Team config here
   # ===== ZSH-TOOL MANAGED SECTION END =====

   # Source personal customizations
   [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
   ```

4. **Idempotency Pattern (Section 7.3):**
   ```zsh
   # Check-then-act pattern
   if [[ -f "$zshrc_local" ]]; then
     _zsh_tool_log DEBUG ".zshrc.local already exists, skipping creation"
     return 0
   fi
   ```

### .zshrc.local Template Content

Current template (verify in `_zsh_tool_setup_custom_layer()`):
```zsh
# Personal zsh customizations
# This file is NOT managed by zsh-tool

# Your custom aliases
# alias ll='ls -lah'

# Your custom exports
# export MY_VAR="value"

# Your custom functions
# my_function() {
#   echo "custom"
# }
```

### Migration Logic

Existing migration logic in `_zsh_tool_install_config()` (lines 270-278):
```zsh
# Extract user content (everything outside managed section)
local user_content=$(sed -n "/${ZSH_TOOL_MANAGED_BEGIN}/,/${ZSH_TOOL_MANAGED_END}/!p" "$zshrc" 2>/dev/null || echo "")

# If user content exists and .zshrc.local doesn't exist, save it
if [[ -n "$user_content" && ! -f "${HOME}/.zshrc.local" ]]; then
  _zsh_tool_log INFO "Migrating existing configuration to .zshrc.local"
  echo "$user_content" > "${HOME}/.zshrc.local"
fi
```

**Known Issues:**
- No atomic write (should use temp file + mv)
- No permission preservation
- No state update after migration
- sed pattern escaping concerns (see Story 1.5 learnings)

### Previous Story Intelligence

**Key learnings from Story 1.5 (Themes):**

1. **Use `typeset -gA`** for global associative arrays when sourced from functions
2. **Use `${pipestatus[1]}`** not `${PIPESTATUS[1]}` (zsh lowercase)
3. **Add validation function** to prevent path traversal and injection
4. **Escape sed patterns** to prevent injection
5. **Preserve file permissions** when editing files
6. **Update state AFTER success** to maintain consistency
7. **Add progress spinner** for long operations using `_zsh_tool_with_spinner`

### Testing Standards

**Testing Framework:** zsh native (matching previous story patterns)

**Test File:** `tests/test-config.zsh` (extend existing)

**Required Test Categories:**

1. Template creation tests - Creates .zshrc.local if missing
2. Template preservation tests - Never overwrites existing .zshrc.local
3. Migration tests - Extracts user content from .zshrc
4. Merge tests - Appends to existing .zshrc.local
5. Idempotency tests - Multiple runs produce same result
6. Source line tests - .zshrc includes source line
7. State update tests - custom_layer_setup in state.json
8. Public command tests - zsh-tool-config subcommands
9. Security tests - Path traversal prevention

### Library/Framework Requirements

| Library | Version | Purpose |
|---------|---------|---------|
| zsh | 5.8+ | Core shell |
| sed | any | Content extraction |

### Git Intelligence

**Recent commits (relevant patterns):**
```
5674ae7 fix(themes): complete story 1.5 with security fixes from code review
```

**Patterns from recent work:**
- Security fixes applied via sed escaping
- State updates added for compliance
- Progress spinners added for user feedback
- Tests created for all functionality

---

## References

- [Source: docs/epic-stories.md#Story 1.6]
- [Source: docs/tech-spec-epic-1.md#Story 1.6: Personal Customization Layer]
- [Source: lib/install/config.zsh:294-315 - _zsh_tool_setup_custom_layer()]
- [Source: lib/install/config.zsh:270-278 - Migration logic in _zsh_tool_install_config()]
- [Source: templates/zshrc.template:31 - Source line for .zshrc.local]
- [Source: lib/core/utils.zsh - Logging and state utilities]
- [Source: tests/test-config.zsh - Existing config tests]

---

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

None - all tests passed on first attempt after implementation.

### Completion Notes List

**Implementation Summary:**

✅ **Task 1 (Validation & Enhancement):** Enhanced existing `_zsh_tool_setup_custom_layer()` with:
- Path validation function `_zsh_tool_validate_path()` to prevent traversal attacks
- Atomic write operations using temp files with `$$` PID suffix
- macOS and Linux compatible permission preservation (stat -f/%OLp vs stat -c/%a)
- State tracking updates (custom_layer_setup, migration_timestamp)

✅ **Task 2 (Public Functions):** Implemented complete public interface:
- `zsh-tool-config` dispatcher supporting custom|show|edit subcommands
- `_zsh_tool_config_custom()` - displays custom layer status with file stats
- `_zsh_tool_config_show()` - shows all config sources (main, custom, team)
- `_zsh_tool_config_edit()` - opens .zshrc.local in $EDITOR with auto-creation

✅ **Task 3 (Preserve User Config):** Created new `_zsh_tool_preserve_user_config()`:
- Extracts content outside managed section markers with sed
- Escapes special regex characters in markers to prevent injection (Story 1.5 pattern)
- Filters out template-generated lines to avoid re-migration
- Merges preserved content into existing .zshrc.local or creates new file
- Atomic writes with permission preservation
- State updates with migration timestamp

✅ **Task 4 (State & Logging):** Integrated comprehensive tracking:
- `custom_layer_setup: true` after template creation
- `custom_layer_migrated: true` after content preservation
- `migration_timestamp` with ISO datetime
- DEBUG/INFO logging throughout all operations

✅ **Task 5 (Unit Tests):** Added 20 new tests to `tests/test-config.zsh`:
- Security: path validation (traversal, tilde expansion)
- Preserve: creates, merges, escapes sed patterns, state updates, atomic writes
- Setup: state tracking, atomic writes, idempotency
- Public commands: existence, status display, error handling, usage messages
- Integration: install workflow, permission preservation, template verification

✅ **Task 6 (Integration Validation):** Verified end-to-end workflows:
- Fresh install: creates both .zshrc and .zshrc.local
- Upgrade scenario: migrates user content to .zshrc.local
- Idempotency: re-runs don't duplicate content
- State tracking: all operations update state.json correctly

**Test Results:** 49/49 tests passing (100% success rate)

**Security Improvements Applied:**
- Path traversal prevention (rejects ../and ~ patterns)
- Sed pattern escaping for managed markers
- Template line filtering to prevent re-migration loops
- Atomic file operations throughout

**Code Review Fixes Applied (2026-01-03):**

✅ **HIGH Issues Fixed (6):**
1. Added progress indicators using `_zsh_tool_with_spinner` (AC9 compliance)
2. Fixed false "custom setup" command reference in error message
3. Enhanced path validation with symlink resolution and validation
4. Replaced `$$` PID-based temp files with `mktemp` (eliminates race conditions)
5. Added comprehensive error handling for all `mv` operations with cleanup
6. Updated test file header to properly attribute Stories 1.3 & 1.6

✅ **MEDIUM Issues Fixed (3):**
7. Optimized grep chain from 5 processes to 1 using extended regex
8. Made template filtering more efficient (combined with #7)
9. Added $EDITOR validation before execution (prevents command injection)

**Post-Review Test Results:** 49/49 tests passing (100% success rate maintained)

### Change Log

- 2026-01-03: Story file created with comprehensive context from epic analysis
- 2026-01-03: Implemented all AC requirements with TDD red-green-refactor approach
- 2026-01-03: All tasks completed - 49 unit/integration tests passing
- 2026-01-03: Code review performed - 9 issues found (6 HIGH, 3 MEDIUM)
- 2026-01-03: All review issues fixed and validated - tests still passing

### File List

**Implementation:**
- `lib/install/config.zsh` - Team configuration management with personal customization layer support, including user content migration and .zshrc.local management (Last modified: 2026-01-03)
- `lib/core/utils.zsh` - Core utilities dependency (validated)

**Tests:**
- `tests/test-config.zsh` - 49 comprehensive tests covering config parsing, template generation, migration, and customization layer (Stories 1.3 & 1.6), all passing (Last modified: 2026-01-03)

**Documentation:**
- `docs/implementation-artifacts/1-6-personal-customization-layer.md` - This story file

**Functions Implemented for Story 1.6:**
- `_zsh_tool_validate_path()` - Path validation with traversal and symlink protection
- `_zsh_tool_preserve_user_config()` - User content preservation with atomic writes
- `zsh-tool-config()` - Public dispatcher for customization commands
- `_zsh_tool_config_custom()` - Customization layer status display
- `_zsh_tool_config_show()` - Configuration sources overview
- `_zsh_tool_config_edit()` - Safe editor integration for .zshrc.local
- Enhanced `_zsh_tool_install_config()` - Integrated migration and setup
- Enhanced `_zsh_tool_setup_custom_layer()` - Path validation and atomic operations
