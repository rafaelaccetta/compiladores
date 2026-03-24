{-# LANGUAGE DuplicateRecordFields #-}
module Automata where
import RegEx (RegEx (Literal, Seq, Union, Star))

data DFA = DFA
    { states :: Int
    , transition :: Int -> Char -> Maybe Int
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
                    _ -> map (+ (r1_states +1 )) (r1_trans (st - r1_states - 1) sy)
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