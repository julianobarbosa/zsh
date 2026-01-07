# Story 2.4: Configuration Restore from Backup

Status: review

---

## Story

**As a** developer
**I want** to restore my zsh configuration from any available backup
**So that** I can recover from configuration errors, experiment safely, and sync configurations across machines

---

## Acceptance Criteria

1. **AC1:** Command `zsh-tool-restore list` lists all available backups with selection numbers
2. **AC2:** Command `zsh-tool-restore apply <backup-id>` restores from selected backup
3. **AC3:** Restore displays manifest showing what will be restored before confirmation
4. **AC4:** Pre-restore backup is created automatically before overwriting current state
5. **AC5:** Restore copies files atomically (temp file then mv) to prevent corruption
6. **AC6:** Restore updates state.json with last_restore metadata
7. **AC7:** Restore prompts user confirmation before applying (unless --force)
8. **AC8:** Restore prompts user to reload shell after successful restoration
9. **AC9:** Backup not found displays error with available backup list
10. **AC10:** Restore failure mid-operation rolls back to pre-restore backup automatically
11. **AC11:** Partial restore with --files flag restores only specified files (future enhancement, stub OK)
12. **AC12:** File permission issues logged with actionable message suggesting sudo if needed

---

## Tasks / Subtasks

- [x] Task 1: Create restore.zsh module (AC: 1-12)
  - [x] 1.1 Implement `_zsh_tool_restore_list()` - reuse `_zsh_tool_list_backups()` from backup-mgmt.zsh
  - [x] 1.2 Implement `_zsh_tool_restore_from_backup(backup_id)` - main restore logic
  - [x] 1.3 Implement `_zsh_tool_parse_manifest(backup_path)` - load and validate backup manifest
  - [x] 1.4 Implement `_zsh_tool_restore_file(source, dest)` - atomic file copy
  - [x] 1.5 Implement `_zsh_tool_restore_directory(source, dest)` - atomic directory copy
  - [x] 1.6 Implement `_zsh_tool_verify_restore()` - verify restoration success
  - [x] 1.7 Implement `_zsh_tool_rollback_restore(pre_restore_backup)` - rollback on failure

- [x] Task 2: Update install.sh command routing (AC: 1, 2)
  - [x] 2.1 Add `zsh-tool-restore list` command
  - [x] 2.2 Add `zsh-tool-restore apply <backup-id>` command
  - [x] 2.3 Support backup selection by number or timestamp

- [x] Task 3: State tracking (AC: 6)
  - [x] 3.1 Record last_restore in state.json: timestamp, from_backup, files_restored
  - [x] 3.2 Update restoration metadata after successful restore

- [x] Task 4: Error handling and rollback (AC: 9, 10, 12)
  - [x] 4.1 Handle backup not found with available options
  - [x] 4.2 Implement automatic rollback on mid-operation failure
  - [x] 4.3 Handle file permission errors with actionable messages
  - [x] 4.4 Log all restore operations

- [x] Task 5: User experience (AC: 3, 7, 8)
  - [x] 5.1 Display manifest preview before restore
  - [x] 5.2 Implement --force flag to skip confirmation
  - [x] 5.3 Prompt shell reload after success

- [x] Task 6: Write comprehensive tests
  - [x] 6.1 Test backup listing via restore command
  - [x] 6.2 Test restore from valid backup
  - [x] 6.3 Test pre-restore backup creation
  - [x] 6.4 Test atomic file operations
  - [x] 6.5 Test rollback on failure
  - [x] 6.6 Test invalid backup ID handling
  - [x] 6.7 Test state.json updates
  - [x] 6.8 Test --force flag behavior

---

## Dev Notes

### Component Location
- **Primary File:** `lib/restore/restore.zsh` (NEW)
- **Dependencies:**
  - `lib/core/utils.zsh` - logging, state management
  - `lib/install/backup.zsh` - `_zsh_tool_create_backup()` for pre-restore backup
  - `lib/restore/backup-mgmt.zsh` - `_zsh_tool_list_backups()` for listing

### Architecture Compliance

