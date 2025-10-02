# Epic 2 Technical Specification: Maintenance & Lifecycle Management

**Epic:** Maintenance & Lifecycle Management
**Goal:** Provide tools for ongoing management, updates, backups, and restoration of zsh configurations
**Stories:** 5 (17 story points)
**Priority:** P0 - Must Have
**Dependencies:** Epic 1 (Core Installation must be complete)

---

## Architecture Extract

**Technology Stack:**
- zsh 5.8+
- Oh My Zsh (stable release or commit SHA)
- git 2.30+
- bats-core 1.10.0 (testing)

**Components:**
- `update/self.zsh`
- `update/omz.zsh`
- `update/plugins.zsh`
- `restore/backup-mgmt.zsh`
- `restore/restore.zsh`
- `git/integration.zsh`

**Data Models:**
- `~/.config/zsh-tool/state.json` - Tool state
- `~/.config/zsh-tool/backups/` - Backup directories
- `~/.config/zsh-tool/last-update` - Update check timestamp
- Dotfiles git repository (optional, user-managed)

---

## Story 2.1: Self-Update Mechanism

**Component:** `update/self.zsh`

**Functions:**
```zsh
zsh-tool-update self                      # User-facing command
_zsh_tool_self_update()                   # Main update logic
_zsh_tool_check_for_updates()             # git fetch + compare
_zsh_tool_display_changelog()             # Show commits since last update
_zsh_tool_apply_update()                  # git pull + reload
_zsh_tool_rollback_update(version)        # Revert to previous version
```

**Update Flow:**
```zsh
1. Check current version (git describe --tags or commit SHA)
2. git fetch origin
3. Compare local vs remote
4. Display changelog: git log HEAD..origin/main --oneline
5. Prompt user to proceed
6. git pull (or git reset --hard origin/main)
7. Reload functions: source ~/.zshrc or exec zsh
8. Update state.json with new version
```

**Implementation Notes:**
- Tool installed in `~/.local/bin/zsh-tool/` as git repository
- Update = `cd ~/.local/bin/zsh-tool && git pull`
- Version tracking: Use git tags (v1.0.0) or commit SHA
- Automatic backup before update (reuse `install/backup.zsh`)
- Rollback: `git checkout <previous-version>`

**Changelog Display:**
```zsh
Updates available:
  - feat: Add plugin search command (abc123)
  - fix: Backup retention bug (def456)
  - docs: Update README (ghi789)

Current version: v1.0.0
New version: v1.1.0

Update now? (y/n)
```

**Error Handling:**
- git pull fails → rollback to previous commit automatically
- Network unavailable → skip update, inform user
- Merge conflicts (unlikely) → abort, warn user to manually resolve

**State Tracking:**
```json
{
  "tool_version": {
    "current": "v1.1.0",
    "previous": "v1.0.0",
    "last_update": "2025-10-15T14:30:00Z",
    "last_check": "2025-10-15T14:30:00Z"
  }
}
```

**Testing:**
- Mock git fetch showing new commits → prompts update
- Mock git pull failure → rolls back, restores previous version
- Update successful → version in state.json updated
- Rollback command → reverts to specified version

---

## Story 2.2: Bulk Plugin and Theme Updates

**Component:** `update/omz.zsh`, `update/plugins.zsh`

**Functions:**
```zsh
zsh-tool-update omz                       # Update Oh My Zsh framework
zsh-tool-update plugins                   # Update all plugins
zsh-tool-update all                       # Update everything (omz + plugins + self)
_zsh_tool_update_omz()                    # Main OMZ update logic
_zsh_tool_update_plugin(plugin_name)      # Update single plugin
_zsh_tool_update_all_plugins()            # Iterate all plugins
_zsh_tool_check_plugin_updates()          # Check for available updates
```

**Oh My Zsh Update:**
```zsh
# Official OMZ update command
cd ~/.oh-my-zsh
git pull origin master
# Or use OMZ's built-in updater
omz update
```

**Plugin Update:**
```zsh
# For custom plugins (git repos)
for plugin in ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/*; do
  if [[ -d "$plugin/.git" ]]; then
    echo "Updating $(basename $plugin)..."
    cd "$plugin"
    git pull
  fi
done
```

**Implementation Notes:**
- Backup before updates (reuse `install/backup.zsh`)
- Update OMZ first, then plugins
- Skip built-in plugins (they update with OMZ)
- Display progress for each plugin
- Record update timestamp in state.json

