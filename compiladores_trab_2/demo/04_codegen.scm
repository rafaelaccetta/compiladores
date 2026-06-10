(define (abs x) (if (< x 0) (- 0 x) x))
(define (entre? x lo hi) (and (> x lo) (< x hi)))

(let ((a 3) (b 4)) (+ (* a a) (* b b)))
(abs -7)
(entre? 5 1 10)

(+ 1 2 3 4)
(list 1 2 3)
(car (list 10 20 30))
(cdr (list 10 20 30))
(cons 5 (list 6 7))
(null? (list))
