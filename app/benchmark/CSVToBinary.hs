import Criterion.Main
import HML.FileIO.AppIO (ConduitAppIO, runAppIO)
import HML.FileIO.MatrixHeader (MatrixHeader(..))
import HML.FileIO.CSVReader (csvToBinary)
import HML.Types.PosInt (PosInt)
import HML.Types.TypeName (TypeName(DBL))
import HML.Utils.SafeEncoding (safeStdEncodings)
import System.Directory (removeFile)
import System.FilePath (takeBaseName)
import Test.QuickCheck.Modifiers (Positive(..))

dataDir :: FilePath
dataDir = "app/benchmark/data/"

convert :: (FilePath -> FilePath -> MatrixHeader -> ConduitAppIO)
        -> FilePath
        -> PosInt
        -> PosInt
        -> IO ()
convert readWrite fName nRows nCols = do
  let header = MatrixHeader DBL nRows nCols
  let outFile = (takeBaseName fName) ++ ".dat"
  result <- runAppIO $ readWrite (dataDir ++ fName)
                                 outFile
                                 header
  removeFile outFile
  either putStrLn
         (const $ return ())
         result

main :: IO ()
main = safeStdEncodings >> defaultMain [
  bgroup "csv to binary " [
    bench " 5x3" $ nfIO
      (convert csvToBinary "smallCSV.csv" (Positive 5) (Positive 3))
  , bench " 100x401" $ nfIO
      (convert csvToBinary "digits_fst100.csv" (Positive 100) (Positive 401))
    ]
  ]
