module RegEx where


data RegEx = Empty
    | Epsilon
    | Literal Char
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

printre :: Maybe RegEx -> String
printre (Just (Literal a)) = [a]
printre (Just (Seq a b)) = printre (Just a) ++ ";" ++ printre (Just b)
printre (Just (Union a b)) = "(" ++ printre (Just a) ++ " + " ++ printre (Just b) ++ ")"
printre (Just (Star a))= "(" ++ printre (Just a) ++ ")" ++ "*"
printre _ = "erro"


main :: IO ()
main = putStrLn (printre (parseRegEx "ab;*a+*" []))
