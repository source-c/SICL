(cl:in-package #:asdf-user)

(defsystem #:sicl-hir-to-mir
  :depends-on (:cleavir-hir-to-mir
	       :cleavir-processor-x86-64
	       :sicl-target-sicl)
  :serial t
  :components
  ((:file "packages")
   (:file "general")
   (:file "cons")
   (:file "integer")
   (:file "environment-related-instructions")))
