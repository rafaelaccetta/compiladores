; programa completo: maior de três números
(define (maior3 a b c)
  (cond
    ((and (>= a b) (>= a c)) a)
    ((>= b c)                b)
    (else                    c)))

(define (fib n)
  (if (< n 2)
      n
      (+ (fib (- n 1)) (fib (- n 2)))))

(define resultado (maior3 3 7 5))
