# Comparison evidence and target limits

Source: archived session 019f8056-9275-7e43-8fa2-651004902291, clean-load
experiments and org-transclusion capability comparison. No experiments were
rerun during memory reconstruction; precise original Git snapshots are unknown.

The recorded clean Emacs loading attempts initially failed because manually
assembled load-paths omitted transitive dependencies. Loading dependencies via
straight bootstrap and straight-use-package subsequently succeeded. This validates
that historical dependency-loading route, not every export path in the prototype.

## Observations in the tested org-transclusion environment

- :only-contents with :level removed more heading structure than the requested
  mount semantics; :no-first-heading with automatic :level was closer.
- Default property filtering removed source-root drawer/CUSTOM_ID while retaining
  the local CUSTOM_ID in the tested case.
- File-node exclusion of keyword and property-drawer elements removed document
  metadata while preserving affiliated NAME/CAPTION keywords in the examples.
- :expand-links resolved relative file links against the source directory.
- A narrowed add-all invocation avoided invalid IDs outside the restriction.

The assistant recommended further evaluation of an org-transclusion wrapper.
The user instead adopted the narrower independent adapter contract. Do not
confuse that recommendation with an adopted replacement decision.

## What remains unproven

The comparison did not establish complete LaTeX/batch-export equivalence, all
COMMENT behavior or every descendant-property filtering boundary. It did not
prove the proposed adapter's FILE::LINE search syntax. Earlier prototype checks
were static. Implement and test the base/mount compiler, literal contexts,
affiliated keywords and restriction handling before claiming those contracts.
