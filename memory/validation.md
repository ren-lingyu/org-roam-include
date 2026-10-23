# Setup and recursive API evidence

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, recursive API
probes and setup-check tests following base-adapter integration. No project tests
were rerun during reconstruction; original experimental Git snapshots are not
unambiguously identified for this phase.

## Recorded API probes

The expander existed with optional included, dir, footnotes, includer-file and
expand-env arguments. Export preprocessing hooks and advice add/remove/query
interfaces existed. Native recursion re-entered the same function symbol.
A probe advice normalizing the current buffer before the original expander
successfully handled native INCLUDE containing ROAM_INCLUDE.

Buffer-local state did not automatically enter child buffers; dynamic recursive
state did. Unmarked ordinary buffers remained inert, and advice was removable.
These are evidence for the integration approach, not proof of the complete
recursive package or its headline locations.

## Recorded setup tests

The setup report combined variable and capability checks, included the native
expander requirement and was exposed by the public diagnostic command. Simulated
missing capabilities produced a failed report; enabling the mode kept it off and
used display-warning without raising an error. The recorded test completion
reported no tracked working-tree changes.

## Inherited limits

Base compiler tests covered raw arguments, affiliated keywords, literal contexts,
mount replacement, COMMENT and narrowing. They did not demonstrate end-to-end
native expansion of FILE::LINE. The historical org-transclusion comparison
informed scope rather than a replacement decision. Main squash integration does
not retroactively identify the original dev experiment snapshots.

Next test mixed recursion, property mounts, outer :lines selection and headline
cycles before introducing package-specific depth or cycle machinery.
