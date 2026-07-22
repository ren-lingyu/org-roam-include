;;; org-roam-include-test.el --- Tests for org-roam-include -*- lexical-binding: t; -*-

;;; Commentary:

;; These tests create source Org fixtures with `make-temp-file', using Emacs'
;; standard `temporary-file-directory'.  Set TMPDIR when invoking Emacs to
;; control where those temporary files are written.

;;; Code:

(require 'cl-lib)
(require 'ert)
(require 'org)
(require 'ox)

(cl-defstruct (org-roam-node
               (:constructor org-roam-node-create
                             (&key id file point level)))
  id file point level)

(defun org-roam-node-from-id (_id)
  nil)

(provide 'org-roam)

(load-file
 (expand-file-name
  "org-roam-include.el"
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name))))))

(defvar org-roam-include-test--fixtures nil)
(defvar org-roam-include-test--nodes nil)

(defun org-roam-include-test--write-file (file content)
  "Write CONTENT to FILE, creating parent directories as needed."
  (make-directory (file-name-directory file) t)
  (with-temp-file file
    (insert content)))

(defun org-roam-include-test--find-heading-point (file heading)
  "Return the beginning position of HEADING in FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (re-search-forward (rx line-start "* " (literal heading)))
    (line-beginning-position)))

(defun org-roam-include-test--node (id file level &optional heading)
  "Return a mock Org-roam node."
  (org-roam-node-create
   :id id
   :file file
   :point (if heading
              (org-roam-include-test--find-heading-point file heading)
            1)
   :level level))

(defun org-roam-include-test--lookup-node (id)
  "Return the mock node for ID."
  (cdr (assoc id org-roam-include-test--nodes)))

(defun org-roam-include-test--expand (content &optional marked)
  "Run native INCLUDE expansion for CONTENT.

When MARKED is non-nil, mark the temporary buffer as an Org export working
copy before invoking the native INCLUDE expander."
  (with-temp-buffer
    (insert content)
    (let ((default-directory org-roam-include-test--fixtures))
      (org-mode)
      (when marked
        (org-roam-include--mark-export-buffer nil))
      (org-export-expand-include-keyword nil org-roam-include-test--fixtures)
      (buffer-string))))

(defun org-roam-include-test--result (content &optional marked)
  "Return expansion result for CONTENT as a plist."
  (condition-case err
      (with-timeout (3 (list :status :timeout
                             :text nil
                             :error "timed out"))
        (list :status :ok
              :text (org-roam-include-test--expand content marked)
              :error nil))
    (error
     (list :status :error
           :text nil
           :error (error-message-string err)))))

(defun org-roam-include-test--ok-text (result)
  "Return text from successful RESULT."
  (should (eq (plist-get result :status) :ok))
  (plist-get result :text))

(defun org-roam-include-test--cycle-error-p (result)
  "Return non-nil when RESULT is a native recursive include error."
  (and (eq (plist-get result :status) :error)
       (let ((case-fold-search t))
         (string-match-p
          (rx (or "recursive file inclusion"
                  "recursive include"
                  "lisp nesting exceeds"))
          (plist-get result :error)))))

