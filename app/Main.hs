module Main where

import System.Environment (getArgs)
import RacketLexer        (tokenize)
import RacketParser       (parseProgram, prettyExpr)

main :: IO ()
main = do
    args <- getArgs
    src  <- case args of
                [file] -> readFile file
                _      -> getContents
    case tokenize src >>= parseProgram of
        Left  err   -> putStrLn ("Erro: " ++ err)
        Right exprs -> mapM_ (putStrLn . prettyExpr) exprs
