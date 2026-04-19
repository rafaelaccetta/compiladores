; cond básico
(define (sinal n)
  (cond
    ((< n 0) "negativo")
    ((= n 0) "zero")
    (else    "positivo")))

; cond com múltiplas expressões no corpo
(define (classifica n)
  (cond
    ((< n 10) (display "pequeno") n)
    (else     (display "grande")  n)))
