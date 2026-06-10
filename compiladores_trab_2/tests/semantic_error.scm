; Cada bloco demonstra um tipo de erro semantico diferente.
; O compilador deve reportar todos os erros abaixo.

; --- Erro 1: identificador nao declarado ---
y

; --- Erro 2: aritmetica com bool ---
(+ #t 1)

; --- Erro 3: comparacao com bool ---
(< #f 10)

; --- Erro 4: operador booleano com int ---
(and 1 0)

; --- Erro 5: 'not' com int ---
(not 42)

; --- Erro 6: condicao do if nao e bool ---
(if 1 2 3)

; --- Erro 7: ramos do if com tipos diferentes ---
(if #t 1 #f)

; --- Erro 8: set! em variavel nao declarada ---
(set! z 99)

; --- Erro 9: chamada a identificador nao declarado ---
(f 1 2)

; --- Erro 10: aridade errada ---
(define (soma a b) (+ a b))
(soma 1)

; --- Erro 11: redeclaracao no mesmo escopo ---
(define x 10)
(define x 20)

; --- Erro 12: set! com tipo incompativel ---
(define flag #t)
(set! flag 42)

; --- Erro 13: chamada de nao-funcao ---
(define n 5)
(n 1 2)
