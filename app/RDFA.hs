{-# LANGUAGE DuplicateRecordFields #-}
module RDFA where

import Automata
import RegEx (parseRegEx)

data RDFA = RDFA
    { states :: Int
    , transition :: Int -> Char -> Int
    , start :: Int
    , final :: [(Int, String)]
    }

fromDFA :: DFA -> String -> RDFA
fromDFA (DFA dfa_states dfa_trans dfa_start dfa_final) token = 
    RDFA
    { states = dfa_states
    , transition = dfa_trans
    , start = dfa_start
    , final = map (\st -> (st, token)) dfa_final
    }

printRDFA :: [Int] -> RDFA -> String
printRDFA ignore (RDFA stts trans strt fnl) =
    "states: " ++ show stts ++ "\ntransition: \n" ++
        foldMap
            (\st ->
                foldMap (\sy -> if trans st sy `elem` ignore then "" else
                    "(" ++ show st ++ ", " ++ show sy ++ ") -> " ++ show (trans st sy) ++ "\n")
                    alphabet)
            [0..stts-1]
        ++ "start: " ++ show strt ++
        "\nfinal " ++ show fnl


