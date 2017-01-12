(cl:in-package #:sicl-sequence)

;;; This function calls KEY-FUNCTION with ELEMENT as the only
;;; argument.  It is semantically equivalent to FUNCALL except that
;;; only functions are allowed, and not any other function
;;; designators.  However, we do not trust the implementation of
;;; FUNCALL to optimize when KEY-FUNCTION is either #'IDENTITY, #'CAR,
;;; or #'CDR, so we treat those cases separately here.
;;;
;;; When this function is inlined in a context where the key-function
;;; is EQ to one of the constants tested for in the function body, a
;;; sufficently smart compiler will remove the test and just leave the
;;; appropriate branch.

(declaim (inline apply-key-function))

(defun apply-key-function (element key-function)
  (declare (optimize (speed 3) (debug 0) (safety 3)))
  (declare (type function key-function))
  (cond ((eq key-function #'identity)
	 element)
	((eq key-function #'car)
	 (car element))
	((eq key-function #'cdr)
	 (cdr element))
	(t
	 (funcall key-function element))))

(defmacro canonicalize-key (key-var)
  `(cond ((null ,key-var)
	  (setf ,key-var #'identity))
	 ((not (functionp ,key-var))
	  (setf ,key-var (fdefinition ,key-var)))
	 (t nil)))

(defmacro for-each-relevant-cons
    ((cons-var index-var list start end from-end) &body body)
  (let ((fun-var (gensym))
	(list-var (gensym))
	(start-var (gensym))
	(end-var (gensym))
	(rest-var (gensym))
	(length-var (gensym))
	(iter-var (gensym)))
    `(let (,length-var
	   (,list-var ,list)
	   (,start-var ,start)
	   (,end-var ,end))
       (if ,from-end
	   (progn (when (null ,end-var)
		    (setf ,end-var (length ,list-var)))
		  (if (null ,start-var)
		      (setf ,start-var 0)
		      (setf ,list-var (nthcdr ,start-var ,list-var)))
		  (setf ,length-var (- ,end-var ,start-var))
		  (labels ((,fun-var (,rest-var ,index-var ,length-var)
			     (declare (type fixnum ,length-var))
			     (when (> ,length-var 0)
			       (when (consp ,rest-var)
				 (traverse (cdr ,rest-var)
					   (1+ ,index-var)
					   (1- ,length-var))
				 (let ((,cons-var ,rest-var))
				   ,@body))))
			   (traverse (rest index length)
			     (declare (type fixnum index length))
			     (if (< length 100)
				 (,fun-var rest index length)
				 (let* ((p8 (ash length -1))
					(p4 (ash p8 -1))
					(p2 (ash p4 -1))
					(p1 (ash p2 -1))
					(p3 (+ p2 (ash (- p4 p2) -1)))
					(p6 (+ p4 (ash (- p8 p4) -1)))
					(p5 (+ p4 (ash (- p6 p4) -1)))
					(p7 (+ p6 (ash (- p8 p6) -1)))
					(p12 (+ p8 (ash (- length p8) -1)))
					(p10 (+ p8 (ash (- p12 p8) -1)))
					(p9 (+ p8 (ash (- p10 p8) -1)))
					(p11 (+ p10 (ash (- p12 p10) -1)))
					(p14 (+ p12 (ash (- length p12) -1)))
					(p13 (+ p12 (ash (- p14 p12) -1)))
					(p15 (+ p14 (ash (- length p14) -1)))
					(r1 (nthcdr p1 rest))
					(r2 (nthcdr (- p2 p1) r1))
					(r3 (nthcdr (- p3 p2) r2))
					(r4 (nthcdr (- p4 p3) r3))
					(r5 (nthcdr (- p5 p4) r4))
					(r6 (nthcdr (- p6 p5) r5))
					(r7 (nthcdr (- p7 p6) r6))
					(r8 (nthcdr (- p8 p7) r7))
					(r9 (nthcdr (- p9 p8) r8))
					(r10 (nthcdr (- p10 p9) r9))
					(r11 (nthcdr (- p11 p10) r10))
					(r12 (nthcdr (- p12 p11) r11))
					(r13 (nthcdr (- p13 p12) r12))
					(r14 (nthcdr (- p14 p13) r13))
					(r15 (nthcdr (- p15 p14) r14)))
				   (declare (type fixnum p1 p2 p3 p4 p5 p6)
					    (type fixnum p7 p8 p9 p10 p11)
					    (type fixnum p12 p13 p14 p15))
				   (traverse r15 (+ index p15) (- length p15))
				   (traverse r14 (+ index p14) (- p15 p14))
				   (traverse r13 (+ index p13) (- p14 p13))
				   (traverse r12 (+ index p12) (- p13 p12))
				   (traverse r11 (+ index p11) (- p12 p11))
				   (traverse r10 (+ index p10) (- p11 p10))
				   (traverse r9 (+ index p9) (- p10 p9))
				   (traverse r8 (+ index p8) (- p9 p8))
				   (traverse r7 (+ index p7) (- p8 p7))
				   (traverse r6 (+ index p6) (- p7 p6))
				   (traverse r5 (+ index p5) (- p6 p5))
				   (traverse r4 (+ index p4) (- p5 p4))
				   (traverse r3 (+ index p3) (- p4 p3))
				   (traverse r2 (+ index p2) (- p3 p2))
				   (traverse r1 (+ index p1) (- p2 p1))
				   (traverse rest (+ index p1) p1)))))
		    (traverse ,list-var ,start-var ,length-var)))
	   (progn (if (null ,start-var)
		      (setf ,start-var 0)
		      (setf ,list-var (nthcdr ,start-var ,list-var)))
		  (loop for ,iter-var of-type fixnum from ,start-var
			for ,rest-var = ,list-var then (cdr ,rest-var)
			do (if (atom ,rest-var)
			       (if (null ,rest-var)
				   (if (and (not (null ,end-var))
					    (> ,end-var ,iter-var))
				       (error "END too large")
				       (loop-finish))
				   (error "List must be proper"))
			       (if (and (not (null ,end-var))
					(>= ,iter-var ,end-var))
				   (loop-finish)
				   (let ((,cons-var ,rest-var)
					 (,index-var ,iter-var))
				     (declare (ignorable ,index-var))
				     ,@body)))))))))

(defmacro with-test-and-test-not ((test-var test-not-var) &body body)
  `(cond ((null ,test-not-var)
	  (locally (declare (type function ,test-var))
	    (cond ((eq ,test-var #'eq)
		   ,@body)
		  ((eq ,test-var #'eql)
		   ,@body)
		  (t
		   ,@body))))
	 ((null ,test-var)
	  (locally (declare (type function ,test-not-var))
	    (cond ((eq ,test-not-var #'eq)
		   ,@body)
		  ((eq ,test-not-var #'eql)
		   ,@body)
		  (t
		   ,@body))))
	 (t nil)))

(defmacro with-from-end (from-end-var &body body)
  `(if ,from-end-var
       (progn ,@body)
       (progn ,@body)))

(defmacro with-key-function (key-function-var &body body)
  `(cond ((eq ,key-function-var #'identity)
	  ,@body)
	 ((eq ,key-function-var #'car)
	  ,@body)
	 ((eq ,key-function-var #'cdr)
	  ,@body)
	 (t
	  ,@body)))

(declaim (inline satisfies-two-argument-test-p))

(defun satisfies-two-argument-test-p (item element test test-not)
  (declare (optimize (speed 3) (debug 0) (safety 3)))
  (cond ((null test-not)
	 (locally (declare (type function test))
	   (cond ((eq test #'eq)
		  (eq item element))
		 ((eq test #'eql)
		  (eql item element))
		 (t
		  (funcall test item element)))))
	((null test)
	 (locally (declare (type function test-not))
	   (cond ((eq test-not #'eq)
		  (not (eq item element)))
		 ((eq test-not #'eql)
		  (not (eql item element)))
		 (t
		  (not (funcall test-not item element))))))
	(t nil)))

(defmacro for-each-relevant-element
    ((element-var index-var array start end from-end) &body body)
  (let ((array-var (gensym))
	(start-var (gensym))
	(end-var (gensym)))
    `(let ((,array-var ,array)
	   (,start-var ,start)
	   (,end-var ,end))
       (declare (type fixnum ,start-var ,end-var))
       (if ,from-end
	   (loop for ,index-var of-type fixnum downfrom (1- ,end-var) to ,start-var
		 do (let ((,element-var (aref ,array-var ,index-var)))
		      ,@body))
	   (loop for ,index-var of-type fixnum from ,start-var below ,end-var
		 do (let ((,element-var (aref ,array-var ,index-var)))
		      ,@body))))))

(defmacro with-simple (array &body body)
  `(if (typep ,array 'simple-array)
       (progn ,@body)
       (progn ,@body)))


(defun make-situation (vector-var type accessor-name body)
  `((typep ,vector-var ',type)
    (locally (declare (type ,type ,vector-var))
      (macrolet ((vref (vector index)
		   `(,',accessor-name ,vector ,index)))
	,@body))))

(defmacro with-vector-type (vector-var &body body)
  `(cond ,@(loop for (type . accessor-name) in *special-array-information*
		 collect (make-situation vector-var type accessor-name body))
	 ((simple-vector-p ,vector-var)
	  (macrolet ((vref (vector index) `(aref ,vector ,index)))
	      ,@body))
	 (t (macrolet ((vref (vector index) `(aref ,vector ,index)))
	      ,@body))))

(defun same-type-p (type1 type2)
  (and (subtypep type1 type2) (subtypep type2 type1)))

(defmacro with-element-type (array &body body)
  (let ((type-var (gensym)))
    `(let ((,type-var (array-element-type ,array)))
       (cond ((same-type-p ,type-var 't)
	      ,@body)
	     ((same-type-p ,type-var 'bit)
	      ,@body)
	     ((same-type-p ,type-var 'base-char)
	      ,@body)
	     ((same-type-p ,type-var 'character)
	      ,@body)
	     ((same-type-p ,type-var '(unsigned-byte 8))
	      ,@body)
	     ((same-type-p ,type-var '(unsigned-byte 16))
	      ,@body)
	     ((same-type-p ,type-var '(signed-byte 16))
	      ,@body)
	     ((same-type-p ,type-var '(unsigned-byte 32))
	      ,@body)
	     ((same-type-p ,type-var '(signed-byte 32))
	      ,@body)
	     ((same-type-p ,type-var '(unsigned-byte 64))
	      ,@body)
	     ((same-type-p ,type-var '(signed-byte 64))
	      ,@body)
	     ((same-type-p ,type-var 'short-float)
	      ,@body)
	     ((same-type-p ,type-var 'single-float)
	      ,@body)
	     ((same-type-p ,type-var 'double-float)
	      ,@body)
	     ((same-type-p ,type-var 'long-float)
	      ,@body)
	     ((same-type-p ,type-var '(complex short-float))
	      ,@body)
	     ((same-type-p ,type-var '(complex single-float))
	      ,@body)
	     ((same-type-p ,type-var '(complex double-float))
	      ,@body)
	     ((same-type-p ,type-var '(complex long-float))
	      ,@body)))))

;;; This macro is used when the sequence is a list in order to check
;;; that the START and END parameters are valid.  BODY is duplicated
;;; in two different contexts, according to the type of the END
;;; parameter (i.e., NULL or FIXNUM).
(defmacro with-bounding-indices-list ((start-var end-var) &body body)
  `(progn (verify-bounding-indices-list ,start-var ,end-var)
	  (if (typep ,end-var 'fixnum)
	      (locally (declare (type fixnum ,start-var ,end-var))
		,@body)
	      (locally (declare (type fixnum ,start-var)
				(type null ,end-var))
		,@body))))

;;; This macro is used when the sequence is a vector in order to check
;;; that the START and END parameters are valid.  BODY is duplicated
;;; in two different contexts, according to the type of the END
;;; parameter (i.e., NULL or FIXNUM), and in the context where END is
;;; of type NULL, it is rebound to the length of the vector
(defmacro with-bounding-indices-vector ((vector-var start-var end-var) &body body)
  `(progn (verify-bounding-indexes-vector ,vector-var ,start-var ,end-var)
	  (if (typep ,end-var 'fixnum)
	      (locally (declare (type fixnum ,start-var ,end-var))
		,@body)
	      (let ((,end-var (length ,vector-var)))
		(locally (declare (type fixnum ,start-var ,end-var))
		  ,@body)))))
