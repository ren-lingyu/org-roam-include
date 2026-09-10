#!@guile@ \
--no-auto-compile -s
!#

(define home-directory
  (string-append (getenv "TMPDIR") "/home"))

(setenv "HOME" home-directory)
(mkdir home-directory)

(unless
  (zero?
    (system*
      "@emacs@"
      "-Q"
      "--batch"
      "--load"
      "@testFile@"
      "--funcall"
      "ert-run-tests-batch-and-exit"))
  (exit 1))

(call-with-output-file
  (getenv "out")
  (lambda (port) #t))
