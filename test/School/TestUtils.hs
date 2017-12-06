{-# LANGUAGE NamedFieldPuns #-}

module School.TestUtils
( CostFunc
, diffCost
, diffInput
, doCost
, dummyHeader
, dummyList
, dummyMatrix
, empty
, fromLeft
, fromRight
, getRandDouble
, isSorted
, jTest
, matIndexes
, randomAffineParams
, randomMatrix
, randomMatrixL
, randomVector
, runTrainConduit
, testRun
, weight1
, whenPrint
) where

import Conduit (ConduitM)
import Control.Monad (when)
import Data.Either (either)
import Data.List (sort)
import Data.Void (Void)
import Numeric.LinearAlgebra ((><), (|>), Element, IndexOf, Matrix, R, Vector, accum, sumElements)
import School.FileIO.AppIO (AppIO, runAppIO)
import School.FileIO.MatrixHeader (MatrixHeader(..))
import School.Types.DoubleConversion (doubleRange)
import School.Types.TypeName (TypeName(INT))
import School.Train.AppTrain (runTrainConduit)
import School.Train.TrainState (CostParams)
import School.Unit.CostFunction (CostFunction(..))
import School.Unit.Unit (Unit(..))
import School.Unit.UnitGradient (UnitGradient(..))
import School.Unit.UnitActivation (UnitActivation(..))
import School.Unit.UnitParams (UnitParams(..))
import School.Unit.WeightDecay (weightDecay)
import System.Random (getStdRandom, randomR)
import Test.QuickCheck.Modifiers (Positive(..))
import Test.QuickCheck.Monadic (PropertyM, run)

isSorted :: (Ord a) => [a] -> Bool
isSorted xs = xs == (reverse . sort $ xs)

testRun :: ConduitM () Void AppIO a
        -> PropertyM IO (Either String a)
testRun = run . runAppIO

dummyHeader :: MatrixHeader
dummyHeader = MatrixHeader INT n n where
  n = Positive 1

dummyList :: (Num a) => Int -> Int -> [a]
dummyList r c = map fromIntegral [ r*i + j | i <- [1..r], j <- [1..c] ]

dummyMatrix :: Int -> Int -> Matrix Double
dummyMatrix r c = r >< c $ dummyList r c

getRandDouble :: IO Double
getRandDouble =
  getStdRandom (randomR doubleRange)

matMax :: Double
matMax = 1e3

randomMatrix :: Int -> Int -> IO (Matrix R)
randomMatrix nRows nCols = do
  let nEls = nRows * nCols
  inputList <- sequence . (replicate nEls) $ getStdRandom (randomR (-matMax, matMax))
  return $ (nRows >< nCols) inputList

randomMatrixL :: Double -> Int -> Int -> IO (Matrix R)
randomMatrixL limit nRows nCols = do
  let nEls = nRows * nCols
  inputList <- sequence . (replicate nEls) $ getStdRandom (randomR (-limit, limit))
  return $ (nRows >< nCols) inputList

randomVector :: Int -> IO (Vector R)
randomVector n = do
  inputList <- sequence . (replicate n) $ getStdRandom (randomR (-matMax, matMax))
  return $ n |> inputList

randomAffineParams :: Int
                   -> Int
                   -> IO (UnitParams R)
randomAffineParams fSize oSize = do
  affineBias <- randomVector oSize
  affineWeights <- randomMatrix oSize fSize
  return AffineParams { affineBias
                      , affineWeights
                      }

toPrint :: (Show a) => String -> a -> IO ()
toPrint tag val = putStrLn $ tag ++ " " ++ (show val)

whenPrint :: (Show a) => Bool -> [String] -> [a] -> IO ()
whenPrint cond tags vals = do
  when cond (sequence_ $ zipWith toPrint tags vals)

type CostFunc = UnitActivation R -> Double

jTest :: CostFunc
jTest (BatchActivation m) = sumElements m
jTest _ = 0

diffInput :: Unit R
          -> UnitParams R
          -> UnitActivation R
          -> Double
          -> IndexOf Matrix
          -> Double
diffInput unit params input eps idx =
  (jAdd - jSub) / (2*eps) where
    outAdd = apply unit params (alterInput eps idx input)
    outSub = apply unit params (alterInput (-eps) idx input)
    jAdd = jTest outAdd
    jSub = jTest outSub

fromRight :: b -> Either a b -> b
fromRight b = either (const b) id

fromLeft :: a -> Either a b -> a
fromLeft b = either id (const b)

diffCost :: CostFunction R
         -> UnitActivation R
         -> Double
         -> IndexOf Matrix
         -> CostParams
         -> Double
diffCost costFunc input eps idx costParams = let
  jAdd = computeCost costFunc (alterInput eps idx input) costParams
  jSub = computeCost costFunc (alterInput (-eps) idx input) costParams
  in (fromRight 0 jAdd - fromRight 0 jSub) / (2*eps)

alterInput :: AlterInput
alterInput change idx (BatchActivation m) =
  BatchActivation $ accum m (+) [(idx, change)]
alterInput _ _ _ = ApplyFail "alterInput error"

type AlterInput = Double
               -> IndexOf Matrix
               -> UnitActivation R
               -> UnitActivation R

matIndexes :: Int -> Int -> [IndexOf Matrix]
matIndexes r c = [ (j, k) | j <- [0..r-1], k <- [0..c-1] ] 

empty :: (Element a) => Matrix a
empty = (0><0) []

weight1 :: CostFunction R
weight1 = weightDecay 1

doCost :: (Element a, Num a)
       => CostFunction a
       -> UnitActivation a
       -> CostParams
       -> (a, UnitGradient a)
doCost costFunction activation params =
  fromRight (0, BatchGradient empty) result where
    result = do
      cost <- computeCost costFunction activation params
      grad <- derivCost costFunction activation params
      return (cost, grad)