**Update Summary:**
```
Updating zsh-tool components...

✓ Oh My Zsh updated (master → master, 15 commits)
✓ zsh-syntax-highlighting updated (v0.7.1 → v0.8.0)
✓ zsh-autosuggestions updated (v0.7.0 → v0.7.1)
✓ git (built-in, updated with OMZ)
✓ docker (built-in, updated with OMZ)

Backup created: ~/.config/zsh-tool/backups/2025-10-15-143000/

Reload shell to apply updates: exec zsh
```

**Error Handling:**
- Plugin update fails → skip, warn, continue with others
- OMZ update fails → rollback (use backup)
- Network errors → inform user, skip updates

**State Tracking:**
```json
{
  "omz": {
    "version": "master-xyz789",
    "last_update": "2025-10-15T14:30:00Z"
  },
  "plugins": {
    "zsh-syntax-highlighting": {
      "version": "v0.8.0",
      "last_update": "2025-10-15T14:30:00Z"
    },
    "zsh-autosuggestions": {
      "version": "v0.7.1",
      "last_update": "2025-10-15T14:30:00Z"
    }
  }
}
```

**Testing:**
- Update OMZ → git pull executed, version updated
- Update plugins → all custom plugins pulled
- Update all → self + omz + plugins all updated
- Plugin update failure → continues with others, warns

---

## Story 2.3: Configuration Backup Management

**Component:** `restore/backup-mgmt.zsh`

**Functions:**
```zsh
zsh-tool-backup create [--remote]         # Manual backup trigger
_zsh_tool_create_manual_backup()          # Create backup now
_zsh_tool_list_backups()                  # List all backups
_zsh_tool_prune_old_backups()             # Delete backups beyond retention
_zsh_tool_backup_to_remote()              # Push backup to git remote
_zsh_tool_fetch_remote_backups()          # Pull backups from git remote
```

**Manual Backup:**
```zsh
# Reuse install/backup.zsh logic
_zsh_tool_create_backup "manual-$(date +%Y-%m-%d-%H%M%S)"
```

**List Backups:**
```zsh
Available backups:

1. 2025-10-15-143000 (manual) - 2 hours ago
2. 2025-10-10-120000 (pre-update) - 5 days ago
3. 2025-10-05-090000 (pre-install) - 10 days ago
4. 2025-10-01-120000 (pre-install) - 14 days ago

Use 'zsh-tool-restore apply <number>' to restore
```

**Backup Retention:**
- Keep last 10 backups
- Prune oldest when > 10
- Automatic prune after each backup creation

**Remote Backup (Optional):**
```zsh
# Push backups to git remote
cd ~/.config/zsh-tool/backups/
git init (if not already)
git add .
git commit -m "Backup: $(date)"
git push origin main
```

**Implementation Notes:**
- Backups stored in `~/.config/zsh-tool/backups/TIMESTAMP/`
- Each backup has manifest.json with metadata
- Remote backup: User configures git remote, tool pushes
- Remote backup optional (user may use personal git server)

**Error Handling:**
- Disk space insufficient → warn, ask user to clean up
- Remote push fails → local backup still exists, warn user
- Prune fails → warn, continue

**State Tracking:**
```json
{
  "backups": {
    "last_backup": "2025-10-15-143000",
    "count": 10,
    "remote_enabled": true,
    "remote_url": "git@github.com:user/zsh-backups.git"
  }
}
```

**Testing:**
- Create manual backup → new directory with timestamp
- List backups → displays all with metadata
- Prune old backups → deletes oldest when > 10
- Remote backup → pushes to git remote

---

## Story 2.4: Configuration Restore from Backup

**Component:** `restore/restore.zsh`

**Functions:**
```zsh
zsh-tool-restore list                     # List available backups
zsh-tool-restore apply <backup-id>        # Restore from backup
_zsh_tool_restore_from_backup(backup_id)  # Main restore logic
_zsh_tool_parse_manifest(backup_path)     # Load backup metadata
_zsh_tool_restore_file(source, dest)      # Copy file from backup
_zsh_tool_verify_restore()                # Verify restoration success
```

**Restore Flow:**
```zsh
1. User selects backup (by number or timestamp)
2. Display backup manifest (what will be restored)
3. Prompt confirmation
4. Create pre-restore backup (backup of current state)
5. Copy files from backup directory to home
6. Update state.json
7. Prompt user to reload shell
```

**Restore Confirmation:**
```
Restore from backup: 2025-10-10-120000

This will restore:
  - .zshrc
  - .zsh_history
  - .oh-my-zsh/custom/ (5 files)

Current state will be backed up first.

Continue? (y/n)
```

**Implementation Notes:**
- Create backup before restore (safety net)
- Use atomic file operations (cp to temp, then mv)
- Restore manifest to verify backup integrity
- Update state.json to reflect restored state

**Partial Restore (Future Enhancement):**
```zsh
# Restore only .zshrc
zsh-tool-restore apply 2025-10-10-120000 --files .zshrc
```

