# Project memory

This retrospective snapshot captures the isolated headline-location repair on
main before recursive normalization is integrated. Read [design.md](design.md)
for the current contract and [validation.md](validation.md) for the experiments.

## Consequential finding and repair

Native Org INCLUDE does not treat the bare numeric suffix in FILE::LINE as the
intended headline line search in the tested environment. It reaches fuzzy search
and fails. Earlier compiler-output tests therefore did not establish headline
export correctness.

Headline nodes now use FILE::org-roam-include-line:N. A private search handler
navigates to the recorded physical line and validates a heading, preserving the
Org-roam DB identity/location boundary without title search or a custom selection
parser. Org still interprets :only-contents and relative :lines semantics.

A recursive dev implementation was tested, but the user deliberately separated
the headline bug fix onto main before integrating recursion. In this isolated
repair, mode lifecycle registers/removes the handler; the later intended dynamic
binding is not the main implementation at this boundary. Setup and base compiler
behavior remain in place. The old depth/stack declarations have not yet been
removed as part of recursive integration.

## Next action

Integrate recursive normalization while preserving the standalone headline fix.
Resolve main/dev differences deliberately, use dynamic search binding within the
native expander advice, then repeat headline and recursion boundary tests. Do not
replace private search with absolute subtree line ranges: that would require
interpreting native selection arguments inside the adapter.

## Evidence and limits

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, recursive
boundary probes exposing numeric search failure, private-search dev experiments,
and the user's request to reapply only the headline repair on main with tests.
The tests and staged repair do not identify a single clean original commit.
No main or dev commit is guessed as their project parent.

Prototype, scope, base implementation and setup states are represented in
first-parent history. Recursive integration and later release/test-system work
remain to be reconstructed.
