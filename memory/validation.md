# Headline repair and recursion findings

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, recursive
boundary probes and standalone main headline repair. These are historical
observations, not tests rerun during reconstruction. Exact original clean commits
for the experimental and staged states are not established.

## Failure that changed the implementation

Whole-file mixed recursion worked in initial advice experiments, but headline
FILE::LINE expansion failed with a fuzzy-expression error. Direct probes also
showed that a numeric suffix was not interpreted as the intended line location;
CUSTOM_ID and title searches had different semantics. Compiler formatting tests
had missed this failure.

The chosen private prefix uses the recorded database point to derive a physical
line, leaving native selection and :only-contents to Org. Falling back to absolute
subtree ranges would have forced the adapter to interpret native argument
combinations and was rejected.

## Recorded repair tests

The private-search dev tests covered gated handler behavior, headline includes,
headline :only-contents, mixed recursive forms and native cycle detection.
They validate that experimental dev state, not an already-integrated main feature.

After the user switched to main and requested the isolated repair, a separate
run passed private location generation, headline/body/child expansion,
:only-contents removal of the source root, and literal wrapper preservation in
source blocks. The repair was then explicitly staged. No recursive advice was
introduced by that standalone patch.

Prior setup tests exercised combined diagnostics, failed capability reports,
warning-only mode disablement and cleanup. Base structural compiler tests covered
raw tails, affiliated prefixes, mounts, restrictions and literal contexts.

Next repeat headline and recursive tests after main/dev integration. Preserve
that distinction rather than transferring dev successes to untested main code.
