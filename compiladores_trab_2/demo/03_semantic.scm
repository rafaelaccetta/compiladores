; Erros semanticos para demonstracao

; 1. Identificador nao declarado
y

; 2. Tipo errado no operador
(+ #t 1)

; 3. Condicao do if nao e bool
(if 1 2 3)

; 4. Aridade errada
(define (soma a b) (+ a b))
(soma 1)
