; --- Literais isolados ---
42
#t
#f

; --- Definicoes de variavel ---
(define x 10)
(define flag #t)

; --- Definicoes de funcao ---
(define (soma a b) (+ a b))
(define (identidade x) x)
(define (fat n) (if (= n 0) 1 (* n (fat (- n 1)))))

; --- If ---
(if #t 1 0)
(if (> x 0) #t #f)

; --- Let ---
(let ((y 2) (z 3)) (* y z))
(let ((a 1)) a)
(let () 0)

; --- Set! ---
(set! x (+ x 1))

; --- Operadores binarios ---
(+ 1 2)
(- 10 3)
(* 4 5)
(/ 8 2)
(< 1 2)
(> 5 3)
(= 7 7)

; --- Operadores booleanos ---
(and #t #f)
(or #f #t)
(not #t)
(not #f)

; --- Chamadas de funcao ---
(soma 1 2)
(fat 5)
(identidade 99)

; --- Numeros negativos ---
(define neg -5)
(+ -1 -2)

; --- Expressoes aninhadas ---
(if (and (> x 0) (< x 100)) (+ x 1) (- x 1))
(let ((res (soma 3 4))) (* res 2))
(define (max a b) (if (> a b) a b))
