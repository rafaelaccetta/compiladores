{-# LANGUAGE DuplicateRecordFields #-}
module Main where

import System.IO (hSetEncoding, stdout, utf8)
import Automata
import EpsilonRemoval

-- Exemplo: EpsilonNFA que reconhece a linguagem (ab)*
--
-- Estados: 0, 1, 2, 3
--   0 --a--> 1
--   1 --b--> 2
--   2 --ε--> 0    (loop: repete ab)
--   2 --ε--> 3    (aceita aqui também)
-- Estado inicial: 0
-- Estado final:   3
--
-- Nota: ε-fecho(0) = {0}, ε-fecho(2) = {0,2,3}
exampleENFA :: EpsilonNFA
exampleENFA = EpsilonNFA
    { states     = 4
    , transition = trans
    , start      = 0
    , final      = [3]
    }
  where
    trans 0 (Just 'a') = [1]
    trans 1 (Just 'b') = [2]
    trans 2 Nothing    = [0, 3]  -- transições epsilon
    trans _ _          = []

-- Função auxiliar: verifica se um NFA aceita uma string
-- (execução por conjunto de estados)
acceptsNFA :: NFA -> String -> Bool
acceptsNFA (NFA _ t s0 fs) input = any (`elem` fs) (foldl step [s0] input)
  where
    step qs c = concatMap (`t` c) qs

main :: IO ()
main = do
    hSetEncoding stdout utf8
    let nfa = removeEpsilon exampleENFA

    putStrLn "=== ε-fecho de cada estado ==="
    mapM_ (\q -> putStrLn $ "  ε-fecho(" ++ show q ++ ") = "
                           ++ show (epsilonClosure exampleENFA [q]))
          [0..3]

    putStrLn "\n=== Estados finais do NFA resultante ==="
    let NFA { final = fs } = nfa
    print fs

    putStrLn "\n=== Testes de aceitacao no NFA resultante ==="
    let testar s = putStrLn $ "  \"" ++ s ++ "\" -> " ++
                              if acceptsNFA nfa s then "ACEITA" else "REJEITA"
    testar ""      -- rejeita
    testar "ab"    -- aceita
    testar "abab"  -- aceita
    testar "a"     -- rejeita
    testar "b"     -- rejeita
    testar "aba"   -- rejeita