**Error Handling:**
- Backup not found → list available backups
- Restore fails mid-operation → rollback using pre-restore backup
- File permissions issues → warn user, suggest sudo

**State Tracking:**
```json
{
  "last_restore": {
    "timestamp": "2025-10-15T15:00:00Z",
    "from_backup": "2025-10-10-120000",
    "files_restored": [".zshrc", ".zsh_history"]
  }
}
```

**Testing:**
- List backups → shows available options
- Restore from backup → files copied correctly
- Restore creates pre-restore backup → safety net exists
- Restore failure → rolls back to pre-restore state

---

## Story 2.5: Git Integration for Dotfiles

**Component:** `git/integration.zsh`

**Functions:**
```zsh
zsh-tool-git init                         # Initialize dotfiles repo
zsh-tool-git status                       # git status
zsh-tool-git commit [message]             # Commit changes
zsh-tool-git push                         # Push to remote
zsh-tool-git pull                         # Pull from remote
_zsh_tool_git_init_repo()                 # Initialize git in home dir or dotfiles dir
_zsh_tool_git_add_gitignore()             # Create .gitignore for dotfiles
_zsh_tool_git_setup_remote(url)           # Add remote origin
```

**Dotfiles Git Strategy:**

**Option 1: Bare Repository (Recommended)**
```zsh
# Initialize bare repo
git init --bare ~/.dotfiles

# Create alias
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# Add dotfiles
dotfiles add .zshrc .zsh_history
dotfiles commit -m "Initial commit"
dotfiles push -u origin main
```

