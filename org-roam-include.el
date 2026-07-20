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
;; node IDs while exporting Org buffers.  A headline such as:
;;
;;   ** Chapter
;;      :PROPERTIES:
;;      :ROAM_INCLUDE: node-id
;;      :END:
;;
;; is intended to keep the local headline as the exported document structure
;; while taking the body from the referenced Org-roam node.  The implementation
;; should run only in Org export temporary buffers and should not modify source
;; files.
;;
;; This package is currently experimental.  The first stable target is an
;; export-only preprocessor based on `org-export-before-processing-functions',
;; not an editing preview mode and not an advice around Org's include expander.

;;; Code:

;; ==============================
;; 声明外部依赖
;; ==============================

(require 'cl-lib)
(require 'org)
(require 'ox)
(require 'org-roam)
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
  "Maximum recursive Org-roam include expansion depth."
  :type 'integer
  :safe #'integerp
  :group 'org-roam-include)

(defcustom org-roam-include-rewrite-relative-file-links
  t
  "Whether to rewrite relative file links copied from included nodes.

When non-nil, the planned expansion logic should resolve relative
file links against the source node file.  This keeps export results
closer to ordinary Org include behavior after node text is copied into
the export buffer."
  :type 'boolean
  :group 'org-roam-include)

;; ==============================
;; 常量定义
;; ==============================

(defconst org-roam-include--variable-type-alist
  '((org-roam-include-property . string)
    (org-roam-include-max-depth . integer)
    (org-roam-include-rewrite-relative-file-links . boolean))
  "Variables and expected types checked by `org-roam-include--check-variables'.")

;; ==============================
;; 内部变量
;; ==============================

(defvar org-roam-include--expansion-stack nil
  "Internal stack of Org-roam node IDs currently being expanded.")

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
                                 (stringp var-value)))
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
                                 (integerp var-value)))
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
              (unless (stringp var-value)
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
              (unless (integerp var-value)
                (setq result-bool nil)))
             (t
              (funcall add-to-result-message-short)
              (setq result-bool nil)))))
        (cons result-bool result-message))
    (cons nil "Inner Constant org-roam-include--variable-type-alist is NOT defined properly. ")))

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

This is currently a placeholder for the export-only preprocessor.  It
intentionally performs no mutation until the node extraction and
recursive expansion semantics are implemented."
  nil)

;; ==============================
;; Minor-Mode
;; ==============================

;; defination
;;;###autoload
(define-minor-mode org-roam-include-mode
  "Toggle expansion of Org-roam include properties during Org export.

The mode is global.  When enabled, Org export temporary buffers are
preprocessed before parsing so that headlines with
`org-roam-include-property' can be expanded into ordinary Org text."
  :global t
  :group 'org-roam-include
  :lighter " ORI")

;; hook
(add-hook 'org-roam-include-mode-hook
          (lambda ()
            (if org-roam-include-mode
                (let* ((check-result
                        (when (boundp 'org-roam-include--variable-type-alist)
                          (org-roam-include--check-variables
                           org-roam-include--variable-type-alist))))
                  (if (not (car check-result))
                      (progn
                        (setq org-roam-include-mode nil)
                        (message "%s"
                                 (concat
                                  "[WARNING] There are variables not defined properly. "
                                  "Org Roam Include Mode setup failed.\n"
                                  (format "%s\n" (car check-result))
                                  (cdr check-result))))
                    (add-hook 'org-export-before-processing-functions
                              #'org-roam-include--before-processing)))
              (remove-hook 'org-export-before-processing-functions
                           #'org-roam-include--before-processing))))

(provide 'org-roam-include)

;;; org-roam-include.el ends here
