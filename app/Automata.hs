{-# LANGUAGE DuplicateRecordFields #-}
module Automata where

import RegEx (RegEx (Literal, Seq, Union, Star), parseRegEx)
import Data.List (nub, sort, elemIndex)
import Data.Maybe (fromMaybe)

alphabet :: [Char]
alphabet = ['A'..'z']

data DFA = DFA
    { states :: Int
    , transition :: Int -> Char -> Int
    , start :: Int
    , final :: [Int]
    }

data NFA = NFA
    { states :: Int
    , transition :: Int -> Char -> [Int]
    , start :: Int
    , final :: [Int]
    }

data EpsilonNFA = EpsilonNFA
    { states :: Int
    , transition :: Int -> Maybe Char -> [Int]
    , start :: Int
    , final :: [Int]
    }

----------------------------------------------------------------

regEx2EpsilonNFA :: RegEx -> EpsilonNFA

regEx2EpsilonNFA (Literal a) = EpsilonNFA
    { states = 2
    , transition =
        \st sy -> ([1 | (st, sy) == (0, Just a)])
    , start = 0
    , final = [1]
    }

regEx2EpsilonNFA (Seq r1 r2) =
    let
        EpsilonNFA r1_states r1_trans r1_start r1_final = regEx2EpsilonNFA r1
        EpsilonNFA r2_states r2_trans r2_start r2_final = regEx2EpsilonNFA r2
    in
        EpsilonNFA
        { states = r1_states + r2_states
        , transition = \st sy ->
            if st < r1_states then
                case (st `elem` r1_final, sy) of
                    (True, Nothing) -> (r1_states + r2_start) : r1_trans st Nothing
                    _ -> r1_trans st sy
            else
                map (+ r1_states)
                    (r2_trans (st - r1_states) sy)
        , start = r1_start
        , final = map (+ r1_states) r2_final
        }

regEx2EpsilonNFA (Union r1 r2) =
    let
        EpsilonNFA r1_states r1_trans r1_start r1_final = regEx2EpsilonNFA r1
        EpsilonNFA r2_states r2_trans r2_start r2_final = regEx2EpsilonNFA r2
    in
        EpsilonNFA
        { states = r1_states + r2_states + 2
        , transition = \st sy ->
            if st == 0 then
                case sy of
                    Nothing -> [r1_start + 1, r1_states + r2_start + 1]
                    _ -> []
            else if st < (r1_states + 1) then
                case ((st - 1) `elem` r1_final, sy) of
                    (True, Nothing) -> r1_states + r2_states + 1 :
                        map (+ 1) (r1_trans (st - 1) Nothing)
                    _ -> map (+ 1) (r1_trans (st - 1) sy)
            else if st < (r1_states + r2_states + 1) then
                case ((st - r1_states - 1) `elem` r2_final, sy) of
                    (True, Nothing) -> r1_states + r2_states + 1 :
                        map (+ (r1_states + 1)) (r2_trans (st - r1_states - 1) Nothing)
                    _ -> map (+ (r1_states +1 )) (r2_trans (st - r1_states - 1) sy)
            else []
        , start = 0
        , final = [r1_states + r2_states + 1]
        }

regEx2EpsilonNFA (Star r) =
    let EpsilonNFA r_states r_trans r_start r_final = regEx2EpsilonNFA r
    in
        EpsilonNFA
        { states = r_states + 2
        , transition = \st sy ->
            if st == 0 then
                case sy of
                    Nothing -> [r_start + 1, r_states + 1]
                    _ -> []
            else if st < (r_states + 1) then
                case ((st - 1) `elem` r_final, sy) of
                    (True, Nothing) -> r_start + 1 : r_states + 1 :
                        map (+ 1) (r_trans (st - 1) Nothing)
                    _ -> map (+ 1) (r_trans (st - 1) sy)
            else []
        , start = 0
        , final = [r_states + 1]
        }

----------------------------------------------------------------

-- | Retorna todos os estados alcançáveis a partir de 'initialStates'
-- usando apenas transições epsilon (Nothing). O próprio estado está
-- sempre no seu fecho.
--
-- Exemplo: se o estado 0 tem ε → 1 e 1 tem ε → 2, então
--   epsilonClosure enfa [0] == [0, 1, 2]
epsilonClosure :: EpsilonNFA -> [Int] -> [Int]
epsilonClosure (EpsilonNFA _ t _ _) initialStates =
    sort $ go initialStates initialStates
  where
    -- BFS: 'visited' acumula todos os estados já encontrados;
    --       'queue'   é a fronteira de estados ainda a explorar.
    go visited []         = nub visited
    go visited (s:queue)  =
        let newStates = filter (`notElem` visited) (t s Nothing)
        in  go (visited ++ newStates) (queue ++ newStates)

-- | Converte um EpsilonNFA em um NFA equivalente sem transições epsilon.
--
-- Algoritmo (Thompson):
--   1. Nova transição: δ'(q, a) = ε-fecho(⋃{ δ(r, Just a) | r ∈ ε-fecho({q}) })
--   2. Novos estados finais: q ∈ F' sse ε-fecho({q}) ∩ F ≠ ∅
--   3. Estado inicial: inalterado
--   4. Número de estados: inalterado
removeEpsilon :: EpsilonNFA -> NFA
removeEpsilon enfa@(EpsilonNFA n t s0 finalStates) = NFA
    { states     = n
    , transition = newTransition
    , start      = s0
    , final      = newFinalStates
    }
  where
    -- Para cada estado q e símbolo a:
    --   1. calcula o ε-fecho de {q}
    --   2. aplica a transição 'a' em cada estado do fecho
    --   3. calcula o ε-fecho do resultado
    newTransition q c =
        let closure   = epsilonClosure enfa [q]
            reachable = concatMap (\r -> t r (Just c)) closure
        in  epsilonClosure enfa reachable

    -- q é final se algum estado no seu ε-fecho era final no EpsilonNFA
    newFinalStates =
        filter (\q -> any (`elem` finalStates) (epsilonClosure enfa [q]))
               [0 .. n - 1]

----------------------------------------------------------------

toPowersOf2 :: Int -> [Int]
toPowersOf2 0 = []
toPowersOf2 n = if n `rem` 2 == 1
    then 0 : map (+1) (toPowersOf2 (n `div` 2))
    else map (+1) (toPowersOf2 (n `div` 2))

fromPowersOf2 :: [Int] -> Int
fromPowersOf2 = foldl (\b a -> b + 2^a) 0 . nub

nfa2DFA :: NFA -> DFA
nfa2DFA (NFA nfa_states nfa_trans nfa_start nfa_final) =
    DFA
    { states = 2 ^ nfa_states
    , transition = \st sy -> fromPowersOf2 (concatMap (`nfa_trans` sy) (toPowersOf2 st))
    , start = 2 ^ nfa_start
    , final = filter (any (`elem` nfa_final) . toPowersOf2) [1..2^nfa_states]
    }

----------------------------------------------------------------

reachableStates :: DFA -> [Int]
reachableStates (DFA _ dfa_trans dfa_start _) =
    let
        dfs :: Int -> [Int] -> [Int]
        dfs st ac =
            if st `elem` ac then ac else
                foldl
                    (\l sy ->
                        dfs (dfa_trans st sy) l
                    ) (ac ++ [st]) alphabet
    in
        dfs dfa_start []

removeUnreachableStates :: DFA -> DFA
removeUnreachableStates dfa@(DFA _ dfa_trans _ dfa_final) =
    let
        reachable = 0 : filter (/= 0) (reachableStates dfa)
    in
        DFA
        { states = length reachable
        , transition =
            \st sy ->
                if st < length reachable then
                    fromMaybe 0 (elemIndex (dfa_trans (reachable !! st) sy) reachable)
                else 0
        , start = 1
        , final = filter (\idx -> (reachable !! idx) `elem` dfa_final) [0..(length reachable - 1)]
        }

----------------------------------------------------------------

regEx2DFA :: RegEx -> DFA
regEx2DFA = removeUnreachableStates . nfa2DFA . removeEpsilon . regEx2EpsilonNFA

----------------------------------------------------------------

printEpsilonNFA :: EpsilonNFA -> String
printEpsilonNFA (EpsilonNFA stts trans strt fnl) =
    "states: " ++ show stts ++ "\ntransition: \n" ++
        foldMap
            (\st ->
                foldMap (\sy -> if null (trans st sy) then "" else
                    "(" ++ show st ++ ", " ++ maybe "ε" show sy ++ ") -> " ++ show (trans st sy) ++ "\n")
                    (Nothing : map Just alphabet))
            [0..stts-1]
        ++ "start: " ++ show strt ++
        "\nfinal " ++ show fnl

printNFA :: NFA -> String
printNFA (NFA stts trans strt fnl) =
    "states: " ++ show stts ++ "\ntransition: \n" ++
        foldMap
            (\st ->
                foldMap (\sy -> if null (trans st sy) then "" else
                    "(" ++ show st ++ ", " ++ show sy ++ ") -> " ++ show (trans st sy) ++ "\n")
                    alphabet)
            [0..stts-1]
        ++ "start: " ++ show strt ++
        "\nfinal " ++ show fnl

printDFA :: [Int] -> DFA -> String
printDFA ignore (DFA stts trans strt fnl) =
    "states: " ++ show stts ++ "\ntransition: \n" ++
        foldMap
            (\st ->
                foldMap (\sy -> if trans st sy `elem` ignore then "" else
                    "(" ++ show st ++ ", " ++ show sy ++ ") -> " ++ show (trans st sy) ++ "\n")
                    alphabet)
            [0..stts-1]
        ++ "start: " ++ show strt ++
        "\nfinal " ++ show fnl

getStates :: DFA -> Int
getStates (DFA s _ _ _) = s

main :: IO()
main =
    let re = "a*" in
    putStrLn (maybe "erro" (printEpsilonNFA . regEx2EpsilonNFA) (parseRegEx re))
    >> putStrLn (maybe "erro" (printNFA . removeEpsilon . regEx2EpsilonNFA) (parseRegEx re))
    >> putStrLn (maybe "erro" (printDFA [0] . nfa2DFA . removeEpsilon . regEx2EpsilonNFA) (parseRegEx re))
    >> print (maybe [] (reachableStates . nfa2DFA . removeEpsilon . regEx2EpsilonNFA) (parseRegEx re))
    >> putStrLn (maybe "erro" (printDFA [0] . removeUnreachableStates . nfa2DFA . removeEpsilon . regEx2EpsilonNFA) (parseRegEx re))
