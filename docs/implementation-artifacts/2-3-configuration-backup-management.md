# Story 2.3: Configuration Backup Management

Status: done

---

## Story

**As a** developer
**I want** to manage my configuration backups with create, list, prune, and remote sync capabilities
**So that** I can maintain a reliable backup history and optionally sync backups across machines

---

## Acceptance Criteria

1. **AC1:** Command creates manual backups with timestamped directories
2. **AC2:** Command lists all available backups with metadata (trigger, timestamp, age)
3. **AC3:** Command prunes old backups beyond retention limit (default: 10)
4. **AC4:** Command supports optional remote git backup (push to configured remote)
5. **AC5:** Command fetches remote backups when remote is configured
6. **AC6:** Command allows configuring remote backup URL
7. **AC7:** Command displays backup count and remote status in state
8. **AC8:** Command handles errors gracefully (disk space, network, permissions)
9. **AC9:** Command logs all backup operations to log file
10. **AC10:** Command is idempotent - safe to run multiple times

---

## Tasks / Subtasks

- [x] Task 1: Enhance backup-mgmt.zsh module (AC: 1-10)
  - [x] 1.1 Implement `_zsh_tool_list_backups()` - list all backups with metadata
  - [x] 1.2 Implement `_zsh_tool_create_manual_backup()` - manual backup trigger
  - [x] 1.3 Implement `_zsh_tool_backup_to_remote()` - push to git remote
  - [x] 1.4 Implement `_zsh_tool_fetch_remote_backups()` - pull from git remote
  - [x] 1.5 Implement `_zsh_tool_configure_remote_backup()` - configure remote URL
  - [x] 1.6 Implement `_zsh_tool_get_backup_count()` - return current backup count
  - [x] 1.7 Implement `_zsh_tool_get_remote_status()` - check remote configuration status
  - [x] 1.8 Implement `_zsh_tool_relative_time()` - calculate human-readable time ago

- [x] Task 2: State tracking (AC: 7)
  - [x] 2.1 Update state.json with backup count after operations
  - [x] 2.2 Track remote_enabled and remote_url in state
  - [x] 2.3 Track last_backup timestamp in state

- [x] Task 3: Error handling (AC: 8, 9)
  - [x] 3.1 Handle disk space insufficient with warning
  - [x] 3.2 Handle network failures for remote operations
  - [x] 3.3 Handle git repository not initialized
  - [x] 3.4 Log all errors with actionable messages

- [x] Task 4: User interface improvements (AC: 2)
  - [x] 4.1 Improve backup list display format
  - [x] 4.2 Add backup size information to listing
  - [x] 4.3 Show remote sync status indicator

- [x] Task 5: Write comprehensive tests
  - [x] 5.1 Test manual backup creation
  - [x] 5.2 Test backup listing with metadata
  - [x] 5.3 Test pruning (creates correct number, deletes oldest)
  - [x] 5.4 Test remote configuration
  - [x] 5.5 Test error scenarios (disk full, network failure)
  - [x] 5.6 Test state tracking updates
  - [x] 5.7 Test idempotency

---

## Dev Notes

### Component Location
- **File:** `lib/restore/backup-mgmt.zsh`
- **Dependencies:** `lib/core/utils.zsh`, `lib/install/backup.zsh`, git

### Architecture Compliance

**MUST follow these patterns from solution-architecture.md:**

1. **Function naming convention:**
   - Public functions: `zsh-tool-backup` (user-facing command in install.sh)
   - Internal functions: `_zsh_tool_*` prefix

2. **Logging pattern (utils.zsh):**
   ```zsh
   _zsh_tool_log INFO "Creating manual backup..."
   _zsh_tool_log WARN "Remote push failed, local backup preserved"
   _zsh_tool_log ERROR "Disk space insufficient"
   ```

3. **State tracking pattern:**
   - Use `~/.config/zsh-tool/state.json` for backup tracking
   - Update `backups.count`, `backups.last_backup`, `backups.remote_enabled`

### State JSON Structure
```json
{
  "backups": {
    "last_backup": "2026-01-06-143000",
    "count": 10,
    "remote_enabled": true,
    "remote_url": "git@github.com:user/zsh-backups.git"
  }
}
```

### References

- [Source: docs/tech-spec-epic-2.md#Story 2.3]
- [Source: lib/install/backup.zsh - Core backup functions]
- [Source: docs/implementation-artifacts/2-1-self-update-mechanism.md - Previous story patterns]

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

Test execution logs: tests/test-backup-mgmt.zsh

### Completion Notes List

1. Enhanced `lib/restore/backup-mgmt.zsh` with complete backup management functionality:
   - Added `_zsh_tool_get_backup_count()` - returns count of backup directories
   - Added `_zsh_tool_get_remote_status()` - returns "enabled", "disabled", or "not_configured"
   - Added `_zsh_tool_get_backup_size()` - returns human-readable size (KB/MB/GB)
   - Enhanced `_zsh_tool_list_backups()` - shows size, relative time, remote status
   - Added `_zsh_tool_update_backup_state()` - tracks backup count and timestamp
   - Added `_zsh_tool_backup_status()` - summary of backup configuration
   - Added `_zsh_tool_disable_remote_backup()` - disable remote sync
   - Fixed `_zsh_tool_backup_to_remote()` to use subshells for directory safety
   - Fixed `_zsh_tool_fetch_remote_backups()` to use subshells for directory safety

2. Updated `install.sh` zsh-tool-backup command with new subcommands:
   - `status` - Show backup status summary
   - `remote-config <url>` - Configure remote backup URL
   - `remote-disable` - Disable remote backup sync
   - `fetch` - Fetch backups from remote

3. Created comprehensive test suite `tests/test-backup-mgmt.zsh`:
   - 26 tests covering all acceptance criteria
   - Tests for backup count, remote status, backup size
   - Tests for relative time calculation
   - Tests for list, create, configure operations
   - Tests for error handling and idempotency

4. Key implementation patterns:
   - Uses jq for JSON parsing when available, with grep fallback
   - Subshells for directory-changing operations (git commands)
   - Atomic state updates via `_zsh_tool_update_state()`
   - Disk space warnings before backup creation

### Change Log

- 2026-01-06: Story created, started implementation
- 2026-01-06: All tasks completed, 26/26 tests passing, moved to review

### File List

- lib/restore/backup-mgmt.zsh (enhanced - 466 lines)
- install.sh (updated - backup command extended)
- tests/test-backup-mgmt.zsh (new - 26 tests)
