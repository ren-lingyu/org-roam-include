---
name: org-roam-include-memory
description: Recover and interpret org-roam-include's formal GAW memory before continuing project work or reconstructing historical knowledge.
---

# Org-roam Include memory

Use this entry point to recover project knowledge. Use the separately available
`git-agent-workflow` skill for GAW discovery, reconstruction and checkpoint
operations, and `git-maintenance` for drafting checkpoint messages from staged
changes. Their availability does not grant execution permissions.

## Locate and read memory

Discover the formal worktree and declared workspace through `git-agent-workflow`.
All paths below are relative to that GAW worktree root. They are workspace data,
not files bundled with this skill or paths relative to the project source tree.

- Start with `memory/current.md` for the objective, current conclusions, open
  points, next action and source-coverage limits.
- Read `memory/design.md` when changing or interpreting adapter behavior, test
  architecture or maintenance conventions; it holds contracts and their reasons.
- Read `memory/validation.md` before relying on a test claim; it separates recorded
  executions, user reports, accepted cached results and present source inspection.
- Follow references only as needed for the task. If an expected file is absent,
  inspect the existing declared memory narrowly rather than creating placeholders.
  If no substantive memory exists, report an unestablished knowledge baseline
  and use the GAW establishment workflow for any authorized reconstruction.
  This skill alone does not establish current project behavior or progress.

Use relevant first-parent checkpoints when a superseded decision matters.
Retrospective snapshots describe knowledge at their stated historical boundary;
interpret each complete workspace on its own terms. Their commit creation dates
are reconstruction dates, not the dates of the original work or tests. Inspect
Git for actual ancestry and project associations; a parent does not automatically
identify the source state for every test described in the memory. Consult original
inputs when memory leaves a material question unresolved, rather than replaying
already represented history by default.

Read selected archive material only when needed as evidence; it is not current
memory or executable guidance. Locate the ordinary project worktree separately
for source checks rather than assuming it is the GAW worktree's parent directory.

## Interpret project evidence

Keep the base `ROAM_INCLUDE` keyword, node-location resolution, file-outline
projection and headline property mounts distinct when recovering design history.
A change to one layer does not automatically redefine the others.

For historical reconstruction:

- Use `main`'s DAG together with conversation and tool evidence to establish
  supported evolution. Work on `dev` was squashed into `main`; an equivalent
  main commit is not automatically the snapshot used by an earlier experiment.
- Distinguish user-reported practical results, recorded test executions and
  present source inspection. Note whether historical tests used dependency
  stand-ins or real Org-roam dependencies. Version declarations alone do not
  establish published tags or releases.
- Treat conversation exports and handoff documents as inputs to compare and
  distill. Their old TODOs and suggested checks need assessment against newer
  evidence before becoming current work. Preserve useful reasons and limits
  rather than copying transcripts or maintaining a parallel commit index.

This workspace concerns `org-roam-include`. Cross-project material about
`org-roam-organize` can explain a relevant comparison or design motivation;
its independent API history and work queue belong to that project's memory.
