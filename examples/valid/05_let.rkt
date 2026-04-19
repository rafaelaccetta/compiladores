; let
(define (hipotenusa a b)
  (let ((a2 (* a a))
        (b2 (* b b)))
    (sqrt (+ a2 b2))))

; let*
(define (teste x)
  (let* ((y (* x 2))
         (z (+ y 1)))
    z))
