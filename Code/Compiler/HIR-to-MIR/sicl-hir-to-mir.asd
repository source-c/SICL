(cl:in-package #:asdf-user)

(defsystem #:sicl-hir-to-mir
  :depends-on (#:cleavir2-hir
               #:cleavir2-mir)
  :serial t
  :components
  ((:file "packages")
   (:file "static-environment")
   (:file "generic-functions")
   (:file "variables")
   (:file "expand-funcall-instructions")
   (:file "cons")
   (:file "utilities")
   (:file "standard-object")
   (:file "array")
   (:file "boxing")
   (:file "fixnum")
   (:file "eliminate-enclose-instructions")
   (:file "gather-enter-instructions")
   (:file "hir-to-mir")))
