; Programas semanticamente validos

; Variaveis
(define x 10)
(define flag #t)

; Funcoes
(define (soma a b) (+ a b))
(define (fat n) (if (= n 0) 1 (* n (fat (- n 1)))))
(define (max a b) (if (> a b) a b))
(define (neg? n) (< n 0))

; Operadores aritmeticos
(+ x 1)
(- x 1)
(* x 2)
(/ x 2)

; Comparacoes
(< x 100)
(> x 0)
(= x 10)

; Booleanos
(and flag #t)
(or #f flag)
(not flag)

; If com tipos iguais nos ramos
(if flag 1 0)
(if (> x 0) (+ x 1) (- x 1))

; Let
(let ((y 5) (z 3)) (+ y z))
(let ((a (+ x 1))) (* a 2))

; Set!
(set! x (+ x 1))
(set! flag #f)

; Chamadas de funcao
(soma 3 4)
(fat 5)
(max 10 20)
(neg? -1)

; Aninhamento profundo
(if (and (> x 0) (not flag)) (soma x 1) (fat x))
