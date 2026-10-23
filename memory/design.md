# Prototype design

## Scope and integration

The source composition document uses a local headline with a ROAM_INCLUDE
property holding an Org-roam node ID. The local headline supplies title,
structure and ordering. Transform only Org's export working copy; preserve the
source document. The global org-roam-include-mode installs export preprocessing.
Variable validation concerns variables defined by this package, not Org-roam's
configuration.

Native INCLUDE should own file reading, selection, relative-link behavior,
footnotes and export integration. Directly copying subtree text was considered
simpler, but would require recreating path-sensitive native behavior. The first
implementation deliberately postpones recursive ROAM_INCLUDE support.

## Prototype at this boundary

- Resolve IDs through Org-roam's recorded file, point and level. Validate basic
  structure and readable saved files; do not rescan IDs or synchronize the DB.
- Headline sources currently generate FILE::LINE with :only-contents t. This is
  an unverified native-search assumption, not a demonstrated export contract.
- File sources currently use an open-ended :lines range after a file-level
  drawer and whitelisted document metadata. No explicit :minlevel is generated;
  induced heading level is delegated to Org and still needs validation.
- Replacement mounts retain the local heading and other properties while
  replacing local body and descendants. Nested mounts discarded by an outer
  replacement are not resolved first. Respect narrowing and COMMENT exclusion.
- Interpret saved source files, using logical expanded absolute paths rather
  than forcing symlink canonicalization.

## Reasons for earlier revisions

Title-based lookup weakened stable identity through duplicate or changed titles.
Explicit body line ranges avoided that ambiguity but grew custom projection
semantics and required an excluded end line. Rescanning actual ID properties was
briefly implemented, then removed to keep Org-roam's database authoritative.
The current prototype delegates headline selection back to Org instead.

Metadata filtering, node identity, native arguments and mount projection need
clearer boundaries before expansion of this design. Unused link-rewriting
configuration was removed rather than exposed as a reserved option. Handwritten
regular expressions use rx in accordance with the user's coding preference.
