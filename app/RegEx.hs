Module RegEx where

data RegEx = empty
    | epsilon
    | literal char
    | seq RegEx RegEx
    | union RegEx RegEx
    | star RegEx

