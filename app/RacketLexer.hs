module RacketLexer (Token(..), tokenize) where

import Data.Char (isDigit, isSpace)

-- Tokens reconhecidos pelo lexer Racket
data Token
    = TBool             Bool
    | TInt              Integer
    | TFloat            Double
    | TString           String
    | TSymbol           String
    | TLParen
    | TRParen
    | TDot
    | TQuote
    | TQuasiquote
    | TUnquote
    | TUnquoteSplicing
    deriving (Show, Eq)

-- Caracteres que terminam um átomo (delimitadores)
isDelim :: Char -> Bool
isDelim c = isSpace c || c `elem` "()\";"

-- Ponto de entrada: converte String em lista de tokens
tokenize :: String -> Either String [Token]
tokenize []         = Right []
tokenize (';':cs)   = tokenize (dropWhile (/= '\n') cs)   -- comentário de linha
tokenize (c  :cs)
    | isSpace c      = tokenize cs
    | c == '('       = (TLParen          :) <$> tokenize cs
    | c == ')'       = (TRParen          :) <$> tokenize cs
    | c == '\''      = (TQuote           :) <$> tokenize cs
    | c == '`'       = (TQuasiquote      :) <$> tokenize cs
    | c == ','       = case cs of
        ('@':rest)   -> (TUnquoteSplicing :) <$> tokenize rest
        _            -> (TUnquote         :) <$> tokenize cs
    | c == '"'       = lexString cs
    | c == '#'       = lexBool cs
    | startsNum c cs = lexNumber (c:cs)
    | otherwise      = lexAtom (c:cs)

-- '-' seguido de dígito é número; dígito também
startsNum :: Char -> String -> Bool
startsNum c rest
    | isDigit c = True
    | c == '-'  = not (null rest) && isDigit (head rest)
    | otherwise = False

-- String: consome até '"' de fechamento, trata \" como escape
lexString :: String -> Either String [Token]
lexString cs = go cs []
  where
    go []            _   = Left "String não terminada"
    go ('"' :rest)   acc = (TString (reverse acc) :) <$> tokenize rest
    go ('\\':x:rest) acc = go rest (x : acc)
    go (x   :rest)   acc = go rest (x : acc)

-- #t → TBool True, #f → TBool False
lexBool :: String -> Either String [Token]
lexBool ('t':cs) = (TBool True  :) <$> tokenize cs
lexBool ('f':cs) = (TBool False :) <$> tokenize cs
lexBool cs       = Left ("Esperava '#t' ou '#f', encontrou '#" ++ take 3 cs ++ "'")

-- Número: tenta Integer primeiro, depois Double
lexNumber :: String -> Either String [Token]
lexNumber cs =
    let (raw, rest) = span (not . isDelim) cs
    in case (reads raw :: [(Integer, String)]) of
        [(n, "")] -> (TInt   n :) <$> tokenize rest
        _         -> case (reads raw :: [(Double, String)]) of
            [(f, "")] -> (TFloat f :) <$> tokenize rest
            _         -> Left ("Número inválido: " ++ raw)

-- Átomo: símbolo comum ou '.' isolado
lexAtom :: String -> Either String [Token]
lexAtom cs =
    let (raw, rest) = span (not . isDelim) cs
        tok         = if raw == "." then TDot else TSymbol raw
    in (tok :) <$> tokenize rest
