# Verification evidence and runner limits

## Established validation boundary

The first archived session 019f8056-9275-7e43-8fa2-651004902291 records
successful temporary setup/native expansion probes and eight passing standalone
ERT results, including a Nix-provided Emacs 30.2/Org 9.7.38 run and package-lint.
Its original suite supplied dependency stand-ins. The second archived session
019f9eb1-9eac-7ef3-bd38-d2a55514d6a6 migrated ERT to the installed package and
real Org-roam, retaining only a local database-lookup stub. A successful check
after docstring repair used accepted existing check results, not fresh ERT/lint
builders for that invocation.

## Runner migration evidence

Source: archived session 01a0897b-edfc-7a13-a605-5a20c8421e54.

The initial replaceVarsWith shell-runner check did not finish in the planned
window while dependencies were fetched/built. A later user-provided failure showed
Emacs could not load the test source path from the sandbox. An initial workaround
added redundant top-level dependency attributes; the user preferred explicit
string interpolation in replacements, and both test/lint definitions were repaired
accordingly. The next user-provided check exited zero and reported zero checks
needing execution. That is successful check completion, not a new complete run.

The later Scheme conversion received static diff checks. After conversion the
user said tests passed and requested commit preparation. No final complete Guile
builder log accompanies that assertion; preserve it as a user-reported result.
Staged review found coherent Nix definitions and Scheme runners with no unstaged
changes. Review coherence is separate from executed validation.

## Scope and unresolved verification

The eight maintained ERT scenarios cover headline search, mixed recursion,
mounts, selection, COMMENT/literals, activation, cycle-related errors and cleanup.
They do not exercise a live Org-roam database or all export backends. Temporary
setup probes cover additional warning/failed-activation behavior. Installing real
dependencies does not retrospectively change the earlier stand-in test suite.

No project build, ERT or lint was rerun during reconstruction. Most original
experiments used modified/staged states without exact clean-commit provenance.
Do not attach equivalent main commits as substitutes. A version declaration is
not evidence of a published tag or release.

## Reading retrospective states

These GAW snapshots were created during reconstruction, not on the dates of the
original work. Interpret each complete workspace at its stated knowledge boundary.
The original implementation evolved on dev and was squash-integrated into main;
matching code in a main commit does not identify an earlier experimental snapshot.
Use the main DAG together with conversation/tool evidence for supported ordering,
and inspect Git for actual parent relationships rather than inferring them from
commit dates. Consult original inputs when the retained knowledge leaves a material
question unresolved; already represented states need not be replayed by default.

## Pre-refactor source inspection and evidence quality

The pre-refactor inspected source had version 0.1.0, minimum requirements Emacs 30.1,
Org 9.7 and Org-roam 2.0.0. The flake selects Emacs 31. At that inspection README stated Emacs
31.0 and omitted the two run.scm files from its tree listing; these are documentation
differences, not newly established runtime failures. Both Guile files, their Nix
substitutions and real-dependency requires were read; no builders were executed.

The cycle-test helper accepts several error texts, including Lisp nesting-limit
exhaustion. Therefore a passing maintained cycle assertion alone is weaker than
proof of a specific native cycle diagnostic. Historical probe reports describe
native cycle rejection, but this is not an exhaustive guarantee for all inputs.
Similarly, structural DB-position checks cannot detect every stale identity.

The webpage handoff reports user practical successes and corrects stale assistant
reviews; its preparation did not run local checks. Treat those as transferred
reports and source-derived explanations, not independent new executions. Published
tag/release status and current CI were not checked here.

## GAW reconstruction verification

Only memory files were written for the historical reconstruction. Every candidate
was reviewed as a complete snapshot with the existing entry skill and unchanged
GAW config; explicit staging and GAW checks preceded checkpoints. Memory content
and checkpoint messages were screened for credentials, unnecessary personal
information and machine-specific paths. Necessary session identifiers remain as
evidence locators. Project-parent content screening is excluded under the user's
explicit direction; graph associations still use exact observed snapshots.

The reconstruction checkpoint's present-state project parent means its source inspection. The earlier
clean-dev association means its recorded source review, not all preceding test
runs. Other original working-tree provenance remains uncertain. Recover actual
parent relationships from Git rather than a parallel memory index.

## Reference-based Nix refactor validation

The user requested alignment with ../org-texmacs after introducing personal-nixpkgs.
The original test execution used the modified ordinary worktree before project
staging/commit. The existing user-edited flake.lock
was preserved. Lisp source moved to lisp/org-roam-include.el and a byte comparison
against the previous tracked source succeeded. ERT and both run.scm files were
unchanged. Static diff whitespace checking succeeded, and new package/source/check
paths were confirmed visible under the allowlist ignore rules.

