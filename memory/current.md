# Project memory

This retrospective snapshot captures 0.1.0 preparation and the historical Emacs
30 validation completed on 2026-07-27. Read [design.md](design.md) for behavior and
[validation.md](validation.md) for exact coverage and limitations.

## State

The core export-only adapter, private headline search and mixed native/ROAM
recursion are implemented. README and Commentary were aligned with that behavior,
including the distinction between ordinary file targets and private headline
locations, and the fact that Org owns cycle detection rather than a separate
depth guard. Installation examples and include-target documentation exist.

Representative temporary tests were promoted to tests/org-roam-include-test.el,
a standalone eight-test ERT suite. The package header was changed to 0.1.0.
Fixtures use make-temp-file and temporary-file-directory; saved-file behavior
requires real temporary disk files rather than exclusively temporary buffers.
Tests are separate developer tools, not code executed by normal package loading.

The recorded release-preparation ERT run passed eight tests. A later Nix-provided
Emacs 30.2 environment with real dependency packages also passed ERT and
package-lint. The original ERT file still contains dependency stand-ins: putting
real dependencies in the environment does not by itself prove tests use their
real implementation. Version declarations and release readiness are not proof of
a published tag or release.

## Next action and evidence limits

A reproducible flake test environment is being investigated in an overlapping
conversation. Complete that test-system work with an explicit distinction between
source linting, packaged behavior and real Org-roam dependencies. Do not re-add
installation or ERT as nonexistent work, and do not publish a release by inference.

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, documentation,
standalone ERT, version preparation and final Emacs 30 runs. Its complete horizon
is now represented across the reconstructed states. Repeated aborted requests,
small edits and commit-message revisions were examined, not promoted to separate
knowledge states. Original working-tree test provenance remains uncertain.

The flake conversation began before this session's final validation; session
start times do not establish the order of completed knowledge states. Nix testing,
docstring work and runner migration remain to be reconstructed.
