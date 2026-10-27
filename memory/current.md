# Current project memory

## Active staged alignment plan

The user approved implementing a seven-node alignment plan based on the later
org-roam-organize refactor. The earlier lisp/package/test-overlay migration and
rx any-to-in change are already committed; do not repeat those migrations.
Proceed one node at a time: (1) existing dependency/URL updates, (2) ignore rule
sorting only, (3) pure repository formatting, (4) enabling treefmt checks,
(5) default Emacs and named-package/overlay alignment, (6) README alignment,
(7) narrowing llib to directly inherited tests/packages attributes.

The user explicitly chose default pkgs.emacs/pkgs.emacsPackages and removal of
packages.default, retaining org-roam-include and emacs outputs. These choices
supersede the earlier Emacs-31 constraint for the planned alignment. They are
not yet implemented. Preserve Lisp behavior, version 0.1.0, eight ERT scenarios,
and both existing Guile runners. There is one ERT suite, so do not introduce
shared-test-builder scaffolding.

Each node requires review and authorization for validation commands and explicit
ordinary staging, then a git-maintenance message in ordinary-project tmp/commit.md.
Wait for the user's manual commit and verify HEAD movement before the next node.
Maintain current memory during work. Planned checkpoint milestones are after
node 4 and after node 7, with additional checkpoints only for consequential
blockers or decisions. GAW messages must also follow git-maintenance, using
Conventional Commit subjects and the established English memory-message style.

Node 1 is committed by the user as `chore(flake): refresh inputs and normalize
personal-nixpkgs URL`. Inspection confirmed only flake.nix/flake.lock changed,
with the reviewed dependency graph and URL edits; the worktree was clean before
node 2. The authorized flake check passed with zero pending builders on
x86_64-linux, not fresh ERT/lint execution.

Node 2 is committed by the user as `chore(git): sort gitignore whitelist entries
alphabetically`. It changes only .gitignore; the ordinary worktree was clean
before node 3. Its pattern set is identical, and before/after Git ignore decisions
matched for all tracked paths and representative allow/deny paths. No tracked
file is ignored; tmp remains ignored. The staged diff passed whitespace checks.

Node 3 is committed by the user as `style: apply repository formatting`.
Ten files changed only layout; Lisp source, ERT and Scheme non-comment token
streams matched their pre-format versions. The authorized flake check passed on
x86_64-linux, freshly rebuilt the package, ran eight ERT cases successfully and
passed lint. The user committed the reviewed ten-file formatting candidate.

Node 4 is committed as `test(treefmt): add repository formatting check` and
only changes treefmt.flakeCheck to true. The user also independently committed
removal of the obsolete *.patch formatter exclusion before node 4. The ordinary
worktree is clean at this milestone. The agent's node-4 check passed and freshly
executed treefmt, reusing successful node-3 package/ERT/lint results; it preceded
that independent exclusion cleanup. The final commits were inspected statically,
not rerun by the agent after the cleanup. The milestone project parent identifies
that exact post-commit inspection, not new runtime test provenance.

Nodes 1-4 are complete. This is the first planned GAW checkpoint. Next: node 5,
default pkgs.emacs/pkgs.emacsPackages throughout builds, wrapper and tests;
explicit emacsPackages overlay grouping/export; removal of packages.default in
favor of org-roam-include and emacs named outputs. Then node 6 README and node 7
llib narrowing. No node-5 changes have been made yet. The next planned checkpoint
is after node 7, unless a consequential blocker or decision warrants one sooner.

## Earlier completed refactor

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
and the source library is lisp/org-roam-include.el. The earlier move preserved
its bytes; the later node-3 formatting preserved its non-comment token stream. Version declarations remain 0.1.0. The one authorized Nix check
successfully built the package, ran all eight ERT tests and passed package-lint
on x86_64-linux. Other systems were omitted by Nix. Earlier historical evidence
remains in validation.md.

## Open points and next action

- The earlier refactor is committed. Follow the active staged alignment plan
  above for the newly authorized task; the ordinary worktree is clean at the
  node-4 milestone, with node 5 next.
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
