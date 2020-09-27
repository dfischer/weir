(defpackage #:weir-tests
  (:use #:common-lisp #:weir-utils)
  (:export #:run-tests))

(in-package #:weir-tests)

(defvar *tests*)
(defvar *fails*)
(defvar *passes*)
(defvar *catastrophic*)


(defun sort-a-list (a)
  (sort a #'string-lessp :key #'(lambda (x) (string (first x)))))


; TODO: should probably find a framework for this ...
; TODO: approximately similar to

;https://www.rosettacode.org/wiki/Program_termination#Common_Lisp
(defun terminate (status)
  #+sbcl (sb-ext:quit :unix-status status)
  #+ccl (ccl:quitstatus)
  #+clisp (ext:quitstatus)
  #+cmu (unix:unix-exit status)
  #+ecl (ext:quitstatus)
  #+abcl (ext:quit:status status)
  #+allegro (excl:exitstatus :quiet t)
  #+gcl (common-lisp-user::bye status)
  #+ecl (ext:quitstatus))


(defmacro test-title (&body body)
  `(progn
     (format t "~%~%~%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@> ~a~%" ',@body)
     ,@body))


(defmacro do-test (a b)
  (alexandria:with-gensyms (aname bname)
    `(let ((,aname ,a)
           (,bname ,b))
      (incf *tests*)
      (if (equalp ,aname ,bname)
        (progn
          (incf *passes*)
          (format t "~%~%~%~a ~%----------------------------------> pass" ',a))
        (progn
          (incf *fails*)
          (format t "~%~%~%~a ~%#######################################################> fail ~%--  wanted: ~% ~a ~%--  got: ~% ~a~%-----------------------------------------~%"
            ',a ,bname ,aname))))))


(defun %tests-summary ()
  (format t "~% tests:  ~a~% fails:  ~a~% passes: ~a~%"
    *tests* *fails* *passes*)
  (when (> *fails* 0) (print "--- at least one test failed! ---")
                      (terminate 1))
  (when (> *catastrophic* 0) (print "--- at least one catastrophe! ---")
                             (terminate 2)))


;;; test running for whole project

(defvar *test-functions* nil)

(defmacro define-file-tests (name () &body body)
  (alexandria:with-gensyms (cname)
    `(progn
      (defun ,name ()
        (handler-case (progn ,@body)
          (error (,cname)
            (incf *catastrophic*)
            (warn "! ! ! Error when running file tests ~A.~% ~A" ',name ,cname))))
      (pushnew ',name *test-functions*))))

(defun run-tests ()
  (setf *tests* 0)
  (setf *passes* 0)
  (setf *fails* 0)
  (setf *catastrophic* 0)
  (dolist (test *test-functions*)
    (fresh-line)
    (format t "=============================================~%")
    (format t "============== Running file tests ~A~%" test)
    (format t "=============================================~2%")
    (rnd:set-rnd-state 1)               ; Re-seed state before each
                                        ; test.
    (let ((*print-pretty* t))
      (funcall test)))

    (%tests-summary))

