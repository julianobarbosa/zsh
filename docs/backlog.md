# Engineering Backlog

This backlog collects cross-cutting or future action items that emerge from reviews and planning.

Routing guidance:

- Use this file for non-urgent optimizations, refactors, or follow-ups that span multiple stories/epics.
- Must-fix items to ship a story belong in that story's `Tasks / Subtasks`.
- Same-epic improvements may also be captured under the epic Tech Spec `Post-Review Follow-ups` section.

| Date | Story | Epic | Type | Severity | Owner | Status | Notes |
| ---- | ----- | ---- | ---- | -------- | ----- | ------ | ----- |
| 2026-01-05 | ZSHTOOL-010 | 3 | Migration | Critical | - | Ready | Migrate Amazon Q to Kiro CLI - AWS rebranded Nov 2025 (docs/stories/story-kiro-cli-migration.md) |
| 2025-10-04 | SECURITY-001 | 3 | TechDebt | Low | PAI | Done | Add explicit umask for settings file creation (lib/integrations/amazon-q.zsh:247,272,281,303) |
| 2025-10-04 | SECURITY-001 | 3 | Enhancement | Low | PAI | Done | Add concurrent access test to edge case suite (tests/test-amazon-q-edge-cases.zsh:559) |
