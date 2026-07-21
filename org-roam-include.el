;;; org-roam-include.el --- Include Org-roam nodes during Org export -*- lexical-binding: t; -*-

;; Copyright (C) 2026 aRenCoco

;; Author: aRenCoco
;; Maintainer: aRenCoco
;; Version: 0.0.1
;; Package-Requires: ((emacs "31.0") (org "9.7") (org-roam "2.0.0"))
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
;; the database point and the saved source file.  Native INCLUDE arguments are
;; not interpreted by this package.  Properties on the mounting headline are
;; preserved except for the controlling include property itself.
;;
;; The package normalizes Org-roam include forms immediately before each
;; invocation of Org's native INCLUDE expander.  A lightweight export hook marks
;; export working buffers, while a thin around advice ensures that
;; normalization is repeated in recursive INCLUDE buffers.  File reading,
;; INCLUDE argument handling, recursive expansion, and cycle detection remain
;; the responsibility of Org's native exporter.

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
  "Include Org-roam node contents during Org export."
  :group 'org-roam)

;; ==============================
;; 常量定义
;; ==============================

(defconst org-roam-include--variable-type-alist
  nil
  "Variables and expected types checked by `org-roam-include--check-variables'.")

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
`org-roam-include--check-capabilities'.")

(defconst org-roam-include--property-name
  "ROAM_INCLUDE"
  "Org property name used for headline mount declarations.")

(defconst org-roam-include--keyword-name
  "ROAM_INCLUDE"
  "Org keyword name used for base include wrappers.")

(defconst org-roam-include--property-drawer-begin-regexp
  (rx line-start
      (* (any " \t"))
      ":PROPERTIES:"
      (* (any " \t"))
      line-end)
  "Regexp matching the beginning line of an Org property drawer.")

(defconst org-roam-include--property-drawer-end-regexp
  (rx line-start
      (* (any " \t"))
      ":END:"
      (* (any " \t"))
      line-end)
  "Regexp matching the end line of an Org property drawer.")

(defconst org-roam-include--keyword-line-regexp
  (rx line-start
      (group (* (any " \t")))
      "#+"
      (group (+ (not (any ":\n"))))
      ":"
      (group (* nonl))
      line-end)
  "Regexp matching an Org keyword line.")

(defconst org-roam-include--node-id-and-tail-regexp
  (rx string-start
      (* (any " \t"))
      (group (+ (not (any " \t\n\r"))))
      (group (* anything))
      string-end)
  "Regexp matching an Org-roam include node ID and raw INCLUDE tail.")

(defconst org-roam-include--unquotable-location-regexp
  (rx (any "\"\n\r"))
  "Regexp matching characters unsupported in generated INCLUDE locations.")

(defconst org-roam-include--line-search-prefix
  "org-roam-include-line:"
  "Prefix used for internal headline line search locations.")

(defconst org-roam-include--line-search-regexp
  (rx string-start
      "org-roam-include-line:"
      (group (+ digit))
      string-end)
  "Regexp matching an internal Org-roam Include line location.")

;; ==============================
;; 内部变量
;; ==============================

(defvar-local org-roam-include--export-buffer-p nil
  "Non-nil when the current buffer is an Org export working copy.")

(defvar org-roam-include--within-native-expansion nil
  "Non-nil while recursively expanding native Org INCLUDE keywords.")

;; ==============================
;; 内部函数
;; ==============================

(defun org-roam-include--keyword-prefix ()
  "Return the Org keyword prefix used by Org-roam Include."
  (format "#+%s:" org-roam-include--keyword-name))

(defun org-roam-include--keyword-name-p (key)
  "Return non-nil when KEY names an Org-roam include keyword."
  (and (stringp key)
       (string= (upcase key)
                (upcase org-roam-include--keyword-name))))

(defun org-roam-include--warning (message)
  "Display Org-roam Include warning MESSAGE without signaling an error."
  (if (fboundp 'display-warning)
      (display-warning 'org-roam-include message :warning)
    (message "%s" message)))

(defun org-roam-include--check-variables (alist)
  "Check Org-roam Include variables in ALIST.

ALIST should map variable symbols to expected type symbols.  This
function follows the diagnostic style of `org-roam-organize--check-variables'
and returns a cons cell whose car is the boolean result and whose cdr is a
human-readable report."
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

