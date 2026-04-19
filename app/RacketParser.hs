module RacketParser
    ( Expr(..)
    , ParseError
    , parseProgram
    , prettyExpr
    ) where

import RacketLexer (Token(..))

-- Árvore sintática
data Expr
    = EBool             Bool
    | EInt              Integer
    | EFloat            Double
    | EString           String
    | ESymbol           String
    | EQuote            Expr
    | EDefineVar        String Expr
    | EDefineFun        String [String] [Expr]
    | ELambda           [String] [Expr]
    | EIf               Expr Expr (Maybe Expr)
    | ECond             [(Expr, [Expr])]
    | EAnd              [Expr]
    | EOr               [Expr]
    | EBegin            [Expr]
    | ELet              [(String, Expr)] [Expr]
    | ELetStar          [(String, Expr)] [Expr]
    | EApp              Expr [Expr]
    deriving (Show, Eq)

type ParseError = String
type Tokens     = [Token]
type ParseResult = Either ParseError (Expr, Tokens)

-- ---------------------------------------------------------------------------
-- Ponto de entrada
-- ---------------------------------------------------------------------------

parseProgram :: [Token] -> Either ParseError [Expr]
parseProgram [] = Right []
parseProgram ts =
    case parseExpr ts of
        Left  err       -> Left err
        Right (e, rest) -> fmap (e :) (parseProgram rest)

-- ---------------------------------------------------------------------------
-- Expressão
-- ---------------------------------------------------------------------------

parseExpr :: Tokens -> ParseResult
parseExpr (TBool   b : ts) = Right (EBool   b, ts)
parseExpr (TInt    n : ts) = Right (EInt    n, ts)
parseExpr (TFloat  f : ts) = Right (EFloat  f, ts)
parseExpr (TString s : ts) = Right (EString s, ts)
parseExpr (TSymbol s : ts) = Right (ESymbol s, ts)
parseExpr (TQuote            : ts) = fmap (\(e,r) -> (EQuote e, r)) (parseExpr ts)
parseExpr (TQuasiquote       : ts) = fmap (\(e,r) -> (EApp (ESymbol "quasiquote") [e], r)) (parseExpr ts)
parseExpr (TUnquote          : ts) = fmap (\(e,r) -> (EApp (ESymbol "unquote") [e], r)) (parseExpr ts)
parseExpr (TUnquoteSplicing  : ts) = fmap (\(e,r) -> (EApp (ESymbol "unquote-splicing") [e], r)) (parseExpr ts)
parseExpr (TLParen           : ts) = parseList ts
parseExpr (TRParen : _) = Left "')' inesperado"
parseExpr (TDot    : _) = Left "'.' inesperado"
parseExpr []            = Left "Fim de arquivo inesperado"

-- ---------------------------------------------------------------------------
-- Listas e formas especiais
-- ---------------------------------------------------------------------------

parseList :: Tokens -> ParseResult
parseList (TRParen : ts)              = Right (EApp (ESymbol "") [], ts)
parseList (TSymbol "define" : ts)     = parseDefine ts
parseList (TSymbol "lambda" : ts)     = parseLambda ts
parseList (TSymbol "if"     : ts)     = parseIf     ts
parseList (TSymbol "cond"   : ts)     = parseCond   ts
parseList (TSymbol "and"    : ts)     = parseAndOr EAnd ts
parseList (TSymbol "or"     : ts)     = parseAndOr EOr  ts
parseList (TSymbol "begin"  : ts)     = parseBegin  ts
parseList (TSymbol "let"    : ts)     = parseLet ELet     ts
parseList (TSymbol "let*"   : ts)     = parseLet ELetStar ts
parseList (TSymbol "quote"  : ts)     = parseQuoteForm ts
parseList ts                          = parseApp ts