(defun org-roam-include-test--call-with-fixtures (thunk)
  "Create fixture files and call THUNK with mock Org-roam nodes."
  (let* ((org-roam-include-test--fixtures
          (file-name-as-directory
           (make-temp-file "org-roam-include-test-" t)))
         (c_file (expand-file-name "c.org" org-roam-include-test--fixtures))
         (b_file (expand-file-name "b-roam.org" org-roam-include-test--fixtures))
         (a_file (expand-file-name "a-roam.org" org-roam-include-test--fixtures))
         (native_to_roam_file
          (expand-file-name "native-to-roam.org" org-roam-include-test--fixtures))
         (roam_to_native_file
          (expand-file-name "roam-to-native.org" org-roam-include-test--fixtures))
         (mount_container_file
          (expand-file-name "mount-container.org" org-roam-include-test--fixtures))
         (mount_target_file
          (expand-file-name "mount-target.org" org-roam-include-test--fixtures))
         (lines_file
          (expand-file-name "lines-source.org" org-roam-include-test--fixtures))
         (headline_file
          (expand-file-name "headline.org" org-roam-include-test--fixtures))
         (headline_only_file
          (expand-file-name "headline-only.org" org-roam-include-test--fixtures))
         (comment_file
          (expand-file-name "comment-missing.org" org-roam-include-test--fixtures))
         (literal_file
          (expand-file-name "literal.org" org-roam-include-test--fixtures))
         (whole_cycle_file
          (expand-file-name "whole-cycle.org" org-roam-include-test--fixtures))
         (headline_self_file
          (expand-file-name "headline-self.org" org-roam-include-test--fixtures))
         (headline_a_file
          (expand-file-name "headline-a.org" org-roam-include-test--fixtures))
         (headline_b_file
          (expand-file-name "headline-b.org" org-roam-include-test--fixtures)))
     (org-roam-include-test--write-file c_file "C body.\n")
     (org-roam-include-test--write-file b_file "#+ROAM_INCLUDE: c-id\n")
     (org-roam-include-test--write-file a_file "#+ROAM_INCLUDE: b-id\n")
     (org-roam-include-test--write-file native_to_roam_file "#+ROAM_INCLUDE: b-id\n")
     (org-roam-include-test--write-file
      roam_to_native_file
      "#+INCLUDE: \"native-to-roam.org\"\n")
     (org-roam-include-test--write-file
      mount_target_file
      "* Mounted Target\nMounted target body.\n")
     (org-roam-include-test--write-file
      mount_container_file
      "* Mounted Section\n:PROPERTIES:\n:ROAM_INCLUDE: mount-target-id\n:END:\n")
     (org-roam-include-test--write-file
      lines_file
      "before\n#+ROAM_INCLUDE: missing-before\n#+ROAM_INCLUDE: c-id\nselected\n#+ROAM_INCLUDE: missing-after\n")
     (org-roam-include-test--write-file
      headline_file
      "* Target\n:PROPERTIES:\n:ID: headline-id\n:END:\nTarget body.\n** Child\nChild body.\n")
     (org-roam-include-test--write-file
      headline_only_file
      "* Parent\n:PROPERTIES:\n:ID: headline-only-id\n:END:\n#+ROAM_INCLUDE: c-id\n")
     (org-roam-include-test--write-file
      comment_file
      "* COMMENT Hidden\n#+ROAM_INCLUDE: missing-comment\n\n* Visible\nVisible body.\n")
     (org-roam-include-test--write-file
      literal_file
      "#+BEGIN_SRC org\n#+ROAM_INCLUDE: missing-literal\n#+END_SRC\n\n#+ROAM_INCLUDE: c-id\n")
     (org-roam-include-test--write-file
      whole_cycle_file
      "#+ROAM_INCLUDE: whole-cycle-id\n")
     (org-roam-include-test--write-file
      headline_self_file
      "* Self\n:PROPERTIES:\n:ID: headline-self-id\n:END:\n#+ROAM_INCLUDE: headline-self-id\n")
     (org-roam-include-test--write-file
      headline_a_file
      "* A\n:PROPERTIES:\n:ID: headline-a-id\n:END:\n#+ROAM_INCLUDE: headline-b-id\n")
     (org-roam-include-test--write-file
      headline_b_file
      "* B\n:PROPERTIES:\n:ID: headline-b-id\n:END:\n#+ROAM_INCLUDE: headline-a-id\n")
     (let ((org-roam-include-test--nodes
            (list
             (cons "c-id"
                   (org-roam-include-test--node "c-id" c_file 0))
             (cons "b-id"
                   (org-roam-include-test--node "b-id" b_file 0))
             (cons "a-id"
                   (org-roam-include-test--node "a-id" a_file 0))
             (cons "roam-native-id"
                   (org-roam-include-test--node "roam-native-id" roam_to_native_file 0))
             (cons "mount-container-id"
                   (org-roam-include-test--node "mount-container-id" mount_container_file 0))
             (cons "mount-target-id"
                   (org-roam-include-test--node "mount-target-id" mount_target_file 0))
             (cons "lines-id"
                   (org-roam-include-test--node "lines-id" lines_file 0))
             (cons "headline-id"
                   (org-roam-include-test--node "headline-id" headline_file 1 "Target"))
             (cons "headline-only-id"
                   (org-roam-include-test--node "headline-only-id" headline_only_file 1 "Parent"))
             (cons "comment-id"
                   (org-roam-include-test--node "comment-id" comment_file 0))
             (cons "literal-id"
                   (org-roam-include-test--node "literal-id" literal_file 0))
             (cons "whole-cycle-id"
                   (org-roam-include-test--node "whole-cycle-id" whole_cycle_file 0))
             (cons "headline-self-id"
                   (org-roam-include-test--node "headline-self-id" headline_self_file 1 "Self"))
             (cons "headline-a-id"
                   (org-roam-include-test--node "headline-a-id" headline_a_file 1 "A"))
             (cons "headline-b-id"
                   (org-roam-include-test--node "headline-b-id" headline_b_file 1 "B")))))
       (cl-letf (((symbol-function 'org-roam-node-from-id)
                  #'org-roam-include-test--lookup-node))
         (unwind-protect
             (progn
               (org-roam-include-mode -1)
               (org-roam-include-mode 1)
               (funcall thunk))
           (org-roam-include-mode -1))))))

(defmacro org-roam-include-test--with-fixtures (&rest body)
  "Create fixture files and run BODY with mock Org-roam nodes."
  (declare (indent 0))
  `(org-roam-include-test--call-with-fixtures
    (lambda ()
      ,@body)))

(ert-deftest org-roam-include-test-headline-line-search ()
  "Headline nodes compile to private line-search locations and expand."
  (org-roam-include-test--with-fixtures
    (let ((location
           (with-temp-buffer
             (insert "#+ROAM_INCLUDE: headline-id\n")
             (org-mode)
             (org-roam-include-expand-buffer)
             (buffer-string))))
      (should (string-match-p
               (rx "::org-roam-include-line:1")
               location)))
    (let ((expanded
           (org-roam-include-test--ok-text
            (org-roam-include-test--result
             "#+ROAM_INCLUDE: headline-id\n"
             t))))
      (should (string-match-p (regexp-quote "* Target") expanded))
      (should (string-match-p (regexp-quote "Target body.") expanded))
      (should (string-match-p (regexp-quote "** Child") expanded)))
    (let ((only_contents
           (org-roam-include-test--ok-text
            (org-roam-include-test--result
             "#+ROAM_INCLUDE: headline-id :only-contents t\n"
             t))))
      (should-not (string-match-p (regexp-quote "* Target") only_contents))
      (should (string-match-p (regexp-quote "Target body.") only_contents)))))

(ert-deftest org-roam-include-test-recursive-expansion ()
  "ROAM_INCLUDE forms are normalized in recursive native INCLUDE buffers."
  (org-roam-include-test--with-fixtures
    (let ((roam_chain
           (org-roam-include-test--ok-text
            (org-roam-include-test--result "#+ROAM_INCLUDE: a-id\n" t)))
          (native_to_roam
           (org-roam-include-test--ok-text
            (org-roam-include-test--result
             "#+INCLUDE: \"native-to-roam.org\"\n"
             t)))
          (mixed
           (org-roam-include-test--ok-text
            (org-roam-include-test--result
             "#+ROAM_INCLUDE: roam-native-id\n"
             t))))
      (should (string-match-p (regexp-quote "C body.") roam_chain))
      (should (string-match-p (regexp-quote "C body.") native_to_roam))
      (should (string-match-p (regexp-quote "C body.") mixed)))))

(ert-deftest org-roam-include-test-property-mount-recursion ()
  "Property mounts inside included files are normalized recursively."
  (org-roam-include-test--with-fixtures
    (let ((expanded
           (org-roam-include-test--ok-text
            (org-roam-include-test--result
             "#+ROAM_INCLUDE: mount-container-id\n"
             t))))
      (should (string-match-p (regexp-quote "* Mounted Section") expanded))
      (should (string-match-p (regexp-quote "** Mounted Target") expanded))
      (should (string-match-p (regexp-quote "Mounted target body.") expanded)))))

(ert-deftest org-roam-include-test-lines-before-recursion ()
  "Outer native :lines selection happens before recursive normalization."
  (org-roam-include-test--with-fixtures
    (let ((expanded
           (org-roam-include-test--ok-text
            (org-roam-include-test--result
             "#+ROAM_INCLUDE: lines-id :lines \"3-5\"\n"
             t))))
      (should (string-match-p (regexp-quote "C body.") expanded))
      (should (string-match-p (regexp-quote "selected") expanded))
      (should-not (string-match-p (regexp-quote "missing-before") expanded))
      (should-not (string-match-p (regexp-quote "missing-after") expanded)))))

(ert-deftest org-roam-include-test-comment-and-literal-boundaries ()
  "COMMENT subtrees and literal block contents are not normalized."
  (org-roam-include-test--with-fixtures
    (let ((comment
           (org-roam-include-test--ok-text
            (org-roam-include-test--result "#+ROAM_INCLUDE: comment-id\n" t)))
          (literal
           (org-roam-include-test--ok-text
            (org-roam-include-test--result "#+ROAM_INCLUDE: literal-id\n" t))))
      (should (string-match-p
               (regexp-quote "#+ROAM_INCLUDE: missing-comment")
               comment))
      (should (string-match-p
               (regexp-quote "#+ROAM_INCLUDE: missing-literal")
               literal))
      (should (string-match-p (regexp-quote "C body.") literal)))))

(ert-deftest org-roam-include-test-expansion-activation-boundaries ()
  "Normalization and private line search stay inactive outside export expansion."
  (org-roam-include-test--with-fixtures
    (let ((unmarked
           (org-roam-include-test--ok-text
            (org-roam-include-test--result
             "#+ROAM_INCLUDE: missing-unmarked\n"
             nil)))
          (private_unmarked
           (org-roam-include-test--result
            "#+INCLUDE: \"headline-only.org::org-roam-include-line:1\"\n"
            nil))
          (private_marked
           (org-roam-include-test--ok-text
            (org-roam-include-test--result
             "#+INCLUDE: \"headline-only.org::org-roam-include-line:1\"\n"
             t))))
      (should (string-match-p
               (regexp-quote "#+ROAM_INCLUDE: missing-unmarked")
               unmarked))
      (should (eq (plist-get private_unmarked :status) :error))
      (should (string-match-p (regexp-quote "* Parent") private_marked)))))

(ert-deftest org-roam-include-test-native-cycle-detection ()
  "Cycles through generated native INCLUDE locations are reported by Org."
  (org-roam-include-test--with-fixtures
    (should
     (org-roam-include-test--cycle-error-p
      (org-roam-include-test--result "#+ROAM_INCLUDE: whole-cycle-id\n" t)))
    (should
     (org-roam-include-test--cycle-error-p
      (org-roam-include-test--result "#+ROAM_INCLUDE: headline-self-id\n" t)))
    (should
     (org-roam-include-test--cycle-error-p
      (org-roam-include-test--result "#+ROAM_INCLUDE: headline-a-id\n" t)))))

(ert-deftest org-roam-include-test-mode-disable-removes-hooks ()
  "Disabling the mode removes its hook and advice."
  (org-roam-include-test--with-fixtures
    (org-roam-include-mode -1)
    (should-not
     (memq #'org-roam-include--mark-export-buffer
           org-export-before-processing-functions))
    (should-not
     (advice-member-p
      #'org-roam-include--around-expand-include-keyword
      'org-export-expand-include-keyword))))

;;; org-roam-include-test.el ends here
