(cl:in-package #:sicl-hir-interpreter)

(defmethod interpret-instruction
    (client
     (instruction cleavir-ir:catch-instruction)
     lexical-environment)
  (destructuring-bind (continuation-output dynamic-environment-output)
      (cleavir-ir:outputs instruction)
    (let* ((successors (cleavir-ir:successors instruction))
           (transfer-tag (list nil))
           (abandon-tag (list nil)))
      (setf (lexical-value continuation-output lexical-environment)
            transfer-tag)
      (setf (lexical-value dynamic-environment-output lexical-environment)
            (cons (make-instance 'block/tagbody-entry
                    :abandon-tag abandon-tag)
                  (lexical-value (cleavir-ir:dynamic-environment-location instruction)
                                 lexical-environment)))
      (catch abandon-tag
        (loop for index = 0
                then  (catch transfer-tag
                        (interpret-instructions client successor lexical-environment))
              for successor = (nth index successors))))))
