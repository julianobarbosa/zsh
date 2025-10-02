# Story: Add Safety Checks to .zshrc Modification

**Story ID**: ZSHTOOL-BUG-006
**Epic**: Epic 3 - Advanced Integrations
**Priority**: Medium
**Estimate**: 3 points
**Status**: To Do
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

- [ ] Create backup before modifying .zshrc
- [ ] Check if .zshrc is a symlink
- [ ] Verify file is writable
- [ ] Rollback on failure
- [ ] All tests pass

## Tasks/Subtasks

- [ ] **Task 1: Add backup creation**
  - [ ] Create timestamped backup
  - [ ] Verify backup succeeded

- [ ] **Task 2: Add symlink detection**
  - [ ] Check if .zshrc is symlink
  - [ ] Warn user and ask for confirmation

- [ ] **Task 3: Add write verification**
  - [ ] Check write permissions
  - [ ] Verify append succeeded

- [ ] **Task 4: Add rollback capability**
  - [ ] Restore backup on failure
  - [ ] Log rollback actions

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

- **Location**: `lib/integrations/amazon-q.zsh:206-226`
- **Epic**: Epic 3 - Advanced Integrations
