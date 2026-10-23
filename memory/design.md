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
Headline nodes lower to FILE::org-roam-include-line:N. The private numeric suffix
is handled through org-execute-file-search-functions, moves to the physical line
and checks headline alignment. Bare FILE::LINE was tested and rejected because
Org treated it as fuzzy search. Do not reinstate it or fall back to title lookup.

Bind the handler dynamically in org-execute-file-search-functions during native
expansion. It is private intermediate syntax, not a permanent ordinary-link
extension. The adapter does not add :only-contents t automatically; native
arguments select root removal and range semantics.

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

## Structural compiler

Collect actual keyword elements through org-element-parse-buffer and
org-element-map. Use :post-affiliated, falling back to :begin, to replace the
wrapper line without consuming affiliated keywords. Process positions from the
end to avoid invalidating earlier offsets and preserve the original indentation.
Find file-outline starts through actual headline elements, excluding literal
headlines inside source/example blocks. Keep regexp match data protected around
COMMENT checks. A successful earlier text scan did not cover these structural
hazards.

Use internal constants for keyword/property spelling and role-based helper
families rather than exposing unstable knobs. The public mode remains global
and export-only. No custom recursive engine has been added.

## Setup gate and recursive integration

org-roam-include-check-setup is the public diagnostic command. Internal variable
and capability checks collect a combined result before enabling the global mode.
Check package-owned variables only. Missing required runtime interfaces cause
warning diagnostics and keep the mode off; failure must not block Emacs startup.
Retain the general check machinery even when a current variable list is empty.

Use runtime capabilities rather than an assumed Emacs version alone. The
preprocessing hook marks the export buffer. Around advice on
org-export-expand-include-keyword acts only on the marked export copy or within
org-roam-include--within-native-expansion, dynamically propagating recursion into
Org-created child buffers. A buffer-local marker alone cannot do this.

Normalize the current buffer before each native invocation, bind the private
search handler dynamically, and preserve native arguments, result and errors.
An outer native :lines selection happens before recursion into its selected
buffer, so excluded wrappers are never unnecessarily resolved. File reading,
recursive expansion and cycle detection remain Org responsibilities.

Unmarked ordinary buffers do not trigger normalization. Disabling the mode
removes hook/advice integration; failed setup leaves it disabled. The private
handler is not permanently added to global file-search hooks. Package-specific
depth limits and cycle-stack scaffolding have been removed after native cycle
behavior was tested.

## Reasons and non-goals

Org should own selection, levels, recursion, paths, links and footnotes. The
comparison showed viable transclusion features, but the adopted goal remains a
small export-only identity adapter with Org-roam DB authority. Replacing metadata
whitelists with explicit outline projection makes the high-level policy narrow
without redefining whole-file INCLUDE.

No editing preview, live transclusion, property inheritance, ID/CUSTOM_ID migration,
attachment repair, automatic DB synchronization or independent INCLUDE parser is
part of this contract. Mixed recursive native/ROAM INCLUDE is supported through
native expansion rather than a separate engine. Package-owned validation
infrastructure remains separate from Org-roam configuration validation.

## Package and regression-test boundary

The package remains a single Emacs Lisp library; the 0.1.0 header is release
preparation, not evidence of a published tag. README provides installation and
configuration using require plus the global minor mode. Testing is explicit and
separate from require or mode activation.

The standalone ERT file is tests/org-roam-include-test.el at this historical
boundary. Saved-source fixtures use make-temp-file with temporary-file-directory,
so tests do write temporary disk files. A temporary buffer
alone cannot represent native INCLUDE file-reading behavior faithfully.

Handwritten regexps use rx; internal constants centralize syntax spelling and
helper names reflect their keyword/mount/node/outline responsibilities. These
coding conventions support the package without adding user-facing configuration.
