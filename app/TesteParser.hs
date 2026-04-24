
module TesteParser where

import Parser
import Control.Exception

runTeste :: IO () -> IO ()
runTeste t = catch t (\e -> putStrLn ("  " ++ show (e :: SomeException)))






-- Função para contar espaços vazios na tabela LL(1)
naoTerminais :: [String]
naoTerminais = ["top-level-form", "module-level-form-rep", "top-level-form-rep", "module-level-form", "raw-provide-spec-rep", "declaration-keyword-rep", "submodule-form", "general-top-level-form", "id-rep", "expr", "expr-rep", "formals-expr-rep", "formals-expr", "id-expr-rep", "formals", "module-path", "raw-provide-spec", "datum", "declaration-keyword"]

terminais :: [String]
terminais = ["(", ")", "id", ".", "[", "]", "#%expression", "module", "module*", "#%plain-module-begin", "begin", "begin-for-syntax", "#%provide", "#%declare", "define-values", "define-syntaxes", "#%require", "#%plain-lambda", "case-lambda", "if", "begin0", "let-values", "letrec-values", "set!", "quote", "quote-syntax", "#:local", "with-continuation-mark", "#%plain-app", "#%top", "#%variable-reference", "$"]

contaEspacosVazios :: Int
contaEspacosVazios = length [ (nt, t) | nt <- naoTerminais, t <- terminais, tabela nt t == [] ]


