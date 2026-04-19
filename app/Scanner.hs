module Scanner where

import RDFA (RDFA(RDFA), fromDFA, productRDFA, printRDFA)
import Automata (regEx2DFA)
import RegEx (parseRegEx)

delimiters :: [Char]
delimiters = [' ', '\n', '\t', ';', '(', ')']
whitespace :: [Char]
whitespace = [' ', '\n', '\t']

scanAux :: RDFA -> String -> [(String, String)] -> String -> [Int] -> Either String [(String, String)]
scanAux rdfa@(RDFA _ trans strt fnl) str acc word state = 
    case str of
        [] -> case fnl state of
            Nothing -> Left ("Couldn't match string: " ++ word)
            Just token -> Right (acc ++ (if word == "" then [] else [(token, word)]))
        a:as -> 
            if a `elem` delimiters 
            then case fnl state of
                Nothing -> Left ("Couldn't match string: " ++ word)
                Just token -> 
                    case dropWhile (`elem` whitespace) str of
                        [] -> Right (acc ++ (if word == "" then [] else [(token, word)]))
                        b:bs -> scanAux rdfa bs (acc ++ (if word == "" then [] else [(token, word)])) [b] (trans strt b)
            else 
                scanAux rdfa as acc (word ++ [a]) (trans state a)

scan :: RDFA -> String -> Either String [(String, String)]
scan rdfa@(RDFA _ _ strt _) str = 
    scanAux rdfa str [] "" strt


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


main :: IO()
main = 
    case createScanner [("a*", "a*"), (")", ")")] of
        Nothing -> print "erro"
        Just rdfa -> putStrLn (printRDFA [[0,0]] rdfa)>>print (scan rdfa "a) aa")