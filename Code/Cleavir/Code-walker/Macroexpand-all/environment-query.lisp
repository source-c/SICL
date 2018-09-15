(cl:in-package #:cleavir-macroexpand-all)

(defun variable-info (environment symbol)
  (let ((result (cleavir-env:variable-info environment symbol)))
    (if (null result)
        (make-instance 'cleavir-env:special-variable-info :name symbol)
        result)))

(defun function-info (environment function-name)
  (let ((result (cleavir-env:function-info environment function-name)))
    (if (null result)
        (make-instance 'cleavir-env:global-function-info :name function-name)
        result)))

(defun block-info (environment block-name)
  (let ((result (cleavir-env:block-info environment block-name)))
    (loop while (null result)
	  do (restart-case (error 'cleavir-env:no-block-info
				  :name block-name)
	       (substitute (new-block-name)
		 :report (lambda (stream)
			   (format stream "Substitute a different name."))
		 :interactive (lambda ()
				(format *query-io* "Enter new name: ")
				(list (read *query-io*)))
		 (setq result (cleavir-env:block-info environment new-block-name)))))
    result))

(defun tag-info (environment tag-name)
  (let ((result (cleavir-env:tag-info environment tag-name)))
    (loop while (null result)
	  do (restart-case (error 'cleavir-env:no-tag-info
				  :name tag-name)
	       (substitute (new-tag-name)
		 :report (lambda (stream)
			   (format stream "Substitute a different name."))
		 :interactive (lambda ()
				(format *query-io* "Enter new name: ")
				(list (read *query-io*)))
		 (setq result (cleavir-env:tag-info environment new-tag-name)))))
    result))