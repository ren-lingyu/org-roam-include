# Project memory

This retrospective snapshot captures the implemented base adapter on dev before
main integration, reviewed on 2026-07-21. Read [design.md](design.md) and
[validation.md](validation.md) for the contract and limits.

## Objective and implemented state

The export-only adapter compiles file-node headline mounts to base ROAM_INCLUDE
keywords, then lowers those keywords to native INCLUDE. Saved files and the
Org-roam database remain authoritative. Native arguments are preserved verbatim.
File-outline projection is explicit; general metadata filtering has been removed.

The compiler now uses Org AST elements for real keywords and headings, rather
than matching block-contained examples. Actual keyword positions prefer
:post-affiliated, preserving NAME/CAPTION prefixes. Local surface parsing uses rx;
family-based helper naming separates keyword, mount, node, outline and INCLUDE
responsibilities. Keyword and property names are internal constants, not premature
user options.

The inspected dev worktree was clean. Its changes were judged coherent for
integration into main, but no staged changes existed during that review. This
source-review context is associated with the exact inspected project snapshot.

## Limits and next action

Temporary tests cover compilation output and structural boundaries. The headline
form FILE::LINE is still assumed to be a native location; successful formatting
is not proof that Org can expand it. Recursive ROAM_INCLUDE remains deferred.

Integrate the coherent adapter into main, then probe Org's recursive entry points
and protect mode activation with runtime capability checks before enabling a
recursive design. Do not duplicate native argument or file-reading semantics.

## Evidence

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, narrowed
implementation, AST/affiliated-keyword fixes, temporary tests and the clean-dev
merge assessment. The preceding comparison explains why this is an independent
adapter rather than a transclusion wrapper.

The project-parent association records the clean source inspection. Original
working-tree experiments do not gain exact provenance from that association.
Subsequent main integration, recursion, release and Nix intervals remain pending
historical reconstruction.
