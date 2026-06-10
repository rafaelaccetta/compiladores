# Definição da Linguagem - Trabalho 2

## Objetivo

Definir um subconjunto de Scheme para a entrega do Trabalho 2:
- Scanner com Flex
- Parser bottom-up com Bison
- Verificação de tipos
- Verificação de contexto de identificadores (escopo/declaração)
- Geração de código Python

Esta definição prioriza um escopo enxuto para reduzir risco de retrabalho.

## Base no Trabalho 1

No Trabalho 1, vocês já trabalharam com gramática e tokens de Racket/Scheme (mais amplo do que o necessário agora), incluindo símbolos como:
- define-values
- if
- let-values
- set!
- quote
- #%plain-app

Para o Trabalho 2, a recomendação é simplificar para um Scheme educacional com sintaxe S-expression, sem elementos internos de Racket como #%plain-app, #%expression etc.

## Escopo Fechado (MVP)

### Formas aceitas no nível de programa

Um programa é uma sequência de definições e expressões:
- (define id expr)
- (define (id params...) expr)
- expr

### Expressões aceitas

- Literais:
  - inteiro (ex.: 0, 10, -5)
  - booleano (#t, #f)
- Identificador
- If:
  - (if expr expr expr)
- Let local:
  - (let ((id expr) ...) expr)
- Atualização:
  - (set! id expr)
- Chamada de função:
  - (id expr ...)
- Operadores primitivos como chamada:
  - (+ e1 e2)
  - (- e1 e2)
  - (* e1 e2)
  - (/ e1 e2)
  - (< e1 e2)
  - (> e1 e2)
  - (= e1 e2)
  - (and e1 e2)
  - (or e1 e2)
  - (not e)

## Itens fora do escopo (versão inicial)

- quote e listas literais
- cond
- begin
- lambda anônima fora de define de função
- recursão mútua com declarações avançadas
- strings (podem ser adicionadas depois, se sobrar tempo)
- macros e formas internas de Racket (#%...)

## Tipos da linguagem

Tipos minimos:
- int
- bool
- função (assinatura de parâmetros e retorno)

Regras principais:
- Operações aritméticas exigem int e retornam int
- Comparações (<, >, =) exigem int e retornam bool
- and/or/not exigem bool e retornam bool
- if exige condição bool e os dois ramos com mesmo tipo
- set! exige variavel previamente declarada e tipo compativel
- Chamada de função exige aridade e tipos compatíveis com a assinatura

## Contexto de identificadores

Escopos:
- Escopo global para defines de variável e função
- Escopo local em let
- Escopo de parâmetros em define de função

Erros semânticos obrigatórios:
- Uso de identificador não declarado
- Redeclaração indevida no mesmo escopo
- set! em identificador não declarado
- Chamada com número errado de argumentos
- Incompatibilidade de tipos

## Tokens iniciais para o scanner (Flex)

Delimitadores e estrutura:
- LPAREN: (
- RPAREN: )

Palavras-chave:
- DEFINE, IF, LET, SET

Booleanos:
- BOOL: #t | #f

Operadores:
- PLUS (+), MINUS (-), MUL (*), DIV (/)
- LT (<), GT (>), EQ (=)
- AND, OR, NOT

Átomos:
- INT: -?[0-9]+
- ID: [a-zA-Z_][a-zA-Z0-9_?!-]*

Ignorados:
- Espaços, tabs, quebras de linha
- Comentários iniciados por ; até o fim da linha

## Gramática inicial (forma amigável para converter em Bison)

program      -> forms
forms        -> form forms | vazio
form         -> define_var | define_fun | expr

define_var   -> ( define id expr )
define_fun   -> ( define ( id params ) expr )
params       -> id params | vazio

expr         -> int
             | bool
             | id
             | if_expr
             | let_expr
             | set_expr
             | call_expr

if_expr      -> ( if expr expr expr )
let_expr     -> ( let ( bindings ) expr )
bindings     -> binding bindings | vazio
binding      -> ( id expr )
set_expr     -> ( set! id expr )
call_expr    -> ( id args )
args         -> expr args | vazio

## Mapeamento para Python (primeira versão)

- (define x e) -> x = <e>
- (define (f a b) e) -> def f(a, b): return <e>
- (if c t e) -> (<t> if <c> else <e>)
- (let ((x a) (y b)) e) -> (lambda x, y: <e>)(<a>, <b>)
- (set! x e) -> x = <e>
- (+ a b) -> (a + b) (análogo para -, *, /)
- (< a b) -> (a < b) (análogo para >, =)
- (and a b) -> (a and b), (or a b) -> (a or b), (not a) -> (not a)

Observação: no Python, '=' de comparação é '=='.

## Critérios de pronto desta etapa

Esta etapa de definição está pronta quando:
1. O grupo concorda com esse escopo.
2. Vocês não adicionam construção nova sem atualizar este documento.
3. Scanner e parser são implementados estritamente com base nesta definição.

## Próximo passo imediato

Com esta definição aprovada, implementar:
1. scanner.l (Flex) com a tabela de tokens acima
2. parser.y (Bison) com a gramatica acima
3. AST mínima para suportar checagem semântica e tradução para Python