(cl:in-package #:sicl-boot-phase-6)

(defun load-fasl (relative-pathname global-environment)
  (format *trace-output* "Loading file ~s~%" relative-pathname)
  (let* ((client (make-instance 'sicl-boot:client))
         (prefixed (concatenate 'string "ASTs/" relative-pathname))
         (pathname (asdf:system-relative-pathname '#:sicl-boot prefixed))
         (ast (cleavir-io:read-model pathname '(v0)))
         (hir (sicl-ast-to-hir:ast-to-hir client ast))
         (hir2 (sicl-ast-to-hir:ast-to-hir client ast))
         (fun (sicl-hir-interpreter:top-level-hir-to-host-function client hir))
         (sicl-hir-interpreter:*dynamic-environment* '()))
    (sicl-hir-to-mir:hir-to-mir client hir2)
    (funcall fun
             (sicl-hir-interpreter:make-function-cell-finder global-environment)
             (apply #'vector
                    nil ; Ultimately, replace with code object.
                    (labels ((enclose (entry-point code-object &rest static-environment-values)
                               (let* ((static-environment
                                        (apply #'vector
                                               code-object
                                               #'enclose
                                               #'cons
                                               nil
                                               static-environment-values))
                                      (closure (funcall (sicl-genv:fdefinition 'make-instance sicl-boot:*e5*)
                                              'function
                                              :environment static-environment)))
                                 (closer-mop:set-funcallable-instance-function
                                  closure
                                  (lambda (&rest args)
                                    (funcall entry-point
                                             args
                                             static-environment
                                             sicl-hir-interpreter:*dynamic-environment*)))
                                 closure)))
                      #'enclose)
                    #'cons
                    nil
                    (sicl-hir-transformations:constants hir)))))
