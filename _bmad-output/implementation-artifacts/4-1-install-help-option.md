# Story 4.1: Implement --help Option for zsh-tool-install

Status: done

## Story

As a user,
I want to run `zsh-tool-install --help` to see usage information,
so that I can understand the command options without triggering a full installation.

## Acceptance Criteria

1. Running `zsh-tool-install --help` displays help text and exits without installing
2. Running `zsh-tool-install -h` also displays help text (short form)
3. Help output follows the same style as other zsh-tool commands
4. All existing functionality remains unchanged when no flags are passed

## Tasks / Subtasks

- [x] Task 1: Analyze current install function (AC: #1)
  - [x] Review zsh-tool-install function in install.sh
  - [x] Review help patterns from other commands (zsh-tool-update, zsh-tool-backup)
- [x] Task 2: Implement argument parsing (AC: #1, #2)
  - [x] Add argument parsing loop at start of zsh-tool-install
  - [x] Handle --help and -h flags
- [x] Task 3: Create help text (AC: #3)
  - [x] Document available options
  - [x] Match style of zsh-tool-help output
- [x] Task 4: Test implementation (AC: #4)
  - [x] Verify syntax is valid (zsh -n)

## Dev Notes

### Current State Analysis
- `zsh-tool-install` function is defined in `install.sh` lines 145-224
- Function has NO argument parsing - immediately starts installation
- Other commands like `zsh-tool-update` have proper `--help` handling via case statements
- The main `install.sh` script only handles `--dev` flag (line 25)

### Implementation Pattern
Follow the pattern from `zsh-tool-update` (lines 229-371):
```zsh
while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h)
      # show help
      return 0
      ;;
    *)
      # unknown option
      ;;
  esac
done
```

### References
- [Source: install.sh#145-224] - zsh-tool-install function
- [Source: install.sh#229-371] - zsh-tool-update with argument parsing pattern
- [Source: install.sh#567-626] - zsh-tool-help command style reference

## Dev Agent Record

### Agent Model Used
Claude Opus 4.5 (claude-opus-4-5-20251101)

### Completion Notes List
- Added argument parsing loop with while/case pattern (matches zsh-tool-update style)
- Handles both --help and -h flags
- Unknown options display error and usage hint
- Syntax validated with `zsh -n`

### File List
- install.sh:145-188 (added argument parsing to zsh-tool-install function)
