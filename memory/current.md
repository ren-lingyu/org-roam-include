# Project memory

This retrospective snapshot captures the completed initial flake test-system
migration and README alignment. Read [design.md](design.md) for package and test
contracts and [validation.md](validation.md) for evidence limits.

## State and adopted structure

The 0.1.0 export-only adapter retains private headline search, native recursive
normalization and file-node replacement mounts. Testing now has a flake-parts
entry point, package build, ERT and package-lint checks plus a matching development
shell. The purpose of introducing the flake was reproducible testing; packaging
and the development shell support that goal.

An explicit fileset creates a source tree containing the primary library, README
and license. packages.default builds the library with compilation warnings as
errors. The combined Emacs environment includes that package, its real Org and
Org-roam dependencies and package-lint. ERT loads the installed package and real
Org-roam; only node lookup is locally replaced to avoid a live database.
Package-lint checks the filtered source tree.

The suite moved to tests/ert/ert.el; tests/default.nix coordinates separate ERT
and lint derivations. Test Nix code receives its external inputs and does not
reach into the parent directory or assume filenames outside tests. Native
arguments, source identity and built-package loading have distinct owners.

A temporary Nixpkgs pin was adopted to obtain an upstream Org hash-mismatch fix
not yet available on nixpkgs-unstable. Earlier override experiments are not a
permanent package design requirement. README now documents nix flake check and
temporary saved-file fixtures instead of the retired standalone test location.

## Next action and evidence

The next selected work is richer symbol-level documentation of contracts,
implementation and rationale. Keep the actual test dependency boundary explicit:
real Org-roam types do not mean a real database is exercised.

Source: archived session 019f9eb1-9eac-7ef3-bd38-d2a55514d6a6, from the opening
flake discussion through fileset/parameter decisions, real-dependency migration
and testing documentation. The user reported a passing test state during setup;
static syntax checks and staged review do not prove every later revision was rerun.
Original clean project provenance for working-tree runs remains uncertain.

The earlier session's final Emacs 30 verification overlaps the start of this
source; the order here follows completed knowledge states, not session starts.
Docstring correction and runner migration remain to be reconstructed.
