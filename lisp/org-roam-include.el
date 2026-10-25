;;; org-roam-include.el --- Include Org-roam nodes during Org export -*- lexical-binding: t; -*-

;; Copyright (C) 2026 aRenCoco

;; Author: aRenCoco
;; Maintainer: aRenCoco
;; Version: 0.1.0
;; Package-Requires: ((emacs "30.1") (org "9.7") (org-roam "2.0.0"))
;; Keywords: outlines, hypermedia
;; URL: https://github.com/ren-lingyu/org-roam-include
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-roam-include expands Org-roam node IDs into native Org INCLUDE
;; locations while exporting Org buffers.  The base public syntax is:
;;
;;   #+ROAM_INCLUDE: node-id :only-contents t
;;
;; which is compiled to a native include location and preserves the native
;; INCLUDE arguments after the node ID.  A higher-level file-node mount syntax
;; is also supported.  A headline such as:
;;
;;   ** Chapter
;;      :PROPERTIES:
;;      :ROAM_INCLUDE: node-id
;;      :END:
;;
;; is intended to keep the local headline as the exported document structure
;; while mounting the outline forest of the referenced file node below it.
;; Mounted headlines are replacement mount points: any local body and child
;; subtrees under the mounting headline are removed from the export copy before
;; the generated base include keyword is inserted.  The implementation should
;; run only in Org export temporary buffers and should not modify source files.
;;
;; Node locations are taken directly from the Org-roam database.  The package
;; does not rescan source files by ID to repair stale database entries.  When a
;; recorded position is inconsistent with the saved source file, expansion
;; fails and the Org-roam database must be synchronized.
;;
;; File nodes in the base syntax are compiled to whole-file INCLUDE locations.
;; Headline nodes are compiled to private line-search locations derived from
;; the database point and the saved source file.  The private search syntax is
;; resolved by a handler dynamically bound in `org-execute-file-search-functions'
;; while Org's native INCLUDE expander runs.  Native INCLUDE arguments are not
;; interpreted by this package.  Properties on the mounting headline are
;; preserved except for the controlling include property itself.
;;
;; The package normalizes Org-roam include forms immediately before each
;; invocation of Org's native INCLUDE expander.  A lightweight export hook marks
;; export working buffers, while a thin around advice carries recursive
;; expansion context into temporary INCLUDE buffers and normalizes them before
;; their own native INCLUDE expansion runs.  File reading, INCLUDE argument
;; handling, recursive expansion, and cycle detection remain the responsibility
;; of Org's native exporter.

;;; Code:

;; ==============================
;; 声明外部依赖
;; ==============================

(require 'org)
(require 'org-element)
(require 'ox)
(require 'org-roam)
(require 'rx)
(require 'subr-x)

;; ==============================
;; 用户变量定义
;; ==============================

;;;###autoload
(defgroup org-roam-include
  nil
  "Resolve Org-roam nodes into native Org includes during export.

Customize this group to control Org-roam Include behavior.  The package acts
only on Org export working buffers and leaves source Org files unchanged.

Rationale: Org-roam owns node identity while Org owns include expansion, so
this group covers only the adapter between those systems."
  :group 'org-roam)

;; ==============================
;; 常量定义
;; ==============================

(defconst org-roam-include--variable-type-alist
  nil
  "Variables and expected types checked before enabling the package.

Each entry has the form (VARIABLE . TYPE) understood by
`org-roam-include--check-variables'.  The list is currently empty because the
package exposes no behavior-changing user options.

Rationale: Keeping the validation input explicit lets future options join the
same setup report without coupling the validator to particular variables.")

(defconst org-roam-include--capability-alist
  '((org-export-before-processing-functions . variable)
    (org-export-expand-include-keyword . function)
    (org-execute-file-search-functions . variable)
    (advice-add . function)
    (advice-remove . function)
    (advice-member-p . function)
    (org-element-parse-buffer . function)
    (org-element-map . function)
    (org-map-entries . function)
    (org-entry-get . function)
    (org-entry-delete . function)
    (org-in-commented-heading-p . function))
  "Runtime capabilities required by Org-roam Include.

The list maps symbols to capability types checked by
`org-roam-include--check-capabilities'.

Rationale: Checking the interfaces used by the implementation is more precise
than inferring compatibility from package version numbers alone.")

(defconst org-roam-include--property-name
  "ROAM_INCLUDE"
  "Org property name used to declare headline replacement mounts.

The property value is an Org-roam node ID.  A mount preserves its local
headline and unrelated properties while replacing its body and descendants in
the export working copy.")

(defconst org-roam-include--keyword-name
  "ROAM_INCLUDE"
  "Org keyword name used for base Org-roam include declarations.

The keyword value begins with an Org-roam node ID followed by an uninterpreted
tail of native Org INCLUDE arguments.")

(defconst org-roam-include--property-drawer-begin-regexp
  (rx line-start
      (* (any " \t"))
      ":PROPERTIES:"
      (* (any " \t"))
      line-end)
  "Regexp matching an Org property drawer opening line.

This fallback parser is used only when the running Org lacks the preferred
metadata boundary helper.")

(defconst org-roam-include--property-drawer-end-regexp
  (rx line-start
      (* (any " \t"))
      ":END:"
      (* (any " \t"))
      line-end)
  "Regexp matching an Org property drawer closing line.

This pairs with `org-roam-include--property-drawer-begin-regexp' in the
compatibility fallback for locating headline body content.")

