(in-package #:sicl-clos)

(defun set-lambda-list-and-argument-precedence-order
    (generic-function
     lambda-list
     lambda-list-p
     argument-precedence-order
     argument-precedence-order-p)
  (when (and argument-precedence-order-p
	     (not lambda-list-p))
    (error "when argument precedence order appears, so must lambda list"))
  (unless (proper-list-p argument-precedence-order)
    (error "argument-precedence-order must be a proper list"))
  (when lambda-list-p
    (let ((parsed-lambda-list
	    (parse-generic-function-lambda-list lambda-list)))
      (unless argument-precedence-order-p
	(setf argument-precedence-order
	      (required parsed-lambda-list)))
      (setf (specializer-profile generic-function)
	    (make-list (length (required parsed-lambda-list))
		       :initial-element nil))
      (setf (gf-lambda-list generic-function)
	    lambda-list)
      (setf (gf-argument-precedence-order generic-function)
	    argument-precedence-order))))

(defun set-documentation (generic-function documentation)
  (unless (or (null documentation) (stringp documentation))
    (error "documentation must be NIL or a string"))
  (setf (gf-documentation generic-function)
	documentation))
  

(defun set-declarations (generic-function declarations)
  (unless (proper-list-p declarations)
    (error "declarations must be a proper list"))
  ;; FIXME: check the syntax of each declaration
  (setf (gf-declarations generic-function)
	declarations))

(defun set-method-combination (generic-function method-combination)
  ;; FIXME: check that method-combination is a method-combination metaobject
  (setf (gf-method-combination generic-function)
	method-combination))

(defun set-method-class (generic-function method-class)
  ;; FIXME: check that the method-class is a subclss of METHOD.
  (setf (gf-method-class generic-function)
	method-class))

(defun initialize-instance-after-standard-generic-function-default
    (generic-function
     &key
       (lambda-list nil lambda-list-p)
       (argument-precedence-order nil argument-precedence-order-p)
       documentation
       declarations
       method-combination
       (method-class (find-method-class 'standard-method))
       (name nil)
     &allow-other-keys)
  ;; FIXME: handle different method combinations.
  (declare (ignore method-combination))
  (set-documentation generic-function documentation)
  (set-declarations generic-function declarations)
  (set-method-class generic-function method-class)
  (set-lambda-list-and-argument-precedence-order
   generic-function
   lambda-list
   lambda-list-p
   argument-precedence-order
   argument-precedence-order-p)
  (let ((fun (lambda (&rest args)
	       (declare (ignore args))
	       (error "no applicable methods"))))
    (setf (discriminating-function generic-function) fun)
    (setf (gf-name generic-function) name)
    (unless (null name)
      (set-funcallable-instance-function fun generic-function))))

(defun reinitialize-instance-after-standard-generic-function-default
    (generic-function
     &key
       (lambda-list nil lambda-list-p)
       (argument-precedence-order nil argument-precedence-order-p)
       (documentation nil documentation-p)
       (declarations nil declarations-p)
       method-combination
       (method-class nil method-class-p)
       (name nil name-p)  ; FIXME: check if this belongs here.
     &allow-other-keys)
  ;; FIXME: handle different method combinations.
  (declare (ignore method-combination))
  (when documentation-p
    (set-documentation generic-function documentation))
  (when declarations-p
    (set-declarations generic-function declarations))
  (when method-class-p
    (set-method-class generic-function method-class))
  (when name-p
    (setf (gf-name generic-function) name))
  (set-lambda-list-and-argument-precedence-order
   generic-function
   lambda-list
   lambda-list-p
   argument-precedence-order
   argument-precedence-order-p)
  (map-dependents
   generic-function
   (lambda (dependent)
     (apply #'update-dependent generic-function dependent args))))
