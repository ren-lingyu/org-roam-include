#!@guile@ \
--no-auto-compile -s
!#

(use-modules
  (ice-9 ftw)
  (srfi srfi-1)
  (srfi srfi-13))

(define (directory-entries directory)
  (scandir
    directory
    (lambda (name)
      (not (member name '("." ".."))))))

(define (elisp-files path)
  (let ((type (stat:type (stat path))))
    (cond
      ((eq? type 'directory)
       (append-map
         (lambda (name)
           (elisp-files (string-append path "/" name)))
         (directory-entries path)))
      ((and (eq? type 'regular) (string-suffix? ".el" path))
       (list path))
      (else '()))))

(define home-directory
  (string-append (getenv "TMPDIR") "/home"))

(define files
  (elisp-files "@source@"))

(unless (pair? files)
  (error "No Elisp files found" "@source@"))

(setenv "HOME" home-directory)
(mkdir home-directory)

(unless
  (zero?
    (apply
      system*
      (append
        '("@emacs@"
          "-Q"
          "--batch"
          "-L"
          "@source@"
          "--load"
          "package-lint"
          "--funcall"
          "package-lint-batch-and-exit")
        files)))
  (exit 1))

(call-with-output-file
  (getenv "out")
  (lambda (port) #t))
