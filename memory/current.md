# Current project memory

## Completed framework alignment

The user-approved seven-node alignment is complete and each node was separately
committed by the user: dependency/URL updates, ignore-rule sorting, pure
formatting, the treefmt gate, default-Emacs/named-package overlays, README
alignment, and direct llib construction. The obsolete *.patch formatter exclusion
was additionally removed in an independent user commit. The final ordinary
worktree is clean. The first planned GAW milestone covered nodes 1-4; this final
checkpoint records the completed alignment. No additional implementation or
staging step remains for this task.

## Verified current state

org-roam-include remains a single-library, export-only Org-roam ID to native
INCLUDE adapter at lisp/org-roam-include.el. Lisp/Nix version declarations remain
0.1.0. Package requirements remain Emacs 30.1, Org 9.7 and Org-roam 2.0.0. Base
keywords support file/headline nodes; property replacement mounts support file
nodes only. Saved sources, DB positions, AST-aware compilation, private numeric
headline search and native recursive INCLUDE expansion remain the design boundary.
No live transclusion, database repair or metadata migration was added.

The flake uses personal-nixpkgs with a lisp-rooted source fileset, package overlays
and tests.mkChecks. All package, wrapper, development and check environments use
default pkgs.emacs/pkgs.emacsPackages rather than explicitly selecting Emacs 31.
The current locked default happens to be Emacs 31.1; future input updates may
change it. Public package outputs are org-roam-include and emacs, with no default
package. The emacsPackages overlay is explicitly grouped and publicly exported.
llib directly inherits only the framework tests/packages attributes; replacing
the former single-element recursive merge simplified construction without
changing that attribute set.

There is one real-dependency ERT suite with eight existing scenarios and a
separate package-lint check. Their adjacent Guile runners remain, without shared
builder scaffolding; only the lint environment adds package-lint. Treefmt is part
of flake checks. Repository formatting changed only layout, with identical
non-comment token streams in the library, ERT and changed Scheme runner.

README now documents named-package builds, default Emacs selection, the public
overlay and the treefmt gate. It distinguishes structural DB-location validation
from complete stale-identity detection and omits unverified publication claims.
It retains local lisp/ installation paths and the native INCLUDE behavior model.

## Validation and continuation

Read [design.md](design.md) for supported behavior and maintenance reasons, and
[validation.md](validation.md) for the complete evidence scope and limitations.
Paths to source/tests refer to the ordinary tree; memory links are relative here.

The formatting candidate rebuilt the package, freshly ran all eight ERT tests
with zero unexpected results, and passed package-lint on x86_64-linux. Subsequent
checks for the gate and final wiring passed, reusing the same successful package,
ERT and lint derivations while executing treefmt freshly. The final authorized
flake check used the working candidate before the user's last commit; that
committed diff was then inspected and the ordinary worktree confirmed clean.
The checkpoint's project parent records that exact final source inspection,
not a new post-commit test run. Other exposed systems were omitted by Nix.

README validation was static: six balanced Elisp examples, four referenced
package symbols present at HEAD, a valid LICENSE link and whitespace checks.
No example evaluation or new live database, backend or compatibility matrix was
performed. Publication and current CI status remain unverified.

No project files remain to change for this plan. Keep the committed dependency
lock unless a new task explicitly requests dependency maintenance. No Lisp
feature or package-merger task is adopted. Temporary commit-message material
remains in the ignored ordinary-project tmp directory.

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
