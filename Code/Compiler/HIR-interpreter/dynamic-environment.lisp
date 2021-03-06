(cl:in-package #:sicl-hir-interpreter)

(defparameter *dynamic-environment* '())

(defclass entry () ())

(defgeneric invalidate-entry (entry))

(defmethod invalidate-entry (entry)
  (declare (ignore entry))
  nil)

(defclass exit-point (entry)
  ((%valid-p :initform t :accessor valid-p)))

(defmethod invalidate-entry ((entry exit-point))
  (setf (valid-p entry) nil))

(defclass block/tagbody-entry (exit-point)
  ((%abandon-tag :initarg :abandon-tag :reader abandon-tag)))

(defmethod print-object ((object block/tagbody-entry) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~s" (abandon-tag object))))

(defclass catch-entry (exit-point)
  ((%tag :initarg :tag :reader tag)))

(defmethod print-object ((object catch-entry) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~s" (tag object))))

(defclass special-variable-entry (entry)
  ((%name :initarg :name :reader name)
   (%value :initarg :value :accessor value)))

(defmethod print-object ((object special-variable-entry) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~s ~s" (name object) (value object))))

(defclass unwind-protect-entry (entry)
  ((%thunk :initarg :thunk :reader thunk)))

(defmethod print-object ((object unwind-protect-entry) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~s" (thunk object))))

(declaim (notinline compute-source-info))

(defvar *global-values-location*)

(defmethod interpret-instruction :before
    (client instruction lexical-environment)
  (let ((env1 (lexical-value 'dynamic-environment lexical-environment))
        (env2 (lexical-value (cleavir-ir:dynamic-environment-location
                              instruction)
                             lexical-environment)))
    (unless (or (eq env1 env2)
                (> (length env2) (length env1)))
      (loop for env = env1 then (rest env)
            for entry = (first env)
            until (eq env env2)
            do (invalidate-entry entry))
      (let ((last-block/tagbody
              (loop with result = nil
                    for env = env1 then (rest env)
                    for entry = (first env)
                    until (eq env env2)
                    when (typep entry 'unwind-protect-entry)
                      do (funcall (thunk entry))
                    when (typep entry 'block/tagbody-entry)
                      do (setf result entry)
                    finally (return result))))
        (unless (null last-block/tagbody)
          (throw (abandon-tag last-block/tagbody)
            instruction))))))

(defmethod interpret-instruction :after
    (client instruction lexical-environment)
  (declare (ignore client))
  (setf (lexical-value 'dynamic-environment lexical-environment)
        (lexical-value (cleavir-ir:dynamic-environment-location
                        instruction)
                       lexical-environment)))
