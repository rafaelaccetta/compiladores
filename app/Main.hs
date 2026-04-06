{-# LANGUAGE DuplicateRecordFields #-}
module Main where

import System.IO (hSetEncoding, stdout, utf8)
import Automata
import EpsilonRemoval
import NFAtoDFA
import Tests (runAll)

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

main :: IO ()
main = do
    hSetEncoding stdout utf8
    let nfa = removeEpsilon exampleENFA
        dfa = nfaToDFA nfa ['a', 'b']

    putStrLn "=== e-fecho de cada estado ==="
    mapM_ (\q -> putStrLn $ "  e-fecho(" ++ show q ++ ") = "
                           ++ show (epsilonClosure exampleENFA [q]))
          [0..3]

    putStrLn "\n=== Estados finais do NFA resultante (epsilon-remocao) ==="
    let NFA _ _ _ nfaFinals = nfa
    print nfaFinals

    putStrLn "\n=== Aceitacao no NFA (epsilon-remocao) ==="
    mapM_ (\s -> putStrLn $ "  \"" ++ s ++ "\" -> " ++
                             if acceptsNFA nfa s then "ACEITA" else "REJEITA")
          ["", "ab", "abab", "a", "b", "aba"]

    putStrLn "\n=== DFA resultante (construcao de subconjuntos) ==="
    let DFA n _ _ dfaFinals = dfa
    putStrLn $ "  estados: " ++ show n
    putStrLn $ "  finais:  " ++ show dfaFinals

    putStrLn "\n=== Aceitacao no DFA ==="
    mapM_ (\s -> putStrLn $ "  \"" ++ s ++ "\" -> " ++
                             if acceptsDFA dfa s then "ACEITA" else "REJEITA")
          ["", "ab", "abab", "a", "b", "aba"]

    putStrLn ""
    runAll
