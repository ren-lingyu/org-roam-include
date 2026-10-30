# Current project memory

## Completed changelog and README maintenance

The user adopted English Org summaries in `CHANGELOG.org` and standalone
per-version manuscripts in `CHANGELOGS/`, using the git-maintenance Org profile.
The user confirms v0.1.0 was the first version and formal release. Its public
GitHub release is neither draft nor prerelease, and its tag object matches the
local tag. The platform body contains only a generated Full Changelog link;
there is no substantive prior manuscript to import. Historical reconstruction
uses the v0.1.0 source, README and tests, not current HEAD or retrospective
memory alone. The release declares Emacs 31.0, Org 9.7 and Org-roam 2.0.0, and
contains no Nix flake. Current Emacs 30.1/Nix changes belong in Unreleased.

Phase one is committed as `docs(changelog): backfill v0.1.0 release history`,
introducing `CHANGELOG.org` and `CHANGELOGS/v0.1.0.org`.
The summary covers node includes, outline projection and replacement mounts,
native recursive export, document boundaries, mode/setup diagnostics and
resolution errors. The detailed manuscript groups those capabilities with
requirements and limitations. It distinguishes structural DB-position checks
from complete stale-identity detection, retains saved-source/native-Org
boundaries and avoids unnecessary private implementation detail. The root
uses `DONE v0.1.0`, matching CUSTOM_ID and tagged-commit UTC committer time
`[2026-07-22 Wed 10:26]`. Its preface declares version-level CLOSED times UTC;
the user permits natural wording rather than requiring an exact sentence.
Details have no root backlinks, generic reference section or external source/
comparison/release navigation. They will be the source of truth for future
platform release-note preparation; platform writes are outside this task.

Both changelog phases are committed: historical backfill followed by
`docs(changelog): document unreleased changes since v0.1.0`. The Unreleased
entry records the lowered declared Emacs minimum (31.0 to 30.1), the breaking
manual-installation path move into `lisp/`, and newly added Nix packaging,
development shell, wrapper/overlay/legacy outputs and ERT/lint/treefmt workflow
with real dependencies. Since v0.1.0 had no Nix output, intermediate unreleased
default-output changes are not described as a breaking migration from the
published release. There is no chosen next version, Unreleased detailed file,
historical state/time change or self-referential changelog addition.

The user authorized README maintenance with separate staging and commit wait
boundaries, all now completed. README work used committed HEAD
`ebcf8d3d59f1bc1ceb8be0d377fc074d55e243f4` as its implementation baseline,
not the release tag. The user committed the README update as
`docs(readme): clarify setup and normalization boundaries`. The committed diff
contains only README.org, and the ordinary worktree is clean.

The existing README already described INCLUDE arguments, node resolution,
replacement mounts, recursive export, native search integration and Nix
installation/tests. The update preserves those explanations and adds mode
setup/disable semantics, the diagnostic command's lack of per-document/DB
validation, and the public normalization helper's destructive current-buffer
contract. It clarifies keyword case/raw arguments/non-UUID IDs, first-real-
headline-to-EOF projection and literal-block exclusion, export error propagation,
and automatic export-copy safety versus explicit direct calls. Historical
first-version wording now describes current behavior; the repository tree and
links include the committed changelog and standalone v0.1.0 manuscript.
The complete resulting README and diff were reviewed against affected HEAD
source and tracked paths; whitespace checks passed. No runtime or example test
was executed.

All planned documentation work is complete and user-committed. The completion
checkpoint is grounded in the final committed documentation review, not a new
build, test or publication run. No follow-up implementation task remains in
scope; resume by confirming a new objective and current source state. Project
staging and commits remain human operations, and requested commit messages
must describe the staged candidate. The ignore whitelist was committed
independently. Formatting, ignore, lock-refresh and runner internals remain
outside the changelog inventory.

Validation so far is static tagged-source/README/test-body and document review.
Git whitespace checks reported no issues, and ignore-rule inspection confirmed
both new files are trackable. No build, ERT, formatter, installation, export or
publication test was run. The repository work before these new documents was
at `1fd964bedb9083ec783314f060e1b07debbe704b`.

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
Framework-alignment validation observed default Emacs 31.1 at that time;
subsequent lock refreshes were not evaluated during documentation maintenance.
Input updates can change the selected version. Public package outputs are org-roam-include and emacs, with no default
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
The framework-alignment checkpoint's project parent records that source inspection,
not a new post-commit test run. Other exposed systems were omitted by Nix.

Framework-alignment README validation was static: six balanced Elisp examples, four referenced
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
