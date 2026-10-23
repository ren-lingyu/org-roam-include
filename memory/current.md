# Current project memory

The requested historical reconstruction is complete through the three supplied
Codex archives, with the relevant supplementary handoff distilled and the present
project source inspected. Read [design.md](design.md) for behavior/rationale and
[validation.md](validation.md) for the verification ledger and its limits.
Source-code and test paths refer to the ordinary project tree. Links between
these memory files are relative to this GAW memory directory.

## Verified present state

org-roam-include is a single-library, export-only Org-roam ID to native INCLUDE
adapter. Version declarations in the Lisp header and Nix package are 0.1.0.
Base keywords support file and headline nodes; headline property replacement
mounts support file nodes only. The implementation uses saved files, DB locations,
a private numeric headline search, AST-aware compilation and dynamically scoped
normalization around native INCLUDE recursion. It does not provide live
transclusion, DB repair or metadata migration.

The flake uses Emacs 31 with the built package and real dependencies. ERT is at
tests/ert/ert.el and locally stubs only node lookup; package-lint checks the
filtered source tree. Separate run.scm files under both check directories are
generated with replaceVarsWith and run under Guile. Nixpkgs uses nixpkgs-unstable;
the earlier temporary pin and the current locked-input refresh are repository
facts, not grounds to invent unrecorded decisions or historical validation.

Current source inspection is associated with the exact project snapshot used.
That association does not identify the original snapshots for earlier dirty-tree
tests. No Nix build, ERT or package-lint was rerun during this reconstruction.

## Open points and next action

- README Requirements still says Emacs 31.0, while Package-Requires declares
  Emacs 30.1. Historical execution on Emacs 30.2 exists, but is not a complete
  compatibility matrix. Reconcile the documentation in a separately authorized
  maintenance task rather than silently choosing a new minimum version here.
- README Repository Structure omits tests/ert/run.scm and
  tests/package-lint/run.scm. The handoff repeats an incomplete layout; the actual
  source files establish the present runner structure.
- Git tag/release publication and current CI status were not independently
  verified. Existing installation, ERT and 0.1.0 declarations are not unfinished
  work merely because an earlier review said they were missing.

No new feature or package-merger task is adopted from the supplied materials.
For follow-up maintenance, first address the concrete documentation discrepancies
if requested; run builds/tests only within that task's authorization. Keep the
existing native INCLUDE boundary when considering future features.

## Reconstruction coverage and evidence limits

The entire substantive horizon of each supplied archive was surveyed. The
prototype/comparison/implementation/setup/headline/recursion/release/Emacs-30 work
in session 019f8056-9275-7e43-8fa2-651004902291, flake/dependency/docstring work
in session 019f9eb1-9eac-7ef3-bd38-d2a55514d6a6, and parameterization/path-repair/
Guile work in session 01a0897b-edfc-7a13-a605-5a20c8421e54 are represented by
supported key states in first-parent memory history. Minor revisions, retries,
rollbacks and commit-message discussions were examined without replaying them.
The first two archives overlap; completed-state order also uses the main DAG.

The root input gaw-input.md is a later distilled webpage handoff, not the complete
web conversation or independent execution proof. Its relevant design reasons,
corrections and verification limits are incorporated; it is not required to resume
from this memory. Its org-roam-organize API history remains outside this project's
scope, and no other repository was independently verified for this integration.

No substantive missing interval was identified within the supplied archive files.
Precise original clean-commit provenance remains unavailable for many tests, and
the complete original webpage discussion was not supplied. Those evidence limits
are preserved rather than filled with timestamps, equivalent commits or nearby
main states. No raw archive import, Auxiliary history or history rewrite was used.
