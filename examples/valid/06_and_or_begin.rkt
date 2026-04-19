; and / or / begin
(define (entre a b n)
  (and (>= n a) (<= n b)))

(define (ou-zero a b)
  (or (= a 0) (= b 0)))

(define (sequencia x)
  (begin
    (define y (* x 2))
    (+ y 1)))
