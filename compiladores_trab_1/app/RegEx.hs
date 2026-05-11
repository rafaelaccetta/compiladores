module RegEx where

data RegEx = Literal Char
    | Seq RegEx RegEx
    | Union RegEx RegEx
    | Star RegEx

parseRegExAux :: String -> [RegEx] -> Maybe RegEx
parseRegExAux "" [a] = Just a

parseRegExAux ('\\':a:as) rs = parseRegExAux as (Literal a : rs)
parseRegExAux (';':as) (r1:r2:rs) = parseRegExAux as (Seq r2 r1 : rs)
parseRegExAux ('+':as) (r1:r2:rs) = parseRegExAux as (Union r2 r1 : rs)
parseRegExAux ('*':as) (r1:rs) = parseRegExAux as (Star r1 : rs)

parseRegExAux (a:as) rs = parseRegExAux as (Literal a : rs)
parseRegExAux _ _ = Nothing

parseRegEx :: String -> Maybe RegEx
parseRegEx s = parseRegExAux s []

printre :: RegEx -> String
printre (Literal a) = [a]
printre (Seq a b) = printre a ++ ";" ++ printre b
printre (Union a b) = "(" ++ printre a ++ " + " ++ printre b ++ ")"
printre (Star a)= "(" ++ printre a ++ ")" ++ "*"


main :: IO ()
main = putStrLn
    (maybe "erro" printre (parseRegEx "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+++++++++++++++++++++++++++++++++++++++++++++++++++abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*;"))
