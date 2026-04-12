{-# LANGUAGE DuplicateRecordFields #-}
module RDFA where

import Data.Maybe (fromMaybe)

import Automata
import RegEx (parseRegEx, main)

data RDFA = RDFA
    { states :: Int
    , transition :: Int -> Char -> Int
    , start :: Int
    , final :: [(Int, String)]
    }

fromDFA :: String -> DFA -> RDFA
fromDFA token (DFA dfa_states dfa_trans dfa_start dfa_final) = 
    RDFA
    { states = dfa_states
    , transition = dfa_trans
    , start = dfa_start
    , final = map (\st -> (st, token)) dfa_final
    }

----------------------------------------------------------------

fromPair :: (Int, Int) -> Int
fromPair (m, n) = (2^m)*(2*n+1)

toPair :: Int -> (Int, Int)
toPair k =
    let 
        gpo2f :: Int -> Int
        gpo2f num = if num `rem` 2 == 1 then 0 else 1 + gpo2f (num `div` 2)

        m = gpo2f k
        n = k `div` m
    in
        (m, n)

productRDFA :: RDFA -> RDFA -> RDFA
productRDFA (RDFA s1 t1 st1 f1) (RDFA s2 t2 st2 f2) =
    RDFA 
    { states = s1 * s2
    , transition = \st sy ->
        let 
            (m, n) = toPair st
        in 
            fromPair (t1 m sy, t2 n sy)
    , start = fromPair (st1, st2)
    , final = [(fromPair (x, y), t) | (x, t) <- f1, y <- [0..s1 * s2]] ++ [(fromPair (x, y), t) | x <- [0..s1 * s2], (y, t) <- f2]
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
