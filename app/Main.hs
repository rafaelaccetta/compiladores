{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}
module Main where

import System.Environment

import Scanner (toPairs, createScanner)
import RDFA (RDFA(RDFA), reachableStates)
import Automata (alphabet)


createOutput :: RDFA -> IO ()
createOutput rdfa@(RDFA rdfa_states rdfa_trans rdfa_start rdfa_final) =
    writeFile "Out.hs" "{-# LANGUAGE LambdaCase #-}\nmodule Out where\n\nimport System.Environment\n\ndata RDFA = RDFA\n    { states :: [Int]\n    , transition :: [Int] -> Char -> [Int]\n    , start :: [Int]\n    , isFinal :: [Int] -> Maybe String\n    }"
            >> appendFile "Out.hs" "\n\ndelimiters :: [Char]\ndelimiters = [' ', '\\n', '\\t', ';', '(', ')']\n\nwhitespace :: [Char]\nwhitespace = [' ', '\\n', '\\t']\n\nscanAux :: RDFA -> String -> [(String, String)] -> String -> [Int] -> Either String [(String, String)]\nscanAux rdfa@(RDFA _ trans strt fnl) str acc word state = \n    case str of\n        [] -> case fnl state of\n            Nothing -> Left (\"Couldn't match string: \" ++ word)\n            Just token -> Right (acc ++ (if word == \"\" then [] else [(token, word)]))\n        a:as -> \n            if a `elem` delimiters \n            then case fnl state of\n                Nothing -> \n                    if word /= \"\" \n                    then Left (\"Couldn't match string: \" ++ word)\n                    else scanAux rdfa as acc (if a `elem` whitespace then [] else [a]) (trans strt a)\n                Just token -> \n                    case dropWhile (`elem` whitespace) str of\n                        [] -> Right (acc ++ (if word == \"\" then [] else [(token, word)]))\n                        b:bs -> scanAux rdfa bs (acc ++ (if word == \"\" then [] else [(token, word)])) [b] (trans strt b)\n            else \n                scanAux rdfa as acc (word ++ [a]) (trans state a)\n\nscan :: RDFA -> String -> Either String [(String, String)]\nscan rdfa@(RDFA _ _ strt _) str = \n    scanAux rdfa str [] \"\" strt"
            >> appendFile "Out.hs" "\n\ntran :: [Int] -> Char -> [Int]"
            >> appendFile "Out.hs" 
                (foldMap (\st -> 
                    foldMap (\sy ->
                        if rdfa_trans st sy == map (\_ -> 0) rdfa_states then "" 
                        else "\ntran " ++ show st ++ " " ++ show sy ++ " = " ++ show (rdfa_trans st sy)) alphabet) (reachableStates rdfa))
            >> appendFile "Out.hs" ("\ntran _ _ = " ++ show (map (\_ -> 0) rdfa_states))
            >> appendFile "Out.hs" "\n\nfinal :: [Int] -> Maybe String"
            >> appendFile "Out.hs" 
                (foldMap (\st -> 
                    case rdfa_final st of
                        Nothing -> ""
                        Just t -> "\nfinal " ++ show st ++ " = Just \"" ++ t ++ "\"") (reachableStates rdfa))
            >> appendFile "Out.hs" "\nfinal _ = Nothing"
            >> appendFile "Out.hs" "\n\nrdfa :: RDFA"
            >> appendFile "Out.hs" ("\nrdfa = RDFA " ++ show rdfa_states ++ " tran " ++ show rdfa_start ++ "final")
            >> appendFile "Out.hs" "\n\nmain :: IO ()"
            >> appendFile "Out.hs" "\n\nmain  = getArgs >>= \\case\n    [file] -> readFile file >>= \\text -> print (scan rdfa text)\n    _ -> print \"Program must be run with 1 filepath as argument.\""

main :: IO ()
main = getArgs >>= \case
    [file] -> toPairs . lines <$> readFile file >>= \regexes ->
        case createScanner regexes of
            Nothing -> print "erro"
            Just rdfa -> createOutput rdfa
    _ -> print "Program must be run with 1 filepath as argument."
