{-# LANGUAGE LambdaCase #-}
module Out where

import System.Environment

data RDFA = RDFA
    { states :: [Int]
    , transition :: [Int] -> Char -> [Int]
    , start :: [Int]
    , isFinal :: [Int] -> Maybe String
    }

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
                Nothing -> 
                    if word /= "" 
                    then Left ("Couldn't match string: " ++ word)
                    else scanAux rdfa as acc (if a `elem` whitespace then [] else [a]) (trans strt a)
                Just token -> 
                    case dropWhile (`elem` whitespace) str of
                        [] -> Right (acc ++ (if word == "" then [] else [(token, word)]))
                        b:bs -> scanAux rdfa bs (acc ++ (if word == "" then [] else [(token, word)])) [b] (trans strt b)
            else 
                scanAux rdfa as acc (word ++ [a]) (trans state a)

scan :: RDFA -> String -> Either String [(String, String)]
scan rdfa@(RDFA _ _ strt _) str = 
    scanAux rdfa str [] "" strt

tran :: [Int] -> Char -> [Int]
tran [1,1,1] '(' = [0,2,0]
tran [1,1,1] ')' = [0,0,2]
tran [1,1,1] 'a' = [2,0,0]
tran [2,0,0] 'b' = [3,0,0]
tran [3,0,0] 'a' = [2,0,0]
tran _ _ = [0,0,0]

final :: [Int] -> Maybe String
final [1,1,1] = Just "<1>"
final [0,2,0] = Just "<2>"
final [0,0,2] = Just "<3>"
final [3,0,0] = Just "<1>"
final _ = Nothing

rdfa :: RDFA
rdfa = RDFA [4,3,3] tran [1,1,1]final

main :: IO ()

main  = getArgs >>= \case
    [file] -> readFile file >>= \text -> print (scan rdfa text)
    _ -> print "Program must be run with 1 filepath as argument."