{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}
module RDFA where

import Automata (alphabet, DFA(DFA))
import Data.Maybe (isJust, mapMaybe)

data RDFA = RDFA
    { states :: [Int]
    , transition :: [Int] -> Char -> [Int]
    , start :: [Int]
    , isFinal :: [Int] -> Maybe String
    }

fromDFA :: String -> DFA -> RDFA
fromDFA token (DFA dfa_states dfa_trans dfa_start dfa_final) =
    RDFA
    { states = [dfa_states]
    , transition = \st sy -> map (`dfa_trans` sy) st
    , start = [dfa_start]
    , isFinal = \case
                [y] -> if y `elem` dfa_final then Just token else Nothing
                _ -> Nothing
    }

----------------------------------------------------------------



productRDFA :: RDFA -> RDFA -> RDFA
productRDFA (RDFA s1 t1 st1 f1) (RDFA s2 t2 st2 f2) =
    RDFA
    { states = s1 ++ s2
    , transition = \st sy -> t1 (take (length s1) st) sy ++ t2 (drop (length s1) st) sy
    , start = st1 ++ st2
    , isFinal =
        \st -> case f1 (take (length s1) st) of
            Just token -> Just token
            Nothing -> f2 (drop (length s1) st)
    }

allStates :: [Int] -> [[Int]]
allStates [] = [[]]
allStates (0:_) = []
allStates (n:as) = map (n-1 :) (allStates as) ++ allStates (n-1:as)

printRDFA :: [[Int]] -> RDFA -> String
printRDFA ignore (RDFA stts trans strt fnl) =
    "states: " ++ show stts ++ "\ntransition: \n" ++
        foldMap
            (\st ->
                foldMap (\sy -> if trans st sy `elem` ignore then "" else
                    "(" ++ show st ++ ", " ++ show sy ++ ") -> " ++ show (trans st sy) ++ "\n")
                    alphabet)
            (allStates stts)
        ++ "start: " ++ show strt ++
        "\nfinal: " ++ show (mapMaybe fnl (allStates stts))

--main :: IO()
--main = print (allStates [2,3,4])