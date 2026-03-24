module RegEx where

data RegEx = Literal Char
    | Seq RegEx RegEx
    | Union RegEx RegEx
    | Star RegEx

parseRegEx :: String -> [RegEx] -> Maybe RegEx
parseRegEx "" [a] = Just a
parseRegEx (';':as) (r1:r2:rs) = parseRegEx as (Seq r2 r1 : rs)
parseRegEx ('+':as) (r1:r2:rs) = parseRegEx as (Union r2 r1 : rs)
parseRegEx ('*':as) (r1:rs) = parseRegEx as (Star r1 : rs)

parseRegEx (a:as) rs = parseRegEx as (Literal a : rs)
parseRegEx _ _ = Nothing

printre :: RegEx -> String
printre (Literal a) = [a]
printre (Seq a b) = printre a ++ ";" ++ printre b
printre (Union a b) = "(" ++ printre a ++ " + " ++ printre b ++ ")"
printre (Star a)= "(" ++ printre a ++ ")" ++ "*"


main :: IO ()
main = putStrLn
    (maybe "erro" printre (parseRegEx "ab;*a+*" []))
