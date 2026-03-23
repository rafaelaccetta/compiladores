{-# LANGUAGE DuplicateRecordFields #-}
module Automata where

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

