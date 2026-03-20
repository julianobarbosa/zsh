# Plan: Move .worktrees to .claude/worktrees

## Context

The repo has 6 git worktrees under `.worktrees/` (5 active, 1 prunable). The user wants to relocate them to `.claude/worktrees/` for better organization. `.claude/worktrees/` already exists (empty). `.worktrees/` is already in `.gitignore`.

## Current State

| Worktree | Branch | Status | Last Commit |
|---|---|---|---|
| add-direnv-to-workflow | add-direnv-to-workflow | active | 540fc38 |
| add-git-worktree-skill | add-git-worktree-skill | **prunable** (missing from disk) | 426618f |
| add-vimode | add-vimode | active | a514974 |
| fix-disk-clean | fix-disk-clean | active | 0c24177 |
| iterm2 | iterm2 | active | 61f98ba |
| test-new | test-new | active | 88c3702 |

## Plan

### Step 1: Prune the dead worktree
```bash
git worktree prune
```
Removes `add-git-worktree-skill` which is already missing from disk.

### Step 2: Move each active worktree using `git worktree move`
Git has a built-in `git worktree move` command that safely relocates worktrees and updates all internal pointers (`.git` file in worktree, `.git/worktrees/<name>/gitdir`).

```bash
git worktree move .worktrees/add-direnv-to-workflow .claude/worktrees/add-direnv-to-workflow
git worktree move .worktrees/add-vimode .claude/worktrees/add-vimode
git worktree move .worktrees/fix-disk-clean .claude/worktrees/fix-disk-clean
git worktree move .worktrees/iterm2 .claude/worktrees/iterm2
git worktree move .worktrees/test-new .claude/worktrees/test-new
```

### Step 3: Remove leftover `.worktrees/` directory
```bash
rmdir .worktrees
```
Should be empty after all moves.

### Step 4: Update `.gitignore`
Replace `.worktrees/` with `.claude/worktrees/` (unless `.claude/` is already fully ignored — need to check).

### Step 5: Verify
```bash
git worktree list   # All should point to .claude/worktrees/
ls .claude/worktrees/  # All 5 dirs present
```

## Files Modified
- `.gitignore` — update worktree ignore path

## Verification
- `git worktree list` shows all worktrees under `.claude/worktrees/`
- Each worktree's `.git` file points to correct `.git/worktrees/<name>/gitdir`
- Old `.worktrees/` directory no longer exists
- `git status` in each worktree works correctly
