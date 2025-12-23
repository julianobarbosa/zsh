# Story: Add Safety Checks to .zshrc Modification

**Story ID**: ZSHTOOL-BUG-006
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Medium
**Estimate**: 3 points
**Status**: Ready for Review
**Created**: 2025-10-02
**Labels**: bug, medium-priority

## Story

As a developer, I want .zshrc modifications to include safety checks and backups, so that my shell configuration is protected from corruption.

## Context

`_amazonq_setup_lazy_loading` appends code to `.zshrc` without creating backups, checking for symlinks, or handling write failures, which could corrupt user configurations.

### Current Code
```zsh
cat >> "$zshrc" << 'EOF'
# ... lazy loading code ...
EOF

_zsh_tool_log INFO "✓ Lazy loading configured"
```

### Risks
- No backup before modification
- Could break symlinked configurations
- No rollback on failure
- No permission checks

## Acceptance Criteria

- [x] Create backup before modifying .zshrc
- [x] Check if .zshrc is a symlink
- [x] Verify file is writable
- [x] Rollback on failure
- [x] All tests pass

## Tasks/Subtasks

- [x] **Task 1: Add backup creation**
  - [x] Create timestamped backup
  - [x] Verify backup succeeded

- [x] **Task 2: Add symlink detection**
  - [x] Check if .zshrc is symlink
  - [x] Warn user and ask for confirmation

- [x] **Task 3: Add write verification**
  - [x] Check write permissions
  - [x] Verify append succeeded

- [x] **Task 4: Add rollback capability**
  - [x] Restore backup on failure
  - [x] Log rollback actions

### Review Follow-ups (AI)
- [ ] [AI-Review][MEDIUM] Add backup cleanup - keep only N most recent backup files [lib/integrations/amazon-q.zsh:379]
- [ ] [AI-Review][MEDIUM] Review non-interactive symlink handling - may modify shared configs silently in CI/CD [lib/integrations/amazon-q.zsh:362-369]
- [ ] [AI-Review][MEDIUM] Add test for rollback when append fails [tests/test-amazon-q-edge-cases.zsh]

## Technical Implementation

```zsh
_amazonq_setup_lazy_loading() {
  _zsh_tool_log INFO "Setting up lazy loading for Amazon Q..."

  local zshrc="${HOME}/.zshrc"
  local lazy_load_marker="# Amazon Q lazy loading (zsh-tool)"

  # Verify .zshrc exists
  if [[ ! -f "$zshrc" ]]; then
    _zsh_tool_log ERROR ".zshrc not found: $zshrc"
    return 1
  fi

  # Check for symlink
  if [[ -L "$zshrc" ]]; then
    _zsh_tool_log WARN ".zshrc is a symlink: $zshrc -> $(readlink $zshrc)"
    _zsh_tool_log WARN "Modifying symlinked configuration may affect other systems"
    if ! _zsh_tool_prompt_confirm "Continue anyway?"; then
      return 1
    fi
  fi

  # Check if already configured
  if grep -q "$lazy_load_marker" "$zshrc" 2>/dev/null; then
    _zsh_tool_log INFO "✓ Lazy loading already configured"
    return 0
  fi

  # Create backup
  local backup="${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"
  if ! cp "$zshrc" "$backup"; then
    _zsh_tool_log ERROR "Failed to create backup: $backup"
    return 1
  fi
  _zsh_tool_log INFO "Created backup: $backup"

  # Append with error checking
  if ! cat >> "$zshrc" << 'EOF'

# Amazon Q lazy loading (zsh-tool)
_amazonq_lazy_init() {
  unfunction q 2>/dev/null
  if [[ -f "${HOME}/.aws/amazonq/shell/zshrc" ]]; then
    source "${HOME}/.aws/amazonq/shell/zshrc"
  fi
  q "$@"
}
alias q='_amazonq_lazy_init'

EOF
  then
    _zsh_tool_log ERROR "Failed to append lazy loading code"
    _zsh_tool_log INFO "Restoring from backup..."
    mv "$backup" "$zshrc"
    return 1
  fi

  _zsh_tool_log INFO "✓ Lazy loading configured"
  return 0
}
```

## Definition of Done

- All tasks checked off
- Backup/rollback implemented
- Tests added and passing
- Code reviewed

## References

- **Location**: `lib/integrations/amazon-q.zsh:294-386`
- **Epic**: Epic 3 - Advanced Integrations

---

## File List

- `lib/integrations/amazon-q.zsh` - Already implements all safety checks

## Change Log

**2025-10-02**: Verified .zshrc safety checks implementation
- Timestamped backup creation (line 331-337)
- Symlink detection with user confirmation (lines 308-322)
- Write verification with error checking (lines 340-371)
- Rollback capability on failure (lines 363-370, 374-378)
- Additional verification after append (lines 373-379)

## Dev Agent Record

### Debug Log

**Verification:**
- Reviewed `_amazonq_setup_lazy_loading` function (lines 294-386)
- All safety checks are properly implemented
- Backup creation: timestamped with verification
- Symlink detection: warns user and prompts for confirmation
- Write verification: checks `cat >>` return code
- Rollback: restores backup on append failure or verification failure

### Completion Notes

All required safety checks were already implemented in a previous fix. The current implementation includes:

1. **Backup Creation** (lines 331-337):
   - Creates timestamped backup before modification
   - Verifies backup succeeded
   - Aborts on backup failure to avoid data loss

2. **Symlink Detection** (lines 308-322):
   - Detects symlinked .zshrc
   - Warns about potential impact on other systems
   - Prompts user for confirmation (or continues in non-interactive mode)

3. **Write Verification** (lines 340-371):
   - Checks return code of `cat >>` operation
   - Logs errors if append fails
   - Initiates rollback on write failure

4. **Rollback Capability** (lines 363-370, 374-378):
   - Restores from backup if append fails
   - Also restores if marker verification fails
   - Provides clear error messages if rollback fails

The implementation exceeds requirements by adding post-append verification.
