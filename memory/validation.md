# Nix and real-dependency validation boundary

## Evidence sources

Archived session 019f8056-9275-7e43-8fa2-651004902291 records eight passing ERT
results and successful package-lint using Nix-provided Emacs 30.2/Org 9.7.38.
That original test file unconditionally supplied Org-roam stand-ins; the run is
not proof of real Org-roam integration despite available dependency packages.

Archived session 019f9eb1-9eac-7ef3-bd38-d2a55514d6a6 records flake development,
user-reported passing checks, static Nix syntax/whitespace checks and removal of
the fake node structure, resolver and provided feature. The final ERT now requires
real Org-roam and the installed adapter, with a local lookup stub only. This
establishes the intended test dependency boundary; no live database is exercised.

## Test-system meaning

The package build treats compilation warnings as errors. ERT targets the built
package rather than a source load-path override; lint targets the filtered source
tree. The combined Emacs makes the package build part of the check dependency
chain. Checks have separate temporary HOME/fixture behavior from an interactive
devShell, which does not itself hide the user's configuration.

The maintained ERT scenarios cover private search, mixed recursion, property
mounts, outer selection, COMMENT/literals, activation, cycle-related errors and
mode cleanup. Prior temporary probes separately tested missing-capability failure
and warning-only disablement. Neither set establishes all export backends.

## Limits

The user reported passing tests while the initial environment was being shaped.
Subsequent removal of dependency stand-ins and README edits received static
checks; do not infer a fresh complete execution for every intermediate revision.
The upstream Org hash-mismatch workaround is environment evidence, not an adapter
bug fix. No project build, ERT or lint was rerun for memory reconstruction.

Most original work used staged or modified trees. A nearby main commit is not
assigned as original test provenance. Package version 0.1.0 does not independently
establish tag/release publication.
