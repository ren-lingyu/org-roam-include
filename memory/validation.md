# Recursive integration validation

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, private-search
experiments, main/dev conflict resolution and the repeated tests before staging
the resolved candidate. No tests were rerun during memory reconstruction.

## Historical observations

- Bare FILE::LINE failed in actual native expansion despite earlier compiler
  output tests. Private numeric search repaired headline selection without
  changing native :only-contents or :lines interpretation.
- Recursive ROAM -> ROAM, native -> ROAM, and ROAM -> native -> ROAM passed.
  Included content with file-node property mounts also expanded recursively.
- Outer :lines selection occurred before inner wrapper resolution. Invalid IDs
  outside the selected range did not fail the tested expansion.
- Headline :only-contents still allowed recursive inner wrappers. Whole-file,
  direct-headline and indirect-headline cycles were rejected by native Org.
- COMMENT subtrees and source-block literal wrappers were excluded. Unmarked
  ordinary buffers were inert, and mode disable removed hook/advice integration.
- Main's isolated headline tests and the recursive suite both passed after the
  squash conflict was resolved, before the candidate was explicitly staged.

The resolution kept main's private-search fix and dev's export-marker/dynamic
recursive architecture. Passing dev experiments alone were not treated as main
verification; the integration was tested again.

## Limits and next verification

These were temporary scripts and saved-file fixtures, not yet a maintained ERT
suite. No complete backend compatibility matrix or arbitrary native INCLUDE
behavior is established. Setup failure behavior was tested separately through
simulated missing interfaces and warning-only disablement.

Original experimental and resolved working-tree states do not have unambiguous
clean-commit provenance. Equivalent main commits or later commits cannot supply
it retrospectively. Promote representative boundaries into regression tests and
align package documentation before release preparation.
