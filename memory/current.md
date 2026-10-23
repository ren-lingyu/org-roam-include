# Project memory

This retrospective snapshot captures recursive normalization integrated with the
main headline fix and retested after conflict resolution. Read
[design.md](design.md) for contracts and [validation.md](validation.md) for scope.

## Implemented state and reasons

The export-only adapter now normalizes ROAM_INCLUDE at every native INCLUDE
expander invocation. A preprocessing hook marks the export copy; thin around
advice carries dynamic recursive context into Org-created child buffers, compiles
mounts before keywords and calls the native expander with its original arguments.

Private headline search remains FILE::org-roam-include-line:N. Its handler is
bound dynamically during native expansion, replacing the isolated fix's broader
mode-lifecycle registration. Unmarked ordinary buffers remain inert. Mode disable
removes hook/advice integration. Old package-specific maximum-depth and stack
scaffolding was removed because tested native recursion and cycle detection
cover the intended behavior.

The merge resolution retained main's headline repair together with dev's
recursive architecture. Repeated headline and recursive tests passed on the
resolved working-tree candidate before explicit staging. This is not a claim
that a nearby clean project commit was the original test snapshot.

## Next action

Align README and Commentary with the integrated behavior, then promote useful
temporary tests into a standalone regression suite. Separate implementation,
verification and any later version/tag/release actions. Keep headline-node
property mounts undefined rather than expanding policy for release convenience.

## Evidence and remaining coverage

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, squash conflict
resolution, handler integration and repeated headline/recursive test runs.
Prior first-parent snapshots preserve the standalone fix and earlier assumptions.
Release preparation, Emacs compatibility, Nix testing and runner migration remain
to be reconstructed. No original clean project snapshot is inferred for this
staged integration candidate.
