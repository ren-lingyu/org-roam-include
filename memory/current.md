# Project memory

This retrospective snapshot captures main integration of the base adapter and the
setup gate before recursive normalization. Read [design.md](design.md) for the
implemented contract and [validation.md](validation.md) for historical evidence.

## State and decision

The coherent export-only adapter has been integrated for main use. It preserves
the two-stage mount/keyword pipeline, raw native arguments, explicit file-outline
projection and database authority. Main-facing documentation describes package
behavior rather than a development diary. The dev line and main history are not
interchangeable project snapshots after squash integration.

Capability probes support using native INCLUDE recursion with a thin advice.
Mode activation is now protected by internal variable and runtime capability
checks, combined in org-roam-include-check-setup. Failure produces a complete
warning report and leaves the mode disabled instead of aborting Emacs startup.
Keeping this gate in the single package file avoids needless compatibility-module
loading complexity. An empty package-owned variable list is valid infrastructure,
not a reason to delete validation.

## Limits and next action

The setup failure path has been exercised, but recursive ROAM_INCLUDE is not yet
integrated. A buffer-local export marker cannot propagate into Org-created child
buffers by itself. Use dynamic recursive context alongside the marker when
implementing advice; keep ordinary unmarked buffers inert.

Test recursive file/headline cases and native selection boundaries, especially
whether FILE::LINE actually works inside Org's expander. Do not add a custom
cycle stack or depth guard before testing native behavior.

## Evidence and reconstruction status

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, main squash
preparation, recursive API probes, setup implementation and setup-check tests.
Exact clean commits for all of these experiments are not established: similar
setup subjects occur in both dev and main histories. No project parent is inferred
from equivalent content or nearby main commits.

Earlier prototype and scope decisions are represented in first-parent memory.
Recursion, release, Nix and runner intervals remain to be reconstructed.
