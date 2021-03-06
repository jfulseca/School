{-# LANGUAGE TemplateHaskell #-}

module School.App.Test.CSVReader
( csvReaderTest ) where

import Conduit ((.|), runConduit, sinkList)
import Control.Monad.IO.Class (liftIO)
import Data.Either (isRight)
import Data.List.Split (chunksOf)
import School.App.CSVReader
import School.FileIO.AppIO (runAppIO)
import School.FileIO.FileHeader (FileHeader(..))
import School.FileIO.Source (source)
import School.Types.DataType (DataType(..))
import qualified Numeric.LinearAlgebra as NL
import System.Directory (removeFile)
import Test.QuickCheck.Monadic (assert, monadicIO, run)
import Test.Tasty.QuickCheck
import Test.Tasty (TestTree)
import Test.Tasty.TH

matrixConcat :: (NL.Element a)
             => [NL.Matrix a]
             -> Either String [NL.Matrix a]
matrixConcat [] = return []
matrixConcat matrices = do
  let nCols = NL.cols . head $ matrices
  let compat = all (\m -> NL.cols m == nCols) matrices
  if not compat then Left "Matrices must have same # columns"
    else do
      let allRows = concat . concat $ map NL.toLists matrices
      return [NL.fromLists (chunksOf nCols allRows)]

prop_convert_csv_file :: Property
prop_convert_csv_file = monadicIO $ do
  let filePath = "test/data/csvTest.csv"
  let bFileName = "test.dat"
  let header = FileHeader DBL64B 51 3
  writeRes <- run . runAppIO . runConduit $
    csvToBinary filePath bFileName header
  assert $ isRight writeRes
  readRes <- run . runAppIO . runConduit $
      readCSV filePath
     .| csvToMatrixDouble header
     .| sinkList
  let original = readRes >>= matrixConcat
  written <- run . runAppIO . runConduit $
    source header bFileName .| sinkList
  liftIO $ removeFile bFileName
  assert $ original == written

csvReaderTest :: TestTree
csvReaderTest = $(testGroupGenerator)
