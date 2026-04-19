; if sem else
(define (eh-zero n) (if (= n 0) #t))

; if com else
(define (abs-val n) (if (< n 0) (- n) n))

; fatorial
(define (fat n)
  (if (= n 0)
      1
      (* n (fat (- n 1)))))
