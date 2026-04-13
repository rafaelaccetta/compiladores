{-# LANGUAGE DuplicateRecordFields #-}
module RDFA where

import Data.Maybe (fromMaybe)

import Automata
import RegEx (parseRegEx, main)

data RDFA = RDFA
    { states :: [Int]
    , transition :: [Int] -> Char -> [Int]
    , start :: [Int]
    , isFinal :: [Int] -> Maybe String
    }

fromDFA :: String -> DFA -> RDFA
fromDFA token (DFA dfa_states dfa_trans dfa_start dfa_final) = 
    RDFA
    { states = map (\x -> [x]) dfa_states
    , transition = \st sy -> map (`dfa_trans` sy) st
    , start = [dfa_start]
    , final = \x -> match x with
                    | [y] -> if y `elem` dfa_final then Just token else Nothing
                    | _ -> Nothing
    }

----------------------------------------------------------------



productRDFA :: RDFA -> RDFA -> RDFA
productRDFA (RDFA s1 t1 st1 f1) (RDFA s2 t2 st2 f2) =
    RDFA 
    { states = s1 ++ s2
    , transition = \st sy ->
    , start = st1 ++ st2
    , final = 
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
