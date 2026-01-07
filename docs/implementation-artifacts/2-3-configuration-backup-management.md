# Story 2.3: Configuration Backup Management

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**As a** developer
**I want** to manually trigger backups of my current configuration to local or remote storage
**So that** I can preserve working configurations before experimenting

## Acceptance Criteria

1. **AC1:** Command `zsh-tool-backup create` creates timestamped backup to local storage
2. **AC2:** Command `zsh-tool-backup remote` pushes backup to configured git repository
3. **AC3:** Command `zsh-tool-backup list` displays available backups with timestamps, triggers, and relative time
4. **AC4:** Command supports configuring remote backup URL via state file
5. **AC5:** Command `zsh-tool-backup fetch` retrieves backups from remote repository
6. **AC6:** Command handles network failures gracefully without breaking shell
7. **AC7:** Command logs all operations to log file with appropriate levels
8. **AC8:** Command tracks backup metadata in state.json (last_backup, remote_enabled, remote_url)
9. **AC9:** Command is idempotent - safe to run multiple times
10. **AC10:** Backup retention automatically prunes backups beyond retention limit (default: 10)

## Tasks / Subtasks

- [x] Task 1: Fix existing backup-mgmt.zsh code issues (AC: 1, 6, 7)
  - [x] 1.1 Fix bare `cd` commands - use subshells `( cd ... )` pattern
  - [x] 1.2 Fix `PIPESTATUS` → `pipestatus` (zsh uses lowercase)
  - [x] 1.3 Add error handling for git operations
  - [x] 1.4 Ensure all functions return proper exit codes

- [x] Task 2: Enhance list backups functionality (AC: 3)
  - [x] 2.1 Improve manifest parsing (use jq if available, fallback to grep)
  - [x] 2.2 Add backup size display
  - [x] 2.3 Show file count per backup
  - [x] 2.4 Handle empty backup directory gracefully

- [x] Task 3: Improve remote backup functionality (AC: 2, 4, 5, 6)
  - [x] 3.1 Detect git branch name dynamically (main vs master)
  - [x] 3.2 Add `zsh-tool-backup fetch` command for pulling from remote
  - [x] 3.3 Add `zsh-tool-backup config <url>` command for configuration
  - [x] 3.4 Handle SSH vs HTTPS authentication properly
  - [x] 3.5 Add merge conflict detection and resolution prompts

- [x] Task 4: Enhance state tracking (AC: 8)
  - [x] 4.1 Track backup timestamps in state.json
  - [x] 4.2 Track remote sync status
  - [x] 4.3 Track backup statistics (count, total size)

- [x] Task 5: Add missing subcommands to install.sh (AC: 4, 5)
  - [x] 5.1 Add `fetch` subcommand to zsh-tool-backup
  - [x] 5.2 Add `config` subcommand to zsh-tool-backup
  - [x] 5.3 Update help text

- [x] Task 6: Write comprehensive tests (AC: all)
  - [x] 6.1 Test backup create functionality
  - [x] 6.2 Test backup list display
  - [x] 6.3 Test backup retention/pruning
  - [x] 6.4 Test remote configuration
  - [x] 6.5 Test remote push functionality
  - [x] 6.6 Test remote fetch functionality
  - [x] 6.7 Test error handling (network failure, git conflicts)
  - [x] 6.8 Test idempotency (multiple runs)
  - [x] 6.9 Test state tracking updates
  - [x] 6.10 Test relative time calculations

## Dev Notes

### CRITICAL DISCOVERY: Code Already Exists

