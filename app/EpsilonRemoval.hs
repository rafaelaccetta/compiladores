{-# LANGUAGE DuplicateRecordFields #-}
module EpsilonRemoval
    ( epsilonClosure
    , removeEpsilon
    ) where

import Data.List (nub, sort)
import Automata

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
