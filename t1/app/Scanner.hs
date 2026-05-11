{-# LANGUAGE LambdaCase #-}
module Scanner where

import System.Environment (getArgs)

import RDFA (RDFA(RDFA), fromDFA, productRDFA, printRDFA)
import Automata (regEx2DFA)
import RegEx (parseRegEx)

delimiters :: [Char]
delimiters = [' ', '\n', '\t', ';', '(', ')']
whitespace :: [Char]
whitespace = [' ', '\n', '\t']

scanAux :: RDFA -> String -> [(String, String)] -> String -> [Int] -> String -> String -> String -> Either String [(String, String)]
scanAux rdfa@(RDFA _ trans strt fnl) str acc word state lword ltoken rstr = 
    case str of
        [] -> case fnl state of
            Nothing -> 
                if lword == "" 
                then Left ("Couldn't match string: " ++ word) 
                else scanAux rdfa rstr (acc ++ [(ltoken, lword)]) [] strt "" "" ""
            Just token -> Right (acc ++ (if word == "" then [] else [(token, word)]))
        a:as -> 
            if a `elem` delimiters 
            then case fnl state of
                Nothing -> 
                    if word /= "" 
                    then 
                        if lword == "" 
                        then Left ("Couldn't match string: " ++ word)
                        else scanAux rdfa rstr (acc ++ [(ltoken, lword)]) [] strt "" "" ""
                    else scanAux rdfa as acc (if a `elem` whitespace then [] else [a]) (trans strt a) 
                            (case fnl (trans strt a) of
                                Nothing -> ""
                                Just _ -> [a])
                            (case fnl (trans strt a) of
                                Nothing -> ""
                                Just t -> t) 
                            as
                Just token -> 
                    case dropWhile (`elem` whitespace) str of
                        [] -> Right (acc ++ (if word == "" then [] else [(token, word)]))
                        b:bs -> scanAux rdfa bs (acc ++ (if word == "" then [] else [(token, word)])) [b] (trans strt b)
                                    (case fnl (trans strt b) of
                                        Nothing -> ""
                                        Just _ -> [b])
                                    (case fnl (trans strt b) of
                                        Nothing -> ""
                                        Just t -> t) 
                                    bs
            else 
                scanAux rdfa as acc (word ++ [a]) (trans state a)
                    (case fnl (trans state a) of
                        Nothing -> lword
                        Just _ -> lword ++ [a])
                    (case fnl (trans state a) of
                        Nothing -> ltoken
                        Just t -> t) 
                    (case fnl (trans state a) of
                        Nothing -> rstr
                        Just _ -> as) 

scan :: RDFA -> String -> Either String [(String, String)]
scan rdfa@(RDFA _ _ strt _) str = 
    scanAux rdfa str [] "" strt "" "" ""


createScanner :: [(String, String)] -> Maybe RDFA
createScanner [] = Nothing
createScanner [(re, t)] =
    case parseRegEx re of
        Nothing -> Nothing
        Just regex -> Just (fromDFA t (regEx2DFA regex))
createScanner ((re, t):res) =
    case (parseRegEx re, createScanner res) of
        (Just regex, Just rdfa) -> Just (productRDFA (fromDFA t (regEx2DFA regex)) rdfa)
        _ -> Nothing

toPairs :: [String] -> [(String, String)]
toPairs (a:b:as) = (a, b) : toPairs as
toPairs _ = []

main :: IO()
main = getArgs >> case ["regexes.txt"] of
    [file] -> toPairs . lines <$> readFile file >>= \regexes ->
        case createScanner regexes of
            Nothing -> print "erro"
            Just rdfa -> putStrLn (printRDFA rdfa) >> print (scan rdfa "((abab))")
    _ -> print "Program must be run with 1 filepath as argument."