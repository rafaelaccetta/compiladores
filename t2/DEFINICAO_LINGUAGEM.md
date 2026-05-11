# Definicao da Linguagem - Trabalho 2

## Objetivo

Definir um subconjunto de Scheme para a entrega do Trabalho 2:
- Scanner com Flex
- Parser bottom-up com Bison
- Verificacao de tipos
- Verificacao de contexto de identificadores (escopo/declaracao)
- Geracao de codigo Python

Esta definicao prioriza um escopo enxuto para reduzir risco de retrabalho.

## Base no Trabalho 1

No Trabalho 1, voces ja trabalharam com gramatica e tokens de Racket/Scheme (mais amplo do que o necessario agora), incluindo simbolos como:
- define-values
- if
- let-values
- set!
- quote
- #%plain-app

Para o Trabalho 2, a recomendacao e simplificar para um Scheme educacional com sintaxe S-expression, sem elementos internos de Racket como #%plain-app, #%expression etc.

## Escopo Fechado (MVP)

### Formas aceitas no nivel de programa

Um programa e uma sequencia de definicoes e expressoes:
- (define id expr)
- (define (id params...) expr)
- expr

### Expressoes aceitas

- Literais:
  - inteiro (ex.: 0, 10, -5)
  - booleano (#t, #f)
- Identificador
- If:
  - (if expr expr expr)
- Let local:
  - (let ((id expr) ...) expr)
- Atualizacao:
  - (set! id expr)
- Chamada de funcao:
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

## Itens fora do escopo (versao inicial)

- quote e listas literais
- cond
- begin
- lambda anonima fora de define de funcao
- recursao mutua com declaracoes avancadas
- strings (podem ser adicionadas depois, se sobrar tempo)
- macros e formas internas de Racket (#%...)

## Tipos da linguagem

Tipos minimos:
- int
- bool
- funcao (assinatura de parametros e retorno)

Regras principais:
- Operacoes aritmeticas exigem int e retornam int
- Comparacoes (<, >, =) exigem int e retornam bool
- and/or/not exigem bool e retornam bool
- if exige condicao bool e os dois ramos com mesmo tipo
- set! exige variavel previamente declarada e tipo compativel
- Chamada de funcao exige aridade e tipos compativeis com a assinatura

## Contexto de identificadores

Escopos:
- Escopo global para defines de variavel e funcao
- Escopo local em let
- Escopo de parametros em define de funcao

Erros semanticos obrigatorios:
- Uso de identificador nao declarado
- Redeclaracao indevida no mesmo escopo
- set! em identificador nao declarado
- Chamada com numero errado de argumentos
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

Atomos:
- INT: -?[0-9]+
- ID: [a-zA-Z_][a-zA-Z0-9_?!-]*

Ignorados:
- Espacos, tabs, quebras de linha
- Comentarios iniciados por ; ate o fim da linha

## Gramatica inicial (forma amigavel para converter em Bison)

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

## Mapeamento para Python (primeira versao)

- (define x e) -> x = <e>
- (define (f a b) e) -> def f(a, b): return <e>
- (if c t e) -> (<t> if <c> else <e>)
- (let ((x a) (y b)) e) -> (lambda x, y: <e>)(<a>, <b>)
- (set! x e) -> x = <e>
- (+ a b) -> (a + b) (analogo para -, *, /)
- (< a b) -> (a < b) (analogo para >, =)
- (and a b) -> (a and b), (or a b) -> (a or b), (not a) -> (not a)

Observacao: no Python, '=' de comparacao e '=='.

## Criterios de pronto desta etapa

Esta etapa de definicao esta pronta quando:
1. O grupo concorda com esse escopo.
2. Voces nao adicionam construcao nova sem atualizar este documento.
3. Scanner e parser sao implementados estritamente com base nesta definicao.

## Proximo passo imediato

Com esta definicao aprovada, implementar:
1. scanner.l (Flex) com a tabela de tokens acima
2. parser.y (Bison) com a gramatica acima
3. AST minima para suportar checagem semantica e traducao para Python