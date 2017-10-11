(cl:in-package #:sicl-global-environment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Function SICL-ENV:GET-SETF-EXPANSION.
;;;
;;; This function differs from CL:GET-SETF-EXPANSION in that both its
;;; parameters are required.

(defun expand-place (place environment)
  (cond ((symbolp place)
	 (let ((expansion (cleavir-env:symbol-macro-expansion place environment)))
	   (if (eq place expansion)
	       place
	       (expand-place expansion environment))))
	((and (consp place) (symbolp (first place)))
	 (let ((expander (cleavir-env:macro-function (first place)
						     environment)))
	   (if (null expander)
	       place
	       (expand-place (funcall expander place environment) environment))))
	(t
	 (error "Invalid place ~s" place))))

(defun get-setf-expansion (place environment)
  (let* ((global-environment (cleavir-env:global-environment environment))
	 (expanded-place (expand-place place environment))
	 (expander (if (symbolp expanded-place)
		       (default-setf-expander global-environment)
		       (or (setf-expander (first expanded-place)
					  global-environment)
			   (default-setf-expander global-environment)))))
    (funcall expander expanded-place environment)))
