{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}
module RDFA where

import Automata (alphabet, DFA(DFA), removeUnreachableStates, nfa2DFA, removeEpsilon, regEx2EpsilonNFA)
import RegEx (parseRegEx)

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


reachableStates_ :: RDFA -> [[Int]]
reachableStates_ (RDFA _ rdfa_trans rdfa_start _) =
    let
        dfs :: [Int] -> [[Int]] -> [[Int]]
        dfs st ac =
            if st `elem` ac then ac else
                foldl
                    (\l sy ->
                        dfs (rdfa_trans st sy) l
                    ) (ac ++ [st]) alphabet
    in
        dfs rdfa_start []


-- TROCAR PARA IMPRIMIR APENAS ESTADOS ACESSÍVEIS COM DFS?
printRDFA :: [[Int]] -> RDFA -> String
printRDFA ignore rdfa@(RDFA stts trans strt fnl) =
    "states: " ++ show stts ++ "\ntransition: \n" ++
        foldMap
            (\st ->
                foldMap (\sy -> if trans st sy `elem` ignore then "" else
                    "(" ++ show st ++ ", " ++ show sy ++ ") -> " ++ show (trans st sy) ++ "\n")
                    alphabet)
            (reachableStates_ rdfa)
        ++ "start: " ++ show strt ++
        "\nfinal:\n" ++ 
        foldMap
            (\st -> case fnl st of
                Just t -> "(" ++ show st ++ ", " ++ t ++ ")\n"
                Nothing -> "")
            (allStates stts)

main :: IO()
main = 
    case (parseRegEx "ab+c;", parseRegEx "ac;b+") of
        (Just a1, Just a2) ->
            putStrLn (printRDFA [[0]] (fromDFA "1". removeUnreachableStates . nfa2DFA . removeEpsilon . regEx2EpsilonNFA $ a1))
            >> putStrLn (printRDFA [[0]] (fromDFA "2". removeUnreachableStates . nfa2DFA . removeEpsilon . regEx2EpsilonNFA $ a2))
            >> putStrLn (printRDFA [[0,0]] 
                (productRDFA
                    (fromDFA "1". removeUnreachableStates . nfa2DFA . removeEpsilon . regEx2EpsilonNFA $ a1)
                    (fromDFA "2". removeUnreachableStates . nfa2DFA . removeEpsilon . regEx2EpsilonNFA $ a2)))
            
        _ -> print "erro"