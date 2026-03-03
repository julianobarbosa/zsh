# Plan: Document Project (BMAD Workflow)

## Context

Barbosa wants to run the `bmad-bmm-document-project` workflow on the **zsh** project. This is a zsh configuration framework (CLI type, monolith) that already has extensive documentation from a previous exhaustive scan completed on 2026-02-04.

**Current state:**
- `docs/INDEX.md` exists with navigation to all docs
- `docs/project-scan-report.json` shows completed exhaustive scan (Feb 4, 2026)
- 40+ documentation files already exist in `docs/`
- Project classified as: CLI Tool, monolith, Pure ZSH

Since existing docs and a completed scan report exist (>24 hours old), the workflow will offer: **full-rescan** or **deep-dive** options.

## Plan

1. **Invoke the `bmad-bmm-document-project` skill** — this is a direct skill invocation that launches the interactive BMAD document-project workflow
2. The workflow will detect existing state and offer options (rescan vs deep-dive)
3. Follow the workflow's interactive prompts to completion
4. Output goes to `docs/` per config (`project_knowledge: "{project-root}/docs"`)

## Verification

- Workflow runs to completion
- Updated documentation files appear in `docs/`
- `project-scan-report.json` is updated with new timestamps
