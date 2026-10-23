# Project memory

This retrospective snapshot captures the decision to continue independent,
strictly bounded development after the org-transclusion comparison on 2026-07-21.
Read [design.md](design.md) for the adopted target and [validation.md](validation.md)
for the experimental evidence. The target is not yet fully implemented here.

## Objective and decision

Keep org-roam-include as an export-only adapter from stable Org-roam identity to
native INCLUDE locations. The user explicitly chose this direction after the
comparison rather than adopting the assistant recommendation to prioritize an
org-transclusion wrapper. Do not build another transclusion engine.

The new target separates a base keyword with untouched native arguments, file
outline projection, and a convenience replacement mount restricted to file
nodes. Remove the prototype metadata whitelist instead of making it more
comprehensive. Database authority and saved-file semantics remain deliberate.

## Next action

Implement the narrowed contract in design.md and validate the two-stage compiler.
In particular, test native headline-location assumptions rather than treating
formatted keyword output as an export success. Recursive ROAM_INCLUDE remains
outside the initial implementation; ordinary native INCLUDE recursion stays Org's
responsibility.

## Evidence and remaining coverage

Source: Codex archived session 019f8056-9275-7e43-8fa2-651004902291,
org-transclusion comparison, the user prompt beginning “我重新思考” with the
development guidance, subsequent boundary discussion and README rewrite.
The preceding prototype is retained in first-parent memory history.

Comparison results belong to the tested historical environment, not a guarantee
about every org-transclusion version. Exact clean package commits for the original
comparison and prototype work are unknown. Later implementation and test-system
intervals are still to be reconstructed.
