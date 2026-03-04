# Quick Tech Spec: Replace kiro-cli with gemini-cli in `gc` function

## Context

The `gc` function in `~/.zsh/functions.zsh` (lines 731-796) currently uses `kiro-cli chat --no-interactive` to generate AI-assisted conventional commit messages from staged git changes. The user wants to switch the AI backend from `kiro-cli` to `gemini-cli` (`/opt/homebrew/bin/gemini`), which is already installed.

## Problem

`kiro-cli` is being replaced by `gemini-cli` as the preferred CLI tool for AI-assisted commit message generation.

## Solution

Replace the `kiro-cli` invocation with `gemini -p` (non-interactive/headless mode) in the `gc` function. Keep the existing UX flow (show staged changes, generate message, confirm/edit/abort).

## File to Modify

- `~/.zsh/functions.zsh` — lines 746-752 (the AI generation block inside `gc()`)

## Change Details

### Current code (lines 746-752):
```zsh
local msg=$(kiro-cli chat --no-interactive "Generate a single-line conventional commit message for these staged changes. Use format: type(scope): description. Types: feat|fix|docs|style|refactor|test|chore|perf|ci|build. Output ONLY the commit message, nothing else.

$(git diff --cached --stat)
---
$(git diff --cached | head -200)" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E '^(feat|fix|docs|style|refactor|test|chore|perf|ci|build)(\(.+\))?!?:' | head -1)
```

### New code:
```zsh
local diff_stat=$(git diff --cached --stat)
local diff_content=$(git diff --cached | head -200)
local prompt="Generate a single-line conventional commit message for these staged changes. Use format: type(scope): description. Types: feat|fix|docs|style|refactor|test|chore|perf|ci|build. Output ONLY the commit message, nothing else.

${diff_stat}
---
${diff_content}"

local msg=$(echo "$prompt" | gemini -p "" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -E '^(feat|fix|docs|style|refactor|test|chore|perf|ci|build)(\(.+\))?!?:' | head -1)
```

### Key differences:
1. **Tool swap**: `kiro-cli chat --no-interactive` → `gemini -p ""`
   - `gemini -p ""` runs in non-interactive mode; stdin is piped as the prompt content, `-p ""` appended (empty string so stdin is the full prompt)
2. **Structured variables**: Extract `diff_stat` and `diff_content` into local vars for readability
3. **Stderr handling**: `2>/dev/null` instead of `2>&1` — gemini stderr is debug noise, not useful output
4. **Everything else unchanged**: validation, interactive confirm/edit/abort, comment line updated

### Also update the comment on line 729:
```zsh
# gc - AI-assisted git commit using gemini-cli
# Generates conventional commit messages from staged diff
```

## Scope

**In scope**: Swap AI backend from kiro-cli to gemini-cli in `gc()` function
**Out of scope**: Changing the UX flow, validation logic, or any other functions

## Verification

1. Stage some changes: `git add -A`
2. Run `gc`
3. Verify: staged changes displayed, AI message generated, confirm/edit/abort works
4. Verify: invalid/empty AI output falls back to manual entry
