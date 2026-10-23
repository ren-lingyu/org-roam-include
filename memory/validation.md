# Release-preparation evidence

## Recorded runs

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, standalone ERT
and Emacs 30 verification. No build or test was rerun for this reconstruction.

The release-preparation batch ERT command reported eight tests and eight expected
results after the package version was changed to 0.1.0. The separate later Nix
run used nixos-25.05's emacs30; its output identifies Emacs 30.2 and Org 9.7.38.
It reported eight expected ERT results and no unexpected results. Package-lint
also exited zero with empty captured diagnostics in that environment.

The earlier attempt against the unstable package set encountered an upstream
Org fixed-output hash mismatch. Falling back to the stable package set allowed
the compatibility experiment to finish. This is an environment-selection result,
not an adapter correctness fix or a guarantee for every Emacs 30/Org combination.

## Regression coverage and dependency limit

The standalone suite covers private headline search, mixed recursion, property
mount recursion, outer selection before recursion, COMMENT/literal boundaries,
activation boundaries, native cycle detection and mode cleanup. Source fixtures
are real temporary files. Package tests are not run by normal package loading.

The original ERT suite unconditionally defines a stand-in Org-roam node structure
and resolver and provides the org-roam feature before loading the package source.
Installing real dependencies in the environment does not remove those stand-ins.
This suite therefore does not establish real Org-roam integration coverage; the
later dependency migration must change the test file itself.

Earlier temporary probes additionally exercised setup failure reports and
warning-only disablement. Their successful experiments and the maintained suite
have distinct scopes; neither establishes all export backends.

## Provenance and publication

The final original session still reported a modified source file. Original exact
clean commits for the working-tree tests are not established, so neither the
version commit nor the suite-introduction commit is attached speculatively.
The header version does not establish a Git tag or release. Those publication
states have not been independently verified.