**Option 2: Standard Repository in ~/.dotfiles/**
```zsh
# Initialize standard repo
mkdir ~/.dotfiles
cd ~/.dotfiles
git init

# Symlink dotfiles
ln -s ~/.zshrc ~/.dotfiles/zshrc
ln -s ~/.zsh_history ~/.dotfiles/zsh_history
```

**Recommended: Option 1 (Bare Repository)**
- No symlinks needed
- Clean home directory
- Standard approach in dotfiles community

**Implementation Notes:**
- Use user's existing git config (name, email, SSH keys)
- Never store credentials
- Add .gitignore to exclude sensitive files
- Provide git wrapper functions for convenience

**Gitignore Template:**
```gitignore
# Exclude sensitive data
.ssh/
.gnupg/
.aws/

# Exclude large files
.zsh_history
.cache/

# Exclude tool state
.config/zsh-tool/state.json
.config/zsh-tool/backups/
```

**Git Integration Commands:**
```zsh
# Initialize
zsh-tool-git init
# Prompts for remote URL (optional)

# Add files
zsh-tool-git add .zshrc .zshrc.local

# Commit
zsh-tool-git commit "Update zsh config"

# Push
zsh-tool-git push

# Pull (sync across machines)
zsh-tool-git pull
```

**Error Handling:**
- Git not configured → prompt user to configure name/email
- No remote configured → local-only mode, warn user
- Push/pull fails → display git error, suggest remedies
- Merge conflicts → instruct user to resolve manually

**State Tracking:**
```json
{
  "git_integration": {
    "enabled": true,
    "repo_type": "bare",
    "repo_path": "~/.dotfiles",
    "remote_url": "git@github.com:user/dotfiles.git",
    "last_commit": "2025-10-15T15:30:00Z",
    "last_push": "2025-10-15T15:30:00Z"
  }
}
```

**Testing:**
- Init dotfiles repo → bare repo created
- Add and commit files → git log shows commit
- Push to remote → files on GitHub
- Pull from remote → updates local dotfiles

---

## Component Dependencies

```
self.zsh (independent, can run anytime)
omz.zsh + plugins.zsh (can run together)
backup-mgmt.zsh → restore.zsh (restore depends on backups)
git/integration.zsh (independent, optional feature)
```

---

## Integration Points

**git:**
- Self-update: git pull in tool directory
- Plugin updates: git pull in plugin directories
- Dotfiles: git operations in home directory (bare repo)
- Use user's existing authentication

**Oh My Zsh:**
- Update framework: omz update or git pull in ~/.oh-my-zsh
- Update custom plugins: git pull in each custom plugin

**File System:**
- Backup management: CRUD in ~/.config/zsh-tool/backups/
- Restore: Copy from backup to home directory
- State tracking: Update state.json

---

## State Management

**state.json Updates (Epic 2):**
```json
{
  "tool_version": {
    "current": "v1.1.0",
    "previous": "v1.0.0",
    "last_update": "2025-10-15T14:30:00Z",
    "last_check": "2025-10-15T14:30:00Z"
  },
  "omz": {
    "version": "master-xyz789",
    "last_update": "2025-10-15T14:30:00Z"
  },
  "plugins": {
    "zsh-syntax-highlighting": {
      "version": "v0.8.0",
      "last_update": "2025-10-15T14:30:00Z"
    }
  },
  "backups": {
    "last_backup": "2025-10-15-143000",
    "count": 10,
    "remote_enabled": true,
    "remote_url": "git@github.com:user/zsh-backups.git"
  },
  "last_restore": {
    "timestamp": "2025-10-15T15:00:00Z",
    "from_backup": "2025-10-10-120000"
  },
  "git_integration": {
    "enabled": true,
    "repo_type": "bare",
    "remote_url": "git@github.com:user/dotfiles.git",
    "last_commit": "2025-10-15T15:30:00Z"
  }
}
```

---

## Testing Strategy

**Unit Tests (bats):**
```bash
# tests/epic2/update.bats
@test "self-update: checks for new commits" { ... }
@test "self-update: applies update via git pull" { ... }
@test "self-update: rolls back on failure" { ... }
@test "omz-update: updates framework" { ... }
@test "plugin-update: updates custom plugins" { ... }
@test "backup: creates manual backup" { ... }
@test "backup: prunes old backups" { ... }
@test "restore: lists available backups" { ... }
@test "restore: restores from backup" { ... }
@test "git: initializes dotfiles repo" { ... }
@test "git: commits and pushes changes" { ... }
```

**Integration Test:**
```zsh
#!/usr/bin/env zsh
# tests/integration/epic2-maintenance.sh

# Prerequisites: Epic 1 completed
source lib/zsh-tool.zsh

# Test self-update
zsh-tool-update self --check
[[ $? -eq 0 ]] || exit 1

# Test backup
zsh-tool-backup create
[[ -d ~/.config/zsh-tool/backups/$(date +%Y-%m-%d)* ]] || exit 1

# Test restore
backup_id=$(ls ~/.config/zsh-tool/backups/ | head -1)
zsh-tool-restore list | grep "$backup_id" || exit 1

# Test git integration
zsh-tool-git init
[[ -d ~/.dotfiles ]] || exit 1

echo "✓ Epic 2 integration test passed"
```

---

## Performance Targets

**Total Epic 2 Operations:**

- Self-update check: < 5s (git fetch)
- Self-update apply: < 30s (git pull + reload)
- OMZ update: 30-60s
- Plugin updates (5 plugins): 30s
- Manual backup creation: 5s
- Backup list display: < 1s
- Restore from backup: 10s
- Git init: < 5s
- Git commit/push: 5-10s

**Optimization:**
- Parallel plugin updates where possible
- Cache git fetch results (5 min TTL)
- Skip unchanged backups during prune

---

## Security Considerations

- Use user's existing git credentials (SSH keys)
- No credential storage in config files
- Gitignore excludes sensitive files (.ssh/, .gnupg/)
- Remote backup optional (user controls remote)
- Validate git remote URLs (no arbitrary URLs)

---

## Epic 2 Implementation Checklist

- [ ] Implement Story 2.1: `update/self.zsh`
- [ ] Implement Story 2.2: `update/omz.zsh`, `update/plugins.zsh`
- [ ] Implement Story 2.3: `restore/backup-mgmt.zsh`
- [ ] Implement Story 2.4: `restore/restore.zsh`
- [ ] Implement Story 2.5: `git/integration.zsh`
- [ ] Create .gitignore template for dotfiles
- [ ] Write unit tests for all components
- [ ] Write integration test for Epic 2 flow
- [ ] Run shellcheck on all .zsh files
- [ ] Manual test on macOS 12, 13, 14
- [ ] Update state.json with Epic 2 fields
- [ ] Document git integration setup in README

---

## Epic 2 Handoff Notes

**Prerequisites from Epic 1:**
- `core/utils.zsh` (logging, error handling)
- `install/backup.zsh` (reused for pre-update/pre-restore backups)
- `~/.config/zsh-tool/state.json` (state tracking)
- `~/.config/zsh-tool/backups/` (backup directory)

**User-Facing Commands Added:**
- `zsh-tool-update [self|omz|plugins|all]`
- `zsh-tool-backup [create]`
- `zsh-tool-restore [list|apply]`
- `zsh-tool-git [init|status|commit|push|pull]`

**State Updates:**
- `tool_version`, `omz.last_update`, `plugins.*.last_update`
- `backups.last_backup`, `last_restore`
- `git_integration` (if enabled)

---

**Epic 2 Status:** Ready for Implementation
**Estimated Effort:** 17 story points (~4-5 days)
**Dependencies:** Epic 1 complete
