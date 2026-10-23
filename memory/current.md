# Project memory

This is a retrospective snapshot of the export-only prototype review boundary
on 2026-07-21. It describes knowledge at that boundary, not today's source tree.
Read [design.md](design.md) for contracts and [validation.md](validation.md) for
evidence limits.

## Objective and state

Compose Org documents using stable Org-roam node IDs while preserving real local
headlines for outline navigation. Only export output is in scope: editing-time
previews, live insertion and navigation enhancements are not required.

The implementation lives in an independent package so experimental development
does not block maintenance of the user's Emacs configuration. The prototype has
package metadata, a global minor mode, package-owned variable checks and an
export-copy preprocessing hook. Native INCLUDE delegation has replaced the
initial direct-subtree-copy proposal.

The prototype has undergone several review-driven changes, but its native
headline location and induced-level assumptions have not received export-level
validation. Do not treat static review as a working-export result.

## Decision and next action

Pause feature growth and compare org-transclusion against the actual composition
requirements before building more metadata, linking or recursion machinery.
Keep the prototype for comparison; no decision to replace it has been made.

## Reconstruction evidence

Source: Codex archived session 019f8056-9275-7e43-8fa2-651004902291,
from the opening design request through prototype review and the decision to
investigate org-transclusion. Its opening repository metadata concerns a different
configuration repository and is not this package's project provenance.

The complete three-session horizon was surveyed before selecting durable states.
This snapshot covers the early prototype interval; later intervals remain to be
represented by subsequent retrospective checkpoints. Exact original project
commits for these working-tree edits are not established.
