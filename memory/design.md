# Narrow native INCLUDE adapter contract

## Identity and base keyword

Use #+ROAM_INCLUDE: NODE-ID RAW-TAIL. Interpret only the first non-whitespace
token as an Org-roam ID; do not impose a UUID format. Preserve the remaining
single-line text, including its leading whitespace, as native INCLUDE arguments.
Do not parse :lines, :only-contents, :minlevel, src or other native parameters.

Resolve file, level and point through Org-roam's database. Read saved source
files; unsaved visiting buffers are not authoritative. Validate readable files,
bounds and structural headline alignment. Do not search by title or CUSTOM_ID,
rescan IDs to repair positions, or synchronize the database during export.

File nodes lower to a whole-file absolute path, without metadata stripping.
The proposed headline form is FILE::LINE, without automatic :only-contents t.
This is a target assumption awaiting actual native expansion testing.

## Projection and mount policy

File-outline projection starts at the first real headline and includes the final
headline's complete subtree through end of file, represented by :lines "N-".
A file with no headline is an error, not an empty or whole-file fallback.

A local headline's ROAM_INCLUDE property may target only a file node. Preserve
the local heading and other properties; remove the controlling property, local
body and descendants in the export copy and insert the file-outline wrapper.
Headline-node property mounts have multiple plausible meanings and are deliberately
undefined. Use the base keyword and explicit native arguments for headline nodes.

Compile mounts before keywords so discarded descendants and their invalid IDs
are not resolved. Skip nested mounts replaced by an ancestor. Respect narrowing
and COMMENT subtrees. Recognize keyword case insensitively; preserve raw arguments.
Quoted locations must obey Org syntax rather than Elisp string-literal rules.

## Reasons and non-goals

Org should own selection, levels, recursion, paths, links and footnotes. The
comparison showed viable transclusion features, but the adopted goal remains a
small export-only identity adapter with Org-roam DB authority. Replacing metadata
whitelists with explicit outline projection makes the high-level policy narrow
without redefining whole-file INCLUDE.

No editing preview, live transclusion, property inheritance, ID/CUSTOM_ID migration,
attachment repair, automatic DB synchronization or independent INCLUDE parser is
planned for this initial contract. Recursive ROAM_INCLUDE is deferred rather than
claimed complete. Package-owned validation infrastructure remains separate from
Org-roam configuration validation.
