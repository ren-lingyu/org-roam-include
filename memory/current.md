# Project memory

This retrospective snapshot captures the Guile/replaceVarsWith test-runner
migration completed in the September conversation. Read [design.md](design.md)
for maintained contracts and [validation.md](validation.md) for evidence limits.

## State and motivation

The export-only adapter and real-dependency test boundary remain unchanged. Both
ERT and package-lint now use executable Scheme runners generated with
pkgs.replaceVarsWith from tests/ert/run.scm and tests/package-lint/run.scm.
The user prefers direct .scm names and Scheme control flow over shell arrays,
quoting and string lists embedded in Nix. Guile is a check dependency, not a new
runtime dependency of the distributed Emacs library.

Nix supplies interpreter, Emacs and source/test paths; Scheme prepares temporary
HOME, invokes Emacs with structured system* arguments, checks failures and creates
the derivation output on success. Lint recursively enumerates .el files in the
filtered source tree and rejects an empty list. Guile uses --no-auto-compile.

An intermediate shell runner could name a source path that was unavailable in
the sandbox. The final repair uses explicit context-bearing replacement strings
for the ERT file and lint source. Extra top-level derivation attributes used as
an initial dependency workaround were removed. Retain the filtered source tree;
replacing it with a path list would break consumers requiring a directory.

Nixpkgs is now selected from nixpkgs-unstable rather than the earlier temporary
pin. The main DAG establishes that intervening configuration change, not its
unrecorded original motivation.

## Verification and next action

The shell-stage repaired check has a successful user-provided result. After the
Guile conversion, the user again reported passing tests, but the final report
does not include a fresh complete execution log. Do not inflate that report into
an independently observed final runner execution or CI result.

Archived session 01a0897b-edfc-7a13-a605-5a20c8421e54 has now been covered from
the initial parameterization discussion through failed sandbox paths, corrected
replacement strings, Guile selection and final staged-message review. The earlier
two sessions are represented in first-parent history. No new feature expansion
was adopted at this boundary; next complete the current-state consolidation with
the supplied handoff and actual present source.
