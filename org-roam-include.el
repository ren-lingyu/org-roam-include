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

;; Org-roam-include expands Org headline properties that refer to Org-roam
;; node IDs into native Org INCLUDE keywords while exporting Org buffers.  A
;; headline such as:
;;
;;   ** Chapter
;;      :PROPERTIES:
;;      :ROAM_INCLUDE: node-id
;;      :END:
;;
;; is intended to keep the local headline as the exported document structure
;; while taking the body from the referenced Org-roam node.  Mounted headlines
;; are replacement mount points: any local body and child subtrees under the
;; mounting headline are removed from the export copy before the generated
;; INCLUDE keyword is inserted.  The implementation should run only in Org
;; export temporary buffers and should not modify source files.
;;
;; Node locations are taken directly from the Org-roam database.  The package
;; does not rescan source files by ID to repair stale database entries.  When a
;; recorded position is inconsistent with the saved source file, expansion
;; fails and the Org-roam database must be synchronized.
;;
;; Headline nodes are compiled to native Org INCLUDE keywords with a file search
;; location and `:only-contents t'.  Consequently, the source headline, planning
;; information, and root property drawer are excluded according to Org's native
;; INCLUDE behavior.  File-level nodes have no direct native `:only-contents'
;; equivalent.  Their mounted body starts after the leading file-level metadata
;; recognized by this package.  Properties on the mounting headline are
;; preserved except for the controlling ROAM_INCLUDE property itself.
;;
;; This package is currently experimental.  The first stable target is an
;; export-only preprocessor based on `org-export-before-processing-functions',
;; not an editing preview mode and not an advice around Org's include expander.

;;; Code:

;; ==============================
;; 声明外部依赖
;; ==============================

(require 'org)
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

(defcustom org-roam-include-property
  "ROAM_INCLUDE"
  "Org property name used to store the source Org-roam node ID."
  :type 'string
  :group 'org-roam-include)

(defcustom org-roam-include-max-depth
  64
  "Maximum recursive Org-roam include expansion depth.

This option is reserved for a later recursive implementation.  The
current expansion logic does not recursively compile included files."
  :type 'integer
  :safe (lambda (value)
          (and (integerp value)
               (> value 0)))
  :group 'org-roam-include)

;; ==============================
;; 常量定义
;; ==============================

(defconst org-roam-include--variable-type-alist
  '((org-roam-include-property . string)
    (org-roam-include-max-depth . integer))
  "Variables and expected types checked by `org-roam-include--check-variables'.")

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

(defconst org-roam-include--blank-line-regexp
  (rx line-start
      (* (any " \t"))
      line-end)
  "Regexp matching a blank line.")

(defconst org-roam-include--keyword-line-regexp
  (rx line-start
      (* (any " \t"))
      "#+"
      (group (+ (not (any ":\n"))))
      ":"
      (* nonl)
      line-end)
  "Regexp matching a leading Org keyword line.")

(defconst org-roam-include--file-metadata-keywords
  '("AUTHOR"
    "DATE"
    "DESCRIPTION"
    "FILETAGS"
    "LANGUAGE"
    "OPTIONS"
    "PROPERTY"
    "ROAM_ALIASES"
    "ROAM_REFS"
    "STARTUP"
    "TITLE")
  "Leading Org keywords treated as file-node metadata.")

(defconst org-roam-include--unquotable-location-regexp
  (rx (any "\"\n\r"))
  "Regexp matching characters unsupported in generated INCLUDE locations.")

;; ==============================
;; 内部变量
;; ==============================