ALIST should map capability symbols to expected capability type symbols.
Return a cons cell whose car is the boolean result and whose cdr is a
human-readable report.  This check is capability-based rather than
version-based so that package startup depends on the interfaces actually
available in the running Emacs."
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
human-readable report."
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
replacement mount."
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
  "Return non-nil when the current headline has a mounted ancestor."
  (save-excursion
    (catch 'mounted
      (while (org-up-heading-safe)
        (when (org-entry-get nil org-roam-include--property-name)
          (throw 'mounted t)))
      nil)))

(defun org-roam-include--org-in-commented-heading-p ()
  "Return non-nil when point is in a COMMENT subtree."
  (and (not (condition-case nil
                (org-before-first-heading-p)
              (error nil)))
       (org-in-commented-heading-p)))

(defun org-roam-include--org-subtree-end ()
  "Return the end position of the current subtree."
  (save-excursion
    (org-back-to-heading t)
    (org-end-of-subtree t t)
    (point)))

(defun org-roam-include--org-skip-property-drawer (&optional bound)
  "Move point past the property drawer at point.

When BOUND is non-nil, do not search past it."
  (when (looking-at-p org-roam-include--property-drawer-begin-regexp)
    (unless (re-search-forward
             org-roam-include--property-drawer-end-regexp
             bound
             t)
      (user-error "Property drawer has no END line"))
    (forward-line 1)))

(defun org-roam-include--org-skip-node-metadata ()
  "Move point past immediate planning lines and property drawer."
  (if (fboundp 'org-end-of-meta-data)
      (org-end-of-meta-data 'standard)
    (while (and (boundp 'org-planning-line-re)
                (looking-at-p org-planning-line-re))
      (forward-line 1))
    (org-roam-include--org-skip-property-drawer)))

(defun org-roam-include--org-headline-body-begin ()
  "Return the body beginning position of the current headline."
  (save-excursion
    (org-back-to-heading t)
    (org-roam-include--org-skip-node-metadata)
    (point)))

(defun org-roam-include--include-line-number-at-pos (pos)
  "Return the 1-based line number at POS."
  (line-number-at-pos pos t))

(defun org-roam-include--keyword-positions ()
  "Return Org-roam include keyword positions from bottom to top."
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
  "Return the beginning position of the first Org headline."
  (org-element-map (org-element-parse-buffer)
      'headline
    (lambda (headline)
      (org-element-property :begin headline))
    nil
    t))

(defun org-roam-include--execute-line-search (search)
  "Handle internal Org-roam Include line SEARCH.

Return non-nil when SEARCH uses the private Org-roam Include line syntax.
Leave point at the corresponding headline."
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

The returned plist has keys :file, :point, :level, and :id."
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
  "Run THUNK in a temporary Org buffer for LOCATION."
  (let ((file (plist-get location :file)))
    (with-temp-buffer
      (insert-file-contents file)
      (let ((org-inhibit-startup t))
        (delay-mode-hooks (org-mode)))
      (funcall thunk))))

(defun org-roam-include--node-location (node)
  "Return NODE as resolver data with a native Org INCLUDE location."
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
  "Resolve ID to Org-roam node data and a native INCLUDE location."
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
content in its saved source file."
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
  "Quote LOCATION for use in an Org INCLUDE keyword."
  (when (string-match-p
         org-roam-include--unquotable-location-regexp
         location)
    (user-error "Location cannot be represented in an Org INCLUDE: %s"
                location))
  (format "\"%s\"" location))

(defun org-roam-include--include-format-native (location raw_tail)
  "Format native INCLUDE using LOCATION and RAW_TAIL.

RAW_TAIL is inserted unchanged and should include its own leading
whitespace when non-empty."
  (format "#+INCLUDE: %s%s"
          (org-roam-include--include-quote-location location)
          raw_tail))

(defun org-roam-include--keyword-parse-value (value)
  "Parse Org-roam include keyword VALUE as a cons cell (ID . RAW-TAIL)."
  (unless (string-match org-roam-include--node-id-and-tail-regexp value)
    (user-error "%s node ID is empty"
                org-roam-include--keyword-name))
  (cons (match-string-no-properties 1 value)
        (match-string-no-properties 2 value)))

(defun org-roam-include--keyword-parse-line ()
  "Parse the Org-roam include keyword line at point.

Return a plist with keys :begin, :end, :indentation, :key, and :value."
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
  "Compile the Org-roam include keyword at point to a native INCLUDE keyword."
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
  "Return the mounted Org-roam node ID at point."
  (string-trim
   (or (org-entry-get (point) org-roam-include--property-name)
       "")))

(defun org-roam-include--keyword-format-base (id raw_tail)
  "Format a base Org-roam include keyword from ID and RAW_TAIL."
  (format "%s %s%s"
          (org-roam-include--keyword-prefix)
          id
          raw_tail))

(defun org-roam-include--mount-replace-body (content)
  "Replace the current headline body with CONTENT."
  (let ((body_begin (org-roam-include--org-headline-body-begin))
        (body_end (org-roam-include--org-subtree-end)))
    (delete-region body_begin body_end)
    (goto-char body_begin)
    (unless (string-empty-p content)
      (insert "\n" content "\n"))))

(defun org-roam-include--mount-compile-at-point ()
  "Compile the mounted headline at point to a base Org-roam include keyword."
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
  "Compile all Org-roam include mounts in current buffer."
  (let ((mounts (org-roam-include--mount-collect)))
    (dolist (pos mounts)
      (goto-char pos)
      (when (org-at-heading-p)
        (org-roam-include--mount-compile-at-point)))))

(defun org-roam-include--keyword-compile-all ()
  "Compile all Org-roam include keywords in the current buffer."
  (save-excursion
    (dolist (pos (org-roam-include--keyword-positions))
      (goto-char pos)
      (unless (org-roam-include--org-in-commented-heading-p)
        (org-roam-include--keyword-compile-at-point)))))

(defun org-roam-include--mark-export-buffer (_backend)
  "Mark the current buffer as an Org export working copy."
  (setq org-roam-include--export-buffer-p t))

(defun org-roam-include--around-expand-include-keyword
    (original_function &rest arguments)
  "Normalize Org-roam includes before native INCLUDE expansion.

ORIGINAL_FUNCTION is `org-export-expand-include-keyword'.  ARGUMENTS
are passed to ORIGINAL_FUNCTION unchanged."
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
validation."
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
performed by Org's native include expander."
  (org-roam-include--mount-compile-all)
  (org-roam-include--keyword-compile-all))

;; ==============================
;; Minor-Mode
;; ==============================

;; definition
;;;###autoload
(define-minor-mode org-roam-include-mode
  "Toggle recursive Org-roam include normalization during Org export.

The mode is global.  When enabled, Org export temporary buffers are
marked before parsing, and Org-roam include forms are normalized before each
invocation of Org's native INCLUDE expander."
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
