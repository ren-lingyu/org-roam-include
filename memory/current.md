# Current project memory

## Completed refactor

The user requests refactoring this project using ../org-texmacs as a reference,
building on their existing personal-nixpkgs input/lock edits, and maintaining GAW
throughout. Initial inspection found flake.nix referencing a missing pkgs directory
and not yet using the reference's mkFlake nixpkgs argument. The adopted scope
is Nix packaging/check discovery, a lisp source directory, and corresponding README
and ignore rules; preserve Lisp behavior, Emacs 31, real-dependency ERT, and Guile
runners. Use package overlays and llib.tests.mkChecks as in the reference.
The implementation now uses lisp/, package overlays, explicit MELPA version,
mkChecks test overlays, and updated README/ignore rules. All build/check Emacs
package sets select Emacs 31. ERT and both Guile runners are unchanged. The user
authorized one 120-second Nix flake check with --no-write-lock-file and the path
source (to include new files without staging); it exited zero with all checks
passed, including eight ERT results and package-lint. The user's
lockfile changes are preserved. The user has committed the complete refactor;
post-commit inspection confirms the committed diff matches the reviewed staged
changes, and the ordinary worktree is clean.

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

The Nix configuration now follows the org-texmacs overlay/check discovery pattern
and the source library is lisp/org-roam-include.el, byte-identical to its previous
root file. Version declarations remain 0.1.0. The one authorized Nix check
successfully built the package, ran all eight ERT tests and passed package-lint
on x86_64-linux. Other systems were omitted by Nix. Earlier historical evidence
remains in validation.md.

## Open points and next action

- Refactor, validation and the user's project commit are complete. The ordinary
  worktree is clean; no implementation or staging step remains for this task.
- Local load paths now end in lisp/. Keep the committed lockfile unless a later
  task explicitly changes dependencies.
- Release publication and current CI status remain unverified and outside this task.

The former README minimum-version and runner-layout discrepancies are addressed
by this refactor. No Lisp feature or package-merger task is adopted. Preserve the
native INCLUDE boundary for any later feature work.

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
