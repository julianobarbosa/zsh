# Story 1.6: Personal Customization Layer

Status: ready-for-dev

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

- [ ] Task 1: Validate existing implementation in `lib/install/config.zsh` (AC: 1-4)
  - [ ] 1.1 Verify `_zsh_tool_setup_custom_layer()` creates template correctly
  - [ ] 1.2 Verify migration logic in `_zsh_tool_install_config()` works
  - [ ] 1.3 Verify template (`templates/zshrc.template`) includes source line for .zshrc.local
  - [ ] 1.4 Add validation for .zshrc.local path (prevent path traversal)
  - [ ] 1.5 Add atomic write operations with permission preservation

- [ ] Task 2: Implement missing public functions (AC: 6)
  - [ ] 2.1 Implement `zsh-tool-config` dispatcher function
  - [ ] 2.2 Implement `_zsh_tool_config_custom()` - setup/status of custom layer
  - [ ] 2.3 Implement `_zsh_tool_config_show()` - display current config sources
  - [ ] 2.4 Implement `_zsh_tool_config_edit()` - open .zshrc.local in $EDITOR

- [ ] Task 3: Implement `_zsh_tool_preserve_user_config()` function (AC: 4-5)
  - [ ] 3.1 Extract content outside managed markers from existing .zshrc
  - [ ] 3.2 Safely merge into .zshrc.local without overwriting user content
  - [ ] 3.3 Handle edge cases (empty content, special characters)
  - [ ] 3.4 Escape sed patterns to prevent injection (per Story 1.5 learnings)

- [ ] Task 4: State and logging integration (AC: 7, 9)
  - [ ] 4.1 Update state.json with `custom_layer_setup: true`
  - [ ] 4.2 Track migration timestamp in state
  - [ ] 4.3 Add logging for all custom layer operations
  - [ ] 4.4 Add progress indicators for user feedback

- [ ] Task 5: Create unit tests (AC: 8, 10)
  - [ ] 5.1 Test `_zsh_tool_setup_custom_layer()` creates template
  - [ ] 5.2 Test template not overwritten if exists
  - [ ] 5.3 Test migration extracts user content correctly
  - [ ] 5.4 Test migration preserves existing .zshrc.local
  - [ ] 5.5 Test source line exists in generated .zshrc
  - [ ] 5.6 Test idempotency - multiple runs produce same result
  - [ ] 5.7 Test state update with custom_layer_setup
  - [ ] 5.8 Test public command `zsh-tool-config custom`
  - [ ] 5.9 Test path validation (no path traversal)
  - [ ] 5.10 Test atomic write with permission preservation

- [ ] Task 6: Integration validation
  - [ ] 6.1 End-to-end: fresh install creates .zshrc + .zshrc.local
  - [ ] 6.2 End-to-end: existing .zshrc with user content migrates to .zshrc.local
  - [ ] 6.3 End-to-end: re-run preserves all customizations
  - [ ] 6.4 Verify .zshrc.local sourced correctly in new shell

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

{{agent_model_name_version}}

### Debug Log References

None yet.

### Completion Notes List

_To be filled by dev agent during implementation_

### Change Log

- 2026-01-03: Story file created with comprehensive context from epic analysis

### File List

_To be filled by dev agent during implementation_
