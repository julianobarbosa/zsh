---
title: 'Clean up P10k right prompt — remove time and unused segments'
slug: 'clean-p10k-right-prompt'
created: '2026-03-19'
status: 'implementation-complete'
stepsCompleted: [1, 2, 3, 4]
tech_stack:
  - powerlevel10k
  - zsh
files_to_modify:
  - '~/.dotfiles/zsh/.p10k.zsh'
code_patterns:
  - 'POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS array in .p10k.zsh'
  - 'Comment-out pattern: prefix line with "# " to disable segment'
test_patterns:
  - 'Visual verification via source ~/.p10k.zsh'
  - 'No automated tests — p10k config is outside zsh-tool repo'
---

# Tech-Spec: Clean up P10k right prompt — remove time and unused segments

**Created:** 2026-03-19

## Overview

### Problem Statement

The Powerlevel10k right prompt displays the current time (`17:35`) at the end of line 1, adding visual clutter with no practical value — the clock is always visible in the OS menu bar. Additionally, the `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` array includes ~20 unused segments (version managers, task trackers) that are not part of Barbosa's workflow and add unnecessary lookup overhead.

### Solution

Edit `~/.dotfiles/zsh/.p10k.zsh` to comment out the `time` segment and all unused version manager/tracker segments from `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS`, keeping only actively used segments.

### Scope

**In Scope:**
- Comment out `time` segment from right prompt elements
- Comment out unused version manager segments (asdf, anaconda, pyenv, goenv, nodenv, nodeenv, rbenv, rvm, fvm, luaenv, jenv, plenv, perlbrew, phpenv, scalaenv, haskell_stack)
- Comment out unused tracker segments (todo, timewarrior, taskwarrior, per_directory_history)

**Out of Scope:**
- Left prompt changes
- Color/style changes
- Adding new segments
- Changes to zsh-tool config.yaml

## Context for Development

### Codebase Patterns

- `.p10k.zsh` lives at `~/.dotfiles/zsh/.p10k.zsh` (symlinked to `~/.p10k.zsh`)
- Segments in `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` array (lines 48-119)
- Existing convention: comment out with `#` + space + segment name + original comment
- Example from file: `# node_version          # node.js version` (line 62)

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `~/.dotfiles/zsh/.p10k.zsh` (line 48-119) | `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` array — the ONLY code to modify |

### Technical Decisions

- **Comment out vs delete**: Comment out (matches existing file convention where ~15 segments are already commented out)
- **Keep nvm, remove nodenv/nodeenv**: Barbosa uses nvm for Node.js
- **Keep virtualenv, remove pyenv/anaconda**: Barbosa uses standard Python venvs
- **Keep shell indicators** (ranger, nnn, lf, xplr, vim_shell, midnight_commander, nix_shell, chezmoi_shell): These are contextual — they only show when you're inside that shell, zero cost otherwise

## Implementation Plan

### Tasks

- [x] Task 1: Comment out unused version manager segments in `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS`
  - File: `~/.dotfiles/zsh/.p10k.zsh`
  - Action: Add `# ` prefix to these lines:
    - Line 54: `asdf` → `# asdf                    # asdf version manager (...)`
    - Line 56: `anaconda` → `# anaconda                # conda environment (...)`
    - Line 57: `pyenv` → `# pyenv                   # python environment (...)`
    - Line 58: `goenv` → `# goenv                   # go environment (...)`
    - Line 59: `nodenv` → `# nodenv                  # node.js version from nodenv (...)`
    - Line 61: `nodeenv` → `# nodeenv                 # node.js environment (...)`
    - Line 70: `rbenv` → `# rbenv                   # ruby version from rbenv (...)`
    - Line 71: `rvm` → `# rvm                     # ruby version from rvm (...)`
    - Line 72: `fvm` → `# fvm                     # flutter version management (...)`
    - Line 73: `luaenv` → `# luaenv                  # lua version from luaenv (...)`
    - Line 74: `jenv` → `# jenv                    # java version from jenv (...)`
    - Line 75: `plenv` → `# plenv                   # perl version from plenv (...)`
    - Line 76: `perlbrew` → `# perlbrew                # perl version from perlbrew (...)`
    - Line 77: `phpenv` → `# phpenv                  # php version from phpenv (...)`
    - Line 78: `scalaenv` → `# scalaenv                # scala version from scalaenv (...)`
    - Line 79: `haskell_stack` → `# haskell_stack           # haskell version from stack (...)`
  - Notes: Preserves original comments for easy re-enabling

- [x] Task 2: Comment out unused tracker/utility segments
  - File: `~/.dotfiles/zsh/.p10k.zsh`
  - Action: Add `# ` prefix to these lines:
    - Line 105: `todo` → `# todo                    # todo items (...)`
    - Line 106: `timewarrior` → `# timewarrior             # timewarrior tracking status (...)`
    - Line 107: `taskwarrior` → `# taskwarrior             # taskwarrior task count (...)`
    - Line 108: `per_directory_history` → `# per_directory_history   # Oh My Zsh per-directory-history (...)`

- [x] Task 3: Comment out `time` segment
  - File: `~/.dotfiles/zsh/.p10k.zsh`
  - Action: Line 110: `time` → `# time                    # current time`

### Acceptance Criteria

- [x] AC1: Given the p10k config is sourced, when a new prompt renders, then no time display appears on the right side of line 1
- [x] AC2: Given the p10k config is sourced, when inspecting `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS`, then only these segments remain active on line 1: `status`, `command_execution_time`, `background_jobs`, `direnv`, `virtualenv`, `nvm`, `kubecontext`, `terraform`, `aws`, `aws_eb_env`, `azure`, `gcloud`, `google_app_cred`, `toolbox`, `context`, `nordvpn`, `ranger`, `nnn`, `lf`, `xplr`, `vim_shell`, `midnight_commander`, `nix_shell`, `chezmoi_shell`
- [x] AC3: Given the p10k config is sourced, when running `sleep 3`, then `command_execution_time` still displays the duration on the right prompt
- [x] AC4: Given the p10k config is sourced, when a kubectl context is active, then `kubecontext` still renders on the right prompt

## Additional Context

### Dependencies

- None — single file change, no external dependencies

### Testing Strategy

- Source the config: `source ~/.p10k.zsh`
- Visual verification: time no longer appears at end of line 1
- Functional check: `sleep 3` shows execution time
- Functional check: `kubectl config current-context` context shows in prompt

### Notes

- Final active right prompt segments (line 1): `status → command_execution_time → background_jobs → direnv → virtualenv → nvm → kubecontext → terraform → aws → aws_eb_env → azure → gcloud → google_app_cred → toolbox → context → nordvpn → [shell indicators]`
- All commented segments can be re-enabled by removing the `# ` prefix
- The `.p10k.zsh` file is in the dotfiles repo, not the zsh-tool repo — commit should go there

## Review Notes
- Adversarial review completed
- Findings: 3 real, 1 fixed (R7 — spec Notes missing segments), 2 not code-fixable (R4 — commit goes to dotfiles repo, R1 — review artifact)
- Resolution approach: auto-fix
