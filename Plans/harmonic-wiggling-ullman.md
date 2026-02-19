# Plan: Remove Duplicate Git Aliases (OMZ Covers Them)

## Context

The project's `templates/config.yaml` defines 3 custom git aliases (`gs`, `gp`, `gps`) but also loads the Oh My Zsh `git` plugin which provides **197 git aliases**. This creates:

1. **A direct conflict:** `gp` in OMZ = `git push`, but the project defines `gp` = `git pull`. Since the project alias loads after OMZ, it silently overrides OMZ's convention, which is confusing for anyone familiar with OMZ.
2. **Redundancy:** OMZ already provides `gst` (git status) and `gl` (git pull), making the custom `gs` and `gp` unnecessary.
3. **`gps`** is not in OMZ but is also not standard — OMZ users expect `gp` for push.

**Decision:** Remove the 3 custom git aliases from `config.yaml`. Users get the OMZ standard aliases (`gst`, `gl`, `gp`) which are well-documented and universally recognized.

## OMZ Equivalents

| Removed Custom Alias | OMZ Replacement | Command |
|----------------------|-----------------|---------|
| `gs` = "git status" | `gst` | `git status` |
| `gp` = "git pull" | `gl` | `git pull` |
| `gps` = "git push" | `gp` | `git push` |

## Changes

### 1. `templates/config.yaml` (lines 25-31)

Remove the `gs`, `gp`, `gps` entries from the `aliases:` section. Keep `ll` (non-git alias, not provided by OMZ):

```yaml
# Team aliases
aliases:
  - name: "ll"
    command: "ls -lah"
```

### 2. `tests/test-config.zsh` (lines 185-190)

Update `test_parse_aliases()` to check for `ll` instead of the removed git aliases:

```zsh
test_parse_aliases() {
  local aliases=$(_zsh_tool_parse_aliases 2>/dev/null)
  echo "$aliases" | grep -q 'alias ll="ls -lah"'
}
```

### 3. `tests/test-plugins.zsh` (line 99-101)

Update test fixture YAML — replace `gs` with `ll`:

```yaml
aliases:
  - name: "ll"
    command: "ls -lah"
```

### 4. `tests/test-themes.zsh` (line 103-105)

Update test fixture YAML — replace `gs` with `ll`:

```yaml
aliases:
  - name: "ll"
    command: "ls -lah"
```

### 5. Documentation updates (read-only reference, low priority)

These docs contain examples showing the old aliases. Update to reflect new state:
- `docs/solution-architecture.md` (line 202-204)
- `docs/development-guide.md` (line 124)
- `docs/implementation-artifacts/1-3-install-team-standard-configuration.md` (line 168)
- `docs/tech-spec-epic-1.md` (lines 157-158)
- `docs/tech-spec-epic-2.md` (line 374) — `dotfiles` alias, unrelated, no change needed
- `docs/QUICKREF.md` (line 230) — `dotfiles` alias, unrelated, no change needed
- `docs/MODULE-REFERENCE.md` (line 318) — `dotfiles` alias, unrelated, no change needed

## Verification

1. `grep -r '"gs"\|"gp"\|"gps"' templates/` — should return no git alias matches
2. Run existing tests: `zsh tests/test-config.zsh` — should pass with updated assertions
3. Run: `zsh tests/test-plugins.zsh` and `zsh tests/test-themes.zsh` — should pass
4. Verify `ll` alias still present in config.yaml
