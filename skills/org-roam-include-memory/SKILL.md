---
name: org-roam-include-memory
description: Use whenever working in the org-roam-include repository or discussing its code, behavior, bugs, tests, Nix checks, documentation, or design. Read project memory first, even when the request does not mention GAW or memory.
---

# Project memory entry

Before substantive project work, locate the formal GAW worktree using
`git-agent-workflow`, then read `memory/current.md`.

Paths below are relative to that worktree root and refer to workspace data,
not bundled skill resources:

- `memory/current.md`: current state, open points and next action.
- `memory/design.md`: contracts, design reasons and maintenance conventions.
- `memory/validation.md`: evidence, historical interpretation and verification limits.

Load the latter two only as needed. Keep project facts and progress in memory.
If memory is missing, follow the GAW recovery/establishment workflow.

Use the separately available `git-agent-workflow` for GAW operations and
`git-maintenance` for checkpoint messages.
