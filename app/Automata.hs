Module Automata where

data DFA Q S = DFA
    { states :: [Q]
    , transition :: Q -> S -> Q
    , start :: Q
    , final :: [Q]
    }

data NFA Q S = NFA
    { states :: [Q]
    , transition :: Q -> S -> [Q]
    , start :: Q
    , final :: [Q]
    }

data EpsilonNFA Q S = EpsilonNFA
    { states :: [Q]
    , transition :: Q -> (Maybe S) -> [Q]
    , start :: Q
    , final :: [Q]
    }

epsilonNFA2NFA :: EpsilonNFA Q S -> NFA Q S
epsilonNFA2NFA {}