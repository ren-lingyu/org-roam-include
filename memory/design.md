# Current design and maintenance rationale

## Identity and base keyword

Use #+ROAM_INCLUDE: NODE-ID RAW-TAIL. Interpret only the first non-whitespace
token as an Org-roam ID; do not impose a UUID format. Preserve the remaining
single-line text, including its leading whitespace, as native INCLUDE arguments.
Do not parse :lines, :only-contents, :minlevel, src or other native parameters.

Resolve file, level and point through Org-roam's database. Read saved source
files; unsaved visiting buffers are not authoritative. Validate readable files,
bounds and structural headline alignment. This is structural validation, not a
complete stale-database detector: a stale point landing on another valid headline
need not be rejected. Do not search by title or CUSTOM_ID, rescan IDs to repair
positions, or synchronize the database during export.

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
Check package-owned variables only; the current validation list is empty because
there are no behavior-changing user options. Missing runtime interfaces produce
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

The package remains a single Emacs Lisp library at lisp/org-roam-include.el; the 0.1.0 header is release
preparation, not evidence of a published tag. README provides installation and
configuration using require plus the global minor mode. Testing is explicit and
separate from require or mode activation.

The maintained ERT file is tests/ert/ert.el. Saved-source fixtures use make-temp-file
with temporary-file-directory, so tests do write temporary disk files. A temporary
buffer alone cannot represent native INCLUDE file-reading behavior faithfully.

Handwritten regexps use rx; internal constants centralize syntax spelling and
helper names reflect their keyword/mount/node/outline responsibilities. These
coding conventions support the package without adding user-facing configuration.

## Nix testing architecture

flake.nix calls personal-nixpkgs.lib.mkFlake with inputs.nixpkgs, moduleLocation,
llib, lpkgs, and specialArgs.src following the org-texmacs reference. src is a
fileset.toSource directory rooted at lisp/. Keep a source directory, not a list
of files: both the package builder and package-lint need directory semantics.

pkgs/default.nix discovers overlay.nix through llib.packages.mkOverlays. The
emacsPackages/org-roam-include overlay uses melpaBuild with explicit version and
melpaVersion 0.1.0, Org/Org-roam requirements, and compilation warnings as errors.
The Emacs wrapper overlay selects Emacs 31. packages.default and the named package
use emacsPackagesFor emacs31 too, so builds, ERT, lint and development agree.
Package-lint is added only to the lint check's Emacs, not the development wrapper.
legacyPackages and overlays are exposed through the shared mkFlake integration.

tests/default.nix uses llib.tests.mkChecks to discover test-overlay.nix and supplies
src, emacs, Guile/build primitives and the Emacs 31 package set. Each check overlay
calls its adjacent test.nix; Nix definitions may use paths within tests but do not
reach into the parent tree. ERT remains tests/ert/ert.el and requires real org-roam
and the installed org-roam-include, stubbing only node lookup for fixture records.
Lint enumerates only the filtered source tree. Both checks retain the Guile runners
below. No tests run when requiring the library or enabling the mode.

README documents the lisp/ load path and package/check layout. Its Emacs minimum
now matches Package-Requires (30.1), while explicitly describing the Nix environment
as Emacs 31. This wording does not establish a new compatibility test matrix.
The shared treefmt integration is enabled through the committed flakeCheck = true
gate, after a separate pure-formatting commit. The obsolete *.patch exclusion was
removed in an independent user commit. The later alignment starts from the
reviewed user-supplied dependency updates; no additional lockfile refresh is
planned.

## Symbol documentation convention

The user maintains both this package and org-roam-organize and requested a shared
style that allows design context to be recovered from symbols themselves.
Begin with a concise Emacs-style behavior summary, then explain parameter and
return contracts, relevant side effects and errors. Use uppercase parameter names
and Emacs symbol quoting in docstrings. Scale detail to responsibility rather
than requiring every simple accessor to contain every possible section.

For complex symbols, Implementation notes: describes collaboration and boundaries;
Rationale: explains why that responsibility or approach exists. Especially preserve
the division between DB position authority, native INCLUDE semantics, export-only
normalization and replacement mounts. Do not embed temporary progress or commit
narration in source documentation.

The local untracked DOCSTRING.md described this convention but is not a required
input for future work. Documentation-only editing can still break Lisp syntax:
function docstrings precede executable bodies, while a constant/variable
docstring may be the final form argument. Static whitespace checks do not prove
that those forms remain syntactically or semantically correct.

## Generated Guile runners

Both check definitions generate executable runners with pkgs.replaceVarsWith from
adjacent run.scm files. The user explicitly prefers .scm without an .in suffix.
Scheme was chosen because the maintainer finds shell list construction and quoting
hard to read; reducing interpreter closure size was not worth that maintenance
cost. Keep Guile within checks rather than adding it to the library runtime.

Inject interpreter and Emacs executables plus context-bearing strings for source
or test inputs. The historical missing-source failure was corrected with
testFile = "${./ert.el}" and source = "${source}" in replacements, without
redundant top-level input attributes. Do not replace fileset.toSource with toList:
the built package and lint load-path still need a source directory.

Runners disable Guile automatic compilation, prepare HOME below the build TMPDIR
before starting Emacs, and use system* with explicit argument lists. ERT invokes
quick/batch Emacs with ert.el and ert-run-tests-batch-and-exit; lint recursively
collects .el files, requires a nonempty list and invokes package-lint. Nonzero
child status fails the runner; successful completion creates the derivation output.
The current implementation normalizes a nonzero child status to exit 1 rather
than preserving the exact child exit number. Nix owns dependencies and static
substitution; runtime environment setup belongs to the runner.

## Cross-project boundary

The supplementary handoff supports preserving stable note identity and independent
source notes as motivations. Shared Org-roam concepts do not establish a runtime
dependency on org-roam-organize or a decision to merge packages. Keep this package
focused on export composition. The other project's note-type policy, removed
moving APIs and future work belong to its own memory; do not create local tasks
from that material.
