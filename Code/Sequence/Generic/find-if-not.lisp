(cl:in-package #:sicl-sequence)

(defmethod find-if-not (predicate (datum t) &key &allow-other-keys)
  (error 'must-be-sequence
         :datum datum))

(defmethod find-if-not (predicate (list list) &key from-end start end key)
  (with-predicate (predicate predicate)
    (with-key-function (key key)
      (for-each-relevant-cons (cons index list start end from-end)
        (let ((element (car cons)))
          (unless (predicate (key element))
            (return-from find-if-not element)))))))

(replicate-for-each-relevant-vectoroid #1=#:vectoroid
  (defmethod find-if-not (predicate (vectoroid #1#) &key from-end start end key)
    (with-predicate (predicate predicate)
      (with-key-function (key key)
        (for-each-relevant-element (element index vectoroid start end from-end)
          (unless (predicate (key element))
            (return-from find-if-not element)))))))