(defvar org-roam-include--expansion-stack nil
  "Internal stack of Org-roam node IDs currently being expanded.

This variable is reserved for a later recursive implementation.")

;; ==============================
;; 内部函数
;; ==============================

(defun org-roam-include--check-variables (alist)
  "Check Org-roam Include variables in ALIST.

ALIST should map variable symbols to expected type symbols.  This
function follows the diagnostic style of `org-roam-organize--check-variables'
and returns a cons cell whose car is the boolean result and whose cdr is a
human-readable report."
  (if (listp alist)
      (let* ((result-bool t)
             (result-message
              (concat "All org-roam-include variables are as follow.\n"))
             (add-to-result-message
              (lambda (var-name var-value var-expected-type)
                (setq result-message
                      (concat
                       result-message
                       (format "- %s? %s \n" var-name var-value)
                       (cond
                        ((or (and (eq var-value nil)
                                  (eq var-expected-type 'directory))
                             (and (eq var-value nil)
                                  (eq var-expected-type 'file)))
                         (format "  %s? %s (should be t)\n"
                                 var-expected-type nil))
                        ((eq var-expected-type 'directory)
                         (format "  %s? %s (should be t)\n"
                                 var-expected-type
                                 (and (stringp var-value)
                                      (file-directory-p var-value))))
                        ((eq var-expected-type 'file)
                         (format "  %s? %s (should be t)\n"
                                 var-expected-type
                                 (and (stringp var-value)
                                      (file-exists-p var-value))))
                        ((eq var-expected-type 'string)
                         (format "  %s? %s (should be t)\n"
                                 var-expected-type
                                 (and (stringp var-value)
                                      (not (string-empty-p var-value)))))
                        ((eq var-expected-type 'list)
                         (format "  %s? %s (should be t)\n"
                                 var-expected-type
                                 (listp var-value)))
                        ((eq var-expected-type 'boolean)
                         (format "  %s? %s (should be t)\n"
                                 var-expected-type
                                 (booleanp var-value)))
                        ((eq var-expected-type 'integer)
                         (format "  %s? %s (should be t)\n"
                                 var-expected-type
                                 (and (integerp var-value)
                                      (> var-value 0))))
                        (t
                         (format "  the type of variable is not acceptable\n"))))))))
        (dolist (pair alist)
          (let* ((var-name (car pair))
                 (var-value (when (boundp var-name) (symbol-value var-name)))
                 (var-expected-type (cdr pair))
                 (add-to-result-message-short
                  (lambda ()
                    (funcall add-to-result-message
                             var-name
                             var-value
                             var-expected-type))))
            (cond
             ((and (eq var-value nil)
                   (not (eq var-expected-type 'boolean)))
              (funcall add-to-result-message-short)
              (setq result-bool nil))
             ((eq var-expected-type 'list)
              (funcall add-to-result-message-short)
              (unless (listp var-value)
                (setq result-bool nil)))
             ((eq var-expected-type 'string)
              (funcall add-to-result-message-short)
              (unless (and (stringp var-value)
                           (not (string-empty-p var-value)))
                (setq result-bool nil)))
             ((eq var-expected-type 'directory)
              (funcall add-to-result-message-short)
              (unless (and
                       (stringp var-value)
                       (file-directory-p var-value))
                (setq result-bool nil)))
             ((eq var-expected-type 'file)
              (funcall add-to-result-message-short)
              (unless (and
                       (stringp var-value)
                       (file-exists-p var-value))
                (setq result-bool nil)))
             ((eq var-expected-type 'boolean)
              (funcall add-to-result-message-short)
              (unless (booleanp var-value)
                (setq result-bool nil)))
             ((eq var-expected-type 'integer)
              (funcall add-to-result-message-short)
              (unless (and (integerp var-value)
                           (> var-value 0))
                (setq result-bool nil)))
             (t
              (funcall add-to-result-message-short)
              (setq result-bool nil)))))
        (cons result-bool result-message))
    (cons nil "Inner Constant org-roam-include--variable-type-alist is NOT defined properly. ")))

(defun org-roam-include--collect-mounts ()
  "Return positions of headlines with `org-roam-include-property'.

Positions are returned from bottom to top so buffer mutations do not
invalidate earlier positions.  The scan respects the current buffer
restriction, skips COMMENT subtrees, and ignores mounts inside another
replacement mount."
  (let (mounts)
    (org-map-entries
     (lambda ()
       (when (and (not (org-in-commented-heading-p))
                  (org-entry-get nil org-roam-include-property)
                  (not (org-roam-include--mounted-ancestor-p)))
         (push (point) mounts)))
     nil
     nil)
    (sort mounts #'>)))

(defun org-roam-include--mounted-ancestor-p ()
  "Return non-nil when the current headline has a mounted ancestor."
  (save-excursion
    (catch 'mounted
      (while (org-up-heading-safe)
        (when (org-entry-get nil org-roam-include-property)
          (throw 'mounted t)))
      nil)))

(defun org-roam-include--subtree-end ()
  "Return the end position of the current subtree."
  (save-excursion
    (org-back-to-heading t)
    (org-end-of-subtree t t)
    (point)))

(defun org-roam-include--next-heading-position ()
  "Return the position of the next heading, or `point-max'."
  (save-excursion
    (if (outline-next-heading)
        (point)
      (point-max))))

(defun org-roam-include--skip-property-drawer (&optional bound)
  "Move point past the property drawer at point.

When BOUND is non-nil, do not search past it."
  (when (looking-at-p org-roam-include--property-drawer-begin-regexp)
    (unless (re-search-forward
             org-roam-include--property-drawer-end-regexp
             bound
             t)
      (user-error "Property drawer has no END line"))
    (forward-line 1)))

(defun org-roam-include--skip-node-metadata ()
  "Move point past immediate planning lines and property drawer."
  (if (fboundp 'org-end-of-meta-data)
      (org-end-of-meta-data 'standard)
    (while (and (boundp 'org-planning-line-re)
                (looking-at-p org-planning-line-re))
      (forward-line 1))
    (org-roam-include--skip-property-drawer)))

(defun org-roam-include--headline-body-begin ()
  "Return the body beginning position of the current headline."
  (save-excursion
    (org-back-to-heading t)
    (org-roam-include--skip-node-metadata)
    (point)))

(defun org-roam-include--skip-file-metadata ()
  "Move point past leading file-level metadata."
  (let ((changed t))
    (while changed
      (setq changed nil)
      (while (looking-at-p org-roam-include--blank-line-regexp)
        (setq changed t)
        (forward-line 1))
      (when (looking-at-p org-roam-include--property-drawer-begin-regexp)
        (setq changed t)
        (org-roam-include--skip-property-drawer
         (org-roam-include--next-heading-position)))
      (while (looking-at-p org-roam-include--blank-line-regexp)
        (setq changed t)
        (forward-line 1))
      (while (and (looking-at org-roam-include--keyword-line-regexp)
                  (member (upcase (match-string-no-properties 1))
                          org-roam-include--file-metadata-keywords))
        (setq changed t)
        (forward-line 1)))))

(defun org-roam-include--line-number-at-pos (pos)
  "Return the 1-based line number at POS."
  (line-number-at-pos pos t))

(defun org-roam-include--file-node-body-start-line ()
  "Return the file node body start line in the current buffer."
  (goto-char (point-min))
  (org-roam-include--skip-file-metadata)
  (when (< (point) (point-max))
    (org-roam-include--line-number-at-pos (point))))

(defun org-roam-include--node-location-data (node)
  "Return NODE location data from the Org-roam database.

The returned plist has keys :file, :point, :level, and :id."
  (let ((file (org-roam-node-file node))
        (node-point (org-roam-node-point node))
        (node-level (org-roam-node-level node))
        (id (org-roam-node-id node)))
    (unless (and file (file-readable-p file))
      (user-error "Org-roam include source file is not readable: %s" file))
    (unless (and (integerp node-point)
                 (integerp node-level)
                 (>= node-level 0))
      (user-error
       "Org-roam database contains an invalid location for node ID %s"
       id))
    (list :file file
          :point node-point
          :level node-level
          :id id)))

(defun org-roam-include--source-buffer-for-location (location thunk)
  "Run THUNK in a temporary Org buffer for LOCATION."
  (let ((file (plist-get location :file)))
    (with-temp-buffer
      (insert-file-contents file)
      (let ((org-inhibit-startup t))
        (delay-mode-hooks (org-mode)))
      (funcall thunk))))

(defun org-roam-include--headline-node-location (node)
  "Return a native Org INCLUDE location for headline NODE."
  (let* ((location (org-roam-include--node-location-data node))
         (file (plist-get location :file))
         (point (plist-get location :point))
         (id (plist-get location :id)))
    (org-roam-include--source-buffer-for-location
     location
     (lambda ()
       (unless (<= (point-min) point (point-max))
         (user-error
          "Org-roam database position is outside file %s for node ID %s; run org-roam-db-sync"
          file
          id))
       (goto-char point)
       (unless (org-at-heading-p)
         (user-error
          "Org-roam database position is not at a headline for node ID %s; run org-roam-db-sync"
          id))
       (format "%s::%d"
               (expand-file-name file)
               (org-roam-include--line-number-at-pos point))))))

(defun org-roam-include--file-node-body-start (node)
  "Return file node body start data for NODE."
  (let* ((location (org-roam-include--node-location-data node))
         (file (plist-get location :file))
         (point (plist-get location :point))
         (id (plist-get location :id)))
    (org-roam-include--source-buffer-for-location
     location
     (lambda ()
       (unless (<= (point-min) point (point-max))
         (user-error
          "Org-roam database position is outside file %s for node ID %s; run org-roam-db-sync"
          file
          id))
       (let ((start-line (org-roam-include--file-node-body-start-line)))
         (when start-line
           (list :file (expand-file-name file)
                 :start start-line)))))))

(defun org-roam-include--quote-location (location)
  "Quote LOCATION for use in an Org INCLUDE keyword."
  (when (string-match-p
         org-roam-include--unquotable-location-regexp
         location)
    (user-error "Location cannot be represented in an Org INCLUDE: %s"
                location))
  (format "\"%s\"" location))

(defun org-roam-include--format-headline-include (node)
  "Return an Org INCLUDE keyword for headline NODE."
  (format "#+INCLUDE: %s :only-contents t"
          (org-roam-include--quote-location
           (org-roam-include--headline-node-location node))))

(defun org-roam-include--format-file-include (node)
  "Return an Org INCLUDE keyword for file NODE."
  (let ((body-start (org-roam-include--file-node-body-start node)))
    (when body-start
      (format "#+INCLUDE: %s :lines \"%d-\""
              (org-roam-include--quote-location
               (plist-get body-start :file))
              (plist-get body-start :start)))))

(defun org-roam-include--include-keyword (node)
  "Return an Org INCLUDE keyword for NODE, or nil for an empty body."
  (if (zerop (org-roam-node-level node))
      (org-roam-include--format-file-include node)
    (org-roam-include--format-headline-include node)))

(defun org-roam-include--mount-id-at-point ()
  "Return the mounted Org-roam node ID at point."
  (string-trim
   (or (org-entry-get (point) org-roam-include-property)
       "")))

(defun org-roam-include--replace-mount-body (content)
  "Replace the current headline body with CONTENT."
  (let ((body-begin (org-roam-include--headline-body-begin))
        (body-end (org-roam-include--subtree-end)))
    (delete-region body-begin body-end)
    (goto-char body-begin)
    (unless (string-empty-p content)
      (insert "\n" content "\n"))))

(defun org-roam-include--compile-one-at-point ()
  "Compile the mounted headline at point to a native Org INCLUDE keyword."
  (org-back-to-heading t)
  (let* ((id (org-roam-include--mount-id-at-point))
         (mount-level (org-outline-level)))
    (when (string-empty-p id)
      (user-error "ROAM_INCLUDE property is empty at headline: %s"
                  (org-get-heading t t t t)))
    (let* ((node (org-roam-node-from-id id))
           (_ (unless node
                (user-error
                 "Cannot find Org-roam node for ROAM_INCLUDE ID: %s"
                 id)))
           (include-keyword (or (org-roam-include--include-keyword node)
                                "")))
      (org-entry-delete (point) org-roam-include-property)
      (org-roam-include--replace-mount-body include-keyword))))

(defun org-roam-include--compile-buffer ()
  "Compile all Org-roam include mounts in current buffer."
  (let ((mounts (org-roam-include--collect-mounts)))
    (dolist (pos mounts)
      (goto-char pos)
      (when (org-at-heading-p)
        (org-roam-include--compile-one-at-point)))))

(defun org-roam-include--before-processing (_backend)
  "Expand Org-roam include properties before Org export parsing.

This function is installed by `org-roam-include-mode'.  It is
expected to run in Org's export temporary buffer."
  (org-roam-include-expand-buffer))

;; ==============================
;; 可调用结构函数
;; ==============================

;;;###autoload
(defun org-roam-include-check-variables ()
  "Check variables required by Org-roam Include."
  (interactive)
  (let ((check-result
         (org-roam-include--check-variables
          org-roam-include--variable-type-alist)))
    (message "%s"
             (if (consp check-result)
                 (cdr check-result)
               check-result))))

(defun org-roam-include-expand-buffer ()
  "Expand all Org-roam include properties in the current Org buffer.

This function is intended to run in Org export temporary buffers.  It
compiles `org-roam-include-property' mounts to native Org INCLUDE
keywords.  The current implementation does not recursively compile
included files."
  (org-roam-include--compile-buffer))

;; ==============================
;; Minor-Mode
;; ==============================

;; definition
;;;###autoload
(define-minor-mode org-roam-include-mode
  "Toggle expansion of Org-roam include properties during Org export.

The mode is global.  When enabled, Org export temporary buffers are
preprocessed before parsing so that headlines with
`org-roam-include-property' can be expanded into ordinary Org text."
  :global t
  :group 'org-roam-include
  :lighter " ORI"
  (if org-roam-include-mode
      (let ((check-result
             (org-roam-include--check-variables
              org-roam-include--variable-type-alist)))
        (if (car check-result)
            (add-hook 'org-export-before-processing-functions
                      #'org-roam-include--before-processing)
          (setq org-roam-include-mode nil)
          (message "%s"
                   (concat
                    "[WARNING] There are variables not defined properly. "
                    "Org Roam Include Mode setup failed.\n"
                    "Variable validation result: failed\n"
                    (cdr check-result)))))
    (remove-hook 'org-export-before-processing-functions
                 #'org-roam-include--before-processing)))

(provide 'org-roam-include)

;;; org-roam-include.el ends here
