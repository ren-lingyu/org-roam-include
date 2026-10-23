# Base adapter validation

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, temporary
compiler tests and clean-dev integration assessment on 2026-07-21. No project
tests were rerun for memory reconstruction.

## Recorded compiler tests

The archived runs reported passing file-node whole-file compilation, headline
FILE::LINE formatting, unchanged raw-tail spacing and ordering, original keyword
indentation, replacement mount semantics, COMMENT exclusion and narrowed scans.
Additional coverage preserved one or multiple affiliated keywords and ignored
pseudo-keywords/headlines inside source, example and comment blocks. Headline-node
mounts and file-outline projection without a real heading correctly failed.

Testing exposed regexp match-data corruption during COMMENT checking, repaired
with save-match-data. Org AST collection and :post-affiliated then addressed
literal contexts and affiliated prefix preservation. The final temporary test
run reported a clean tracked worktree; the subsequent dev review also recorded
empty staged/unstaged diffs and identified the exact tip under inspection.

These tests validate compiler behavior, not successful native expansion of
FILE::LINE or recursive ROAM_INCLUDE. Original experiments mostly preceded
commits or operated on working trees; the source-review parent is not a blanket
provenance claim for them.

## Adopted scope from the comparison

In the tested org-transclusion environment, :no-first-heading with automatic
:level was closer to mount requirements than :only-contents; metadata exclusions,
relative-link expansion and narrowed processing also worked in examples.
Nevertheless, the user chose a small export-only adapter with Org-roam DB
location authority. The comparison did not establish complete backend equivalence
or imply a package-replacement decision.

Next probes should verify recursive native entry points, propagation across
Org-created buffers, inactive ordinary-buffer behavior and advice cleanup.
