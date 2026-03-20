---
title: 'Test Design: gc function — gemini-cli migration'
created: '2026-03-04'
status: 'complete'
scope: lightweight
inputDocuments:
  - ~/.zsh/functions.zsh
---

# Test Design: `gc` function — gemini-cli migration

## 1. Scope

**Change**: Replace `kiro-cli chat --no-interactive` with `gemini -p ""` in the `gc()` function.
**File**: `~/.zsh/functions.zsh` (lines 731-800)
**Dependencies**: `gemini` CLI at `/opt/homebrew/bin/gemini`, `_validate_commit_msg()` helper (unchanged)

## 2. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| gemini output format doesn't match conventional commit regex | Medium | High — commit silently fails to auto-generate | Grep filter + manual fallback already handles this |
| gemini stderr leaks into msg variable | Low | Medium — corrupted commit message | `2>/dev/null` redirects stderr |
| gemini hangs or times out on large diffs | Low | Medium — blocks terminal | `head -200` limits diff size; user can Ctrl+C |
| Empty response from gemini | Medium | Low — user prompted for manual input | Existing validation catches empty/invalid messages |

## 3. Test Cases

### TC-01: Happy Path — AI generates valid commit message

**Preconditions**: Git repo with staged changes, `gemini` installed and API key configured
**Steps**:
1. `echo "test" >> README.md && git add README.md`
2. Run `gc`
3. Observe output

**Expected**:
- Staged changes summary displayed
- "Generating commit message..." shown
- Valid conventional commit message suggested (e.g., `docs(readme): update README`)
- Prompt: `[Y] Accept  [e] Edit  [n] Abort`

**Verify**: Press `Y` → commit created with suggested message

---

### TC-02: Accept with Enter key

**Steps**: Same as TC-01, but press Enter (empty) instead of Y

**Expected**: Commit created (Enter maps to accept via `$'\n'` case match)

---

### TC-03: Edit suggested message

**Steps**: Same as TC-01, but press `e`

**Expected**:
- "Edit message:" prompt with pre-filled message
- Modified message validated against conventional commit format
- Commit created with edited message

---

### TC-04: Abort commit

**Steps**: Same as TC-01, but press `n` (or any key other than Y/e)

**Expected**: "Aborted." printed, no commit created, exit code 1

---

### TC-05: No staged changes

**Preconditions**: Clean working tree (nothing staged)
**Steps**: Run `gc`

**Expected**: "Nothing staged. Run 'git add' first." and exit code 1

---

### TC-06: Not a git repository

**Preconditions**: Run from a non-git directory (e.g., `/tmp`)
**Steps**: `cd /tmp && gc`

**Expected**: "Not a git repository" and exit code 1

---

### TC-07: gemini returns invalid/non-conventional format

**Preconditions**: Staged changes exist but gemini returns prose instead of conventional commit format
**Steps**: Run `gc` (may need to artificially trigger by staging trivial changes)

**Expected**:
- "Could not generate valid message. Enter manually:" prompt
- User types valid conventional commit → accepted
- User types invalid format → error shown, re-prompted
- User presses Enter (empty) → "Aborted."

---

### TC-08: gemini not installed or API key missing

**Preconditions**: `gemini` not in PATH or GOOGLE_API_KEY unset
**Steps**: Run `gc` with staged changes

**Expected**: gemini command fails silently (`2>/dev/null`), falls back to manual entry prompt

---

### TC-09: Large diff (boundary)

**Preconditions**: Stage changes across many files (>200 lines of diff)
**Steps**: Run `gc`

**Expected**: Only first 200 lines of diff sent to gemini (`head -200`), commit message generated normally

---

### TC-10: ANSI escape codes in gemini output

**Preconditions**: gemini returns colored output with ANSI codes
**Steps**: Run `gc`

**Expected**: `sed 's/\x1b\[[0-9;]*m//g'` strips ANSI codes before regex matching; clean message displayed

## 4. Not in Scope

- Testing `_validate_commit_msg()` in isolation (unchanged function)
- Testing gemini API quality/accuracy (external dependency)
- Automated test harness (shell functions require manual interactive testing)

## 5. Entry/Exit Criteria

**Entry**: `gemini` installed, API key configured, function sourced in shell
**Exit**: All TC-01 through TC-06 pass manually; TC-07/TC-08 fallback confirmed
