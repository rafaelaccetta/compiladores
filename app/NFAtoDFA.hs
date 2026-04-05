{-# LANGUAGE DuplicateRecordFields #-}
module NFAtoDFA
    ( nfaToDFA
    , acceptsDFA
    , acceptsNFA
    ) where

import Data.List (nub, sort)
import Automata

-- | Verifica se um DFA aceita uma string.
acceptsDFA :: DFA -> String -> Bool
acceptsDFA (DFA _ t s0 fs) input = foldl t s0 input `elem` fs

-- | Verifica se um NFA aceita uma string (execução por conjunto de estados).
acceptsNFA :: NFA -> String -> Bool
acceptsNFA (NFA _ t s0 fs) input = any (`elem` fs) (foldl step [s0] input)
  where
    step qs c = concatMap (`t` c) qs

-- | Converte um NFA em um DFA equivalente usando construção de subconjuntos.
--
-- Algoritmo:
--   Para cada subconjunto S de estados NFA e símbolo a:
--     δ_DFA(S, a) = ⋃{ δ_NFA(q, a) | q ∈ S }
--
--   O conjunto inicial é {start_NFA}. Subconjuntos vazios representam
--   o estado morto (sem transições úteis, não-final).
--
-- Resumo: para cada estado x (subconjunto de estados NFA) e transição y,
-- analisa-se o conjunto de estados NFA em x e coletam-se todos os estados
-- alcançáveis a partir deles usando y. Esse conjunto é o estado destino de x por y.
nfaToDFA :: NFA -> [Char] -> DFA
nfaToDFA (NFA _ t s0 nfaFinals) alphabet = DFA
    { states     = length allSubsets
    , transition = dfaTransition
    , start      = 0
    , final      = dfaFinals
    }
  where
    -- Próximo conjunto de estados NFA dado um subconjunto e um símbolo
    step :: [Int] -> Char -> [Int]
    step qs c = sort $ nub $ concatMap (`t` c) qs

    -- BFS: descobre todos os subconjuntos alcançáveis a partir de {s0}
    allSubsets :: [[Int]]
    allSubsets = bfs [[s0]] [[s0]]

    bfs visited []        = visited
    bfs visited (q:queue) =
        let nexts = filter (`notElem` visited) [step q c | c <- alphabet]
        in  bfs (visited ++ nexts) (queue ++ nexts)

    -- Mapeia subconjunto de estados NFA → ID do estado DFA
    subsetId :: [Int] -> Int
    subsetId ss = case lookup ss (zip allSubsets [0..]) of
        Just i  -> i
        Nothing -> error $ "NFAtoDFA: subconjunto inalcançável: " ++ show ss

    dfaTransition :: Int -> Char -> Int
    dfaTransition q c =
        let subset = allSubsets !! q
        in  subsetId (step subset c)

    dfaFinals :: [Int]
    dfaFinals = [i | (ss, i) <- zip allSubsets [0..], any (`elem` nfaFinals) ss]
