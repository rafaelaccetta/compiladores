(define (abs x) (if (< x 0) (- 0 x) x))
(define (entre? x lo hi) (and (> x lo) (< x hi)))

(let ((a 3) (b 4)) (+ (* a a) (* b b)))
(abs -7)
(entre? 5 1 10)
