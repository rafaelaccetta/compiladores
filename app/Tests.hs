{-# LANGUAGE DuplicateRecordFields #-}
module Tests
    ( runAll
    ) where

import Automata
import EpsilonRemoval
import NFAtoDFA

-- | ε-NFA para (ab)*
--
--   0 --a--> 1
--   1 --b--> 2
--   2 --ε--> 0   (loop)
--   2 --ε--> 3   (aceita)
--   Inicial: 0  |  Final: {3}
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
    trans 2 Nothing    = [0, 3]
    trans _ _          = []

check :: Bool -> String -> String
check True  desc = "  [OK]   " ++ desc
check False desc = "  [FAIL] " ++ desc

-- ---------------------------------------------------------------------------
-- Testes: epsilonClosure
-- ---------------------------------------------------------------------------
epsilonClosureTests :: [String]
epsilonClosureTests =
    [ check (epsilonClosure exampleENFA [0]   == [0])     "e-fecho({0}) = {0}"
    , check (epsilonClosure exampleENFA [1]   == [1])     "e-fecho({1}) = {1}"
    , check (epsilonClosure exampleENFA [2]   == [0,2,3]) "e-fecho({2}) = {0,2,3}"
    , check (epsilonClosure exampleENFA [3]   == [3])     "e-fecho({3}) = {3}"
    , check (epsilonClosure exampleENFA [0,2] == [0,2,3]) "e-fecho({0,2}) = {0,2,3}"
    ]

-- ---------------------------------------------------------------------------
-- Testes: removeEpsilon
-- ---------------------------------------------------------------------------
removeEpsilonTests :: [String]
removeEpsilonTests =
    let nfa              = removeEpsilon exampleENFA
        NFA _ _ _ finals = nfa
    in  [ check (finals == [2,3])              "estados finais = {2,3}"
        , check (not (acceptsNFA nfa ""))      "rejeita \"\""
        , check (acceptsNFA nfa "ab")          "aceita \"ab\""
        , check (acceptsNFA nfa "abab")        "aceita \"abab\""
        , check (acceptsNFA nfa "ababab")      "aceita \"ababab\""
        , check (not (acceptsNFA nfa "a"))     "rejeita \"a\""
        , check (not (acceptsNFA nfa "b"))     "rejeita \"b\""
        , check (not (acceptsNFA nfa "aba"))   "rejeita \"aba\""
        , check (not (acceptsNFA nfa "ba"))    "rejeita \"ba\""
        , check (not (acceptsNFA nfa "aab"))   "rejeita \"aab\""
        ]

-- ---------------------------------------------------------------------------
-- Testes: nfaToDFA (construção de subconjuntos)
-- ---------------------------------------------------------------------------
nfaToDFATests :: [String]
nfaToDFATests =
    let nfa              = removeEpsilon exampleENFA
        dfa              = nfaToDFA nfa ['a', 'b']
        DFA n _ _ finals = dfa
    in  [ check (n == 4)                       "DFA tem 4 estados"
        , check (finals == [3])                "DFA: estados finais = {3}"
        , check (not (acceptsDFA dfa ""))      "DFA: rejeita \"\""
        , check (acceptsDFA dfa "ab")          "DFA: aceita \"ab\""
        , check (acceptsDFA dfa "abab")        "DFA: aceita \"abab\""
        , check (acceptsDFA dfa "ababab")      "DFA: aceita \"ababab\""
        , check (not (acceptsDFA dfa "a"))     "DFA: rejeita \"a\""
        , check (not (acceptsDFA dfa "b"))     "DFA: rejeita \"b\""
        , check (not (acceptsDFA dfa "aba"))   "DFA: rejeita \"aba\""
        , check (not (acceptsDFA dfa "ba"))    "DFA: rejeita \"ba\""
        , check (not (acceptsDFA dfa "aab"))   "DFA: rejeita \"aab\""
        ]

-- ---------------------------------------------------------------------------
runAll :: IO ()
runAll = do
    putStrLn "=== Testes: epsilonClosure ==="
    mapM_ putStrLn epsilonClosureTests

    putStrLn "\n=== Testes: removeEpsilon ==="
    mapM_ putStrLn removeEpsilonTests

    putStrLn "\n=== Testes: nfaToDFA (construcao de subconjuntos) ==="
    mapM_ putStrLn nfaToDFATests

    let todos   = epsilonClosureTests ++ removeEpsilonTests ++ nfaToDFATests
        total   = length todos
        ok      = length (filter (isPrefixOf "  [OK]") todos)
    putStrLn $ "\n=== Resultado: " ++ show ok ++ "/" ++ show total ++ " testes passaram ==="
  where
    isPrefixOf prefix str = take (length prefix) str == prefix
