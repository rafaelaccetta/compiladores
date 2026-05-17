; Programas validos para testar a geracao de codigo Python

(define x 10)
(define flag #t)

(define (soma a b) (+ a b))
(define (fat n) (if (= n 0) 1 (* n (fat (- n 1)))))
(define (max a b) (if (> a b) a b))
(define (neg? n) (< n 0))

(set! x (+ x 1))

(let ((y 3) (z 4)) (soma y z))

(if (> x 0) (+ x 1) (- x 1))

(and #t (not #f))

(soma 10 20)
(fat 6)
(max 7 3)