-- (define (f p...) corpo...)  ou  (define x expr)
parseDefine :: Tokens -> ParseResult
parseDefine (TLParen : TSymbol f : ts) =
    case parseSymList ts of
        Left err            -> Left err
        Right (params, ts') ->
            case parseBody ts' of
                Left err             -> Left err
                Right (body, ts'')   -> Right (EDefineFun f params body, ts'')
parseDefine (TSymbol name : ts) =
    case parseExpr ts of
        Left err       -> Left err
        Right (e, ts') -> case ts' of
            (TRParen : ts'') -> Right (EDefineVar name e, ts'')
            _                -> Left ("Esperava ')' após 'define " ++ name ++ "'")
parseDefine ts = Left ("Forma inválida de 'define': " ++ showToks ts)

-- (lambda (p...) corpo...)
parseLambda :: Tokens -> ParseResult
parseLambda (TLParen : ts) =
    case parseSymList ts of
        Left err            -> Left err
        Right (params, ts') ->
            case parseBody ts' of
                Left err             -> Left err
                Right (body, ts'')   -> Right (ELambda params body, ts'')
parseLambda ts = Left ("Esperava '(' após 'lambda': " ++ showToks ts)

-- (if cond então) ou (if cond então senão)
parseIf :: Tokens -> ParseResult
parseIf ts =
    case parseExpr ts of
        Left err          -> Left err
        Right (cond, ts1) ->
            case parseExpr ts1 of
                Left err            -> Left err
                Right (thenE, ts2)  -> case ts2 of
                    (TRParen : ts3) -> Right (EIf cond thenE Nothing, ts3)
                    _ ->
                        case parseExpr ts2 of
                            Left err            -> Left err
                            Right (elseE, ts3)  -> case ts3 of
                                (TRParen : ts4) -> Right (EIf cond thenE (Just elseE), ts4)
                                _               -> Left "Esperava ')' após 'if'"

-- (cond (teste corpo...) ...)
parseCond :: Tokens -> ParseResult
parseCond ts =
    case parseCondClauses ts of
        Left err             -> Left err
        Right (clauses, ts') -> Right (ECond clauses, ts')

parseCondClauses :: Tokens -> Either ParseError ([(Expr, [Expr])], Tokens)
parseCondClauses (TRParen : ts) = Right ([], ts)
parseCondClauses (TLParen : ts) =
    case parseExpr ts of
        Left err          -> Left err
        Right (test, ts') ->
            case parseBody ts' of
                Left err              -> Left err
                Right (body, ts'')   ->
                    case parseCondClauses ts'' of
                        Left err               -> Left err
                        Right (rest, ts''')    -> Right ((test, body) : rest, ts''')
parseCondClauses ts = Left ("Esperava cláusula em 'cond': " ++ showToks ts)

-- (and/or e...)
parseAndOr :: ([Expr] -> Expr) -> Tokens -> ParseResult
parseAndOr ctor ts =
    case parseExprs ts of
        Left err        -> Left err
        Right (es, ts') -> Right (ctor es, ts')

-- (begin e...)
parseBegin :: Tokens -> ParseResult
parseBegin ts =
    case parseBody ts of
        Left err        -> Left err
        Right (es, ts') -> Right (EBegin es, ts')

-- (let/let* ((x v)...) corpo...)
parseLet :: ([(String, Expr)] -> [Expr] -> Expr) -> Tokens -> ParseResult
parseLet ctor (TLParen : ts) =
    case parseBindings ts of
        Left err              -> Left err
        Right (bindings, ts') ->
            case parseBody ts' of
                Left err            -> Left err
                Right (body, ts'')  -> Right (ctor bindings body, ts'')
parseLet _ ts = Left ("Esperava '(' em 'let': " ++ showToks ts)

parseBindings :: Tokens -> Either ParseError ([(String, Expr)], Tokens)
parseBindings (TRParen : ts) = Right ([], ts)
parseBindings (TLParen : TSymbol name : ts) =
    case parseExpr ts of
        Left err       -> Left err
        Right (v, ts') -> case ts' of
            (TRParen : ts'') ->
                case parseBindings ts'' of
                    Left err             -> Left err
                    Right (rest, ts''')  -> Right ((name, v) : rest, ts''')
            _ -> Left ("Esperava ')' no binding de '" ++ name ++ "'")
parseBindings ts = Left ("Binding mal formado: " ++ showToks ts)

-- (quote expr)
parseQuoteForm :: Tokens -> ParseResult
parseQuoteForm ts =
    case parseExpr ts of
        Left err       -> Left err
        Right (e, ts') -> case ts' of
            (TRParen : ts'') -> Right (EQuote e, ts'')
            _                -> Left "Esperava ')' após 'quote'"

-- (f arg...)
parseApp :: Tokens -> ParseResult
parseApp ts =
    case parseExpr ts of
        Left err          -> Left err
        Right (func, ts') ->
            case parseExprs ts' of
                Left err             -> Left err
                Right (args, ts'')   -> Right (EApp func args, ts'')

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Consome zero ou mais expressões até ')'  (consome o ')')
parseExprs :: Tokens -> Either ParseError ([Expr], Tokens)
parseExprs (TRParen : ts) = Right ([], ts)
parseExprs ts =
    case parseExpr ts of
        Left err       -> Left err
        Right (e, ts') ->
            case parseExprs ts' of
                Left err            -> Left err
                Right (es, ts'')    -> Right (e : es, ts'')

parseBody :: Tokens -> Either ParseError ([Expr], Tokens)
parseBody = parseExprs

-- Lista de símbolos até ')'
parseSymList :: Tokens -> Either ParseError ([String], Tokens)
parseSymList (TRParen : ts)   = Right ([], ts)
parseSymList (TSymbol s : ts) =
    case parseSymList ts of
        Left err         -> Left err
        Right (ss, ts')  -> Right (s : ss, ts')
parseSymList ts = Left ("Esperava símbolo ou ')': " ++ showToks ts)

showToks :: Tokens -> String
showToks [] = "<fim>"
showToks ts = unwords (map show (take 3 ts)) ++ if length ts > 3 then " ..." else ""

-- ---------------------------------------------------------------------------
-- Pretty-printer
-- ---------------------------------------------------------------------------

prettyExpr :: Expr -> String
prettyExpr (EBool True)  = "#t"
prettyExpr (EBool False) = "#f"
prettyExpr (EInt    n)   = show n
prettyExpr (EFloat  f)   = show f
prettyExpr (EString s)   = "\"" ++ s ++ "\""
prettyExpr (ESymbol s)   = s
prettyExpr (EQuote  e)   = "(quote " ++ prettyExpr e ++ ")"

prettyExpr (EDefineVar name e) =
    "(define " ++ name ++ " " ++ prettyExpr e ++ ")"
prettyExpr (EDefineFun name params body) =
    "(define (" ++ unwords (name:params) ++ ") " ++ unwords (map prettyExpr body) ++ ")"
prettyExpr (ELambda params body) =
    "(lambda (" ++ unwords params ++ ") " ++ unwords (map prettyExpr body) ++ ")"

prettyExpr (EIf cond thenE Nothing) =
    "(if " ++ prettyExpr cond ++ " " ++ prettyExpr thenE ++ ")"
prettyExpr (EIf cond thenE (Just elseE)) =
    "(if " ++ prettyExpr cond ++ " " ++ prettyExpr thenE ++ " " ++ prettyExpr elseE ++ ")"

prettyExpr (ECond clauses) =
    "(cond " ++ unwords (map prettyClause clauses) ++ ")"
  where
    prettyClause (test, body) = "(" ++ prettyExpr test ++ " " ++ unwords (map prettyExpr body) ++ ")"

prettyExpr (EAnd   es) = "(and "   ++ unwords (map prettyExpr es) ++ ")"
prettyExpr (EOr    es) = "(or "    ++ unwords (map prettyExpr es) ++ ")"
prettyExpr (EBegin es) = "(begin " ++ unwords (map prettyExpr es) ++ ")"

prettyExpr (ELet     bindings body) = "(let "  ++ prettyBindings bindings ++ " " ++ unwords (map prettyExpr body) ++ ")"
prettyExpr (ELetStar bindings body) = "(let* " ++ prettyBindings bindings ++ " " ++ unwords (map prettyExpr body) ++ ")"

prettyExpr (EApp func args) = "(" ++ unwords (map prettyExpr (func:args)) ++ ")"

prettyBindings :: [(String, Expr)] -> String
prettyBindings bs = "(" ++ unwords (map pb bs) ++ ")"
  where pb (name, val) = "(" ++ name ++ " " ++ prettyExpr val ++ ")"