**IMPORTANT:** Most of the backup management code already exists in `lib/restore/backup-mgmt.zsh` (184 lines). Your primary task is to:
1. **Fix existing bugs** (see Issues Identified below)
2. **Enhance functionality** (add missing features)
3. **Write comprehensive tests** (test file doesn't exist yet)

### Issues Identified in Existing Code

**lib/restore/backup-mgmt.zsh:**

| Line | Issue | Severity | Fix |
|------|-------|----------|-----|
| 110, 139 | Bare `cd` without subshell | HIGH | Use `( cd ... )` subshell pattern |
| 124, 150 | `PIPESTATUS` (bash) vs `pipestatus` (zsh) | HIGH | Use lowercase `pipestatus` for zsh |
| 12 | Uses `ls` for listing - non-portable | MEDIUM | Use zsh glob: `backup_dirs=("$dir"/*(/On))` |
| 94 | Hardcoded `origin main` branch | MEDIUM | Detect branch dynamically |
| 167-173 | `read` without timeout or validation | LOW | Add input validation |

### Component Location

**Existing Files to Modify:**
- `/Users/juliano.barbosa/Repos/github/zsh/lib/restore/backup-mgmt.zsh` (184 lines - needs fixes)
- `/Users/juliano.barbosa/Repos/github/zsh/install.sh` (add fetch, config subcommands)

**New Files to Create:**
- `/Users/juliano.barbosa/Repos/github/zsh/tests/test-backup-mgmt.zsh` (test suite)

**Related Files (reference only - DO NOT MODIFY):**
- `/Users/juliano.barbosa/Repos/github/zsh/lib/install/backup.zsh` (core backup logic - already correct)
- `/Users/juliano.barbosa/Repos/github/zsh/lib/core/utils.zsh` (logging, state management)
- `/Users/juliano.barbosa/Repos/github/zsh/lib/restore/restore.zsh` (restore logic)

### Architecture Compliance

**MUST follow these patterns established in the codebase:**

#### 1. Function Naming Convention
```zsh
# Public user-facing commands (no underscore prefix) - in install.sh only
zsh-tool-backup() { }

# Internal helper functions (underscore prefix)
_zsh_tool_list_backups() { }
_zsh_tool_backup_to_remote() { }
```

#### 2. Logging Pattern (from utils.zsh:44-72)
```zsh
_zsh_tool_log INFO "Creating backup..."
_zsh_tool_log WARN "Remote URL not configured"
_zsh_tool_log ERROR "Failed to push backup to remote"
_zsh_tool_log DEBUG "Backup directory: $backup_dir"
```

**CRITICAL:** Use uppercase log levels (INFO, WARN, ERROR, DEBUG) - the existing code has some lowercase which should be fixed.

#### 3. Directory Change Pattern (CRITICAL - from Story 2.2 learnings)
```zsh
# WRONG - bare cd (affects calling shell)
cd "$BACKUP_DIR"
git pull origin main
cd - >/dev/null

# CORRECT - subshell (isolated)
(
  cd "$BACKUP_DIR" || return 1
  git pull origin main
)
local status=$?
```

#### 4. State Tracking Pattern (from utils.zsh:122-156)
```zsh
# Update state for backups
_zsh_tool_update_state "last_backup" "\"${timestamp}\""
_zsh_tool_update_state "backups.remote_enabled" "true"
_zsh_tool_update_state "backups.remote_url" "\"${remote_url}\""
_zsh_tool_update_state "backups.last_remote_sync" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
```

#### 5. Git Branch Detection Pattern (from Story 2.2)
```zsh
# Detect default branch dynamically
_zsh_tool_get_default_branch() {
  # Try upstream tracking first
  local branch=$(git rev-parse --abbrev-ref @{u} 2>/dev/null | cut -d'/' -f2)
  if [[ -z "$branch" ]]; then
    # Try common names
    for try_branch in main master; do
      if git show-ref --verify --quiet "refs/remotes/origin/${try_branch}"; then
        branch="$try_branch"
        break
      fi
    done
  fi
  echo "${branch:-main}"
}
```

### Previous Story Intelligence (Story 2.2: Bulk Plugin and Theme Updates)

**KEY LEARNINGS FROM STORY 2.2:**

#### Critical Implementation Insights:
1. **Subshells for `cd`** - ALWAYS use subshells to prevent affecting calling shell
2. **pipestatus is lowercase in zsh** - NOT `PIPESTATUS` like bash
3. **Component-manager pattern** - Parallel operations via shared module
4. **Error messages must be specific** - Include component name in failures

#### Problems Encountered & Solutions:
1. **Problem:** Bare `cd` commands pollute calling shell's directory
   - **Solution:** Use `( cd ... )` subshells or `pushd`/`popd`

2. **Problem:** `PIPESTATUS` not working in zsh
   - **Solution:** Use lowercase `pipestatus` (zsh arrays are 1-indexed)

3. **Problem:** Hardcoded `origin/master` fails on `main` repos
   - **Solution:** Detect branch dynamically with fallback pattern

4. **Problem:** Network errors not clearly reported
   - **Solution:** Capture git stderr and include in error message

### Library/Framework Requirements

| Library | Version | Purpose | Already Installed |
|---------|---------|---------|-------------------|
| zsh | 5.8+ | Core shell | Yes (macOS default) |
| git | 2.30+ | Remote backup operations | Yes |
| jq | 1.6+ | JSON parsing (optional) | Check in tests |

**No Additional Dependencies Required**

### File Structure Requirements

**Backup Directory Structure (from solution-architecture.md:239-259):**
```
~/.config/zsh-tool/backups/
├── 2026-01-07-120000/
│   ├── .zshrc
│   ├── .zsh_history
│   ├── oh-my-zsh-custom/
│   └── manifest.json
├── 2026-01-06-093000/
│   └── ...
└── .git/  (if remote backup enabled)
```

**Manifest Format:**
```json
{
  "timestamp": "2026-01-07T12:00:00Z",
  "trigger": "manual",
  "files": [".zshrc", ".zsh_history", "oh-my-zsh-custom"],
  "omz_version": "master-abc123",
  "tool_version": "1.0.0"
}
```

**State File Structure:**
```json
{
  "version": "1.0.0",
  "last_backup": "2026-01-07-120000",
  "backups": {
    "remote_enabled": true,
    "remote_url": "git@github.com:user/zsh-backups.git",
    "last_remote_sync": "2026-01-07T12:00:00Z"
  }
}
```

### Testing Requirements

**Testing Framework:** zsh native (following established pattern)

**Test Coverage Requirements (minimum 15 tests):**

```zsh
# tests/test-backup-mgmt.zsh

# Test 1-3: Create backup functionality
test_create_backup_creates_directory() { }
test_create_backup_generates_manifest() { }
test_create_backup_copies_all_files() { }

# Test 4-6: List backups functionality
test_list_backups_shows_all_backups() { }
test_list_backups_shows_relative_time() { }
test_list_backups_empty_directory_handled() { }

# Test 7-9: Retention/Pruning
test_prune_keeps_retention_limit() { }
test_prune_removes_oldest_first() { }
test_prune_handles_zero_backups() { }

# Test 10-12: Remote operations
test_remote_push_succeeds() { }
test_remote_fetch_succeeds() { }
test_remote_config_saves_url() { }

# Test 13-15: Error handling
test_network_failure_handled_gracefully() { }
test_git_conflict_reported() { }
test_invalid_remote_url_rejected() { }

# Test 16-18: State tracking
test_state_updated_after_backup() { }
test_state_tracks_remote_sync() { }
test_state_persistent_across_runs() { }

# Test 19-20: Idempotency
test_multiple_backups_safe() { }
test_config_idempotent() { }
```

### Implementation Strategy

#### Phase 1: Fix Existing Code

```zsh
# Fix 1: Replace bare cd with subshells in backup-mgmt.zsh

# BEFORE (line 110-126):
cd "$ZSH_TOOL_BACKUP_DIR"
if [[ ! -d ".git" ]]; then
  git init 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  git remote add origin "$remote_url" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
fi
git add . 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
git commit -m "Backup: $(date +%Y-%m-%d\ %H:%M:%S)" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
git push origin main 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
local push_status=${PIPESTATUS[1]}
cd - >/dev/null

# AFTER:
local push_status
push_status=$(
  cd "$ZSH_TOOL_BACKUP_DIR" || exit 1

  # Initialize git if needed
  if [[ ! -d ".git" ]]; then
    git init 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
    git remote add origin "$remote_url" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  fi

  # Get default branch
  local branch=$(_zsh_tool_get_default_branch)

  # Add, commit, push
  git add . 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null
  git commit -m "Backup: $(date +%Y-%m-%d\ %H:%M:%S)" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null || true

  if git push origin "$branch" 2>&1 | tee -a "$ZSH_TOOL_LOG_FILE" >/dev/null; then
    echo "0"
  else
    echo "1"
  fi
)
```

#### Phase 2: Add Missing Subcommands

```zsh
# In install.sh, update zsh-tool-backup function:
zsh-tool-backup() {
  local subcommand="${1:-create}"
  shift 2>/dev/null || true

  case "$subcommand" in
    create)
      _zsh_tool_create_manual_backup
      ;;
    list)
      _zsh_tool_list_backups
      ;;
    remote)
      _zsh_tool_backup_to_remote
      ;;
    fetch)
      _zsh_tool_fetch_remote_backups
      ;;
    config)
      _zsh_tool_configure_remote_backup "$@"
      ;;
    *)
      echo "Usage: zsh-tool-backup [create|list|remote|fetch|config <url>]"
      return 1
      ;;
  esac
}
```

#### Phase 3: Enhance List Display

```zsh
_zsh_tool_list_backups() {
  if [[ ! -d "$ZSH_TOOL_BACKUP_DIR" ]]; then
    _zsh_tool_log WARN "No backup directory found"
    return 1
  fi

  # Use zsh glob for portable, sorted listing
  setopt local_options null_glob
  local -a backup_dirs
  backup_dirs=("${ZSH_TOOL_BACKUP_DIR}"/*(N/om))  # om = sort by modification time, newest first

  if [[ ${#backup_dirs[@]} -eq 0 ]]; then
    echo "No backups available"
    return 1
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Available Backups (newest first)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local index=1
  for backup_path in "${backup_dirs[@]}"; do
    local backup=$(basename "$backup_path")
    local manifest="${backup_path}/manifest.json"
    local trigger="unknown"
    local files_count=0
    local size="?"

    if [[ -f "$manifest" ]]; then
      # Use jq if available, fallback to grep
      if command -v jq >/dev/null 2>&1; then
        trigger=$(jq -r '.trigger // "unknown"' "$manifest" 2>/dev/null)
      else
        trigger=$(grep -o '"trigger":"[^"]*"' "$manifest" | cut -d'"' -f4)
      fi
      files_count=$(ls -1A "$backup_path" 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Calculate size (du -sh for human readable)
    size=$(du -sh "$backup_path" 2>/dev/null | cut -f1 || echo "?")

    # Calculate relative time
    local relative_time=$(_zsh_tool_relative_time "$backup")

    printf "  %2d. %-20s  %-12s  %s  (%s, %d files)\n" \
      "$index" "$backup" "$trigger" "$relative_time" "$size" "$files_count"
    ((index++))
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Use 'zsh-tool-restore apply <number>' to restore"
  echo "Use 'zsh-tool-backup remote' to sync to remote"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}
```

### Git Intelligence - Recent Work Patterns

**Recent Commits Analysis:**

1. **c77f7c5:** Story 3-3 and Epic-3 marked done
   - Pattern: Sprint status updates after story completion

2. **cd89316:** Code review issues resolved for Kiro CLI
   - Pattern: AI review findings tracked in story files

3. **eef3e79:** Kiro CLI migration completed
   - New file: `lib/integrations/kiro-cli.zsh`
   - Pattern: Integration modules are self-contained

4. **b8825af:** Atuin shell history integration
   - Pattern: Comprehensive test coverage (12 tests)
   - Pattern: Health check functions for integrations

**Established Code Conventions:**
- Minimum 15-20 tests per story
- Test file naming: `tests/test-{feature}.zsh`
- State tracking via JSON updates with atomic writes
- Error handling: continue-on-failure, specific error messages
- Logging: INFO for user messages, DEBUG for details, WARN/ERROR for issues

### Performance Targets

- List backups: < 1 second
- Create backup: < 5 seconds
- Remote push: 10-30 seconds (network dependent)
- Remote fetch: 10-30 seconds (network dependent)

### Security Considerations

1. **Git operations use existing authentication** - SSH keys or credential helper
2. **No credentials stored in config** - Remote URLs only
3. **Backup files readable only by user** - chmod 700 on backup directories
4. **Logs don't contain secrets** - Only timestamps and operation status

## References

- [Source: docs/solution-architecture.md#Section 5.2 - Backup Structure, lines 237-259]
- [Source: docs/solution-architecture.md#Section 6.1 - Public Functions, lines 317-325]
- [Source: docs/epic-stories.md#Epic 2 - Story 2.3, lines 149-157]
- [Source: lib/install/backup.zsh - Core backup implementation]
- [Source: lib/restore/backup-mgmt.zsh - Existing management code to fix]
- [Source: lib/core/utils.zsh - Logging and state patterns]
- [Source: docs/implementation-artifacts/2-2-bulk-plugin-and-theme-updates.md - Previous story learnings]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- Tests: 22/22 passing
- Code Review R1: 4 MEDIUM, 3 LOW issues fixed

### Completion Notes List

- Rewrote `lib/restore/backup-mgmt.zsh` with all fixes:
  - Replaced bare `cd` with subshells to avoid polluting caller's directory
  - Removed PIPESTATUS (bash) - using proper exit code capture
  - Added `_zsh_tool_get_backup_branch()` for dynamic branch detection
  - Enhanced `_zsh_tool_list_backups()` with size, file count, better formatting
  - Improved `_zsh_tool_backup_to_remote()` with detailed error messages
  - Added `_zsh_tool_fetch_remote_backups()` with conflict detection
  - Enhanced `_zsh_tool_configure_remote_backup()` with URL validation
  - Added `_zsh_tool_backup_stats()` for backup statistics
  - Added `_zsh_tool_count_backups()` helper
- Updated `install.sh` zsh-tool-backup command with new subcommands: fetch, config, stats
- Created comprehensive test suite `tests/test-backup-mgmt.zsh` with 22 tests covering all ACs

**Code Review R1 Fixes:**
- M1: Updated main help text with fetch, config, stats subcommands
- M2: Added Linux compatibility for `date` command (cross-platform)
- M3: Added git init fallback for older git versions (<2.28)
- M4: Improved tests to source actual functions and validate JSON
- L1: Added JSON escaping for remote URL input
- L2: Replaced `find` with zsh glob for file counting
- L3: Improved relative time tests to call actual functions

### File List

- lib/restore/backup-mgmt.zsh (modified - complete rewrite with fixes + review fixes)
- install.sh (modified - added fetch, config, stats subcommands + help text)
- tests/test-backup-mgmt.zsh (new - 22 tests, improved)

### Senior Developer Review (AI)

**Review Date:** 2026-01-07
**Outcome:** Approved (after fixes)
**Issues Found:** 4 Medium, 3 Low
**Issues Fixed:** 7/7 (100%)