**MUST follow these patterns from solution-architecture.md:**

1. **Function naming convention:**
   - Public command: `zsh-tool-restore` (in install.sh)
   - Internal functions: `_zsh_tool_restore_*` prefix

2. **Logging pattern (from utils.zsh):**
   ```zsh
   _zsh_tool_log INFO "Restoring from backup: ${backup_id}..."
   _zsh_tool_log WARN "File permission denied: ${file}"
   _zsh_tool_log ERROR "Restore failed - rolling back..."
   ```

3. **Atomic file operations pattern:**
   ```zsh
   # Copy to temp, then atomic move
   local temp_file=$(mktemp)
   cp -p "$source" "$temp_file"
   mv "$temp_file" "$dest"
   ```

4. **State tracking pattern:**
   ```zsh
   _zsh_tool_update_state "last_restore.timestamp" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
   _zsh_tool_update_state "last_restore.from_backup" "\"${backup_id}\""
   ```

### Restore Flow (from tech-spec-epic-2.md)

```
1. User selects backup (by number or timestamp)
2. Parse and display backup manifest (what will be restored)
3. Prompt confirmation (unless --force)
4. Create pre-restore backup (backup of current state)
5. Copy files from backup directory to home (atomically)
6. Update state.json with restore metadata
7. Prompt user to reload shell
```

### Implementation Details

**Manifest Parsing:**
```zsh
_zsh_tool_parse_manifest() {
  local backup_path="$1"
  local manifest="${backup_path}/manifest.json"

  if [[ ! -f "$manifest" ]]; then
    _zsh_tool_log ERROR "Manifest not found: $manifest"
    return 1
  fi

  # Use jq if available, fallback to grep
  if command -v jq &>/dev/null; then
    cat "$manifest" | jq -r '.files[]'
  else
    grep -o '"[^"]*"' "$manifest" | grep -v timestamp | grep -v trigger | tr -d '"'
  fi
}
```

**Atomic Restore:**
```zsh
_zsh_tool_restore_file() {
  local source="$1"
  local dest="$2"

  # Create temp file in same directory for atomic mv
  local temp_file="${dest}.tmp.$$"

  if ! cp -p "$source" "$temp_file"; then
    _zsh_tool_log ERROR "Failed to copy: $source"
    rm -f "$temp_file"
    return 1
  fi

  if ! mv "$temp_file" "$dest"; then
    _zsh_tool_log ERROR "Failed to move: $temp_file -> $dest"
    rm -f "$temp_file"
    return 1
  fi

  return 0
}
```

**Rollback Logic:**
```zsh
_zsh_tool_rollback_restore() {
  local pre_restore_backup="$1"
  _zsh_tool_log WARN "Rolling back to pre-restore state..."

  # Use same restore logic but from pre-restore backup
  # This is recursive but safe since pre-restore won't create another backup
  _zsh_tool_restore_from_backup "$pre_restore_backup" --no-backup

  return $?
}
```

### State JSON Structure (after restore)

```json
{
  "last_restore": {
    "timestamp": "2026-01-07T15:00:00Z",
    "from_backup": "2026-01-05-120000",
    "files_restored": [".zshrc", ".zsh_history", "oh-my-zsh-custom"]
  }
}
```

### Restore Confirmation UI

```
Restore from backup: 2026-01-05-120000

This will restore:
  - .zshrc
  - .zsh_history
  - oh-my-zsh-custom/ (directory)

Current state will be backed up first.

Continue? (y/n)
```

### Files to Restore

Based on backup.zsh, these files are backed up and should be restored:
1. `~/.zshrc` - Main configuration
2. `~/.zsh_history` - Command history
3. `~/.oh-my-zsh/custom/` - Custom plugins, themes, aliases

### Error Handling Patterns

**Backup Not Found:**
```zsh
if [[ ! -d "$backup_path" ]]; then
  _zsh_tool_log ERROR "Backup not found: $backup_id"
  echo "Available backups:"
  _zsh_tool_list_backups
  return 1
fi
```

