module Quests where

import Prelude
import Data.Char
import Data.List (isInfixOf)
import Data.Digest.Pure.MD5
import Data.Map (Map)
import Data.Bits
import Data.Int
import qualified Data.Map as M
import qualified Data.ByteString.Lazy.Char8 as C
import Control.Applicative hiding ((<|>))
import Control.Monad
import Text.Regex.Posix
import Text.Parsec
import Text.ParserCombinators.Parsec hiding(try)

{-# LANGUAGE OverloadedStrings #-}

-- day 1

go :: Int -> Char -> Int
go f '(' = f + 1
go f ')' = f - 1
go _ _   = error "Wrong char"

quest01 :: String -> Int
quest01 = foldl (go) 0

quest02 :: String -> Int -> Int -> Int
quest02 []     p f = p
quest02 (x:xs) p f = if nf < 0 then
                       p
                     else
                       quest02 xs (p+1) nf
                     where
                       nf = go f x

-- day 2

splitOn :: Char -> String -> [String]
splitOn c [] = []
splitOn c xs | elem c xs = (takeWhile (/=c) xs) : (splitOn c . tail . dropWhile (/=c) $ xs)
             | otherwise = [xs]

splitBoxes :: String -> [[Int]]
splitBoxes [] = []
splitBoxes xs = [ map (read) . splitOn 'x' $ line | line <- splitOn '\n' xs ]

sort :: [Int] -> [Int]
sort [] = []
sort (x:xs) = sort l ++ [x] ++ sort g
              where
                l = [ x' | x' <- xs, x' < x ]
                g = [ x' | x' <- xs, x' >= x ]

boxArea :: [Int] -> Int
boxArea []         = 0
boxArea (x:y:z:[]) = 3 * x * y + 2 * z * (x + y)
boxArea _          = error "invalid box format"

quest03 :: String -> Int
quest03 [] = 0
quest03 xs = sum . map (boxArea . sort) . splitBoxes $ xs

ribbonLength :: [Int] -> Int
ribbonLength []      = 0
ribbonLength [x,y,z] = 2 * (x + y) + x * y * z

quest04 :: String -> Int
quest04 [] = 0
quest04 xs = sum . map (ribbonLength . sort) . splitBoxes $ xs


-- day 3

goFrom :: (Int, Int) -> Char -> (Int, Int)
goFrom (x, y) '^' = (x, y + 1)
goFrom (x, y) '<' = (x - 1, y)
goFrom (x, y) '>' = (x + 1, y)
goFrom (x, y) 'v' = (x, y - 1)
goFrom (x, y) _   = error "wrong direction"

coords :: String -> [(Int, Int)]
coords = foldl (\acc c -> acc ++ [goFrom (last acc) c]) [(0, 0)]

remDups :: [(Int, Int)] -> [(Int, Int)]
remDups []     = []
remDups (x:xs) | elem x xs = remDups xs
               | otherwise = x : remDups xs


coordsRobo :: String -> [(Int, Int)]
coordsRobo = foldl (\acc c -> acc ++ [goFrom (last . init $ acc) c]) [(0, 0), (0, 0)]

quest05 :: String -> Int
quest05 = length . remDups . coords

quest06 :: String -> Int
quest06 = length . remDups . coordsRobo

-- day 4

nZeros :: Int -> String -> Bool
nZeros n = (==n) . length . takeWhile (=='0')

quest07 :: String -> Int -> Int -> Int
quest07 k n i = if nZeros n . show . md5 . C.pack $ k ++ show i
              then i
              else quest07 k n (i + 1)

-- quest08 ^^^^^^

-- day 5

vowels :: [Char]
vowels = "aeiou"

vowelsCount :: String -> Int
vowelsCount s = length [ c | c <- s, elem c vowels ]

tirsCount :: String -> Int
tirsCount s = length [ 1 | (x, y) <- zip s (tail s), x == y ]

frbdnSubs :: [String]
frbdnSubs = ["ab", "cd", "pq", "xy"]

hasFrbdnSub :: String -> Bool
hasFrbdnSub str = any (\sub -> isInfixOf sub str) frbdnSubs

quest09 :: String -> Int
quest09 ss = length [ 1 | s <- splitOn '\n' ss
                        , not . hasFrbdnSub $ s
                        , (>=3) . vowelsCount $ s
                        , (>=1) . tirsCount $ s ]

allPairs :: String -> [String]
allPairs s = [ [x, y] | (x, y) <- zip s (tail s) ]

hasReps :: Eq a => [a] -> Bool
hasReps [_]     = False
hasReps (x:xs) = elem x (tail xs) || hasReps xs

repThrOne :: String -> Bool
repThrOne [] = False
repThrOne s  = not . null $ [ () | (x, y) <- zip s (tail (tail s))
                                 , x == y ] 

quest10 :: String -> Int
quest10 ss = length [ 1 | s <- splitOn '\n' ss
                        , hasReps . allPairs $ s
                        , repThrOne s ]

-- day 6

grid :: Int -> [[Bool]]
grid n = replicate n $ replicate n False

grid' :: Int -> [[Int]]
grid' n = replicate n $ replicate n 0

parseLightRegex :: String
parseLightRegex = "(turn (on|off)|toggle) ([0-9]+,[0-9]+) through ([0-9]+,[0-9]+)"

parseLightCmd :: String -> [String]
parseLightCmd s = (\(_, _, _, r) -> r) (s =~ parseLightRegex :: (String, String, String, [String]))

turnOnLight :: Bool -> Bool
turnOnLight = \_ -> True

turnOffLight :: Bool -> Bool
turnOffLight = \_ -> False

toggleLight :: Bool -> Bool
toggleLight = not

turnOnLight' :: Int -> Int
turnOnLight' = (+) 1

turnOffLight' :: Int -> Int
turnOffLight' n = max (n - 1) 0

toggleLight' :: Int -> Int
toggleLight' = (+) 2

applyLightCmd :: (a -> a) -> [[a]] -> (Int, Int) -> (Int, Int) -> [[a]]
applyLightCmd cmd g (fx, fy) (tx, ty) =
  zipWith (\col x -> if x < fx || x > tx
                       then col
                       else zipWith (\e y -> if y < fy || y > ty
                                               then e
                                               else cmd e
                                    ) col [0..length col - 1]
          ) g [0..length g - 1]

toCoord :: String -> (Int, Int)
toCoord s = read $ "(" ++ s ++ ")"

toCmd :: String -> (Bool -> Bool)
toCmd s = case s of
               "turn on"  -> turnOnLight
               "turn off" -> turnOffLight
               "toggle"   -> toggleLight

toCmd' :: String -> (Int -> Int)
toCmd' s = case s of
               "turn on"  -> turnOnLight'
               "turn off" -> turnOffLight'
               "toggle"   -> toggleLight'

performLightCmd :: [[Bool]] -> [String] -> [[Bool]]
performLightCmd g [cmd, _, f, t] =
  applyLightCmd (toCmd cmd) g (toCoord f) (toCoord t)

performLightCmd' :: [[Int]] -> [String] -> [[Int]]
performLightCmd' g [cmd, _, f, t] =
  applyLightCmd (toCmd' cmd) g (toCoord f) (toCoord t)


quest11 :: [[Bool]] -> String -> Int
quest11 grid s =
  length . filter (==True) . concat . foldl (\g line -> performLightCmd g $ parseLightCmd line) grid . splitOn '\n' $ s


quest12 :: [[Int]] -> String -> Int
quest12 gr s =
  sum . concat . foldl (\g line -> performLightCmd' g $ parseLightCmd line) gr . splitOn '\n' $ s

-- day 7

type CWires = Map String Int

data CExpr = CApp COperator [COperand] String
             deriving (Show)

data COperator = CNot | CId | CAnd | COr | CRshift | CLshift
                 deriving (Show)

data COperand = CVal Int | CVar String
                deriving (Show)

cOperand :: CharParser st COperand
cOperand = (many1 digit >>= \x -> return (CVal (read x)))
            <|> (many1 lower >>= \w -> return (CVar w))

cOperator :: CharParser st COperator
cOperator = do o <- many1 upper
               return (case o of
                            "AND"    -> CAnd
                            "OR"     -> COr
                            "RSHIFT" -> CRshift
                            "LSHIFT" -> CLshift
                            "NOT"    -> CNot
                            otherwise -> error "Invalid operator")

cExpr :: CharParser st CExpr
cExpr = try cExprFull <|> try cExprSignal <|> try cExprNot

cExprFull :: CharParser st CExpr
cExprFull = do x <- cOperand
               space
               o <- cOperator
               space
               y <- cOperand
               space
               string "->"
               space
               w <- many1 lower
               return (CApp o [x, y] w)

cExprSignal :: CharParser st CExpr
cExprSignal = do x <- cOperand
                 space
                 string "->"
                 space
                 w <- many1 lower
                 return (CApp CId [x] w)

cExprNot :: CharParser st CExpr
cExprNot = do o <- cOperator
              space
              x <- cOperand
              space
              string "->"
              space
              w <- many1 lower
              return (CApp o [x] w)

wireVal :: COperand -> CWires -> Int
wireVal (CVal x) _ = x
wireVal (CVar s) ws = case M.lookup s ws of
                           Just x  -> x
                           Nothing -> error "Value not found"

execCExpr :: CWires -> CExpr -> CWires
execCExpr ws (CApp o xs y) =
  case o of
       CId -> M.insert y (wireVal (head xs) ws) ws
       CNot -> M.insert y ((wireVal (head xs) ws) `xor` 65535) ws
       CAnd -> M.insert y ((wireVal (head xs) ws) .&. (wireVal (head (tail xs)) ws)) ws
       COr -> M.insert y ((wireVal (head xs) ws) .|. (wireVal (head (tail xs)) ws)) ws
       CRshift -> M.insert y ((wireVal (head xs) ws) `shiftR` (wireVal (head (tail xs)) ws)) ws
       CLshift -> M.insert y ((wireVal (head xs) ws) `shiftL` (wireVal (head (tail xs)) ws)) ws

parseCExpr :: String -> CExpr
parseCExpr s =
  case parse cExpr "" s of
       Left _  -> error "Invalid expression"
       Right e -> e

cOperators :: CExpr -> [String]
cOperators (CApp _ xs _) = foldl (\a v -> case v of
                                               (CVar x)  -> x:a
                                               otherwise -> a
                                 ) [] xs

combineCircuit :: CWires -> [CExpr] -> CWires
combineCircuit ws []     = ws
combineCircuit ws (e:es) =
  if all (flip elem (M.keys ws)) (cOperators e)
    then combineCircuit (execCExpr ws e) es
    else combineCircuit ws (es ++ [e])

quest13 :: String -> CWires
quest13 =
  combineCircuit (M.empty) . map parseCExpr . splitOn '\n'

-- day 8

backSlash :: CharParser st Int
backSlash = string "\\\\" >> return 1

quote :: CharParser st Int
quote = string "\\\"" >> return 1

ascii :: CharParser st Int
ascii = string "\\x" >> count 2 hexDigit >> return 1


oneChar :: CharParser st Int
oneChar = try backSlash
          <|> try quote
          <|> try ascii
          <|> try (string "\"" >> return 0) 
          <|> (letter >> return 1)

unEscapeLength :: String -> Int
unEscapeLength s =
  case parse (many1 oneChar) "" s of
       Left _   -> error "Invalid string"
       Right ns -> sum ns

unEscape :: String -> String
unEscape = read

quest15 :: IO Int
quest15 =
  do text <- readFile "string08.txt"
     return
       $ sum . map (\s -> length s - unEscapeLength s)
       $ splitOn '\n' text

quest16 :: IO Int
quest16 =
  do text <- readFile "string08.txt"
     return
       $ sum . map (\s -> length (show s) - length s)
       $ splitOn '\n' text







string01 :: String
string01 = "()(((()))(()()()((((()(((())(()(()((((((()(()(((())))((()(((()))((())(()((()()()()(((())(((((((())))()()(()(()(())(((((()()()((())(((((()()))))()(())(((())(())((((((())())))(()())))()))))()())()())((()()((()()()()(()((((((((()()())((()()(((((()(((())((())(()))()((((()((((((((())()((()())(())((()))())((((()())(((((((((((()()(((((()(()))())(((()(()))())((()(()())())())(()(((())(())())()()(()(()((()))((()))))((((()(((()))))((((()(()(()())())()(((()((((())((((()(((()()(())()()()())((()((((((()((()()))()((()))()(()()((())))(((()(((()))((()((()(()))(((()()(()(()()()))))()()(((()(((())())))))((()(((())()(()(())((()())))((((())))(()(()(()())()((()())))(((()((()(())()()((()((())(()()((())(())()))()))((()(())()))())(((((((()(()()(()(())())))))))(()((((((())((((())((())())(()()))))()(())(()())()())((())(()))))(()))(()((()))()(()((((((()()()()((((((((()(()(())((()()(()()))(())()())()((())))()))()())(((()))(())()(())()))()((()((()(()()())(())()()()((())())))((()()(()()((()(())()()())(((()(()()))))(())))(()(()())()))()()))))))()))))((((((())))())))(()(())())(()())))))(()))()))))))()((()))))()))))(()(()((()())())(()()))))(((())()))())())())(((()(()()))(())()(())(())((((((()()))))((()(()))))))(()))())(((()()(()))()())()()()())))))))))))))(())(()))(()))((()(())(()())(())())(()())(())()()(()())))()()()))(())())()))())())(())((())))))))(())))(())))))()))))((())(()(((()))))(()))()((()(())))(()())(((((()))()())()()))))()))))()))())(()(()()()))()))))))((()))))))))))()((()))((()(())((())()()(()()))()(()))))()()(()))()))(((())))(())()((())(())(()())()())())))))))())))()((())))()))(()))()()))(((((((()))())(()()))(()()(()))()(()((()())()))))))(((()()()())))(())()))()())(()()))()()))))))))(())))()))()()))))))()))()())))()(())(())))))()(())()()(()()))))())((()))))()))))(()(((((()))))))))())))())()(())()()))))(())))())()()())()()())()(()))))()))()))))))))())))((()))()))()))())))()())()()())))())))(()((())()((()))())))))())()(())((())))))))))))())()())(())())())(()))(()))()))())(()(())())()())()()(()))))(()(())))))))(())))())(())))))))())()()(())())())))(())))))()))()(()())()(()))())())))))()()(()))()))))())))))))))()))))()))))))())()())()()))))()())))())))))))))))()()))))()()(((()))()()(())()))))((()))))(()))(())())))(())()))))))(()))()))))(())())))))()))(()())))))))))))))())))))))))()((()())(()())))))))((()))))(())(())))()(()())())))())())(()()()())))()))))))())))))())()()())))))))))))()()(()))))()())()))((()())(()))))()(()))))))))))()())())(((())(()))))())()))()))()))))))()))))))(()))))()))))()(())))(())))(()))())()()(()()))()))(()()))))))))()))(()))())(()()(()(()())()()))()))))))))(())))))((()()(()))())())))))()))())(()())()()))())))()(()()()()))((())())))())()(()()))()))))))))(()))(())))()))))(()(()())(()))))()())())()))()()))())))))))))))())()))))))()))))))))())))))()))))())(()())))(())()))())())))))()()(()()())(()())))()()))(((()))(()()()))))()))))()))))((())))()((((((()()))))))())))))))))))(((()))))))))))))(())())))))())(()))))))(()))((()))())))()(()((()))()))()))))))))))())()))()(()()))))())))())(())()(()))()))())(()))()))))(()()))()()(())))))()))(())(()(()()))(()()())))))(((()))))))()))))))))))))(())(()))))()())())()()((()()))())))))(()))))())))))))()()()))))))))())))()(((()()))(())))))(((())())))))((()))()(()))(()))))(()())))(()))())))))()))))(())(())))()((()))(())())))()()))()))))))))()))(()()()(()()()(()))())(())()())(((()))(())))))))))(((()())))()()))))))))()(())(()))()((((())(())(()())))()))(((())()()()))((()))(()))())())))())))(()))())()())())(()(())())()()()(())))())(())))(())))(())()))()))(()((()))))))))())(()))))))())(()()))()()))()(()(()())))()()(()((()((((((()))(())))()()()))())()))((()()(()))())((()(()(()))(()()))))()())))()))()())))))))()()((()())(())))()))(()))(())(()))())(()(())))()()))))))(((()(((()()))()(()(())())((()()))()))()))()))()(()()()(()))((()())()(())))()()))(((())()()())(())()((()()()()(()(())(()()))()(((((()())))((())))))(()()()))))(((()(())))()))((()((()(())()(()((())))((()())()(()))(((()())()()(()))(())(((()((()())()((())()())(((()()))((()((())(()))(()())(()()()))((()))(())(()((()()())((()))(())))(())(())(())))(()())))(((((()(()(((((()())((((()(()())(())(()()(((())((()(((()()(((()()((((((())))())(()((((((()(()))()))()()((()((()))))()(()()(()((()()))))))(((((()(((((())()()()(())())))))))()))((()()(())))(())(()()()())))))(()((((())))))))()()(((()(()(()(()(()())()()()(((((((((()()())()(()))((()()()()()(((((((()())()((())()))((((((()(()(()(()())(((()(((((((()(((())(((((((((())(())())()))((()(()))(((()()())(())(()(()()(((()(())()))())))(())((((((())(()()())()()(((()(((())(()(((())(((((((()(((((((((()))(())(()(()(()))))((()))()(())())())((()(()((()()))((()()((()(())(())(()((())(((())(((()()()((((((()()(())((((())()))))(())((()(()((())))(((((()(()()())())((())())))((())((()((()()((((((())(((()()(()())())(()(()))(()(()))())())()(((((((()(((()(())()()((())((()(()()((()(()()(((((((((((())((())((((((())((()((((()(()((((()(((((((())()((()))))())()((()((((()(()(((()((()())))(())())(((()(((())((((((()(((((((((()()(())))(()(((((()((((()())))((()((()((()(()()(((())((((((((((((()(((())(()(((((()))(()()(()()()()()()((())(((((((())(((((())))))())()(()()(()(()(((()()(((((())(()((()((()(((()()((()((((())()))()((((())(())))()())(((())(())(()()((()(((()()((((((((((()()(()())())(((((((((())((((()))()()((((())(()((((()(((())())(((((((((((()((((())))(())(()(((()(((()((())(((((()((()()(()(()()((((((()((((()((()(()((()(()((((((()))))()()(((((()((()(()(())()))(())(((((((()((((()())(()((()((()(()))())))(())((()))))(((((((()()()())(()))(()()((()())()((()((()()()(()(()()))(()())(())(((((()(((((((((((()((()(((()(((((((()()((((((()(((((()(()((()(((((())((((((()))((((())((()()((())(((())()(((((()()(((((()((()(()(((((((()(((((()((()((()((())(())((())(()))()()))(()()(()(()()(((((((()(((()(((())()(((((()((((((()())((((())()((()((()(()()())(()))((((()()((((((()((()(()(()((((()((()((())((((((()(()(())((((((()((((((((((()((())()))()(()(()(((((()()()))((())))()(()((((((((((((((()(((()((((()((())((()((()(((()()(()(((()((())(()()())))()(()(()(((((()()(()(()((((()(((((())()(()(()))(((((()()(((()()(())((((((((((((((())((())(((((((((((())()()()(())()(()(()(((((((((())(((()))(()()())(()((((()(())(((((()())(())((((((((())()((((()((((((())(()((()(())(((()((((()))(((((((((()()))((((()(())()()()(())(()((())((()()))()(((())(((((())((((((()()))(((((((((()((((((())))(((((((()((()(()(())))())(()(()))()(((((()())(()))()(()(())(((()))))())()())))(((((()))())()((()(()))))((()()()((((((()))()()((((((((())((()(()(((()(()((())((()())(()((((())(()(((()()()(()(()()))())())((((((((((())())((()))()((())(())(())))())()(()()(())))())(()))(((()(()()(((()(((())))()(((()(())()((((((())()))()))()((((((()(()(((((()())))()))))())()()(((()(((((())((()()(()((()((()(()(()(())))(()()()()((()(())(((()((()))((((()))())(())))())(()))()()()())()))(((()()())()((())))(())(()()()()(()())((()(()()((((())))((()((()(())((()(()((())()(()()(((()())()()())((()))((())(((()()(())))()()))(((()((())()(((((()())(())((())()())())((((((()(()(((((()))(()("

string02 :: String
string02 = "3x11x24\n13x5x19\n1x9x27\n24x8x21\n6x8x17\n19x18x22\n10x9x12\n12x2x5\n26x6x11\n9x23x15\n12x8x17\n13x29x10\n28x18x6\n22x28x26\n1x5x11\n29x26x12\n8x28x29\n27x4x21\n12x7x16\n7x4x23\n15x24x8\n15x14x2\n11x6x29\n28x19x9\n10x3x1\n5x20x13\n10x25x1\n22x17x7\n16x29x3\n18x22x8\n18x11x19\n21x24x20\n4x7x17\n22x27x12\n1x26x6\n5x27x24\n29x21x3\n25x30x2\n21x26x2\n10x24x27\n10x16x28\n18x16x23\n6x5x26\n19x12x20\n6x24x25\n11x20x7\n4x8x5\n2x13x11\n11x17x1\n13x24x6\n22x29x16\n4x24x20\n10x25x10\n12x29x23\n23x27x12\n11x21x9\n13x2x6\n15x30x2\n8x26x24\n24x7x30\n22x22x8\n29x27x8\n28x23x27\n13x16x14\n9x28x20\n21x4x30\n21x20x20\n11x17x30\n9x14x22\n20x2x6\n10x11x14\n1x8x23\n23x19x19\n26x10x13\n21x12x12\n25x7x24\n1x28x17\n20x23x9\n2x24x27\n20x24x29\n1x3x10\n5x20x14\n25x21x3\n15x5x22\n14x17x19\n27x3x18\n29x23x19\n14x21x19\n20x8x3\n22x27x12\n24x15x18\n9x10x19\n29x25x28\n14x22x6\n4x19x28\n4x24x14\n17x19x17\n7x19x29\n28x8x26\n7x20x16\n11x26x29\n2x18x3\n12x7x18\n11x15x21\n24x7x26\n2x22x23\n2x30x5\n1x19x8\n15x29x10\n15x26x22\n20x16x14\n25x29x22\n3x13x19\n1x12x30\n3x15x27\n19x9x11\n30x8x21\n26x12x20\n11x17x19\n17x25x1\n19x24x12\n30x6x20\n11x19x18\n18x15x29\n18x8x9\n25x15x5\n15x6x26\n13x27x19\n23x24x12\n3x15x28\n17x10x10\n15x4x7\n15x27x7\n21x8x11\n9x18x2\n7x20x20\n17x23x12\n2x19x1\n7x26x26\n13x23x8\n10x3x12\n11x1x9\n1x11x19\n25x14x26\n16x10x15\n7x6x11\n8x1x27\n20x28x17\n3x25x9\n30x7x5\n17x17x4\n23x25x27\n23x8x5\n13x11x1\n15x10x21\n22x16x1\n12x15x28\n27x18x26\n25x18x5\n21x3x27\n15x25x5\n29x27x19\n11x10x12\n22x16x21\n11x8x18\n6x10x23\n21x21x2\n13x27x28\n2x5x20\n23x16x20\n1x21x7\n22x2x13\n11x10x4\n7x3x4\n19x2x5\n21x11x1\n7x27x26\n12x4x23\n12x3x15\n25x7x4\n20x7x15\n16x5x11\n1x18x26\n11x27x10\n17x6x24\n19x13x16\n6x3x11\n4x19x18\n16x15x15\n1x11x17\n19x11x29\n18x19x1\n1x25x7\n8x22x14\n15x6x19\n5x30x18\n30x24x22\n11x16x2\n21x29x19\n20x29x11\n27x1x18\n20x5x30\n12x4x28\n3x9x30\n26x20x15\n18x25x18\n20x28x28\n21x5x3\n20x21x25\n19x27x22\n8x27x9\n1x5x15\n30x6x19\n16x5x15\n18x30x21\n4x15x8\n9x3x28\n18x15x27\n25x11x6\n17x22x15\n18x12x18\n14x30x30\n1x7x23\n27x21x12\n15x7x18\n16x17x24\n11x12x19\n18x15x21\n6x18x15\n2x21x4\n12x9x14\n19x7x25\n22x3x1\n29x19x7\n30x25x7\n6x27x27\n5x13x9\n21x4x18\n13x1x16\n11x21x25\n27x20x27\n14x25x9\n23x11x15\n22x10x26\n15x16x4\n14x16x21\n1x1x24\n17x27x3\n25x28x16\n12x2x29\n9x19x28\n12x7x17\n6x9x19\n15x14x24\n25x21x23\n26x27x25\n7x18x13\n15x10x6\n22x28x2\n15x2x14\n3x24x18\n30x22x7\n18x27x17\n29x18x7\n20x2x4\n4x20x26\n23x30x15\n5x7x3\n4x24x12\n24x30x20\n26x18x17\n6x28x3\n29x19x29\n14x10x4\n15x5x23\n12x25x4\n7x15x19\n26x21x19\n18x2x23\n19x20x3\n3x13x9\n29x21x24\n26x13x29\n30x27x4\n20x10x29\n21x18x8\n7x26x10\n29x16x21\n22x5x11\n17x15x2\n7x29x5\n6x18x15\n23x6x14\n10x30x14\n26x6x16\n24x13x25\n17x29x20\n4x27x19\n28x12x11\n23x20x3\n22x6x20\n29x9x19\n10x16x22\n30x26x4\n29x26x11\n2x11x15\n1x3x30\n30x30x29\n9x1x3\n30x13x16\n20x4x5\n23x28x11\n24x27x1\n4x25x10\n9x3x6\n14x4x15\n4x5x25\n27x14x13\n20x30x3\n28x15x25\n5x19x2\n10x24x29\n29x30x18\n30x1x25\n7x7x15\n1x13x16\n23x18x4\n1x28x8\n24x11x8\n22x26x19\n30x30x14\n2x4x13\n27x20x26\n16x20x17\n11x12x13\n28x2x17\n15x26x13\n29x15x25\n30x27x9\n2x6x25\n10x26x19\n16x8x23\n12x17x18\n26x14x22\n13x17x4\n27x27x29\n17x13x22\n9x8x3\n25x15x20\n14x13x16\n8x7x13\n12x4x21\n27x16x15\n6x14x5\n28x29x17\n23x17x25\n10x27x28\n1x28x21\n18x2x30\n25x30x16\n25x21x7\n2x3x4\n9x6x13\n19x6x10\n28x17x8\n13x24x28\n24x12x7\n5x19x5\n18x10x27\n16x1x6\n12x14x30\n1x2x28\n23x21x2\n13x3x23\n9x22x10\n10x17x2\n24x20x11\n30x6x14\n28x1x16\n24x20x1\n28x7x7\n1x24x21\n14x9x7\n22x8x15\n20x1x21\n6x3x7\n7x26x14\n5x7x28\n5x4x4\n15x7x28\n30x16x23\n7x26x2\n1x2x30\n24x28x20\n5x17x28\n4x15x20\n15x26x2\n1x3x23\n22x30x24\n9x20x16\n7x15x2\n6x21x18\n21x21x29\n29x10x10\n4x3x23\n23x2x18\n29x24x14\n29x29x16\n22x28x24\n21x18x24\n16x21x6\n3x9x22\n9x18x4\n22x9x9\n12x9x13\n18x21x14\n7x8x29\n28x28x14\n1x6x24\n11x11x3\n8x28x6\n11x16x10\n9x16x16\n6x6x19\n21x5x12\n15x17x12\n3x6x29\n19x1x26\n10x30x25\n24x26x21\n1x10x18\n6x1x16\n4x17x27\n17x11x27\n15x15x21\n14x23x1\n8x9x30\n22x22x25\n20x27x22\n12x7x9\n9x26x19\n26x25x12\n8x8x16\n28x15x10\n29x18x2\n25x22x6\n4x6x15\n12x18x4\n10x3x20\n17x28x17\n14x25x13\n14x10x3\n14x5x10\n7x7x22\n21x2x14\n1x21x5\n27x29x1\n6x20x4\n7x19x23\n28x19x27\n3x9x18\n13x17x17\n18x8x15\n26x23x17\n10x10x13\n11x5x21\n25x15x29\n6x23x24\n10x7x2\n19x10x30\n4x3x23\n22x12x6\n11x17x16\n6x8x12\n18x20x11\n6x2x2\n17x4x11\n20x23x22\n29x23x24\n25x11x21\n22x11x15\n29x3x9\n13x30x5\n17x10x12\n10x30x8\n21x16x17\n1x5x26\n22x15x16\n27x7x11\n16x8x18\n29x9x7\n25x4x17\n10x21x25\n2x19x21\n29x11x16\n18x26x21\n2x8x20\n17x29x27\n25x27x4\n14x3x14\n25x29x29\n26x18x11\n8x24x28\n7x30x24\n12x30x22\n29x20x6\n3x17x1\n6x15x14\n6x22x20\n13x26x26\n12x2x1\n7x14x12\n15x16x11\n3x21x4\n30x17x29\n9x18x27\n11x28x16\n22x3x25\n18x15x15\n2x30x12\n3x27x22\n10x8x8\n26x16x14\n15x2x29\n12x10x7\n21x20x15\n2x15x25\n4x14x13\n3x15x13\n29x8x3\n7x7x28\n15x10x24\n23x15x5\n5x7x14\n24x1x22\n1x11x13\n26x4x19\n19x16x26\n5x25x5\n17x25x14\n23x7x14\n24x6x17\n5x13x12\n20x20x5\n22x29x17\n11x17x29\n25x6x4\n29x8x16\n28x22x24\n24x23x17\n16x17x4\n17x8x25\n22x9x13\n24x4x8\n18x10x20\n21x23x21\n13x14x12\n23x26x4\n4x10x29\n2x18x18\n19x5x21\n2x27x23\n6x29x30\n21x9x20\n6x5x16\n25x10x27\n5x29x21\n24x14x19\n19x11x8\n2x28x6\n19x25x6\n27x1x11\n6x8x29\n18x25x30\n4x27x26\n8x12x1\n7x17x25\n7x14x27\n12x9x5\n14x29x13\n18x17x5\n23x1x3\n28x5x13\n3x2x26\n3x7x11\n1x8x7\n12x5x4\n2x30x21\n16x30x11\n3x26x4\n16x9x4\n11x9x22\n23x5x6\n13x20x3\n4x3x2\n14x10x29\n11x8x12\n26x15x16\n7x17x29\n18x19x18\n8x28x4\n22x6x13\n9x23x7\n11x23x20\n13x11x26\n15x30x13\n1x5x8\n5x10x24\n22x25x17\n27x20x25\n30x10x21\n16x28x24\n20x12x8\n17x25x1\n30x14x9\n14x18x6\n8x28x29\n12x18x29\n9x7x18\n6x12x25\n20x13x24\n22x3x12\n5x23x22\n8x10x17\n7x23x5\n10x26x27\n14x26x19\n10x18x24\n8x4x4\n16x15x11\n3x14x9\n18x5x30\n29x12x26\n16x13x12\n15x10x7\n18x5x26\n14x1x6\n10x8x29\n3x4x9\n19x4x23\n28x17x23\n30x7x17\n19x5x9\n26x29x28\n22x13x17\n28x2x1\n20x30x8\n15x13x21\n25x23x19\n27x23x1\n4x6x23\n29x29x24\n5x18x7\n4x6x30\n17x15x2\n27x4x2\n25x24x14\n28x8x30\n24x29x5\n14x30x14\n10x18x19\n15x26x22\n24x19x21\n29x23x27\n21x10x16\n7x4x29\n14x21x3\n21x4x28\n17x16x15\n24x7x13\n21x24x15\n25x11x16\n10x26x13\n23x20x14\n20x29x27\n14x24x14\n14x23x12\n18x6x5\n3x18x9\n8x18x19\n20x26x15\n16x14x13\n30x16x3\n17x13x4\n15x19x30\n20x3x8\n13x4x5\n12x10x15\n8x23x26\n16x8x15\n22x8x11\n12x11x18\n28x3x30\n15x8x4\n13x22x13\n21x26x21\n29x1x15\n28x9x5\n27x3x26\n22x19x30\n4x11x22\n21x27x20\n22x26x7\n19x28x20\n24x23x16\n26x12x9\n13x22x9\n5x6x23\n20x7x2\n18x26x30\n3x6x28\n24x18x13\n28x19x16\n25x21x25\n25x19x23\n22x29x10\n29x19x30\n4x7x27\n5x12x28\n8x26x6\n14x14x25\n17x17x2\n5x27x11\n8x2x2\n3x20x24\n26x10x9\n22x28x27\n18x15x20\n12x11x1\n5x14x30\n7x3x16\n2x16x16\n18x20x15\n13x14x29\n1x17x12\n13x5x23\n19x4x10\n25x19x11\n15x17x14\n1x28x27\n11x9x28\n9x10x18\n30x11x22\n21x21x20\n2x1x5\n2x25x1\n7x3x4\n22x15x29\n21x28x15\n12x12x4\n21x30x6\n15x10x7\n10x14x6\n21x26x18\n14x25x6\n9x7x11\n22x3x1\n1x16x27\n1x14x23\n2x13x8\n14x19x11\n21x26x1\n4x28x13\n12x16x20\n21x13x9\n3x4x13\n14x9x8\n21x21x12\n27x10x17\n6x20x6\n28x23x23\n2x28x12\n8x10x10\n3x9x2\n20x3x29\n19x4x16\n29x24x9\n26x20x8\n15x28x26\n18x17x10\n7x22x10\n20x15x9\n6x10x8\n7x26x21\n8x8x16\n15x6x29\n22x30x11\n18x25x8\n6x21x20\n7x23x25\n8x25x26\n11x25x27\n22x18x23\n3x2x14\n16x16x1\n15x13x11\n3x9x25\n29x25x24\n9x15x1\n12x4x1\n23x30x20\n3x1x23\n6x10x29\n28x13x24\n4x19x17\n6x6x25\n27x29x17\n12x13x2\n10x7x13\n14x15x8\n22x2x3\n27x17x19\n23x10x16\n5x9x25\n9x25x14\n11x18x6\n18x10x12\n9x4x15\n7x16x14\n17x24x10\n11x4x6\n12x9x17\n22x18x12\n6x24x24\n6x22x23\n5x17x30\n6x9x5\n17x20x10\n6x8x12\n14x17x13\n29x10x17\n22x4x5\n10x19x30\n22x29x11\n10x12x29\n21x22x26\n16x6x25\n1x26x24\n30x17x16\n27x28x5\n30x13x22\n7x26x12\n11x24x30\n1x17x25\n22x1x3\n29x24x6\n4x8x24\n13x9x20\n8x12x9\n21x25x4\n23x23x28\n5x2x19\n29x3x15\n22x1x14\n3x23x30\n8x25x3\n15x8x14\n30x14x6\n23x27x24\n19x1x2\n10x9x13\n13x8x7\n8x13x22\n5x15x20\n17x14x8\n5x11x20\n5x10x27\n24x17x19\n21x2x3\n15x30x26\n21x19x15\n2x7x23\n13x17x25\n30x15x19\n26x4x10\n2x25x8\n9x9x10\n2x25x8\n19x21x30\n17x26x12\n7x5x10\n2x22x14\n10x17x30\n1x8x5\n23x2x25\n22x29x8\n13x26x1\n26x3x30\n25x17x8\n25x18x26\n26x19x15\n8x28x10\n12x16x29\n30x6x29\n28x19x4\n27x26x18\n15x23x17\n5x21x30\n8x11x13\n2x26x7\n19x9x24\n3x22x23\n6x7x18\n4x26x30\n13x25x20\n17x3x15\n8x20x18\n23x18x23\n28x23x9\n16x3x4\n1x29x14\n20x26x22\n3x2x22\n23x8x17\n19x5x17\n21x18x20\n17x21x8\n30x28x1\n29x19x23\n12x12x11\n24x18x7\n21x18x14\n14x26x25\n9x11x3\n10x7x15\n27x6x28\n14x26x4\n28x4x1\n22x25x29\n6x26x6\n1x3x13\n26x22x12\n6x21x26\n23x4x27\n26x13x24\n5x24x28\n22x16x7\n3x27x24\n19x28x2\n11x13x9\n29x16x22\n30x10x24\n14x14x22\n22x23x16\n14x8x3\n20x5x14\n28x6x13\n3x15x25\n4x12x22\n15x12x25\n10x11x24\n7x7x6\n8x11x9\n21x10x29\n23x28x30\n8x29x26\n16x27x11\n1x10x2\n24x20x16\n7x12x28\n28x8x20\n14x10x30\n1x19x6\n4x12x20\n18x2x7\n24x18x17\n16x11x10\n1x12x22\n30x16x28\n18x12x11\n28x9x8\n23x6x17\n10x3x11\n5x12x8\n22x2x23\n9x19x14\n15x28x13\n27x20x23\n19x16x12\n19x30x15\n8x17x4\n10x22x18\n13x22x4\n3x12x19\n22x16x23\n11x8x19\n8x11x6\n7x14x7\n29x17x29\n21x8x12\n21x9x11\n20x1x27\n1x22x11\n5x28x4\n26x7x26\n30x12x18\n29x11x20\n3x12x15\n24x25x17\n14x6x11"

string03 :: String
string03 = "v>v<vvv<<vv^v<v>vv>v<<<^^^^^<<^<vv>^>v^>^>^>^>^><vvvv<^>^<<^><<<^vvvv>^>^><^v^><^<>^^>^vvv^<vv>>^>^^<>><>^>vvv>>^vv>^<><>^<v^>^>^><vv^vv^>><<^><<v>><>^<^>>vvv>v>>>v<<^<><^<v<>v>^^v^^^<^v^^>>><^>^>v<>^<>>^>^^v^><v<v>>><>v<v^v>^v<>>^><v>^<>v^>^<>^v^^^v^^>>vv<<^^><^<vvv>^>^^<^>>^^^^^v^<v>vv<>>v^v<^v^^<><^<^vv^><>><><>v>vvv^vv^^<<><<vvv><<^v^><v<>vvv^<^>vvvv^>^>>^v^<v^vv<^^v<>v>vv^<>><v<<<^v^<<><v<^<^<><^^^>^>>v>^>v^<>v><^<^<v^>^^vv<^^<>v^v^vv<>>>>v^v<>><^^v>vv^^>v^v>v<vv>>v>><v^v^v>vv>^^>^v><<vv^v^^vv<^v><^<<v<v^>vv^^^<v^>v>v^^^>><^^<v^<^>>v><vv<v^^>^^v>>v^^^<^^v>^v>><^<^<>>v<<^^vv>^^^v<^<^<v<v^^vv>^vv^>>v^><v>><<<>^vv^<^<>v^^<<<v<^>^><><v^^>>^^^<^vv<^^^>><^^v>^^v^<v^v^>^^<v>^<^v<^<<<<^<v^>v^<^^<>^^>^><<>>^v><>><^<v><^^^>>vv>^><vv>^^^^^v^vvv><><^<^>v>v^v^>^><><^<^><>v<<vv<^>><>^v^^v>^<<<>^v^>^<<v^vv<>v^<v^^vv><<v^<>>>^<v>vv>v>>>^<^>><vv<>>>>v<v>>>^v>v><>>vvv<^^><<^>^>v<^vvvv<v><vv<><^^^v^^^>v^v<>v<^^v>>><>v<v^>>v><v^>>^^<v<<<^<v<><^^v><<v^><<<<^vv<^<>^><vv<<<<^>>>^v>^v>vv>^v<>v>v<v><^>>v>>^>^><^<v^v^>^v<><><^^>^<vvvv^^<>^^^>vv^v^v>^v^^v^^v><v^<^<>><^<v>v>>vv<<v>>vvvv<vv><>>^v^>^>>v^v^<<<vv<><v<<>>>^v<<v>^^vv^><>v>^>v><<<<<<<^>^^v^<<^^>>vvv^<><>><>^^v<<vv><^^v<^^><vv>v^>>>v^v><v^v<^>v^><>v<<>v>^^v><<<<><^v^v>>^<>^<<>^<v<<>>v<<>><^<<<<^v>^<^v>v>vv<v<v<<>^>v<^<<>v^<vvvv^>v>><<v><v<>v>v>>v^vvv^^>>>v^<^<<^^<<<><v>v^<<v<<<>v<^^<><v<v^^<v>^>v>>v<>^>^^>>^v<<>v^^^>>>^vv<^v<v>^>v>^><>v^^<>^^v^^vv^<^>^<<>><<^>^v>>><<<vvvv><<><v<^v^v<vvv^<><<^<vv><v^v^v^>v>v^<vvv^><^><^<vv><>>v^>^^^<>><v^<^^^<>v<<v<^v>>>^>>v^><<>vvv><^>>v><v><>v>>^>v><<><<>^<>^^^vv><v^>v^^>>^>^<^v<v<^^<^vvvv>v<v>^>v^>^><^<vvvv><^><><<v<>v<v^><^<v^>^v^^<<<<^><^^<^><>>^v<<^<<^vv>v>>v<^<^vv>><v<vv>v<v<v>^v<>^>v<>^v<<<v>>^^v>>><vvv>v^>^v^v>^^^v<vvvv>><^>vvv^<vv^^vv><<<>v<>v>^<vvv^<^<v<v<^vv^^>>vv^<^^v^><^^^^^v<^<v<^>>>vv^v^>^<v>^<><v^<^v>>><^v^<<v<<v<>v>^v<v^v>>^^v<<v<v<<>>>vv>>^v>>^<<<<^><<<><^^>>v<>^vvvv>v^^^>^^^>^<vvvv><^^v<v<>v<^v^v<<v^^^v^<v<^v>v^^<>^>^<^v>vv<v^vv<^<<>v><<^><><^^v<<><^^><>^v>^<><<^<^^<<>vv<>^^<<^>><<<>>vvv>^>v^^v^><<^>v>^>^<^<<>v<^>vv^v^v<>vv<<v>vv<vv><^>v^<>^vv^v^<v<^>>>>v^v><^<><<>vv^<vvv^>>vvv^>v>>><^^vv<vvvv>v<^<^>>^^>^^vv>>><^v<>^v^<<>v^^^<v>^>>^<^<v>>^v<^^^<v>^v>^>>v<vv>>^<v^<<>>^>>><v>v^<<^<v>>^<<^^<>v<^v<^<>v^v>^^v<vvvv>^vv>vvv>v^<^>><v^^vv<<<^>vvvv<>>^^<>v^<><>v<^<>v<>^>v<>vv<v^v>>v<v<^<v^^v^vv^vvv><^^>v>><>>^<^^<>>^>^<v^>>vvv^v><v>>^>^>v><><<><vv^v>v<>^v<^vv^^^<>^^<<^^^v<>><v<^<^<^<^^><v^v<^>v^>vvvv>^^v^>^<v<^^^>>^<<vv^<><><^^^^<<>^<><v>vv^<><^>^^<>v^<>>>v><>vvvvv>v>v^^>^<<vvvv<>vv>>v<<^<>^^^v^<><>>^<<<v<v<>>>><><v>v<v<>>^>^^^^vv^^<<><^^<<vv<^<>v>vv<v<><<<^<<v<<<<>v<>>^<^>^>><v>v>><^^<>><<<><<><v^^v<<><^<^v<v^><^^v<<>><<<<^>v^<v>><v^><v<vvv>v^v^<v><<>>v<><<v>^<>><>>^><>v^v>v<<>v<>v^^><<>>>v<<>>>>^>v>><v<<>>>vv>v>^<^^^<>v<v>^<^^v^vvv^>vv>^<v><vvvv>^<<>vvv<<<vv>^^<^>^>>v>v<<<<<>^^vv^>>v>^<^<v^v^>^v>>v>^v<><>^<^>v>v<<<^^^v>^<<<>vvv^v^^>^>>^>v>v<>^^><>>v>^>v<<<^^^v^<v^vv>><><^<^<><vvv<v^>>^v>vv<^v<<^vv>v^<<v>v>v>^v^>^v<<^v^vv>v<v>^<<><v^>>v<>><v<<<^v<<>vvv^<vv<vvv<<>^vv^^v><^>v^vv<<v^<<^^^<^<>^^<<>v<><<v>^><>^<><<v<v^^>vv<>^<v<^<vvv>vv>v><^^v<>><^v^v><><>><v<v>vv<>>><v^^v<>><<^>>><^^^vvv<<<vv<<^v<<<>><<vv>>>>v<<<<<vv><><v>v^^<<^vv^<vv<>>vv>^<>^v^^<>^^^vv>v^^<v<><v>v<v>>^v<v<>>^<v^^><>v^^^>v^^v<vv><^>v^v^<>v>v<v<^^>>v<^^vv^v<^^^^vv<<><<^>>^^<<v^^<<^>v^>>^^^><^^>^v^v>^<<v<vv<<<v<^^^>^>>^v<>^<^>v>^>^v^<^^^<^vv<v><^^>>v<v>^>^v^>>>>^v>^^<<^<v^v<^<<v<<^><^^<v^<><v>v^<<v^^<><<>>><vv<<><>^<>>>v<<v^^^v^^<<<vv<<^<^<^vv^<><><<^^<^^>v^>^<v<>>v^v<><<v>^^v>^<^<vvv<v>v^v>>>^^<^<v^>^vv<<<v<<>^><><^<>v>>>v<v^<>v>><^^^v^^^v<^^<vv^^^>v>v<>>^^<><>v>^<v<>^>>>><>v>^v>^vv^v<vv<<^^>><v<>^>^^<v<^>^<vvv>><>^<<>>><<<><>^^<<<v<>v^>v>v<v>^^^>^>^v<<>v>vv>><<<v>^^<v><vv<<v^^>^>>^><^>v<^<^v>><^^>v<vv^^><><>^><<><>v^>v<><^^>><>^<^^v<^<<v>><v><<<^^<<v<^vv^v<>><>>>^>v<vvv^>^<><v^><^<<^vv<^v^v^v<>v^^v>v^<^>^vv^>>><<>v^vv^<>^v^><<v^v<v>v^<><>>v^v^><>v^vvv^^^<<^<<v<<v<^vv^>>v^v>^^<v<>><>v>>v^<>^>v>^>><<>v^v><^v>v>>><v<v><^<^^>vv<v><^>^<^>^^v><><v<^^v<<><^<<v^<v<<><^^vvv^v>^>^<>>vv>v^^v^^vv<^^>><v^^vv><^v>v^<<v<^v>vvv<>>^v><<>^v<<<>^><^vv><<^^<v^>v<<v>^vv<>^v>>>><<<<^^<^v>^<^^<^<^^>>^^v>^^^^v^^^<<>^^vv<<v^^><v>><^<<><>^>v<>>v^^^>^v^^v^<v^v>v>>>>>^v>^>^^<vvv^^<v^<<<v<<>v>><^^^v<<^^<v>>^<^<^><^<<v^v><<vv<^<>>v>v>^v<><<v>^>vv^v<v>v><^<v>><>^<vv<v^^^^v<^^>><<^^>v>v>^^^<>v>^v^^>vv^vv<^^>><>^>^<>v>><>^v<<v>v>^><^^^v^<vv><<^v^>v^>vv>v^<>v><vv><^v>v<><v^v^v<^v<>^v<v^<<><<v>>^v><v>^^<>vvv^>^<<v^>><^>><^<>^v<v<v<^vvv<><<^v^<v>><<<v>^<^<v>v>^vv^v>v<^^vv<<vvv^<v>><>vv^>v<<>v<vvvv>>v>^^>>><<<^>^vv>><v>^^^>v<^vv<>v<<<v<<<<v>>>>^<^^^^>v<^^<><v>v>v<v^>vv^>v>v<^>^v^<>v>>vvv>^^><^vvv>><>>>^<<^<v<>>>v^^><v<v>>^><>v<^^v^<<v><>^<>>><^v^v>>>^vvvv^<><<<v<^>>v>^v^<v<v<<^<<v^vv^v>v<v<>>v<v^<<<><v^>><^<<^>^^><v>v<^v^<^>v>^<<v>v^<>v^<>vv^<>^>^>v^>^vv<>^^<<>>v<>^v<><v^><><<<vv>v>v^>vv^><<<<v>^v<><>^^<vv>v^^v^^^<v<^^><v^v<>><v<vv>^<>>><vv<^v<<>>^><>>v<v^v^>>>v<<>v<<<<<<<^v<<^^^v<^v<>v^^<<<^<>>v^vv<v>^<^^<^^<<^>vv><^<^^v<<<^><^v<^><>v<vv^>^v^^>>><<vv^^v><^<<^<>>^>>^<<<<v^vv<>>>v>^v>><>v>>v>><>v>><^^><v>^^vv<^^<^>vv><<^>><<><v>^vvv><^v^>vvv^>>^<><^>^<<>>v^v>v<<>^>>^>v<^^<^<<>^^v<vvvvv^^^<^<>^^v>v<>^<^^<<v>v^^vvv^^v>^vv<v^>^<>v<^v^>^<v><v<<<^v<v<v^^<vvv>vv<<vv>v^<<v<^<vv><^>^><^^<^^<<v^^<v^v<v^^^^>^>vv^<>^<>^>^^<^v><<<^>vv^vv>v^v<>^^v^<^^^vvv^><v^<v^^<v<>v^<><>v>vv<^v^>>^v<^^vv>vv>^>><<<<v^^<^><>^><>>v<>>v>^v<^vv>^^>^<^<<v^>>v^v<^^v<vv<^<><^^>^^<>^^^<vv<v<<^^>^>^vv<^>><^<vvv^<>>vv^><v>v^>^vv>^>v^^<>>^v<>>v<^>^v>vv^<vv<^^>>^<v>>>>vvv>vv>^><^v<<<>^^v>v^v<^^^v^^>^><<^^>^<v>><^^^^^<v<vv<v<^<>^^<^v<^>>vv>>^v^vv<>><>^>>>^<v>^^^^><^<<<v<>^v<><vvv^<^^>vv^>>v<vvvv><v^v><^vv<^v<><vvv<vv>v<>^v^<<>>>>v^^>^vv<<vvv<^^><v><><<>v^v<^<^>><vv>^^><^>^><<><v<^v^><^<><>vv>>>>^><<^^^<^v^>^>^^>^<^><v><^^<^^<>><><v>><<<>^>^^v<>^<<<v>>vv>^>>^>^<>>vv<^^vv<>v<>^^>^v<v^^^^v<>^<v>v^v>^^^<v>v<<<^vv^><>^<v>>^^vv>v^<<^><>>vv^^^^^>v>>v<<<>^<vvv<<><><^v<^v<^>^<>^vvv>^>v><<<vv<>v>vv<v<<v>^<^^>v^v>^<^v^<<vvv^^<>^v<<^>^<><>^^<>>^^<^v^<^<v<><<^><v<>v^^>v^v^^^<^v<<^v>^>>^^^^^><<<vv^>>v^><v^^vv><>v^^<^v<^<v^^><<v>v^^^><^^^><<<<<>^<<^<>>v<<v^v^^v<<>^<vv>>><^^^<>>>>vvv>v<>>>v^v^v<^<<^>^<<>v>>^>^^><^><<^v^^<^<>v^v>vv<>>>>>>v<<><v^<v<>>^^>v<<<>^<<v><^><<^v>vv>>>><><>v^<^v><v^<<<<^v><^>v>>^^^v<^>>^>>v<<^<<>vvv>>^v<>>^v><<<^v^v<><v>^vvv<v<v>^^^<><vv^<<>vvv<v<^^v^^><v<^v<^v^<v<^>^^^>>v>^<v^>>^<><<><vv<>vv>^v^>>^<<v<^^v>v<v<vvv>><><<><vvvvv<^v<^>^^><>^<<>^v<<>>v^vv<<>^^v^v^v><^>v>v<^<<^<^>vv>^v<<^>^>>v^<<v^>v^^v^^<v^v>>><vv><<<>^v>><><v<vv<^>v<>><^v>^^v<<<<^v^vv<<<<><><^<^<^v><<^^v^<<<<<^^><^^>vv<v<^<v>v<^><><v<>vvv^<vv>v^>^>^^^v<<^<^^>vv<v^v^v>^vv^><^v^<<>v<^^>^vv<<>^<<><^>v^<<^<>v><><>v<<^^><^^^v>>v>^vv<v^>>^v^^<><<<<<^>^v^<^<^^>^vv<^>v^^v^<>v<><v>v^v>vvv><><<><>vv<vvv^v>^^>^^^<><^>^^^>v<vvvv<>vv<v<v^^>><>v<>>v^>v^^vv^>v>>><v<<<<v<^v>><^^>^v^v<v^v^^^vvv>>>vv<^>><<<^>><^<^>^<^>^>>v^<^<>^<^^<><vvv^^<>^<>>><<v>^<^<v<<><^<<^><^^>vv<>^^><v^v<vv<^<vvv<<^>v^>>v>>>v<<^vv^<><>>>^^<^v^>>^>>><<v<<^<vv><^<>^>>^v>>><^^^<<<vv<<v<v>^vv><><<>^^^<>^<vv^<^<<v>^^><vv>><>>>^>vv>^<^<>>^<^^><v>v^><v>vv><><>>><><<^^v<<^v<v>vv<><><<^v>^v<>^<^^^v^>^<^><^v>v>^v<>><^^v^^^^^<><v<>>vvv<v^^<>v>>>>^<<><^v>vv>>^^><<><><^^^<^<^<<^v>^^^><v>>>>><<v<v>v^^^<>>v<vv<^<>v^^^v<><^>v>><<><>v<^><<>>><>v>^<>>^>v^v<<<<>^<v^vv^>vv<<><v^vv<v<v<<>>>>>vv<><>^<^v>vv^<<v<^v^^<<^<<^^v^>>><<>^<>><^>>><v<>><<>^^>><<<^^^^^v>>^<<>>vvvv<^v<v^^<^>^vv<vv<>v<<<^><>>>>vv^<^v>v<^<>^v>>^<^^v^>>><>^^<^v>>v<<>vv<vvvv<>vv>^><>v^<>^<<^vv<v^^v<vvvv><^>>^v^>^^<<<^>>^^>^<^^<^<<<v^<^^v<<vv^<<^^^vv><v<vv^>v^^v<v>^^<^v<^>>><<>vv<<^><<v^v^^^v<vv>^>vv<^>>^<v<>vv>>>^>>><<v<^<>^<<<>>^<<>><^<<^^^>>v^^>v<<<>v>v>v<v<^>^<>>>^vvv><<^^<<><v<><^<v<vvv>v>>>>vv^^v<v<^<^><v>^v<<v<vv>>v>v<<<<><<>vv<><^^^<>>v<v<vvv><v^<vv^>>><v^^<>>>^^<><^<^v^><vv>>^^v>^<<v^>v>^^>^v^<v<^<v^v><>>v^^<^v^^<<>^^>v^^>><<<<^<^^v>^^v>v<<vv^^vv>^>v^<v<v><>vv>>^<v^v^<v<^>^v>v^^>vvvvv<v><<>vv>vvvvvv>>v>>^^^<v>vv^^><<v>>v^^^^v>vv>v<^v>>>>^>^><v^>^<v<vv>v>^>><v>><<>>^vv<vv^^<^^>>>>><><<^<v<><<v>^><^vv^v>>>>>v>^>^<vv>^v^>v<^v^<^<<vv<<>v<>>^vv<<>^v^v>><><<>>v^^<<>^^<v><>v<<^^<^^>^^>^<^><>>v<>>^^<^>><<<v<>>>^v^>v>v<<^^<<^>v<v^>>v^^v^^<<>^v>v><v^>v<^^>^<vv><vv^<>v<><^<<<vv<<v>v<^<<<<^^>v^v^^><<><^^^<v>v^^>>>vvv><>vv<>>^^v^v<<^>v^^v^>vv>^<<v<^<v^>^^<<v<^^>^v^^<^^v<<>>vv<^>>^><><>v>>v<>^<v^^><<>>>"

string04 :: String
string04 = "bgvyzdsv"

string05 :: String
string05 = "uxcplgxnkwbdwhrp\nsuerykeptdsutidb\ndmrtgdkaimrrwmej\nztxhjwllrckhakut\ngdnzurjbbwmgayrg\ngjdzbtrcxwprtery\nfbuqqaatackrvemm\npcjhsshoveaodyko\nlrpprussbesniilv\nmmsebhtqqjiqrusd\nvumllmrrdjgktmnb\nptsqjcfbmgwdywgi\nmmppavyjgcfebgpl\nzexyxksqrqyonhui\nnpulalteaztqqnrl\nmscqpccetkktaknl\nydssjjlfejdxrztr\njdygsbqimbxljuue\nortsthjkmlonvgci\njfjhsbxeorhgmstc\nvdrqdpojfuubjbbg\nxxxddetvrlpzsfpq\nzpjxvrmaorjpwegy\nlaxrlkntrukjcswz\npbqoungonelthcke\nniexeyzvrtrlgfzw\nzuetendekblknqng\nlyazavyoweyuvfye\ntegbldtkagfwlerf\nxckozymymezzarpy\nehydpjavmncegzfn\njlnespnckgwmkkry\nbfyetscttekoodio\nbnokwopzvsozsbmj\nqpqjhzdbuhrxsipy\nvveroinquypehnnk\nykjtxscefztrmnen\nvxlbxagsmsuuchod\npunnnfyyufkpqilx\nzibnnszmrmtissww\ncxoaaphylmlyljjz\nzpcmkcftuuesvsqw\nwcqeqynmbbarahtz\nkspontxsclmbkequ\njeomqzucrjxtypwl\nixynwoxupzybroij\nionndmdwpofvjnnq\ntycxecjvaxyovrvu\nuxdapggxzmbwrity\ncsskdqivjcdsnhpe\notflgdbzevmzkxzx\nverykrivwbrmocta\nccbdeemfnmtputjw\nsuyuuthfhlysdmhr\naigzoaozaginuxcm\nycxfnrjnrcubbmzs\nfgbqhrypnrpiizyy\ntaoxrnwdhsehywze\nechfzdbnphlwjlew\njhmomnrbfaawicda\nfywndkvhbzxxaihx\naftuyacfkdzzzpem\nyytzxsvwztlcljvb\niblbjiotoabgnvld\nkvpwzvwrsmvtdxcx\nardgckwkftcefunk\noqtivsqhcgrcmbbd\nwkaieqxdoajyvaso\nrkemicdsrtxsydvl\nsobljmgiahyqbirc\npbhvtrxajxisuivj\nggqywcbfckburdrr\ngmegczjawxtsywwq\nkgjhlwyonwhojyvq\nbpqlmxtarjthtjpn\npxfnnuyacdxyfclr\nisdbibbtrqdfuopn\nvucsgcviofwtdjcg\nywehopujowckggkg\nmzogxlhldvxytsgl\nmllyabngqmzfcubp\nuwvmejelibobdbug\nbrebtoppnwawcmxa\nfcftkhghbnznafie\nsqiizvgijmddvxxz\nqzvvjaonnxszeuar\nabekxzbqttczywvy\nbkldqqioyhrgzgjs\nlilslxsibyunueff\nktxxltqgfrnscxnx\niwdqtlipxoubonrg\ntwncehkxkhouoctj\nbdwlmbahtqtkduxz\nsmbzkuoikcyiulxq\nbjmsdkqcmnidxjsr\nicbrswapzdlzdanh\neyszxnhbjziiplgn\npdxhrkcbhzqditwb\nnfulnpvtzimbzsze\nglayzfymwffmlwhk\nbejxesxdnwdlpeup\nukssntwuqvhmsgwj\nhoccqxlxuuoomwyc\nrapztrdfxrosxcig\ncxowzhgmzerttdfq\nyzhcurqhdxhmolak\nkqgulndpxbwxesxi\nyjkgcvtytkitvxiu\nxnhfqhnnaceaqyue\nqkuqreghngfndifr\nxesxgeaucmhswnex\noccbvembjeuthryi\ndmefxmxqjncirdwj\nystmvxklmcdlsvin\npplykqlxmkdrmydq\ncbbjkpbdvjhkxnuc\nembhffzsciklnxrz\nasrsxtvsdnuhcnco\nxcbcrtcnzqedktpi\nmglwujflcnixbkvn\nmnurwhkzynhahbjp\ncekjbablkjehixtj\nkbkcmjhhipcjcwru\nusifwcsfknoviasj\nrsfgocseyeflqhku\nprgcyqrickecxlhm\nasbawplieizkavmq\nsylnsirtrxgrcono\nnzspjfovbtfkloya\nqfxmsprfytvaxgtr\nyckpentqodgzngnv\nycsfscegcexcnbwq\nkbmltycafudieyuh\ntpahmvkftilypxuf\nqivqozjrmguypuxu\ngdhbfradjuidunbk\nvxqevjncsqqnhmkl\nrpricegggcfeihst\nxucvzpprwtdpzifq\negyjcyyrrdnyhxoo\nkfbrzmbtrrwyeofp\nqpjdsocrtwzpjdkd\nreboldkprsgmmbit\nvwkrzqvvhqkensuy\nydvmssepskzzvfdp\nvqbigplejygdijuu\nmzpgnahrhxgjriqm\nuiejixjadpfsxqcv\ntosatnvnfjkqiaha\nyipuojpxfqnltclx\npcxwvgcghfpptjlf\nshrudjvvapohziaj\njdckfjdtjsszdzhj\nhgisfhcbdgvxuilk\ngytnfjmrfujnmnpp\nohflkgffnxmpwrrs\njzxajbkwwjknasjh\nxrcxfollmejrislv\ndjjlwykouhyfukob\nrittommltkbtsequ\nlpbvkxdcnlikwcxm\nvkcrjmcifhwgfpdj\ndkhjqwtggdrmcslq\nswnohthfvjvoasvt\nyrzoksmcnsagatii\nduommjnueqmdxftp\ninlvzlppdlgfmvmx\nxibilzssabuqihtq\ninkmwnvrkootrged\nldfianvyugqtemax\ngbvwtiexcuvtngti\ntemjkvgnwxrhdidc\naskbbywyyykerghp\nonezejkuwmrqdkfr\nkybekxtgartuurbq\nubzjotlasrewbbkl\nstueymlsovqgmwkh\nlhduseycrewwponi\nyohdmucunrgemqcu\nonnfbxcuhbuifbyc\nodrjkigbrsojlqbt\nimqkqqlkgmttpxtx\nsxmlkspqoluidnxw\nakaauujpxhnccleb\nxvgpghhdtpgvefnk\njdxeqxzsbqtvgvcq\nmdusenpygmerxnni\nagihtqvgkmgcbtaw\ndovxcywlyvspixad\nuulgazeyvgtxqkfz\nndhmvrwuflhktzyo\nhcaqkmrbvozaanvm\ntvfozbqavqxdqwqv\nrlkpycdzopitfbsv\ndmyjtmjbtnvnedhs\nfmwmqeigbzrxjvdu\ntwgookcelrjmczqi\ngrxosmxvzgymjdtz\nzsstljhzugqybueo\njpeapxlytnycekbd\niasykpefrwxrlvxl\nazohkkqybcnsddus\naoaekngakjsgsonx\nawsqaoswqejanotc\nsgdxmketnjmjxxcp\nylnyuloaukdrhwuy\newoqjmakifbefdib\nytjfubnexoxuevbp\newlreawvddptezdd\nvmkonztwnfgssdog\nahbpuqygcwmudyxn\nkmahpxfjximorkrh\notjbexwssgpnpccn\naewskyipyztvskkl\nurqmlaiqyfqpizje\nnrfrbedthzymfgfa\nvndwwrjrwzoltfgi\niiewevdzbortcwwe\nqiblninjkrkhzxgi\nxmvaxqruyzesifuu\nyewuzizdaucycsko\nhmasezegrhycbucy\ndwpjrmkhsmnecill\nhnffpbodtxprlhss\navmrgrwahpsvzuhm\nnksvvaswujiukzxk\nzzzapwhtffilxphu\nvwegwyjkbzsrtnol\nqurpszehmkfqwaok\niknoqtovqowthpno\nbrlmpjviuiagymek\nefxebhputzeulthq\nmzkquarxlhlvvost\nxsigcagzqbhwwgps\nqufztljyzjxgahdp\ndlfkavnhobssfxvx\nhgdpcgqxjegnhjlr\nfboomzcvvqudjfbi\nwnjuuiivaxynqhrd\nnhcgzmpujgwisguw\nwjeiacxuymuhykgk\nqmeebvxijcgdlzpf\nnmmnxsehhgsgoich\nejluaraxythbqfkl\nmdbsbwnaypvlatcj\nnnfshfibmvfqrbka\ndvckdmihzamgqpxr\nfoztgqrjbwyxvewk\nokpryqcbvorcxhoh\nfpiwsndulvtthctx\nzrbiovlmzdmibsiq\nsetwafbnnzcftutg\nnyvqghxhgkxfobdm\nenpvqadzarauhajl\ntwblhpvkazpdmhmr\nlbhlllsgswvhdesh\ntdfwkgxnqjxcvsuo\nlnvyjjbwycjbvrrb\njsxqdvmzaydbwekg\nxirbcbvwlcptuvoa\nhwnukxenilatlfsk\nkhwopjqkxprgopmd\nsljzdoviweameskw\nstkrdmxmpaijximn\nfdilorryzhmeqwkc\nmfchaaialgvoozra\ngjxhoxeqgkbknmze\nbeowovcoqnginrno\nmkgmsgwkwhizunxo\nphnhfusyoylvjdou\ncsehdlcmwepcpzmq\npgojomirzntgzohj\nfkffgyfsvwqhmboz\nmrvduasiytbzfwdn\nepzrmsifpmfaewng\nooqxnoyqrlozbbyf\nahcxfmgtedywrbnx\nibqktvqmgnirqjot\nxarssauvofdiaefn\nxradvurskwbfzrnw\nnxklmulddqcmewad\ntwichytatzoggchg\nqmgvroqwrjgcycyv\nyvezgulgrtgvyjjm\njgmcklzjdmznmuqk\nbytajdwwconasjzt\napjttucpycyghqhu\nflfejjzihodwtyup\ngmrtrwyewucyqotv\nnlohdrlymbkoenyl\nwxcmqwbrwgtmkyfe\nnjtzlceyevmisxfn\nhtbbidsfbbshmzlt\ngxhjeypjwghnrbsf\ncifcwnbtazronikv\nezvjijcjcyszwdjy\nsrffeyrvyetbecmc\nxpjefrtatrlkbkzl\nyhncvfqjcyhsxhbb\npqhcufzlcezhihpr\nqtdsfvxfqmsnzisp\ndfonzdicxxhzxkrx\nmqqqzhxkyfpofzty\ndodjadoqyxsuazxt\njjwkrlquazzjbvlm\nttosfloajukoytfb\nllateudmzxrzbqph\ncriqihrysgesmpsx\nnpszvlittbcxxknj\nqmzojrvraitrktil\ncfyoozzpwxwkwoto\ndaxohtcgvtktggfw\nvthkpkoxmiuotjaj\npkfkyobvzjeecnui\nojcjiqrfltbhcdze\nscbivhpvjkjbauun\nysowvwtzmqpjfwyp\nlaeplxlunwkfeaou\njufhcikovykwjhsa\nxrucychehzksoitr\npyaulaltjkktlfkq\noypfrblfdhwvqxcv\nzybrgxixvhchgzcf\npuoagefcmlxelvlp\nxjnhfdrsbhszfsso\nocgvzryoydaoracw\nbxpnqllmptkpeena\npziyeihxlxbbgdio\nbvtrhtlbfzmglsfc\nggpuvtseebylsrfk\npukenexjqecnivfj\njswabfbzpnhhdbpn\nenojrtwqpfziyqsv\nrjtmxudgcudefuiz\niqmjxynvtvdacffc\nuheywxlsusklitvl\nkwhxduejafdpmqdc\nrspgblenbqlmcltn\nrczhurnrqqgjutox\ndqhytibjzxkdblzl\nhpbieadydiycvfys\npucztfoqvenxiuym\nnqpfzgpblwijiprf\nltgseeblgajbvltk\nmwxukbsnapewhfrc\ndvxluiflicdtnxix\npexfbpgnqiqymxcq\ndakudfjjwtpxuzxy\nletlceyzlgmnrewu\nojktahbsdifdfhmd\nanezoybbghjudbih\nsawxtlvzysaqkbbf\nttnkctcevpjiwqua\nedrwrdvbaoqraejd\nwnbfilvuienjxlcr\nwqhzwvyybyxhhtsm\njxbgvyaqczwdlxfo\nwbypqfmbwrsvfmdv\nizdxjyfpidehbets\nvbxbggqseurknjor\negpmpoxickhvwdlz\nivfrzklvpwoemxsy\nxkziseheibmrpdww\nxnrmtoihaudozksa\nefemdmbxdsaymlrw\nyjdjeckmsrckaagx\nvlftqxxcburxnohv\nfwyquwgajaxebduj\ndwpmqvcxqwwnfkkr\nisduxxjfsluuvwga\navdtdppodpntojgf\nvrcoekdnutbnlgqk\nkbhboxjmgomizxkl\ncgsfpjrmewexgzfy\nusdtnhjxbvtnafvp\nbjoddgxbuxzhnsqd\nhoyqdzofddedevsb\nrwiwbvqfjajotaoj\niabomphsuyfptoos\nbubeonwbukprpvhy\nxurgunofmluhisxm\npuyojzdvhktawkua\ndbvqhztzdsncrxkb\noaeclqzyshuuryvm\nnmgwfssnflxvcupr\nvjkiwbpunkahtsrw\nromyflhrarxchmyo\nyecssfmetezchwjc\nqwtocacqdslhozkd\nmesexvfbtypblmam\nmtjucgtjesjppdtt\npvodhqqoeecjsvwi\nvvlcwignechiqvxj\nwiqmzmmjgjajwgov\nkwneobiiaixhclev\nlkdeglzrrxuomsyt\noqovuwcpwbghurva\nlfsdcxsasmuarwwg\nawkbafhswnfbhvck\nsztxlnmyvqsiwljg\nhozxgyxbcxjzedvs\noifkqgfqmflxvyzn\nmfvnehsajlofepib\ndelgbyfhsyhmyrfa\nuenimmwriihxoydv\nvjqutpilsztquutn\nkfebsaixycrodhvl\ncoifyqfwzlovrpaj\nxiyvdxtkqhcqfsqr\nhoidcbzsauirpkyt\nfiumhfaazfkbaglq\nfzwdormfbtkdjgfm\nfaxqrortjdeihjfv\nljhaszjklhkjvrfi\npzrxsffkuockoqyl\nimmbtokjmwyrktzn\nlzgjhyiywwnuxpfx\nvhkocmwzkfwjuzog\nghntjkszahmdzfbl\ngbcthxesvqbmzggy\noyttamhpquflojkh\nnbscpfjwzylkfbtv\nwnumxzqbltvxtbzs\njfhobjxionolnouc\nnrtxxmvqjhasigvm\nhweodfomsnlgaxnj\nlfgehftptlfyvvaj\nccoueqkocrdgwlvy\neuhgvirhsaotuhgf\npdlsanvgitjvedhd\nseokvlbhrfhswanv\npntdqaturewqczti\njkktayepxcifyurj\ndhzzbiaisozqhown\nwehtwakcmqwczpbu\nzwvozvspqmuckkcd\nefucjlrwxuhmjubr\nlzodaxuyntrnxwvp\nqdezfvpyowfpmtwd\nmizijorwrkanesva\ntxmitbiqoiryxhpz\nxhsqgobpouwnlvps\nmuixgprsknlqaele\ndisgutskxwplodra\nbmztllsugzsqefrm\nymwznyowpaaefkhm\nebfifzloswvoagqh\npkldomvvklefcicw\nziqzbbfunmcgrbtq\niuekfpbkraiwqkic\njflgjidirjapcuqo\nachsfbroyrnqnecg\nudbhouhlgjjzapzr\narerrohyhhkmwhyo\ntxyjzkqexgvzdtow\nogzrjwibvzoucrpg\nrfdftaesxdnghwhd\naxdhwmpuxelmpabo\ngtktemowbsvognac\nwkfuclilhqjzxztk\nqbwjouutzegaxhrz\nopfziwqqbwhzzqhj\npvcvcsupfwsmeacs\nxsbohvbguzsgpawn\nsczoefukwywxriwj\noqkhcqfdeaifbqoc\nvtsrholxbjkhwoln\nyuvapljnwbssfbhi\ndxdfwccqvyzeszyl\ngdbmjtonbiugitmb\nqunirtqbubxalmxr\nzzxsirhdaippnopr\nfibtndkqjfechbmq\ngqgqyjvqmfiwiyio\nihwsfkwhtzuydlzw\neygyuffeyrbbhlit\nzdlsaweqomzrhdyy\nptbgfzuvxiuuxyds\nllxlfdquvovzuqva\nwfrltggyztqtyljv\nkwipfevnbralidbm\ngbhqfbrvuseellbx\nobkbuualrzrakknv\nhlradjrwyjgfqugu\nvtqlxbyiaiorzdsp\ntedcbqoxsmbfjeyy\ncxdppfvklbdayghy\ngjnofexywmdtgeft\nldzeimbbjmgpgeax\negrwsmshbvbawvja\nvadfrjvcrdlonrkg\nmojorplakzfmzvtp\njyurlsoxhubferpo\nijwqogivvzpbegkm\ncnmetoionfxlutzg\nlawigelyhegqtyil\nmqosapvnduocctcd\neqncubmywvxgpfld\nvigfretuzppxkrfy\nncwynsziydoflllq\ncbllqinsipfknabg\nndtbvdivzlnafziq\niqrrzgzntjquzlrs\ndamkuheynobqvusp\njxctymifsqilyoxa\nylritbpusymysmrf\npaoqcuihyooaghfu\nobhpkdaibwixeepl\nigrmhawvctyfjfhd\nybekishyztlahopt\nvkbniafnlfqhhsrq\nkltdigxmbhazrywf\nufhcoyvvxqzeixpr\nklcxdcoglwmeynjt\nfunpjuvfbzcgdhgs\nakgyvyfzcpmepiuc\nzhlkgvhmjhwrfmua\nibsowtbnrsnxexuz\nvpufbqilksypwlrn\nngrintxhusvdkfib\nziuwswlbrxcxqslw\nsucledgxruugrnic\nzwnsfsyotmlpinew\noaekskxfcwwuzkor\nqjmqwaktpzhwfldu\ntmgfgqgpxaryktxo\nqfaizepgauqxvffk\naddkqofusrstpamf\nshdnwnnderkemcts\ngwfygbsugzptvena\nfpziernelahopdsj\nbkkrqbsjvyjtqfax\ngxrljlqwxghbgjox\nipfwnqaskupkmevm\nnnyoyhnqyfydqpno\nlgzltbrrzeqqtydq\nfgzxqurhtdfucheb\njvpthtudlsoivdwj\nbmlhymalgvehvxys\nfhklibetnvghlgnp\nhfcyhptxzvblvlst\ndonanindroexgrha\noqawfmslbgjqimzx\njzgehjfjukizosep\nbhlgamcjqijpvipb\njrcrdjrvsyxzidsk\nouwfwwjqezkofqck\nwrvsbnkhyzayialf\nknhivfqjxrxnafdl\nhbxbgqsqwzijlngf\nqlffukpfmnxpfiyq\nevhxlouocemdkwgk\nbaxhdrmhaukpmatw\nnwlyytsvreqaminp\nljsjjzmlsilvxgal\nonunatwxfzwlmgpk\nnjgolfwndqnwdqde\nngdgcjzxupkzzbqi\nieawycvvmvftbikq\nccyvnexuvczvtrit\nenndfwjpwjyasjvv\ntcihprzwzftaioqu\nbkztdkbrxfvfeddu\nqkvhtltdrmryzdco\nrurtxgibkeaibofs\nmjxypgscrqiglzbp\nunpkojewduprmymd\ncsqtkhjxpbzbnqog\nmednhjgbwzlhmufi\nsfrwfazygygzirwd\nijqeupbrhhpqxota\ncmhpncanwudyysyh\nwwcxbwzrplfzrwxd\njriomldifuobjpmq\nradonyagpulnnyee\nryqjwxsspbbhnptd\nyeoqpnsdhludlmzf\nqsqlkeetyalenueh\nqnnedenwsjdrcrzt\nlejkuhsllxbhfcrx\nanddbvllrrqefvke\nwdtljquijaksvdsv\nadslgvfuqqdkzvbc\nwhbccefjpcnjwhaq\nkqrfuankaibohqsg\nfyxisfwihvylgnfd\nrwqdrddghyqudcif\nsyhzowthaaiiouaf\nzjmrtgrnohxmtidu\ndeecwkfvjffxrzge\ndztmvolqxkhdscxe\ncdghcrgavygojhqn\npepqmdbjhnbugqeu\npnumdjpnddbxhieg\njzfhxeyahiagizfw\nhdkwugrhcniueyor\ngmgudeqlbmqynflu\ntoidiotdmfkxbzvm\npyymuoevoezlfkjb\netrbwuafvteqynlr\nusvytbytsecnmqtd\ndfmlizboawrhmvim\nvrbtuxvzzefedlvs\nvslcwudvasvxbnje\nxdxyvoxaubtwjoif\nmduhzhascirittdf\ncqoqdhdxgvvvxamk\ndshnfwhqjbhuznqr\nzimthfxbdmkulkjg\nluylgfmmwbptyzpj\niujpcgogshhotqrc\ncaqcyzqcumfljvsp\nsprtitjlbfpygxya\nfnconnrtnigkpykt\nirmqaqzjexdtnaph\nbbqrtoblmltvwome\nozjkzjfgnkhafbye\nhwljjxpxziqbojlw\nzahvyqyoqnqjlieb\ndptshrgpbgusyqsc\nuzlbnrwetkbkjnlm\nyccaifzmvbvwxlcc\nwilnbebdshcrrnuu\nevxnoebteifbffuq\nkhbajekbyldddzfo\nkjivdcafcyvnkojr\nwtskbixasmakxxnv\nuzmivodqzqupqkwx\nrxexcbwhiywwwwnu\nrowcapqaxjzcxwqi\nfkeytjyipaxwcbqn\npyfbntonlrunkgvq\nqiijveatlnplaifi\nltnhlialynlafknw\nurrhfpxmpjwotvdn\nxklumhfyehnqssys\ncivrvydypynjdoap\nfvbmxnfogscbbnyd\noznavyflpzzucuvg\niyshrpypfbirahqo\nqmzbfgelvpxvqecy\nxkkxaufomsjbofmk\nirlouftdmpitwvlq\ncsjoptbdorqxhnjg\nbkryeshfsaqpdztm\nguxbdqzfafsjoadl\ntgrltexgrzatzwxf\ncwsgsijqdanubxad\nxafnexgturwrzyrg\napcrsqdbsbaxocxr\npspgxnzcevmvvejk\nszephmeegvegugdt\nndjsoloeacasxjap\nbdnfksliscnirjfu\nehglacmzpcgglpux\njwweijomqfcupvzw\nyesblmmkqhbazmdu\nsjsmalypmuslzgac\nfkiqatyttlnuhdho\ntlhnyuzdocvfdihq\nngehtjmycevnybga\nobxodzcdgtrycgry\nstkyrvdfbwovawmk\nbdkhqcfrqaxhxloo\ngpvumnuoiozipnrk\njbhanddinpqhxeol\nhwkzkmbmsrvunzit\nrfuomegkxbyamjpw\nyzbljuksletipzwm\neafedkagwitzqigl\nprenqvsbotqckgwy\nspedpbwzphdrfxfz\ncmsuqwemhwixkxet\nxgdyeqbqfldvaccq\neooxgsrfsbdaolja\nkyhqylxooewrhkho\nmswieugqpoefmspt\nuszoqundysdyeqlc\nhkmjdggxefdyykbq\ndtuhjnlaliodtlvh\noalbueqbhpxoxvvx\noowxtxsoqdwhzbya\nlclajfsrpmtwvzkm\nfxmjufpqtpyazeqo\nozlmreegxhfwwwmf\nmqzrajxtxbaemrho\nnfglecsyqduhakjr\nnkxqtmasjjkpkqbp\njjfonbqimybvzeus\nvjqkhkhjlmvpwkud\nwxxhnvfhetsamzjr\npladhajujzttgmsw\ndbycgxeymodsdlhm\nqxszeuaahuoxjvwu\nadultomodzrljxve\ndmhgrbhvvpxyzwdn\nslohrlwxerpahtyp\nmngbocwyqrsrrxdb\nfacyrtflgowfvfui\nhyvazpjucgghmmxh\ntwtrvjtncmewcxit\nuejkrpvilgccfpfr\npsqvolfagjfvqkum\nnvzolslmiyavugpp\nlpjfutvtwbddtqiu\nfkjnfcdorlugmcha\neaplrvdckbcqqvhq\nxrcydhkockycburw\niswmarpwcazimqxn\nkicnnkjdppitjwrl\nvwywaekzxtmeqrsu\ndxlgesstmqaxtjta\npmeljgpkykcbujbb\nvhpknqzhgnkyeosz\njprqitpjbxkqqzmz\nfiprxgsqdfymyzdl\ndzvfwvhfjqqsifga\naeakhfalplltmgui\nfrqrchzvenhozzsu\nhsvikeyewfhsdbmy\npuedjjhvxayiwgvg\nzmsonnclfovjoewb\nbnirelcaetdyaumi\nszvudroxhcitatvf\nsccfweuyadvrjpys\nyiouqrnjzsdwyhwa\nxyjhkqbnfmjjdefz\nfjwgemkfvettucvg\naapqpwapzyjnusnr\ndytxpkvgmapdamtc\nhgocpfoxlheqpumw\ntwzuiewwxwadkegg\nqdbosnhyqmyollqy\nfclbrlkowkzzitod\nsgxnrrpwhtkjdjth\nxckvsnkvnvupmirv\nnioicfeudrjzgoas\nlcemtyohztpurwtf\noyjxhhbswvzekiqn\nidkblbyjrohxybob\nrthvloudwmktwlwh\noyzhmirzrnoytaty\nysdfhuyenpktwtks\nwxfisawdtbpsmwli\nvgmypwlezbmzeduk\nrpepcfpelvhzzxzj\nzxbovsmixfvmamnj\ncpkabmaahbnlrhiz\njvomcbqeoqrmynjj\niqdeisnegnkrkdws\nilhemlrtxdsdnirr\nfjimtscrwbfuwmpo\nlmfiylebtzwtztmx\nddouhysvomrkcpgu\nxtjwvzdhgnwwauwi\ncntzuwcumbsebwyy\nhieqvdlvnxkygeda\nhushfszxskjdrjxi\nxvdfzqblccfoxvyq\nnldnrtieteunyxnb\nvszpidfocenlhzqb\nofcuvtwhortxesoq\nbwniqemqwxlejcfq\nwkqiwdjnytjnomps\nrbadoommlmrictte\nnsmxhpothlulxivt\nbvzbfcvenskqxejr\nsdqeczmzpqqtqabq\nbjveyzniaaliatkw\nzxsqlntyjajjxytk\njkoxlerbtidsuepg\newtlibdkeqwgxnqt\nlmrshemwxrdwzrgc\nnekcdyxmftlymfir\nedaqvmulzkskzsfy\nznmvqaupykjmyebx\nximtebuxwhqpzubd\nrrlstppkknqyxlho\nuyibwcitxixjfwcr\nchrvoierkimesqmm\ndltxmwhheldvxwqe\nxfuthxjuuizanfjy\nvtiwavmxwonpkpug\nphchnujfnxewglht\nowvmetdjcynohxtw\ncbtujdrumixxatry\niirzildsfxipfipe\nsqxcscqyofohotcy\nsbubnekndkvovuqg\njzhsqqxqdrtibtcd\nmscwasyvxkhlvwbn\nbpafxtagbuxivbwz\nuhvueesygaxrqffw\ntrrxlibhtmzuwkkl\nyktkmkokmfslgkml\ngfzzzdptaktytnqg\npgqmaiwzhplnbyhg\nqjiptlkwfshunsfb\nlewvlpescsyunxck\ntywsfatykshogjas\nqtrnwjjgxdektjgi\narypcritpwijczkn\njwxvngigbhfpiubf\nupsjdctitlbqlnhf\nlvpjlrpnmdjiscrq\njvzchdrsnkgpgsti\nwuoesbwunpseyqzu\nxuqspvoshgxmrnrb\nicdawnmfnpnmyzof\nhwcwtibgpvctznuo\nbzdjrniddyamfloq\nhffkxtzuazageruv\ndeixfxjvzbitalnc\nzihsohukiqrgsnvw\nnwoondfnlgowavkg\nqnuulsywgnoillgn\nkoozejhfjyzuhviy\noetcoipohymhpump\ncizwpfczfoodwuly\njghlinczhtaxifau\nsvjejifbidnvvdvy\nrxmbsnaqhzcnbfcl\nvveubmiecvdtrket\nsbihpvrcnzjtgfep\niqbuljuxkwrlebvw\nptrhvxrpezqvmmvv\nduwzugnhktpiybjw\nlijafjnujfeflkva\ncoylvegferuuyfop\nfowsjrgammrqkkof\npgmcruaioccmbrbz\nosejwflxagwqtjoi\notqflckqgxzvtper\nslwyntdcrncktoka\nhzcdzsppcfkrblqg\njksdmmvtzkqaompg\ngalwwwgugetdohkg\nzbghtjvuikmfjuef\ndmqwcamjtlcofqib\nzbczldlfdzemxeys\nmdlqoklybhppdkwe\ntuyajhkexrrrvnlb\nylfolaubymxmkowo\nnnsyrfnoyrxswzxn\nzkhunhhhigbsslfk\nspbokzdfkbmflanz\nzmzxvrwdhiegfely\nimywhfczvmgahxwl\nfnvabvxeiqvsarqq\nyschramprctnputs\nubyjrgdzsvxzvouj\nqnvdhpptympctfer\nsmipxcntyhjpowug\nouhjibgcmotegljy\nzpflubaijjqqsptz\nfgysnxrnfnxprdmf\npbpznrexzxomzfvj\nthhzjresjpmnwtdv\nsbmokolkhvbfqmua\nsxxpdohxlezmqhhx\npevvsyqgoirixtqh\nwdxrornmhqsbfznb\nzjqziqbctxkshqcn\nnbqcwpzfwfaahylk\nbxbvkonpcxprxqjf\nxplbpqcnwzwqxheb\nprsakggmnjibrpoy\nxoguxbpnrvyqarjl\nilrgryrmgwjvpzjy\nefwrmokaoigjtrij\nyhcncebopycjzuli\ngwcmzbzaissohjgn\nlggmemwbbjuijtcf\nfkqedbfrluvkrwwl\njcbppekecevkwpuk\nonvolrckkxeyzfjt\nzzousprgrmllxboy\ncajthmamvxuesujl\nrmiozfsikufkntpg\nlvekypkwjbpddkcv\ndwaqzfnzcnabersa\npcdsskjopcqwhyis\nuabepbrrnxfbpyvx\nyxlgdomczciiunrk\nccerskfzctqxvrkz\nedvmkntljlncwhax\nxtcbwecdwygrvowo\naxqgqjqkqwrgcqot\ntyjrynolpzqwnjgj\nthrtmlegdjsuofga\nmpgoeqkzzqqugait\nemuslxgoefdjyivl\nklehpcehdznpssfb\nxfgvugyrdxolixkc\nacenyrbdwxywmwst\nyqgperajsfsamgan\ndbjxlnumrmhipquw\nhsnhirmswcenewxm\nqehqkbhmgucjjpwo\ngprjdglsbtsfzqcw\nwvqkyrkoratfmvfi\nmyhzlerupqbduqsl\ncouyazesiuhwwhht\nscxzehubxhkfejrr\ngqlitwfriqkmzqdd\npxtbmqelssoagxko\ndzhklewjqzmrfzsw\nyxgeypduywntnbji\nkwzbgzhkzbgedlfh\nvukmuyfstgmscuab\nvcmaybfvdgwnasgt\nqmybkqqdhjigzmum\ncbnuicuncvczyalu\nqdgpsdpdlgjasjqr\nkdzxqqheurupejjo\nmcatrxfchbqnxelm\nbadunwkeggdkcgco\nntaeanvcylpoqmxi\nghnyfytpzgvuokjn\nozepydixmjijdmts\nqefcfwzdhwmcyfvp\nycyktmpaqgaxqsxt\nedpizkxnsxeeebfl\nuwciveajsxxwoqyr\nrbvjkljpxtglqjsh\nnbplrskduutrptfk\nvewrbadvkseuloec\nupaotnjxquomoflx\nqfwxkinrousqywdd\nmqzxvvskslbxvyjt\noxicszyiqifoyugx\nbkitxwzjpabvhraj\nydrbyjecggynjpir\nhezyteaublxxpamq\nhxkuektnoovsehnd\ncwtbbavnhlpiknza\nqrwvkhbyasgfxwol\nqryjbohkprfazczc\nwjksnogpxracrbud\nznmsxbhliqxhvesr\ngkippedrjzmnnwkp\npklylwsnsyyxwcwg\nosdpwbxoegwaiemr\nkpslrrrljgtjiqka\nvuqkloqucpyzfxgk\nbvtdsisgvkuzghyl\nqlcayluuyvlhdfyy\nkbimqwnzanlygaya\nnvoeanlcfhczijed\nkqvcijcuobtdwvou\npmhdpcmxnprixitl\nyueilssewzabzmij\nzqxhafrvjyeyznyg\nmhdounmxkvnnsekx\nhnacyglnzicxjakg\niaxfdqibnrcjdlyl\niypoelspioegrwix\nuiqouxzmlnjxnbqt\nkslgjfmofraorvjo\nbgvotsdqcdlpkynk\nhuwcgxhvrrbvmmth\nvpqyfnkqqjacpffw\nhpjgdfovgmrzvrcl\nvbntbhbvdeszihzj\nnrbyyuviwyildzuw\nwckeoadqzsdnsbox\nxgsobwuseofxsxox\nanvhsxdshndembsd\niygmhbegrwqbqerg\nylrsnwtmdsrgsvlh\nzvvejnrarsavahvc\nyncxhmmdtxxeafby\nkekgiglblctktnes\nuoqgymsrlrwdruzc\nsaaoymtmnykusicw\nbqvcworpqimwglcp\nzbpgtheydoyzipjv\npkykzslwsjbhcvcj\njhwxxneyuuidrzvl\npafeyajcrlehmant\nklszcvtmcdeyfsmj\nledsltggvrbvlefn\nhubpbvxknepammep\ngthxhaapfpgtilal\njtfhbozlometwztj\njrhshycyenurbpwb\nfyaxbawrsievljqv\nlgfcgbenlqxqcxsd\ndhedabbwbdbpfmxp\nmxzgwhaqobyvckcm\nqboxojoykxvwexav\njcpzfjnmvguwjnum\nohpsxnspfwxkkuqe\nnyekrqjlizztwjqp\nthuynotacpxjzroj\nwymbolrlwosnbxqx\niyaqihnqvewxdtjm\nhdvdbtvfpdrejenu\ngtjscincktlwwkkf\nwtebigbaythklkbd"

string06 :: String
string06 = "turn on 887,9 through 959,629\nturn on 454,398 through 844,448\nturn off 539,243 through 559,965\nturn off 370,819 through 676,868\nturn off 145,40 through 370,997\nturn off 301,3 through 808,453\nturn on 351,678 through 951,908\ntoggle 720,196 through 897,994\ntoggle 831,394 through 904,860\ntoggle 753,664 through 970,926\nturn off 150,300 through 213,740\nturn on 141,242 through 932,871\ntoggle 294,259 through 474,326\ntoggle 678,333 through 752,957\ntoggle 393,804 through 510,976\nturn off 6,964 through 411,976\nturn off 33,572 through 978,590\nturn on 579,693 through 650,978\nturn on 150,20 through 652,719\nturn off 782,143 through 808,802\nturn off 240,377 through 761,468\nturn off 899,828 through 958,967\nturn on 613,565 through 952,659\nturn on 295,36 through 964,978\ntoggle 846,296 through 969,528\nturn off 211,254 through 529,491\nturn off 231,594 through 406,794\nturn off 169,791 through 758,942\nturn on 955,440 through 980,477\ntoggle 944,498 through 995,928\nturn on 519,391 through 605,718\ntoggle 521,303 through 617,366\nturn off 524,349 through 694,791\ntoggle 391,87 through 499,792\ntoggle 562,527 through 668,935\nturn off 68,358 through 857,453\ntoggle 815,811 through 889,828\nturn off 666,61 through 768,87\nturn on 27,501 through 921,952\nturn on 953,102 through 983,471\nturn on 277,552 through 451,723\nturn off 64,253 through 655,960\nturn on 47,485 through 734,977\nturn off 59,119 through 699,734\ntoggle 407,898 through 493,955\ntoggle 912,966 through 949,991\nturn on 479,990 through 895,990\ntoggle 390,589 through 869,766\ntoggle 593,903 through 926,943\ntoggle 358,439 through 870,528\nturn off 649,410 through 652,875\nturn on 629,834 through 712,895\ntoggle 254,555 through 770,901\ntoggle 641,832 through 947,850\nturn on 268,448 through 743,777\nturn off 512,123 through 625,874\nturn off 498,262 through 930,811\nturn off 835,158 through 886,242\ntoggle 546,310 through 607,773\nturn on 501,505 through 896,909\nturn off 666,796 through 817,924\ntoggle 987,789 through 993,809\ntoggle 745,8 through 860,693\ntoggle 181,983 through 731,988\nturn on 826,174 through 924,883\nturn on 239,228 through 843,993\nturn on 205,613 through 891,667\ntoggle 867,873 through 984,896\nturn on 628,251 through 677,681\ntoggle 276,956 through 631,964\nturn on 78,358 through 974,713\nturn on 521,360 through 773,597\nturn off 963,52 through 979,502\nturn on 117,151 through 934,622\ntoggle 237,91 through 528,164\nturn on 944,269 through 975,453\ntoggle 979,460 through 988,964\nturn off 440,254 through 681,507\ntoggle 347,100 through 896,785\nturn off 329,592 through 369,985\nturn on 931,960 through 979,985\ntoggle 703,3 through 776,36\ntoggle 798,120 through 908,550\nturn off 186,605 through 914,709\nturn off 921,725 through 979,956\ntoggle 167,34 through 735,249\nturn on 726,781 through 987,936\ntoggle 720,336 through 847,756\nturn on 171,630 through 656,769\nturn off 417,276 through 751,500\ntoggle 559,485 through 584,534\nturn on 568,629 through 690,873\ntoggle 248,712 through 277,988\ntoggle 345,594 through 812,723\nturn off 800,108 through 834,618\nturn off 967,439 through 986,869\nturn on 842,209 through 955,529\nturn on 132,653 through 357,696\nturn on 817,38 through 973,662\nturn off 569,816 through 721,861\nturn on 568,429 through 945,724\nturn on 77,458 through 844,685\nturn off 138,78 through 498,851\nturn on 136,21 through 252,986\nturn off 2,460 through 863,472\nturn on 172,81 through 839,332\nturn on 123,216 through 703,384\nturn off 879,644 through 944,887\ntoggle 227,491 through 504,793\ntoggle 580,418 through 741,479\ntoggle 65,276 through 414,299\ntoggle 482,486 through 838,931\nturn off 557,768 through 950,927\nturn off 615,617 through 955,864\nturn on 859,886 through 923,919\nturn on 391,330 through 499,971\ntoggle 521,835 through 613,847\nturn on 822,787 through 989,847\nturn on 192,142 through 357,846\nturn off 564,945 through 985,945\nturn off 479,361 through 703,799\ntoggle 56,481 through 489,978\nturn off 632,991 through 774,998\ntoggle 723,526 through 945,792\nturn on 344,149 through 441,640\ntoggle 568,927 through 624,952\nturn on 621,784 through 970,788\ntoggle 665,783 through 795,981\ntoggle 386,610 through 817,730\ntoggle 440,399 through 734,417\ntoggle 939,201 through 978,803\nturn off 395,883 through 554,929\nturn on 340,309 through 637,561\nturn off 875,147 through 946,481\nturn off 945,837 through 957,922\nturn off 429,982 through 691,991\ntoggle 227,137 through 439,822\ntoggle 4,848 through 7,932\nturn off 545,146 through 756,943\nturn on 763,863 through 937,994\nturn on 232,94 through 404,502\nturn off 742,254 through 930,512\nturn on 91,931 through 101,942\ntoggle 585,106 through 651,425\nturn on 506,700 through 567,960\nturn off 548,44 through 718,352\nturn off 194,827 through 673,859\nturn off 6,645 through 509,764\nturn off 13,230 through 821,361\nturn on 734,629 through 919,631\ntoggle 788,552 through 957,972\ntoggle 244,747 through 849,773\nturn off 162,553 through 276,887\nturn off 569,577 through 587,604\nturn off 799,482 through 854,956\nturn on 744,535 through 909,802\ntoggle 330,641 through 396,986\nturn off 927,458 through 966,564\ntoggle 984,486 through 986,913\ntoggle 519,682 through 632,708\nturn on 984,977 through 989,986\ntoggle 766,423 through 934,495\nturn on 17,509 through 947,718\nturn on 413,783 through 631,903\nturn on 482,370 through 493,688\nturn on 433,859 through 628,938\nturn off 769,549 through 945,810\nturn on 178,853 through 539,941\nturn off 203,251 through 692,433\nturn off 525,638 through 955,794\nturn on 169,70 through 764,939\ntoggle 59,352 through 896,404\ntoggle 143,245 through 707,320\nturn off 103,35 through 160,949\ntoggle 496,24 through 669,507\nturn off 581,847 through 847,903\nturn on 689,153 through 733,562\nturn on 821,487 through 839,699\nturn on 837,627 through 978,723\ntoggle 96,748 through 973,753\ntoggle 99,818 through 609,995\nturn on 731,193 through 756,509\nturn off 622,55 through 813,365\nturn on 456,490 through 576,548\nturn on 48,421 through 163,674\nturn off 853,861 through 924,964\nturn off 59,963 through 556,987\nturn on 458,710 through 688,847\ntoggle 12,484 through 878,562\nturn off 241,964 through 799,983\nturn off 434,299 through 845,772\ntoggle 896,725 through 956,847\nturn on 740,289 through 784,345\nturn off 395,840 through 822,845\nturn on 955,224 through 996,953\nturn off 710,186 through 957,722\nturn off 485,949 through 869,985\nturn on 848,209 through 975,376\ntoggle 221,241 through 906,384\nturn on 588,49 through 927,496\nturn on 273,332 through 735,725\nturn on 505,962 through 895,962\ntoggle 820,112 through 923,143\nturn on 919,792 through 978,982\ntoggle 489,461 through 910,737\nturn off 202,642 through 638,940\nturn off 708,953 through 970,960\ntoggle 437,291 through 546,381\nturn on 409,358 through 837,479\nturn off 756,279 through 870,943\nturn off 154,657 through 375,703\nturn off 524,622 through 995,779\ntoggle 514,221 through 651,850\ntoggle 808,464 through 886,646\ntoggle 483,537 through 739,840\ntoggle 654,769 through 831,825\nturn off 326,37 through 631,69\nturn off 590,570 through 926,656\nturn off 881,913 through 911,998\nturn on 996,102 through 998,616\nturn off 677,503 through 828,563\nturn on 860,251 through 877,441\nturn off 964,100 through 982,377\ntoggle 888,403 through 961,597\nturn off 632,240 through 938,968\ntoggle 731,176 through 932,413\nturn on 5,498 through 203,835\nturn on 819,352 through 929,855\ntoggle 393,813 through 832,816\ntoggle 725,689 through 967,888\nturn on 968,950 through 969,983\nturn off 152,628 through 582,896\nturn off 165,844 through 459,935\nturn off 882,741 through 974,786\nturn off 283,179 through 731,899\ntoggle 197,366 through 682,445\nturn on 106,309 through 120,813\ntoggle 950,387 through 967,782\nturn off 274,603 through 383,759\nturn off 155,665 through 284,787\ntoggle 551,871 through 860,962\nturn off 30,826 through 598,892\ntoggle 76,552 through 977,888\nturn on 938,180 through 994,997\ntoggle 62,381 through 993,656\ntoggle 625,861 through 921,941\nturn on 685,311 through 872,521\nturn on 124,934 through 530,962\nturn on 606,379 through 961,867\nturn off 792,735 through 946,783\nturn on 417,480 through 860,598\ntoggle 178,91 through 481,887\nturn off 23,935 through 833,962\ntoggle 317,14 through 793,425\nturn on 986,89 through 999,613\nturn off 359,201 through 560,554\nturn off 729,494 through 942,626\nturn on 204,143 through 876,610\ntoggle 474,97 through 636,542\nturn off 902,924 through 976,973\nturn off 389,442 through 824,638\nturn off 622,863 through 798,863\nturn on 840,622 through 978,920\ntoggle 567,374 through 925,439\nturn off 643,319 through 935,662\ntoggle 185,42 through 294,810\nturn on 47,124 through 598,880\ntoggle 828,303 through 979,770\nturn off 174,272 through 280,311\nturn off 540,50 through 880,212\nturn on 141,994 through 221,998\nturn on 476,695 through 483,901\nturn on 960,216 through 972,502\ntoggle 752,335 through 957,733\nturn off 419,713 through 537,998\ntoggle 772,846 through 994,888\nturn on 881,159 through 902,312\nturn off 537,651 through 641,816\ntoggle 561,947 through 638,965\nturn on 368,458 through 437,612\nturn on 290,149 through 705,919\nturn on 711,918 through 974,945\ntoggle 916,242 through 926,786\ntoggle 522,272 through 773,314\nturn on 432,897 through 440,954\nturn off 132,169 through 775,380\ntoggle 52,205 through 693,747\ntoggle 926,309 through 976,669\nturn off 838,342 through 938,444\nturn on 144,431 through 260,951\ntoggle 780,318 through 975,495\nturn off 185,412 through 796,541\nturn on 879,548 through 892,860\nturn on 294,132 through 460,338\nturn on 823,500 through 899,529\nturn off 225,603 through 483,920\ntoggle 717,493 through 930,875\ntoggle 534,948 through 599,968\nturn on 522,730 through 968,950\nturn off 102,229 through 674,529"

string07 :: String
string07 = "bn RSHIFT 2 -> bo\nlf RSHIFT 1 -> ly\nfo RSHIFT 3 -> fq\ncj OR cp -> cq\nfo OR fz -> ga\nt OR s -> u\nlx -> a\nNOT ax -> ay\nhe RSHIFT 2 -> hf\nlf OR lq -> lr\nlr AND lt -> lu\ndy OR ej -> ek\n1 AND cx -> cy\nhb LSHIFT 1 -> hv\n1 AND bh -> bi\nih AND ij -> ik\nc LSHIFT 1 -> t\nea AND eb -> ed\nkm OR kn -> ko\nNOT bw -> bx\nci OR ct -> cu\nNOT p -> q\nlw OR lv -> lx\nNOT lo -> lp\nfp OR fv -> fw\no AND q -> r\ndh AND dj -> dk\nap LSHIFT 1 -> bj\nbk LSHIFT 1 -> ce\nNOT ii -> ij\ngh OR gi -> gj\nkk RSHIFT 1 -> ld\nlc LSHIFT 1 -> lw\nlb OR la -> lc\n1 AND am -> an\ngn AND gp -> gq\nlf RSHIFT 3 -> lh\ne OR f -> g\nlg AND lm -> lo\nci RSHIFT 1 -> db\ncf LSHIFT 1 -> cz\nbn RSHIFT 1 -> cg\net AND fe -> fg\nis OR it -> iu\nkw AND ky -> kz\nck AND cl -> cn\nbj OR bi -> bk\ngj RSHIFT 1 -> hc\niu AND jf -> jh\nNOT bs -> bt\nkk OR kv -> kw\nks AND ku -> kv\nhz OR ik -> il\nb RSHIFT 1 -> v\niu RSHIFT 1 -> jn\nfo RSHIFT 5 -> fr\nbe AND bg -> bh\nga AND gc -> gd\nhf OR hl -> hm\nld OR le -> lf\nas RSHIFT 5 -> av\nfm OR fn -> fo\nhm AND ho -> hp\nlg OR lm -> ln\nNOT kx -> ky\nkk RSHIFT 3 -> km\nek AND em -> en\nNOT ft -> fu\nNOT jh -> ji\njn OR jo -> jp\ngj AND gu -> gw\nd AND j -> l\net RSHIFT 1 -> fm\njq OR jw -> jx\nep OR eo -> eq\nlv LSHIFT 15 -> lz\nNOT ey -> ez\njp RSHIFT 2 -> jq\neg AND ei -> ej\nNOT dm -> dn\njp AND ka -> kc\nas AND bd -> bf\nfk OR fj -> fl\ndw OR dx -> dy\nlj AND ll -> lm\nec AND ee -> ef\nfq AND fr -> ft\nNOT kp -> kq\nki OR kj -> kk\ncz OR cy -> da\nas RSHIFT 3 -> au\nan LSHIFT 15 -> ar\nfj LSHIFT 15 -> fn\n1 AND fi -> fj\nhe RSHIFT 1 -> hx\nlf RSHIFT 2 -> lg\nkf LSHIFT 15 -> kj\ndz AND ef -> eh\nib OR ic -> id\nlf RSHIFT 5 -> li\nbp OR bq -> br\nNOT gs -> gt\nfo RSHIFT 1 -> gh\nbz AND cb -> cc\nea OR eb -> ec\nlf AND lq -> ls\nNOT l -> m\nhz RSHIFT 3 -> ib\nNOT di -> dj\nNOT lk -> ll\njp RSHIFT 3 -> jr\njp RSHIFT 5 -> js\nNOT bf -> bg\ns LSHIFT 15 -> w\neq LSHIFT 1 -> fk\njl OR jk -> jm\nhz AND ik -> im\ndz OR ef -> eg\n1 AND gy -> gz\nla LSHIFT 15 -> le\nbr AND bt -> bu\nNOT cn -> co\nv OR w -> x\nd OR j -> k\n1 AND gd -> ge\nia OR ig -> ih\nNOT go -> gp\nNOT ed -> ee\njq AND jw -> jy\net OR fe -> ff\naw AND ay -> az\nff AND fh -> fi\nir LSHIFT 1 -> jl\ngg LSHIFT 1 -> ha\nx RSHIFT 2 -> y\ndb OR dc -> dd\nbl OR bm -> bn\nib AND ic -> ie\nx RSHIFT 3 -> z\nlh AND li -> lk\nce OR cd -> cf\nNOT bb -> bc\nhi AND hk -> hl\nNOT gb -> gc\n1 AND r -> s\nfw AND fy -> fz\nfb AND fd -> fe\n1 AND en -> eo\nz OR aa -> ab\nbi LSHIFT 15 -> bm\nhg OR hh -> hi\nkh LSHIFT 1 -> lb\ncg OR ch -> ci\n1 AND kz -> la\ngf OR ge -> gg\ngj RSHIFT 2 -> gk\ndd RSHIFT 2 -> de\nNOT ls -> lt\nlh OR li -> lj\njr OR js -> jt\nau AND av -> ax\n0 -> c\nhe AND hp -> hr\nid AND if -> ig\net RSHIFT 5 -> ew\nbp AND bq -> bs\ne AND f -> h\nly OR lz -> ma\n1 AND lu -> lv\nNOT jd -> je\nha OR gz -> hb\ndy RSHIFT 1 -> er\niu RSHIFT 2 -> iv\nNOT hr -> hs\nas RSHIFT 1 -> bl\nkk RSHIFT 2 -> kl\nb AND n -> p\nln AND lp -> lq\ncj AND cp -> cr\ndl AND dn -> do\nci RSHIFT 2 -> cj\nas OR bd -> be\nge LSHIFT 15 -> gi\nhz RSHIFT 5 -> ic\ndv LSHIFT 1 -> ep\nkl OR kr -> ks\ngj OR gu -> gv\nhe RSHIFT 5 -> hh\nNOT fg -> fh\nhg AND hh -> hj\nb OR n -> o\njk LSHIFT 15 -> jo\ngz LSHIFT 15 -> hd\ncy LSHIFT 15 -> dc\nkk RSHIFT 5 -> kn\nci RSHIFT 3 -> ck\nat OR az -> ba\niu RSHIFT 3 -> iw\nko AND kq -> kr\nNOT eh -> ei\naq OR ar -> as\niy AND ja -> jb\ndd RSHIFT 3 -> df\nbn RSHIFT 3 -> bp\n1 AND cc -> cd\nat AND az -> bb\nx OR ai -> aj\nkk AND kv -> kx\nao OR an -> ap\ndy RSHIFT 3 -> ea\nx RSHIFT 1 -> aq\neu AND fa -> fc\nkl AND kr -> kt\nia AND ig -> ii\ndf AND dg -> di\nNOT fx -> fy\nk AND m -> n\nbn RSHIFT 5 -> bq\nkm AND kn -> kp\ndt LSHIFT 15 -> dx\nhz RSHIFT 2 -> ia\naj AND al -> am\ncd LSHIFT 15 -> ch\nhc OR hd -> he\nhe RSHIFT 3 -> hg\nbn OR by -> bz\nNOT kt -> ku\nz AND aa -> ac\nNOT ak -> al\ncu AND cw -> cx\nNOT ie -> if\ndy RSHIFT 2 -> dz\nip LSHIFT 15 -> it\nde OR dk -> dl\nau OR av -> aw\njg AND ji -> jj\nci AND ct -> cv\ndy RSHIFT 5 -> eb\nhx OR hy -> hz\neu OR fa -> fb\ngj RSHIFT 3 -> gl\nfo AND fz -> gb\n1 AND jj -> jk\njp OR ka -> kb\nde AND dk -> dm\nex AND ez -> fa\ndf OR dg -> dh\niv OR jb -> jc\nx RSHIFT 5 -> aa\nNOT hj -> hk\nNOT im -> in\nfl LSHIFT 1 -> gf\nhu LSHIFT 15 -> hy\niq OR ip -> ir\niu RSHIFT 5 -> ix\nNOT fc -> fd\nNOT el -> em\nck OR cl -> cm\net RSHIFT 3 -> ev\nhw LSHIFT 1 -> iq\nci RSHIFT 5 -> cl\niv AND jb -> jd\ndd RSHIFT 5 -> dg\nas RSHIFT 2 -> at\nNOT jy -> jz\naf AND ah -> ai\n1 AND ds -> dt\njx AND jz -> ka\nda LSHIFT 1 -> du\nfs AND fu -> fv\njp RSHIFT 1 -> ki\niw AND ix -> iz\niw OR ix -> iy\neo LSHIFT 15 -> es\nev AND ew -> ey\nba AND bc -> bd\nfp AND fv -> fx\njc AND je -> jf\net RSHIFT 2 -> eu\nkg OR kf -> kh\niu OR jf -> jg\ner OR es -> et\nfo RSHIFT 2 -> fp\nNOT ca -> cb\nbv AND bx -> by\nu LSHIFT 1 -> ao\ncm AND co -> cp\ny OR ae -> af\nbn AND by -> ca\n1 AND ke -> kf\njt AND jv -> jw\nfq OR fr -> fs\ndy AND ej -> el\nNOT kc -> kd\nev OR ew -> ex\ndd OR do -> dp\nNOT cv -> cw\ngr AND gt -> gu\ndd RSHIFT 1 -> dw\nNOT gw -> gx\nNOT iz -> ja\n1 AND io -> ip\nNOT ag -> ah\nb RSHIFT 5 -> f\nNOT cr -> cs\nkb AND kd -> ke\njr AND js -> ju\ncq AND cs -> ct\nil AND in -> io\nNOT ju -> jv\ndu OR dt -> dv\ndd AND do -> dq\nb RSHIFT 2 -> d\njm LSHIFT 1 -> kg\nNOT dq -> dr\nbo OR bu -> bv\ngk OR gq -> gr\nhe OR hp -> hq\nNOT h -> i\nhf AND hl -> hn\ngv AND gx -> gy\nx AND ai -> ak\nbo AND bu -> bw\nhq AND hs -> ht\nhz RSHIFT 1 -> is\ngj RSHIFT 5 -> gm\ng AND i -> j\ngk AND gq -> gs\ndp AND dr -> ds\nb RSHIFT 3 -> e\ngl AND gm -> go\ngl OR gm -> gn\ny AND ae -> ag\nhv OR hu -> hw\n1674 -> b\nab AND ad -> ae\nNOT ac -> ad\n1 AND ht -> hu\nNOT hn -> ho"
string07' :: String
string07' = "bn RSHIFT 2 -> bo\nlf RSHIFT 1 -> ly\nfo RSHIFT 3 -> fq\ncj OR cp -> cq\nfo OR fz -> ga\nt OR s -> u\nlx -> a\nNOT ax -> ay\nhe RSHIFT 2 -> hf\nlf OR lq -> lr\nlr AND lt -> lu\ndy OR ej -> ek\n1 AND cx -> cy\nhb LSHIFT 1 -> hv\n1 AND bh -> bi\nih AND ij -> ik\nc LSHIFT 1 -> t\nea AND eb -> ed\nkm OR kn -> ko\nNOT bw -> bx\nci OR ct -> cu\nNOT p -> q\nlw OR lv -> lx\nNOT lo -> lp\nfp OR fv -> fw\no AND q -> r\ndh AND dj -> dk\nap LSHIFT 1 -> bj\nbk LSHIFT 1 -> ce\nNOT ii -> ij\ngh OR gi -> gj\nkk RSHIFT 1 -> ld\nlc LSHIFT 1 -> lw\nlb OR la -> lc\n1 AND am -> an\ngn AND gp -> gq\nlf RSHIFT 3 -> lh\ne OR f -> g\nlg AND lm -> lo\nci RSHIFT 1 -> db\ncf LSHIFT 1 -> cz\nbn RSHIFT 1 -> cg\net AND fe -> fg\nis OR it -> iu\nkw AND ky -> kz\nck AND cl -> cn\nbj OR bi -> bk\ngj RSHIFT 1 -> hc\niu AND jf -> jh\nNOT bs -> bt\nkk OR kv -> kw\nks AND ku -> kv\nhz OR ik -> il\nb RSHIFT 1 -> v\niu RSHIFT 1 -> jn\nfo RSHIFT 5 -> fr\nbe AND bg -> bh\nga AND gc -> gd\nhf OR hl -> hm\nld OR le -> lf\nas RSHIFT 5 -> av\nfm OR fn -> fo\nhm AND ho -> hp\nlg OR lm -> ln\nNOT kx -> ky\nkk RSHIFT 3 -> km\nek AND em -> en\nNOT ft -> fu\nNOT jh -> ji\njn OR jo -> jp\ngj AND gu -> gw\nd AND j -> l\net RSHIFT 1 -> fm\njq OR jw -> jx\nep OR eo -> eq\nlv LSHIFT 15 -> lz\nNOT ey -> ez\njp RSHIFT 2 -> jq\neg AND ei -> ej\nNOT dm -> dn\njp AND ka -> kc\nas AND bd -> bf\nfk OR fj -> fl\ndw OR dx -> dy\nlj AND ll -> lm\nec AND ee -> ef\nfq AND fr -> ft\nNOT kp -> kq\nki OR kj -> kk\ncz OR cy -> da\nas RSHIFT 3 -> au\nan LSHIFT 15 -> ar\nfj LSHIFT 15 -> fn\n1 AND fi -> fj\nhe RSHIFT 1 -> hx\nlf RSHIFT 2 -> lg\nkf LSHIFT 15 -> kj\ndz AND ef -> eh\nib OR ic -> id\nlf RSHIFT 5 -> li\nbp OR bq -> br\nNOT gs -> gt\nfo RSHIFT 1 -> gh\nbz AND cb -> cc\nea OR eb -> ec\nlf AND lq -> ls\nNOT l -> m\nhz RSHIFT 3 -> ib\nNOT di -> dj\nNOT lk -> ll\njp RSHIFT 3 -> jr\njp RSHIFT 5 -> js\nNOT bf -> bg\ns LSHIFT 15 -> w\neq LSHIFT 1 -> fk\njl OR jk -> jm\nhz AND ik -> im\ndz OR ef -> eg\n1 AND gy -> gz\nla LSHIFT 15 -> le\nbr AND bt -> bu\nNOT cn -> co\nv OR w -> x\nd OR j -> k\n1 AND gd -> ge\nia OR ig -> ih\nNOT go -> gp\nNOT ed -> ee\njq AND jw -> jy\net OR fe -> ff\naw AND ay -> az\nff AND fh -> fi\nir LSHIFT 1 -> jl\ngg LSHIFT 1 -> ha\nx RSHIFT 2 -> y\ndb OR dc -> dd\nbl OR bm -> bn\nib AND ic -> ie\nx RSHIFT 3 -> z\nlh AND li -> lk\nce OR cd -> cf\nNOT bb -> bc\nhi AND hk -> hl\nNOT gb -> gc\n1 AND r -> s\nfw AND fy -> fz\nfb AND fd -> fe\n1 AND en -> eo\nz OR aa -> ab\nbi LSHIFT 15 -> bm\nhg OR hh -> hi\nkh LSHIFT 1 -> lb\ncg OR ch -> ci\n1 AND kz -> la\ngf OR ge -> gg\ngj RSHIFT 2 -> gk\ndd RSHIFT 2 -> de\nNOT ls -> lt\nlh OR li -> lj\njr OR js -> jt\nau AND av -> ax\n0 -> c\nhe AND hp -> hr\nid AND if -> ig\net RSHIFT 5 -> ew\nbp AND bq -> bs\ne AND f -> h\nly OR lz -> ma\n1 AND lu -> lv\nNOT jd -> je\nha OR gz -> hb\ndy RSHIFT 1 -> er\niu RSHIFT 2 -> iv\nNOT hr -> hs\nas RSHIFT 1 -> bl\nkk RSHIFT 2 -> kl\nb AND n -> p\nln AND lp -> lq\ncj AND cp -> cr\ndl AND dn -> do\nci RSHIFT 2 -> cj\nas OR bd -> be\nge LSHIFT 15 -> gi\nhz RSHIFT 5 -> ic\ndv LSHIFT 1 -> ep\nkl OR kr -> ks\ngj OR gu -> gv\nhe RSHIFT 5 -> hh\nNOT fg -> fh\nhg AND hh -> hj\nb OR n -> o\njk LSHIFT 15 -> jo\ngz LSHIFT 15 -> hd\ncy LSHIFT 15 -> dc\nkk RSHIFT 5 -> kn\nci RSHIFT 3 -> ck\nat OR az -> ba\niu RSHIFT 3 -> iw\nko AND kq -> kr\nNOT eh -> ei\naq OR ar -> as\niy AND ja -> jb\ndd RSHIFT 3 -> df\nbn RSHIFT 3 -> bp\n1 AND cc -> cd\nat AND az -> bb\nx OR ai -> aj\nkk AND kv -> kx\nao OR an -> ap\ndy RSHIFT 3 -> ea\nx RSHIFT 1 -> aq\neu AND fa -> fc\nkl AND kr -> kt\nia AND ig -> ii\ndf AND dg -> di\nNOT fx -> fy\nk AND m -> n\nbn RSHIFT 5 -> bq\nkm AND kn -> kp\ndt LSHIFT 15 -> dx\nhz RSHIFT 2 -> ia\naj AND al -> am\ncd LSHIFT 15 -> ch\nhc OR hd -> he\nhe RSHIFT 3 -> hg\nbn OR by -> bz\nNOT kt -> ku\nz AND aa -> ac\nNOT ak -> al\ncu AND cw -> cx\nNOT ie -> if\ndy RSHIFT 2 -> dz\nip LSHIFT 15 -> it\nde OR dk -> dl\nau OR av -> aw\njg AND ji -> jj\nci AND ct -> cv\ndy RSHIFT 5 -> eb\nhx OR hy -> hz\neu OR fa -> fb\ngj RSHIFT 3 -> gl\nfo AND fz -> gb\n1 AND jj -> jk\njp OR ka -> kb\nde AND dk -> dm\nex AND ez -> fa\ndf OR dg -> dh\niv OR jb -> jc\nx RSHIFT 5 -> aa\nNOT hj -> hk\nNOT im -> in\nfl LSHIFT 1 -> gf\nhu LSHIFT 15 -> hy\niq OR ip -> ir\niu RSHIFT 5 -> ix\nNOT fc -> fd\nNOT el -> em\nck OR cl -> cm\net RSHIFT 3 -> ev\nhw LSHIFT 1 -> iq\nci RSHIFT 5 -> cl\niv AND jb -> jd\ndd RSHIFT 5 -> dg\nas RSHIFT 2 -> at\nNOT jy -> jz\naf AND ah -> ai\n1 AND ds -> dt\njx AND jz -> ka\nda LSHIFT 1 -> du\nfs AND fu -> fv\njp RSHIFT 1 -> ki\niw AND ix -> iz\niw OR ix -> iy\neo LSHIFT 15 -> es\nev AND ew -> ey\nba AND bc -> bd\nfp AND fv -> fx\njc AND je -> jf\net RSHIFT 2 -> eu\nkg OR kf -> kh\niu OR jf -> jg\ner OR es -> et\nfo RSHIFT 2 -> fp\nNOT ca -> cb\nbv AND bx -> by\nu LSHIFT 1 -> ao\ncm AND co -> cp\ny OR ae -> af\nbn AND by -> ca\n1 AND ke -> kf\njt AND jv -> jw\nfq OR fr -> fs\ndy AND ej -> el\nNOT kc -> kd\nev OR ew -> ex\ndd OR do -> dp\nNOT cv -> cw\ngr AND gt -> gu\ndd RSHIFT 1 -> dw\nNOT gw -> gx\nNOT iz -> ja\n1 AND io -> ip\nNOT ag -> ah\nb RSHIFT 5 -> f\nNOT cr -> cs\nkb AND kd -> ke\njr AND js -> ju\ncq AND cs -> ct\nil AND in -> io\nNOT ju -> jv\ndu OR dt -> dv\ndd AND do -> dq\nb RSHIFT 2 -> d\njm LSHIFT 1 -> kg\nNOT dq -> dr\nbo OR bu -> bv\ngk OR gq -> gr\nhe OR hp -> hq\nNOT h -> i\nhf AND hl -> hn\ngv AND gx -> gy\nx AND ai -> ak\nbo AND bu -> bw\nhq AND hs -> ht\nhz RSHIFT 1 -> is\ngj RSHIFT 5 -> gm\ng AND i -> j\ngk AND gq -> gs\ndp AND dr -> ds\nb RSHIFT 3 -> e\ngl AND gm -> go\ngl OR gm -> gn\ny AND ae -> ag\nhv OR hu -> hw\n46065 -> b\nab AND ad -> ae\nNOT ac -> ad\n1 AND ht -> hu\nNOT hn -> ho"
