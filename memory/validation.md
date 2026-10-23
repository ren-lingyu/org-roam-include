# Historical verification and runner limits

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