**Permission Error:**
```zsh
if ! cp -p "$source" "$temp_file" 2>/dev/null; then
  if [[ $? -eq 1 ]]; then
    _zsh_tool_log ERROR "Permission denied copying $source"
    echo "Try running with sudo or check file permissions"
  fi
  return 1
fi
```

**Mid-Operation Failure:**
```zsh
local restore_failed=0
local -a restored_files=()

for file in "${files_to_restore[@]}"; do
  if _zsh_tool_restore_file "$backup_path/$file" "$HOME/$file"; then
    restored_files+=("$file")
  else
    restore_failed=1
    break
  fi
done

if [[ $restore_failed -eq 1 ]]; then
  _zsh_tool_log ERROR "Restore failed mid-operation"
  _zsh_tool_rollback_restore "$pre_restore_backup"
  return 1
fi
```

### Previous Story Learnings (from 2-3)

1. **Use subshells for directory operations** - Prevents working directory pollution
2. **jq with fallback to grep** - Handle systems without jq installed
3. **Atomic state updates** - Use `_zsh_tool_update_state()` helper
4. **Relative time display** - Reuse `_zsh_tool_relative_time()` from backup-mgmt.zsh
5. **Disk space warnings** - Check before operations
6. **Idempotency** - Safe to run multiple times

### Project Structure Notes

- Restore module goes in `lib/restore/restore.zsh`
- Tests go in `tests/test-restore.zsh`
- Command routing in `install.sh` `zsh-tool-restore` function
- Reuse existing backup functions from `lib/install/backup.zsh`

### Test File Structure

```bash
# tests/test-restore.zsh
test_restore_list_shows_available_backups()
test_restore_apply_restores_files()
test_restore_creates_pre_restore_backup()
test_restore_atomic_file_copy()
test_restore_rollback_on_failure()
test_restore_invalid_backup_shows_error()
test_restore_updates_state_json()
test_restore_force_skips_confirmation()
test_restore_handles_permission_error()
test_restore_handles_missing_manifest()
```

### References

- [Source: docs/tech-spec-epic-2.md#Story 2.4]
- [Source: docs/solution-architecture.md#Backup/Restore]
- [Source: lib/install/backup.zsh - Core backup functions]
- [Source: lib/restore/backup-mgmt.zsh - Backup listing/management]
- [Source: docs/implementation-artifacts/2-3-configuration-backup-management.md - Previous story patterns]

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- tests/test-restore.zsh output: 26/26 tests passing

### Completion Notes List

1. Enhanced `lib/restore/restore.zsh` with:
   - `--force` / `-f` flag to skip confirmation (AC7)
   - `--no-backup` internal flag for rollback operations
   - Rollback on mid-operation failure (AC10)
   - Permission error handling with sudo suggestions (AC12)
   - Atomic file operations via temp files (AC5)
   - State tracking for last_restore metadata (AC6)

2. Created comprehensive test suite `tests/test-restore.zsh`:
   - 26 tests covering all acceptance criteria
   - Tests for function existence, restore operations, manifest parsing
   - Tests for pre-restore backup, atomic operations, state tracking
   - Tests for force flag, error handling, rollback, and verification

3. All acceptance criteria verified:
   - AC1: `zsh-tool-restore list` - reuses `_zsh_tool_list_backups()`
   - AC2: `zsh-tool-restore apply <backup-id>` - full implementation
   - AC3: Manifest preview before restore
   - AC4: Pre-restore backup created automatically
   - AC5: Atomic file copy via temp file
   - AC6: State.json updated with last_restore metadata
   - AC7: `--force` flag skips confirmation
   - AC8: Shell reload prompt after success
   - AC9: Backup not found shows available list
   - AC10: Automatic rollback on mid-operation failure
   - AC11: Partial restore stub (future enhancement)
   - AC12: Permission errors with actionable sudo messages

### Change Log

- 2026-01-07: Story created with comprehensive developer context
- 2026-01-07: Implementation complete - 26/26 tests passing

### File List

- lib/restore/restore.zsh (modified - enhanced with --force, rollback, permission handling)
- tests/test-restore.zsh (new - 26 comprehensive tests)

