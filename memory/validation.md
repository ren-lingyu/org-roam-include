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
The ordinary worktree was modified without project staging/commits; no clean
project commit represents this tested state. The existing user-edited flake.lock
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
matrix, or publication validation was performed. No additional project parent is
attached for the dirty refactor: current HEAD would describe the pre-refactor tree.