The user authorized one execution of:
`timeout 120s nix flake check -L --no-write-lock-file path:<project-root>`.
It exited zero with all checks passed on x86_64-linux. The shared flake reported
25 checks; the package was built with compilation warnings as errors, the ERT
builder freshly ran all eight maintained tests (zero unexpected), and the lint
builder completed successfully. The check evaluated named/default package aliases,
the Emacs 31.1 wrapper, development shell, overlays and formatter. Other exposed
systems were omitted as incompatible; no cross-platform claim follows.

Some dependency cache transfers retried. Org's initial .tar URL returned 404,
then its .tar.lz fallback succeeded; these did not prevent the successful check.
No lock update, formatter execution, live Org-roam DB test, new compatibility
matrix, or publication validation was performed. The initial refactor checkpoint
omitted a project parent because HEAD still described the pre-refactor tree.

After the user committed the refactor, read-only inspection of the entire committed
diff confirmed it matches the previously reviewed staged changes; Git status is
clean. The follow-up checkpoint associates the exact project commit inspected for
this completion confirmation. This records post-commit source review, not a fresh
Nix/ERT/lint run and not retroactive clean-commit provenance for the original test.
The existing ancestor closure was already retained through earlier project-parent
associations; the new committed diff contains the reviewed project changes only.


## Later staged alignment: dependency baseline

For node 1 of the user-approved alignment plan, the existing flake URL/lock edits
were reviewed without additional dependency updates. The user authorized one
`timeout 120s nix flake check -L --no-write-lock-file`; it exited zero on
x86_64-linux and reported zero checks needing execution. It accepted existing
package/ERT/lint results; this is not a new fresh run of the eight ERT cases.
Other systems were omitted. The check was against the working candidate before
the user's commit. The two input files were staged with explicit authorization;
no ordinary commit was performed by the agent.


## Staged alignment: formatting validation

For node 3, the user authorized `timeout 120s nix fmt` followed by
`timeout 120s nix flake check -L --no-write-lock-file`. Ten tracked files changed.
Static comparison found identical non-comment token streams in library Lisp,
ERT and the changed Scheme runner, and Nix diffs contained layout changes.
Whitespace checks passed. The flake check exited zero on x86_64-linux, rebuilt
the package with compilation warnings as errors, ran eight ERT tests with zero
unexpected results, and completed package-lint. Other systems were omitted.
This check was on the formatting candidate before the user's commit.


## Staged alignment: formatting check gate

Node 4 only enables treefmt.flakeCheck. The user authorized one
`timeout 120s nix flake check -L --no-write-lock-file`; it passed on x86_64-linux,
freshly executing the treefmt builder while reusing node-3 package/ERT/lint
results. Other systems were omitted. The working diff contains one changed
boolean and passes whitespace checking. No Emacs-selection, package-output or
Lisp behavior change is part of this candidate.


The user committed the formatting and gate candidates separately. Between them,
the user also independently committed removal of the obsolete *.patch formatter
exclusion. The agent inspected these final commits and a clean ordinary worktree;
no check was rerun by the agent after that exclusion cleanup. The first milestone
checkpoint associates the exact gate commit inspected for completion. The earlier
working-candidate test results remain separately scoped rather than being claimed
as fresh runs on the committed milestone.


## Staged alignment: default Emacs and named packages

The user authorized formatting only the four node-5 Nix files and running one
full flake check. Both succeeded on x86_64-linux. Output confirms named
org-roam-include/emacs packages without a default alias and the public
emacsPackages overlay. Default Emacs in the locked nixpkgs is also 31.1;
package, ERT and lint derivations are identical to the successful node-3 ones,
so they were reused. Treefmt ran freshly and passed. No Lisp, runner or ERT logic
was changed. This result applies to the staged working candidate before the
user's commit. No project lockfile update occurred.


## Staged alignment: README verification

Node 6 audits README against the committed node-5 implementation. The agent
read the complete README and verified package/check wiring and the structural
DB-location validation boundary against source. The documentation now describes
default Emacs, named outputs, the public package overlay and treefmt checks;
it narrows the stale-database detection claim and removes an unverified release
publication assertion. Read-only checks confirmed balanced delimiters in six
Elisp blocks, four package symbols defined at HEAD and an existing LICENSE link.
Whitespace checking passed. No example evaluation, build, test or formatter was
run for this documentation candidate. Only README was staged with permission.


## Staged alignment: final llib simplification

Node 7 only replaces a single-element mergeAttrsRecursive expression with direct
inheritance of the same tests/packages attributes. The user authorized one final
`timeout 120s nix flake check -L --no-write-lock-file`; it passed on x86_64-linux.
Package/ERT/lint derivations remained identical to successful earlier results
and were reused; treefmt ran freshly and passed. This is a working-candidate
check before the user's final commit, not a new fresh ERT run. Whitespace checks
passed and only flake.nix was staged with permission.


The user committed the README and llib simplification as separate final project
commits. Read-only inspection confirmed the final commit contains the reviewed
single-expression simplification and the ordinary worktree is clean. The final
GAW checkpoint associates this exact inspected source state. It does not turn
working-candidate checks into fresh post-commit executions. The seven-node plan
is complete; all ordinary commits were performed by the user.
