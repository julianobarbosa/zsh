# Plan: Disable Auto-Collapse of Tool Outputs in Claude Code

## Context

Barbosa wants tool outputs (bash results, file reads, etc.) to display in full by default,
without needing to press `ctrl+o` to expand the `... +N lines (ctrl+o to expand)` truncated view.

## Finding

**There is no setting to control this behavior today.** Research confirmed:

- The tool output collapsing is hardcoded in the Claude Code terminal UI
- `~/.claude/settings.json` has no `expandToolOutput`, `autoExpand`, or equivalent key
- This is a known request tracked in GitHub issue [#11173](https://github.com/anthropics/claude-code/issues/11173)
- There is also a known bug where `ctrl+o` sometimes doesn't even work for individual outputs: [#8214](https://github.com/anthropics/claude-code/issues/8214)

## What Exists (Partial Mitigations)

These settings reduce truncation of bash output content **inside the AI context**, but do NOT
disable the UI collapsing in the terminal display:

```json
// ~/.claude/settings.json → env section
"BASH_MAX_OUTPUT_LENGTH": "999999"   // prevents middle-truncation of bash output
```

This may help with one class of truncation (bash content sent to the model being cut off), but
will NOT remove the `(ctrl+o to expand)` collapsed UI blocks.

## Options

### Option A — Accept Current Behavior (No Action)
- The collapse is cosmetic/UX; content is still sent to the model
- Use `ctrl+o` to expand when you want to inspect specific outputs visually
- Star/upvote [GitHub issue #11173](https://github.com/anthropics/claude-code/issues/11173) to increase priority

### Option B — Add BASH_MAX_OUTPUT_LENGTH to settings.json
- Prevents bash output from being silently truncated mid-content
- Does not affect the UI collapse behavior, but reduces invisible data loss
- File: `~/.claude/settings.json` → `env` section
- Change: add `"BASH_MAX_OUTPUT_LENGTH": "999999"`

### Option C — Use --verbose flag at startup
- `claude --verbose` may show more raw output, but is primarily a debug flag
- Not suitable for everyday use

## Recommendation

**Option B** as a small improvement (prevents content truncation to the model), combined with
**Option A** (accept the UI collapse for now and upvote the GitHub issue).

There is no way to fully disable the `(ctrl+o to expand)` UI behavior without modifying
Claude Code's source code.

## Verification

After adding `BASH_MAX_OUTPUT_LENGTH`:
1. Restart Claude Code
2. Run a bash command that produces >100 lines of output
3. Observe whether content is still cut off mid-output (vs just collapsed in UI)
