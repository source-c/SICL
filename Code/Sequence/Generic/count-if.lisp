(cl:in-package #:sicl-sequence)

(defmethod count-if (predicate (datum t) &key &allow-other-keys)
  (error 'must-be-sequence
         :datum datum))

(defmethod count-if (predicate (list list) &key from-end start end key)
  (let ((count 0))
    (with-predicate (predicate predicate)
      (with-key-function (key key)
        (for-each-relevant-cons (cons index list start end from-end)
          (when (predicate (key (car cons)))
            (incf count)))))
    count))

(replicate-for-each-relevant-vectoroid #1=#:vectoroid
  (defmethod count-if (predicate (vectoroid #1#) &key from-end start end key)
    (let ((count 0))
      (with-predicate (predicate predicate)
        (with-key-function (key key)
          (for-each-relevant-element (element index vectoroid start end from-end)
            (when (predicate (key element))
              (incf count)))))
      count)))