(defconst org-roam-include--keyword-line-regexp
  (rx line-start
      (group (* (any " \t")))
      "#+"
      (group (+ (not (any ":\n"))))
      ":"
      (group (* nonl))
      line-end)
  "Regexp matching one complete Org keyword line.

The groups capture indentation, keyword name, and raw value so compilation can
replace only that line while preserving its indentation.")

(defconst org-roam-include--node-id-and-tail-regexp
  (rx string-start
      (* (any " \t"))
      (group (+ (not (any " \t\n\r"))))
      (group (* anything))
      string-end)
  "Regexp separating an Org-roam node ID from its raw INCLUDE tail.

The first non-whitespace token is the node ID.  Everything after it is retained
verbatim so native INCLUDE argument semantics remain owned by Org.")

(defconst org-roam-include--unquotable-location-regexp
  (rx (any "\"\n\r"))
  "Regexp matching characters unsupported in generated INCLUDE locations.

Rationale: Generated locations are placed in quoted Org syntax.  Rejecting
ambiguous delimiters is safer than applying Elisp-style escaping to Org text.")

(defconst org-roam-include--line-search-prefix
  "org-roam-include-line:"
  "Prefix used for private headline line-search locations.

The prefix distinguishes package-generated line numbers from Org's public
file-search syntax.")

(defconst org-roam-include--line-search-regexp
  (rx string-start
      "org-roam-include-line:"
      (group (+ digit))
      string-end)
  "Regexp matching a complete private headline line-search value.

The captured decimal line number is interpreted by
`org-roam-include--execute-line-search' during native INCLUDE expansion.")

;; ==============================
;; 内部变量
;; ==============================

(defvar-local org-roam-include--export-buffer-p nil
  "Non-nil when the current buffer is an Org export working copy.

`org-roam-include--mark-export-buffer' sets this marker from Org's export hook.
It prevents interactive source buffers from being normalized by the advice.")

(defvar org-roam-include--within-native-expansion nil
  "Non-nil while recursively expanding native Org INCLUDE keywords.

The variable is dynamically bound by
`org-roam-include--around-expand-include-keyword' so temporary buffers created
by Org for nested includes inherit normalization context.

Rationale: Nested temporary buffers do not necessarily run the original export
hook, so recursion needs an explicit dynamic context.")

;; ==============================
;; 内部函数
;; ==============================

(defun org-roam-include--keyword-prefix ()
  "Return the textual prefix for a base Org-roam include keyword.

The returned string includes the #+ prefix and trailing colon.  Centralizing
this format keeps diagnostics and generated keyword text consistent."
  (format "#+%s:" org-roam-include--keyword-name))

(defun org-roam-include--keyword-name-p (key)
  "Return non-nil when KEY names an Org-roam include keyword.

KEY may use any letter case accepted by Org.  Non-string values return nil."
  (and (stringp key)
       (string= (upcase key)
                (upcase org-roam-include--keyword-name))))

(defun org-roam-include--warning (message)
  "Display Org-roam Include warning MESSAGE without signaling an error.

Use `display-warning' when available and fall back to `message' otherwise.
This helper is intended for setup failures that disable the mode cleanly."
  (if (fboundp 'display-warning)
      (display-warning 'org-roam-include message :warning)
    (message "%s" message)))

(defun org-roam-include--check-variables (alist)
  "Check Org-roam Include variables in ALIST.

ALIST maps variable symbols to expected type symbols.  Return a cons cell whose
car is non-nil when every entry is valid and whose cdr is a human-readable
report.  Supported types are `list', `string', `directory', `file', `boolean',
and positive `integer'.

Implementation notes: Each variable is read dynamically and checked against
the declared type while the same observations are appended to the report.
Malformed validation input produces a failed result instead of signaling.

Rationale: Setup diagnostics need to report all invalid options in one pass
rather than stop at the first failure.  The data-driven table also keeps
validation policy separate from mode activation."
  (if (listp alist)
      (let* ((result_bool t)
             (result_message
              (concat "All org-roam-include variables are as follow.\n"))
             (add_to_result_message_
              (lambda (var_name var_value var_expected_type)
                (setq result_message
                      (concat
                       result_message
                       (format "- %s? %s \n" var_name var_value)
                       (cond
                        ((or (and (eq var_value nil)
                                  (eq var_expected_type 'directory))
                             (and (eq var_value nil)
                                  (eq var_expected_type 'file)))
                         (format "  %s? %s (should be t)\n"
                                 var_expected_type nil))
                        ((eq var_expected_type 'directory)
                         (format "  %s? %s (should be t)\n"
                                 var_expected_type
                                 (and (stringp var_value)
                                      (file-directory-p var_value))))
                        ((eq var_expected_type 'file)
                         (format "  %s? %s (should be t)\n"
                                 var_expected_type
                                 (and (stringp var_value)
                                      (file-exists-p var_value))))
                        ((eq var_expected_type 'string)
                         (format "  %s? %s (should be t)\n"
                                 var_expected_type
                                 (and (stringp var_value)
                                      (not (string-empty-p var_value)))))
                        ((eq var_expected_type 'list)
                         (format "  %s? %s (should be t)\n"
                                 var_expected_type
                                 (listp var_value)))
                        ((eq var_expected_type 'boolean)
                         (format "  %s? %s (should be t)\n"
                                 var_expected_type
                                 (booleanp var_value)))
                        ((eq var_expected_type 'integer)
                         (format "  %s? %s (should be t)\n"
                                 var_expected_type
                                 (and (integerp var_value)
                                      (> var_value 0))))
                        (t
                         (format "  the type of variable is not acceptable\n"))))))))
        (dolist (pair alist)
          (let* ((var_name (car pair))
                 (var_value (when (boundp var_name) (symbol-value var_name)))
                 (var_expected_type (cdr pair))
                 (add_to_result_message_short_
                  (lambda ()
                    (funcall add_to_result_message_
                             var_name
                             var_value
                             var_expected_type))))
            (cond
             ((and (eq var_value nil)
                   (not (eq var_expected_type 'boolean)))
              (funcall add_to_result_message_short_)
              (setq result_bool nil))
             ((eq var_expected_type 'list)
              (funcall add_to_result_message_short_)
              (unless (listp var_value)
                (setq result_bool nil)))
             ((eq var_expected_type 'string)
              (funcall add_to_result_message_short_)
              (unless (and (stringp var_value)
                           (not (string-empty-p var_value)))
                (setq result_bool nil)))
             ((eq var_expected_type 'directory)
              (funcall add_to_result_message_short_)
              (unless (and
                       (stringp var_value)
                       (file-directory-p var_value))
                (setq result_bool nil)))
             ((eq var_expected_type 'file)
              (funcall add_to_result_message_short_)
              (unless (and
                       (stringp var_value)
                       (file-exists-p var_value))
                (setq result_bool nil)))
             ((eq var_expected_type 'boolean)
              (funcall add_to_result_message_short_)
              (unless (booleanp var_value)
                (setq result_bool nil)))
             ((eq var_expected_type 'integer)
              (funcall add_to_result_message_short_)
              (unless (and (integerp var_value)
                           (> var_value 0))
                (setq result_bool nil)))
             (t
              (funcall add_to_result_message_short_)
              (setq result_bool nil)))))
        (cons result_bool result_message))
    (cons nil "Inner Constant org-roam-include--variable-type-alist is NOT defined properly. ")))

(defun org-roam-include--check-capabilities (alist)
  "Check Org-roam Include runtime capabilities in ALIST.

ALIST maps symbols to either `function' or `variable'.  Return a cons cell
whose car is non-nil when every capability exists and whose cdr is a
human-readable report.  Malformed input yields a failed result.

Implementation notes: Functions are checked with `fboundp' and variables with
`boundp'.  Every result is recorded so callers can display one complete setup
report.

Rationale: Package startup should depend on the interfaces actually available
in the running Emacs and Org, not only on declared version numbers."
  (if (listp alist)
      (let ((result_bool t)
            (result_message
             "All org-roam-include runtime capabilities are as follow.\n"))
        (dolist (pair alist)
          (let* ((capability_name (car pair))
                 (capability_expected_type (cdr pair))
                 (capability_exists_p
                  (cond
                   ((eq capability_expected_type 'function)
                    (fboundp capability_name))
                   ((eq capability_expected_type 'variable)
                    (boundp capability_name))
                   (t
                    nil))))
            (setq result_message
                  (concat
                   result_message
                   (format "- %s? %s \n" capability_name capability_exists_p)
                   (format "  %s? %s (should be t)\n"
                           capability_expected_type
                           capability_exists_p)))
            (unless capability_exists_p
              (setq result_bool nil))))
        (cons result_bool result_message))
    (cons nil "Inner Constant org-roam-include--capability-alist is NOT defined properly. ")))

(defun org-roam-include--setup-check ()
  "Check whether Org-roam Include can be enabled.

Return a cons cell whose car is the boolean result and whose cdr is a
human-readable report covering variable and runtime capability validation.

Implementation notes: The two independent validators always run and their
reports are concatenated.  The combined result succeeds only when both pass.

Rationale: `org-roam-include-mode' needs one side-effect-free gate that can
also power the user-facing `org-roam-include-check-setup' command."
  (let ((variable_check_result
         (org-roam-include--check-variables
          org-roam-include--variable-type-alist))
        (capability_check_result
         (org-roam-include--check-capabilities
          org-roam-include--capability-alist)))
    (cons
     (and (car variable_check_result)
          (car capability_check_result))
     (concat
      (format "Variable validation result: %s\n"
              (if (car variable_check_result) "passed" "failed"))
      (cdr variable_check_result)
      (format "Runtime capability validation result: %s\n"
              (if (car capability_check_result) "passed" "failed"))
      (cdr capability_check_result)))))

(defun org-roam-include--mount-collect ()
  "Return positions of headlines with `org-roam-include--property-name'.

Positions are returned from bottom to top so buffer mutations do not
invalidate earlier positions.  The scan respects the current buffer
restriction, skips COMMENT subtrees, and ignores mounts inside another
replacement mount.

Implementation notes: `org-map-entries' supplies real headline positions in
the accessible region.  Ancestor mounts are excluded because replacing an
outer mount deletes its original descendants.

Rationale: Collecting first and mutating later separates structural discovery
from edits and makes nested replacement semantics deterministic."
  (let (mounts)
    (org-map-entries
     (lambda ()
       (when (and (not (org-roam-include--org-in-commented-heading-p))
                  (org-entry-get nil org-roam-include--property-name)
                  (not (org-roam-include--mount-ancestor-p)))
         (push (point) mounts)))
     nil
     nil)
    (sort mounts #'>)))

(defun org-roam-include--mount-ancestor-p ()
  "Return non-nil when the current headline has a mounted ancestor.

Point must be at or within an Org headline.  The search walks parent headings
without changing the caller's point.

Rationale: A nested mount belongs to content that its nearest mounted ancestor
will replace, so compiling it separately would perform unnecessary resolution
and could surface errors for content that will be discarded."
  (save-excursion
    (catch 'mounted
      (while (org-up-heading-safe)
        (when (org-entry-get nil org-roam-include--property-name)
          (throw 'mounted t)))
      nil)))

(defun org-roam-include--org-in-commented-heading-p ()
  "Return non-nil when point is in a COMMENT subtree.

Text before the first headline returns nil.  Errors from Org's positional
helpers are treated conservatively as not commented.

Rationale: COMMENT subtrees are not exported, so their include declarations
must remain inert during normalization."
  (and (not (condition-case nil
                (org-before-first-heading-p)
              (error nil)))
       (org-in-commented-heading-p)))

(defun org-roam-include--org-subtree-end ()
  "Return the end position of the current Org subtree.

Point may be anywhere in the subtree and is preserved.  The returned position
includes invisible content and is suitable as a replacement boundary."
  (save-excursion
    (org-back-to-heading t)
    (org-end-of-subtree t t)
    (point)))

(defun org-roam-include--org-skip-property-drawer (&optional bound)
  "Move point past the property drawer at point.

When BOUND is non-nil, do not search past it.  Leave point unchanged when no
drawer begins at point, and signal `user-error' for an unterminated drawer.

Implementation notes: This is the compatibility path used when Org does not
provide the preferred metadata boundary helper."
  (when (looking-at-p org-roam-include--property-drawer-begin-regexp)
    (unless (re-search-forward
             org-roam-include--property-drawer-end-regexp
             bound
             t)
      (user-error "Property drawer has no END line"))
    (forward-line 1)))

(defun org-roam-include--org-skip-node-metadata ()
  "Move point past immediate planning lines and a property drawer.

Point should begin immediately after an Org headline.  Prefer
`org-end-of-meta-data' when available; otherwise use Org's planning regexp and
the local property-drawer parser.

Rationale: Mount replacement must preserve headline metadata while deleting
only body text and child subtrees across supported Org versions."
  (if (fboundp 'org-end-of-meta-data)
      (org-end-of-meta-data 'standard)
    (while (and (boundp 'org-planning-line-re)
                (looking-at-p org-planning-line-re))
      (forward-line 1))
    (org-roam-include--org-skip-property-drawer)))

(defun org-roam-include--org-headline-body-begin ()
  "Return the body beginning position of the current Org headline.

Point may be anywhere in the subtree and is preserved.  Planning lines and the
property drawer are excluded from the body boundary."
  (save-excursion
    (org-back-to-heading t)
    (org-roam-include--org-skip-node-metadata)
    (point)))

(defun org-roam-include--include-line-number-at-pos (pos)
  "Return the one-based line number at buffer position POS.

Absolute line numbers are required because generated headline locations are
later resolved in a fresh buffer containing the saved source file."
  (line-number-at-pos pos t))

(defun org-roam-include--keyword-positions ()
  "Return base Org-roam include keyword positions from bottom to top.

Only real Org keyword elements in the accessible buffer are returned, so
keyword-looking text inside literal blocks is ignored.

Implementation notes: Positions come from an Org Element parse tree and prefer
`:post-affiliated' so replacement starts at the keyword rather than attached
affiliated syntax.  Reverse order keeps positions stable while editing."
  (let ((ast (org-element-parse-buffer))
        positions)
    (org-element-map ast 'keyword
      (lambda (keyword)
        (when (org-roam-include--keyword-name-p
               (org-element-property :key keyword))
          (push (or (org-element-property :post-affiliated keyword)
                    (org-element-property :begin keyword))
                positions))))
    (sort positions #'>)))

(defun org-roam-include--outline-first-headline-begin ()
  "Return the beginning position of the first Org headline, or nil.

The search respects the current buffer restriction and uses Org Element
parsing rather than a textual star-prefix search."
  (org-element-map (org-element-parse-buffer)
      'headline
    (lambda (headline)
      (org-element-property :begin headline))
    nil
    t))

(defun org-roam-include--execute-line-search (search)
  "Handle internal Org-roam Include line SEARCH.

Return non-nil when SEARCH uses the private Org-roam Include line syntax.
Leave point at the corresponding headline.  Signal `user-error' when a
recognized line is invalid, outside the file, or not a headline.

Implementation notes: SEARCH is decoded with
`org-roam-include--line-search-regexp', then resolved from `point-min' using
one-based physical line numbering.

Rationale: Org's native file-search syntax does not provide the exact
database-point semantics needed for headline nodes.  A private handler lets
the native INCLUDE expander retain ownership of file loading and subtree
selection."
  (when (string-match org-roam-include--line-search-regexp search)
    (let ((line (string-to-number
                 (match-string-no-properties 1 search))))
      (when (< line 1)
        (user-error "Invalid Org-roam include line: %d" line))
      (goto-char (point-min))
      (unless (= (forward-line (1- line)) 0)
        (user-error "Org-roam include line is outside source file: %d" line))
      (unless (org-at-heading-p)
        (user-error "Org-roam include line is not at a headline: %d" line))
      t)))

(defun org-roam-include--node-location-data (node)
  "Return NODE location data from the Org-roam database.

The returned plist has keys `:file', `:point', `:level', and `:id'.  Signal
`user-error' when the saved file is unreadable or the recorded point and level
are structurally invalid.

Implementation notes: This function validates only data available without
opening the source file.  Buffer-relative bounds and headline alignment are
checked later by `org-roam-include--node-location'.

Rationale: Org-roam remains the authority for node identity and position; this
package validates that data but does not rescan files to repair it."
  (let ((file (org-roam-node-file node))
        (node_point (org-roam-node-point node))
        (node_level (org-roam-node-level node))
        (id (org-roam-node-id node)))
    (unless (and file (file-readable-p file))
      (user-error "Org-roam include source file is not readable: %s" file))
    (unless (and (integerp node_point)
                 (integerp node_level)
                 (>= node_level 0))
      (user-error
       "Org-roam database contains an invalid location for node ID %s"
       id))
    (list :file file
          :point node_point
          :level node_level
          :id id)))

(defun org-roam-include--source-with-buffer (location thunk)
  "Call THUNK in a temporary Org buffer for LOCATION.

LOCATION is a plist containing `:file'.  Insert the saved file contents,
activate `org-mode' without startup hooks, and return THUNK's value.

Rationale: Include semantics operate on saved source files, matching Org's
native exporter.  A temporary buffer avoids consulting or modifying an
existing visiting buffer with unsaved changes."
  (let ((file (plist-get location :file)))
    (with-temp-buffer
      (insert-file-contents file)
      (let ((org-inhibit-startup t))
        (delay-mode-hooks (org-mode)))
      (funcall thunk))))

(defun org-roam-include--node-location (node)
  "Return resolver data for NODE with a native Org INCLUDE location.

File nodes receive their expanded absolute file name as `:location'.  Headline
nodes receive a private line-search location plus `:line'.  The result retains
the validated `:file', `:point', `:level', and `:id' fields.

Signal `user-error' when the database point is outside the saved file or a
headline node does not point at a headline.

Implementation notes: The saved file is parsed in a temporary Org buffer.
Headline locations encode the database point as a physical line consumed by
`org-roam-include--execute-line-search'.

Rationale: Titles, custom IDs, and textual ID searches are either ambiguous or
land at a different structural position.  Validating the recorded Org-roam
point preserves database authority and reports stale data explicitly."
  (let* ((raw_location (org-roam-include--node-location-data node))
         (raw_file (plist-get raw_location :file))
         (expanded_file (expand-file-name raw_file))
         (location (plist-put raw_location :file expanded_file))
         (point (plist-get location :point))
         (level (plist-get location :level))
         (id (plist-get location :id)))
    (if (zerop level)
        (org-roam-include--source-with-buffer
         location
         (lambda ()
           (unless (<= (point-min) point (point-max))
             (user-error
              "Org-roam database position is outside file %s for node ID %s; run org-roam-db-sync"
              expanded_file
              id))
           (append location
                   (list :type 'file
                         :location expanded_file))))
      (org-roam-include--source-with-buffer
       location
       (lambda ()
         (unless (<= (point-min) point (point-max))
           (user-error
            "Org-roam database position is outside file %s for node ID %s; run org-roam-db-sync"
            expanded_file
            id))
         (goto-char point)
         (unless (org-at-heading-p)
           (user-error
            "Org-roam database position is not at a headline for node ID %s; run org-roam-db-sync"
            id))
         (let ((line (org-roam-include--include-line-number-at-pos point)))
           (append location
                   (list :type 'headline
                         :line line
                         :location
                         (format "%s::%s%d"
                                 expanded_file
                                 org-roam-include--line-search-prefix
                                 line)))))))))

(defun org-roam-include--node-resolve (id)
  "Resolve Org-roam node ID to native INCLUDE resolver data.

Signal `user-error' when ID is empty, no node exists, or its saved location is
invalid.  Return the plist produced by `org-roam-include--node-location'.

Rationale: Resolution deliberately uses `org-roam-node-from-id' without
triggering database synchronization or fallback file scans.  Export should
fail clearly when the user's Org-roam database is stale."
  (when (string-empty-p id)
    (user-error "%s node ID is empty"
                org-roam-include--keyword-name))
  (let ((node (org-roam-node-from-id id)))
    (unless node
      (user-error "Cannot find Org-roam node for ID: %s" id))
    (org-roam-include--node-location node)))

(defun org-roam-include--outline-start-line (node)
  "Return the first headline line for file NODE.

Signal a user error when NODE is not a file node or has no headline
content in its saved source file.  Also reject database points outside the
saved file.

Implementation notes: The source is parsed in a temporary Org buffer and the
first headline position is converted to a one-based physical line.

Rationale: A file-node mount projects the file's outline forest rather than
its file-level metadata and first section.  Headline-node mount semantics are
left undefined because preserving or removing the referenced headline are
both reasonable choices."
  (let* ((location (org-roam-include--node-location-data node))
         (file (plist-get location :file))
         (point (plist-get location :point))
         (level (plist-get location :level))
         (id (plist-get location :id)))
    (unless (zerop level)
      (user-error
       "Headline-node mounts are not defined yet for ID %s; use %s explicitly"
       id
       (org-roam-include--keyword-prefix)))
    (org-roam-include--source-with-buffer
     location
     (lambda ()
       (unless (<= (point-min) point (point-max))
         (user-error
          "Org-roam database position is outside file %s for node ID %s; run org-roam-db-sync"
          file
          id))
       (goto-char (point-min))
       (let ((headline_begin
              (org-roam-include--outline-first-headline-begin)))
         (unless headline_begin
           (user-error "Org-roam file node has no headline content: %s" id))
         (org-roam-include--include-line-number-at-pos headline_begin))))))

(defun org-roam-include--include-quote-location (location)
  "Return LOCATION quoted for use in an Org INCLUDE keyword.

Signal `user-error' when LOCATION contains a quote or line break that cannot
be represented by the generated syntax.

Rationale: LOCATION is Org source text, not an Elisp string.  Rejecting
unsupported characters avoids applying an escaping model that Org may
interpret differently."
  (when (string-match-p
         org-roam-include--unquotable-location-regexp
         location)
    (user-error "Location cannot be represented in an Org INCLUDE: %s"
                location))
  (format "\"%s\"" location))

(defun org-roam-include--include-format-native (location raw_tail)
  "Format native INCLUDE using LOCATION and RAW_TAIL.

RAW_TAIL is inserted unchanged and should include its own leading
whitespace when non-empty.  Return one native #+INCLUDE: line without a
trailing newline.

Rationale: Org owns the syntax and behavior of native INCLUDE arguments.
Preserving RAW_TAIL prevents this package from becoming a second INCLUDE
parser."
  (format "#+INCLUDE: %s%s"
          (org-roam-include--include-quote-location location)
          raw_tail))

(defun org-roam-include--keyword-parse-value (value)
  "Parse Org-roam include keyword VALUE as (ID . RAW-TAIL).

ID is the first non-whitespace token and RAW-TAIL contains all remaining text
unchanged.  Signal `user-error' when VALUE has no node ID.

Rationale: Only node resolution belongs to Org-roam Include; native argument
tokenization remains Org's responsibility."
  (unless (string-match org-roam-include--node-id-and-tail-regexp value)
    (user-error "%s node ID is empty"
                org-roam-include--keyword-name))
  (cons (match-string-no-properties 1 value)
        (match-string-no-properties 2 value)))

(defun org-roam-include--keyword-parse-line ()
  "Parse the Org-roam include keyword line at point.

Return a plist with keys `:begin', `:end', `:indentation', `:key', and
`:value'.  Signal `user-error' when the current line is not the configured
Org-roam include keyword.

Implementation notes: Parsing is limited to one physical line selected earlier
through Org Element, while the regexp retains exact indentation and value
text for replacement."
  (let* ((line_begin (line-beginning-position))
         (line_end (line-end-position))
         (line (buffer-substring-no-properties line_begin line_end)))
    (unless (string-match org-roam-include--keyword-line-regexp line)
      (user-error "Point is not at a %s keyword"
                  (org-roam-include--keyword-prefix)))
    (unless (org-roam-include--keyword-name-p
             (match-string-no-properties 2 line))
      (user-error "Point is not at a %s keyword"
                  (org-roam-include--keyword-prefix)))
    (list :begin line_begin
          :end line_end
          :indentation (match-string-no-properties 1 line)
          :key (match-string-no-properties 2 line)
          :value (match-string-no-properties 3 line))))

(defun org-roam-include--keyword-compile-at-point ()
  "Compile the Org-roam include keyword at point to native INCLUDE syntax.

Replace only the current keyword line, preserving its indentation and raw
native argument tail.  Node lookup and location validation errors are allowed
to propagate as user-facing export failures.

Implementation notes: The line parser, value parser, node resolver, and native
formatter form separate stages so each syntax boundary has one owner.

Rationale: Producing ordinary #+INCLUDE: text lets Org handle file reading,
argument semantics, recursion, and cycle detection."
  (let* ((line_data (org-roam-include--keyword-parse-line))
         (line_begin (plist-get line_data :begin))
         (line_end (plist-get line_data :end))
         (indentation (plist-get line_data :indentation))
         (value (plist-get line_data :value))
         (parsed (org-roam-include--keyword-parse-value value))
         (id (car parsed))
         (raw_tail (cdr parsed))
         (resolved (org-roam-include--node-resolve id))
         (native_include
          (org-roam-include--include-format-native
           (plist-get resolved :location)
           raw_tail)))
    (delete-region line_begin line_end)
    (goto-char line_begin)
    (insert indentation native_include)))

(defun org-roam-include--mount-id-at-point ()
  "Return the mounted Org-roam node ID at point.

Read `org-roam-include--property-name' from the current headline and trim
surrounding whitespace.  Return the empty string when the property is absent.

Rationale: Returning a string gives the mount compiler one explicit empty-ID
error path for missing and blank property values."
  (string-trim
   (or (org-entry-get (point) org-roam-include--property-name)
       "")))

(defun org-roam-include--keyword-format-base (id raw_tail)
  "Return a base Org-roam include keyword for ID and RAW_TAIL.

RAW_TAIL is inserted unchanged and must carry its own leading whitespace.
The result has no trailing newline.

Rationale: Mount compilation emits the same public base syntax accepted from
users, allowing one later keyword compiler to own node resolution."
  (format "%s %s%s"
          (org-roam-include--keyword-prefix)
          id
          raw_tail))

(defun org-roam-include--mount-replace-body (content)
  "Replace the current headline body and descendants with CONTENT.

Preserve the headline, planning data, and property drawer.  Delete everything
from the body boundary through the subtree end, then insert CONTENT as the new
body when it is non-empty.

Rationale: A mount is a replacement point, not an append operation.  Removing
local body and children prevents stale local content from being exported
alongside the mounted outline."
  (let ((body_begin (org-roam-include--org-headline-body-begin))
        (body_end (org-roam-include--org-subtree-end)))
    (delete-region body_begin body_end)
    (goto-char body_begin)
    (unless (string-empty-p content)
      (insert "\n" content "\n"))))

(defun org-roam-include--mount-compile-at-point ()
  "Compile the mounted headline at point to a base include keyword.

The current headline must have a non-empty mount property naming an existing
file node.  Remove only the controlling property, preserve other metadata, and
replace the local body and descendants with a base Org-roam include restricted
to the referenced file's outline.

Signal `user-error' for empty or missing node IDs, stale locations, file nodes
without headlines, and headline-node mounts.

Implementation notes: The outline start line becomes a native `:lines'
argument on the generated base keyword.  Actual node-to-location resolution is
deferred to the keyword compiler.

Rationale: Keeping the local headline supplies document structure, while the
file-node outline supplies mounted content.  Compiling through base syntax
avoids a second native INCLUDE generation path."
  (org-back-to-heading t)
  (let ((id (org-roam-include--mount-id-at-point)))
    (when (string-empty-p id)
      (user-error "%s property is empty at headline: %s"
                  org-roam-include--property-name
                  (org-get-heading t t t t)))
    (let* ((node (org-roam-node-from-id id))
           (_ (unless node
                (user-error
                 "Cannot find Org-roam node for ID: %s"
                 id)))
           (outline_start_line
            (org-roam-include--outline-start-line node))
           (roam_include
            (org-roam-include--keyword-format-base
             id
             (format " :lines \"%d-\"" outline_start_line))))
      (org-entry-delete (point) org-roam-include--property-name)
      (org-roam-include--mount-replace-body roam_include))))

(defun org-roam-include--mount-compile-all ()
  "Compile all Org-roam include mounts in the current buffer.

The operation respects narrowing and COMMENT subtrees.  Mounts are processed
from bottom to top using positions collected before mutation.

Implementation notes: Rechecking `org-at-heading-p' protects against structural
changes made by a previously processed outer region.

Rationale: Mount compilation must precede keyword compilation so discarded
local content cannot trigger node resolution or export errors."
  (let ((mounts (org-roam-include--mount-collect)))
    (dolist (pos mounts)
      (goto-char pos)
      (when (org-at-heading-p)
        (org-roam-include--mount-compile-at-point)))))

(defun org-roam-include--keyword-compile-all ()
  "Compile all base Org-roam include keywords in the current buffer.

The operation respects narrowing, ignores COMMENT subtrees, and does not
modify keyword-looking text inside literal Org elements.

Implementation notes: Positions are obtained from one Org Element parse and
processed from bottom to top to remain valid during line replacement."
  (save-excursion
    (dolist (pos (org-roam-include--keyword-positions))
      (goto-char pos)
      (unless (org-roam-include--org-in-commented-heading-p)
        (org-roam-include--keyword-compile-at-point)))))

(defun org-roam-include--mark-export-buffer (_backend)
  "Mark the current buffer as an Org export working copy.

_BACKEND is the backend argument supplied by
`org-export-before-processing-functions' and is intentionally ignored.

Rationale: The marker confines automatic normalization to export copies while
leaving source and ordinary interactive buffers unchanged."
  (setq org-roam-include--export-buffer-p t))

(defun org-roam-include--around-expand-include-keyword
    (original_function &rest arguments)
  "Normalize Org-roam includes before native INCLUDE expansion.

ORIGINAL_FUNCTION is `org-export-expand-include-keyword'.  ARGUMENTS
are passed to ORIGINAL_FUNCTION unchanged.  Normalize only marked export
buffers or buffers reached recursively from an active native expansion.

Implementation notes: Dynamically bind
`org-roam-include--within-native-expansion' for nested temporary buffers and
temporarily add `org-roam-include--execute-line-search' to
`org-execute-file-search-functions'.  Normalize the current buffer, then call
Org's original expander.

Rationale: Running immediately before every native expansion handles
Org-roam include forms inside recursively included files.  The thin advice
retains Org's ownership of file loading, native arguments, recursion, and
cycle detection."
  (if (or org-roam-include--export-buffer-p
          org-roam-include--within-native-expansion)
      (let ((org-roam-include--within-native-expansion t)
            (org-execute-file-search-functions
             (if (memq
                  #'org-roam-include--execute-line-search
                  org-execute-file-search-functions)
                 org-execute-file-search-functions
               (cons
                #'org-roam-include--execute-line-search
                org-execute-file-search-functions))))
        (save-excursion
          (org-roam-include-expand-buffer))
        (apply original_function arguments))
    (apply original_function arguments)))

;; ==============================
;; 可调用结构函数
;; ==============================

;;;###autoload
(defun org-roam-include-check-setup ()
  "Check whether Org-roam Include can be enabled.

This command reports both variable validation and runtime capability
validation in the echo area.  Invoke it when diagnosing why
`org-roam-include-mode' refuses to stay enabled.

Implementation notes: The command delegates to the same side-effect-free
`org-roam-include--setup-check' used during mode activation and adds a success
prefix when all checks pass.

Rationale: A user-facing diagnostic should report the exact gate used by the
mode rather than maintain a parallel compatibility test."
  (interactive)
  (let ((check_result (org-roam-include--setup-check)))
    (message "%s"
             (if (and (consp check_result)
                      (car check_result))
                 (concat
                  "Org-roam Include setup checks passed.\n"
                  (cdr check_result))
               (if (consp check_result)
                   (cdr check_result)
                 check_result)))))

(defun org-roam-include-expand-buffer ()
  "Normalize Org-roam include forms in the current Org buffer.

Compile file-node property mounts to base Org-roam include keywords, then
compile base Org-roam include keywords to native Org INCLUDE keywords.  This
function only normalizes the current buffer.  Recursive file expansion is
performed by Org's native include expander.

Call this function on an Org export working copy or another disposable buffer;
it destructively edits the current buffer and does not save any file.

Implementation notes: Mount compilation runs first because replacement mounts
delete their original bodies and descendants.  Keyword compilation then
resolves only declarations that remain in the resulting document.

Rationale: Exposing the normalization stage independently keeps transformation
logic testable while automatic recursion remains integrated at Org's native
expansion boundary."
  (org-roam-include--mount-compile-all)
  (org-roam-include--keyword-compile-all))

;; ==============================
;; Minor-Mode
;; ==============================

;; definition
;;;###autoload
(define-minor-mode org-roam-include-mode
  "Toggle recursive Org-roam include normalization during Org export.

The mode is global.  Enable it before exporting documents that contain
`ROAM_INCLUDE' keywords or properties.  Org export temporary buffers are
marked before parsing, and declarations are normalized before each invocation
of Org's native INCLUDE expander.  Disabling the mode removes both integration
points.

If setup validation fails, leave the mode disabled, remove any partial hook or
advice installation, and display the complete diagnostic report.  The mode
does not modify or save source Org files and does not synchronize the Org-roam
database.

Implementation notes: `org-export-before-processing-functions' marks the
initial export copy, while an around advice on
`org-export-expand-include-keyword' carries dynamic context into recursively
included temporary buffers.

Rationale: A global mode matches Org's global export integration points.
Deferring transformation until export preserves editing buffers, and advising
the native expansion boundary lets Org retain its established INCLUDE
semantics."
  :global t
  :group 'org-roam-include
  :lighter " ORI"
  (if org-roam-include-mode
      (let ((check_result (org-roam-include--setup-check)))
        (if (car check_result)
            (progn
              (add-hook 'org-export-before-processing-functions
                        #'org-roam-include--mark-export-buffer)
              (unless (advice-member-p
                       #'org-roam-include--around-expand-include-keyword
                       'org-export-expand-include-keyword)
                (advice-add
                 'org-export-expand-include-keyword
                 :around
                 #'org-roam-include--around-expand-include-keyword)))
          (setq org-roam-include-mode nil)
          (remove-hook 'org-export-before-processing-functions
                       #'org-roam-include--mark-export-buffer)
          (advice-remove
           'org-export-expand-include-keyword
           #'org-roam-include--around-expand-include-keyword)
          (org-roam-include--warning
           (concat
            "Org Roam Include Mode setup failed.\n"
            (cdr check_result)))))
    (remove-hook 'org-export-before-processing-functions
                 #'org-roam-include--mark-export-buffer)
    (advice-remove
     'org-export-expand-include-keyword
     #'org-roam-include--around-expand-include-keyword)))

(provide 'org-roam-include)

;;; org-roam-include.el ends here