-- ============================================================
-- Não-terminais com apenas 1 terminal gerado (possiveisGerados):
--   datum             -> ["id"]    (via quote / quote-syntax)
--   module-path       -> ["id"]    (via module)
--   raw-provide-spec  -> ["id"]    (via #%provide)
--   declaration-keyword -> ["id"]  (via #%declare)
-- ============================================================

-- Teste simples: expressão incompleta
-- Input : ( )
-- Transição tentada: tabela "expr" ")" → [] (vazio)
-- ')' está no FOLLOW de expr → erro genérico (muitas geraçoes possíveis)
teste1 :: IO ()
teste1 = do
  let tokens = [("(", "("), (")", ")")]
  print $ parse tokens

-- Teste válido: apenas um id
-- Input : x
-- Transição: tabela "top-level-form" "id" → general-top-level-form → expr → id
teste2 :: IO ()
teste2 = do
  let tokens = [("id", "x")]
  print $ parse tokens

-- Teste 3: parser real - (quote )
-- Input : ( quote )
-- Transição tentada: tabela "datum" ")" → [] (vazio)
-- ')' está no FOLLOW de datum → "Possível(s) id faltante(s) para 'datum'"
teste3 :: IO ()
teste3 = do
  let tokens = [("(", "("), ("quote", "quote"), (")", ")")]
  print $ parse tokens

-- Teste 4: parser real - (quote-syntax )
-- Input : ( quote-syntax )
-- Transição tentada: tabela "datum" ")" → [] (vazio)
-- Mesmo caminho do teste 3, chegando por quote-syntax em vez de quote
-- ')' está no FOLLOW de datum → "Possível(s) id faltante(s) para 'datum'"
teste4 :: IO ()
teste4 = do
  let tokens = [("(", "("), ("quote-syntax", "quote-syntax"), (")", ")")]
  print $ parse tokens

-- Teste 5: erroTabela direto para module-path
-- Input seria: ( module id ( ... ) ) com module-path faltando
-- Transição tentada: tabela "module-path" "(" → [] (vazio)
-- '(' está no FOLLOW de module-path → "Possível(s) id faltante(s) para 'module-path'"
teste5 :: IO ()
teste5 = putStrLn (erroTabela "module-path" "(")

-- Teste 6: erroTabela direto para raw-provide-spec
-- Input seria: ( #%provide ) com raw-provide-spec faltando
-- Transição tentada: tabela "raw-provide-spec" ")" → [] (vazio)
-- ')' está no FOLLOW de raw-provide-spec → "Possível(s) id faltante(s) para 'raw-provide-spec'"
teste6 :: IO ()
teste6 = putStrLn (erroTabela "raw-provide-spec" ")")

-- Teste 7: erroTabela direto para declaration-keyword
-- Input seria: ( #%declare ) com declaration-keyword faltando
-- Transição tentada: tabela "declaration-keyword" ")" → [] (vazio)
-- ')' está no FOLLOW de declaration-keyword → "Possível(s) id faltante(s) para 'declaration-keyword'"
teste7 :: IO ()
teste7 = putStrLn (erroTabela "declaration-keyword" ")")

-- ============================================================
-- Testes com aridade > 1: não-terminais que geram múltiplos terminais
-- possiveisGerados retorna mais de 1 elemento
-- ============================================================

-- Teste 8: parser real - (let-values () x)
-- Input : ( let-values ( ) x )
-- Transição tentada: tabela "id-expr-rep" ")" → [] (vazio)
-- possiveisGerados "id-expr-rep" = ["[", "(", ")", "]"]  → 4 gerados!
-- ')' está no FOLLOW de id-expr-rep → erro com NT de aridade > 1
-- Mensagem: "Erro de sintaxe: esperava ligações de variáveis antes de ')'."
teste8 :: IO ()
teste8 = do
  let tokens = [("(","("), ("let-values","let-values"), ("(","("), (")",")" ), ("id","x"), (")",")" )]
  print $ parse tokens

-- Teste 9: erroTabela direto para top-level-form
-- Transição tentada: tabela "top-level-form" ")" → [] (vazio)
-- possiveisGerados "top-level-form" = ["(", "#%expression", "module", "#%plain-module-begin", "begin", "begin-for-syntax", ")"]  → vários!
-- ')' está no FOLLOW de top-level-form → erro com NT de aridade > 1
-- Mensagem: "Erro de sintaxe: esperava uma definição ou expressão de nível superior antes de ')'."
teste9 :: IO ()
teste9 = putStrLn (erroTabela "top-level-form" ")")

-- Teste 10: erroTabela direto para general-top-level-form
-- Transição tentada: tabela "general-top-level-form" ")" → [] (vazio)
-- possiveisGerados "general-top-level-form" = ["(", "define-values", "define-syntaxes", "#%require"]  → 4 gerados!
-- ')' está no FOLLOW de general-top-level-form → erro com NT de aridade > 1
-- Mensagem: "Erro de sintaxe: esperava uma definição ou expressão antes de ')'."
teste10 :: IO ()
teste10 = putStrLn (erroTabela "general-top-level-form" ")")

-- Teste 11: erroTabela direto para module-level-form
-- Transição tentada: tabela "module-level-form" ")" → [] (vazio)
-- possiveisGerados "module-level-form" = ["(", "#%provide", "begin-for-syntax", "#%declare"]  → 4 gerados!
-- ')' está no FOLLOW de module-level-form → erro com NT de aridade > 1
-- Mensagem: "Erro de sintaxe: esperava uma definição de módulo antes de ')'."
teste11 :: IO ()
teste11 = putStrLn (erroTabela "module-level-form" ")")

-- Teste 12: erroTabela direto para submodule-form
-- Transição tentada: tabela "submodule-form" ")" → [] (vazio)
-- possiveisGerados "submodule-form" = ["(", "module", "module*", "#%plain-module-begin", "#f"]  → 5 gerados!
-- ')' está no FOLLOW de submodule-form → erro com NT de aridade > 1
-- Mensagem: "Erro de sintaxe: esperava um submódulo antes de ')'."
teste12 :: IO ()
teste12 = putStrLn (erroTabela "submodule-form" ")")

main :: IO ()
main = do
  putStrLn "=== Teste 1 (erro genérico - expr recebe ')' sem conteúdo) ==="
  runTeste teste1
  putStrLn "\n=== Teste 2 (parse válido - identificador simples) ==="
  runTeste teste2
  putStrLn "\n=== Teste 3 (assertivo via parser - datum em (quote )) ==="
  runTeste teste3
  putStrLn "\n=== Teste 4 (assertivo via parser - datum em (quote-syntax )) ==="
  runTeste teste4
  putStrLn "\n=== Teste 5 (assertivo direto - module-path com '(') ==="
  teste5
  putStrLn "\n=== Teste 6 (assertivo direto - raw-provide-spec com ')') ==="
  teste6
  putStrLn "\n=== Teste 7 (assertivo direto - declaration-keyword com ')') ==="
  teste7
  putStrLn "\n--- Testes com aridade > 1 ---"
  putStrLn "\n=== Teste 8 (via parser - id-expr-rep com ')' em let-values vazio) ==="
  runTeste teste8
  putStrLn "\n=== Teste 9 (direto - top-level-form com ')') ==="
  teste9
  putStrLn "\n=== Teste 10 (direto - general-top-level-form com ')') ==="
  teste10
  putStrLn "\n=== Teste 11 (direto - module-level-form com ')') ==="
  teste11
  putStrLn "\n=== Teste 12 (direto - submodule-form com ')') ==="
  teste12
  putStrLn "\n=== Espaços vazios na tabela LL(1) ==="
  print contaEspacosVazios
