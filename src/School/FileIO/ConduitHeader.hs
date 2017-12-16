module School.FileIO.ConduitHeader
( ConduitHeader
, conduitHeader
) where

import Conduit ((.|), ($$+), ($$++), ConduitM, ResumableSource,
                mapM_C, takeCE, takeWhileCE)
import Data.Attoparsec.ByteString (parseOnly) 
import Data.ByteString (ByteString)
import Data.ByteString.Conversion (FromByteString(..))
import Data.Void (Void)
import School.App.AppS (AppS, liftAppS)
import School.FileIO.FileType (FileType(..))
import School.FileIO.MatrixHeader (MatrixHeader, compatibleHeaders)
import School.Utils.Constants (binSeparator, separator)

type ConduitHeader a =
    ConduitM () ByteString (AppS a) ()
 -> AppS a (ResumableSource (AppS a) ByteString)

conduitHeader :: FileType
              -> MatrixHeader
              -> ConduitHeader a
conduitHeader SM header source = do
  let sink = smConduitHeader header
  (resumable, _) <- source $$+ sink
  return resumable 
conduitHeader _ _ _ = undefined

type HeaderSink a =
  ConduitM ByteString Void (AppS a) ()

{-idxConduitHeader :: MatrixHeader
                 -> ConduitHeader a
idxConduitHeader header = do
-}
smConduitHeader :: MatrixHeader
                -> HeaderSink a
smConduitHeader header = do
  let sepEq = (==separator)
  let compat = compatibleHeaders header
  takeCE 1 .| confirmAtom sepEq
  takeWhileCE (/= binSeparator) .| confirmAtom compat
  takeCE 1 .| confirmAtom sepEq

confirmAtom :: (Eq b, FromByteString b, Show b)
            => (b -> Bool)
            -> HeaderSink a
confirmAtom check = mapM_C $ \bytes -> do
  let parseResult = atomParser check bytes
  liftAppS parseResult
  where
    atomParser c b = do
      atom <- parseOnly parser b
      if c atom
        then Right ()
        else Left $ msg b
    msg b = "Parser gave unexpected "
         ++ "result " ++ (show b)

{-
idxConfirm :: MatrixHeader -> ConduitBS a
idxConfirm MatrixHeader { dataType } = do
  takeCE 4 .| checkHeader dataType
  mapC id

errorMsg :: Int -> DataType -> String
errorMsg i t = "Type indicator " ++ (show i)
            ++ " does not correspond to " ++ (show t)

compat :: DataType -> [Int] -> AppS a ()
compat dType ints = do
  let check = length ints == 4
           && ints!!0 == 0
           && ints!!1 == 0
  when (not check)
       (throw "Invalid IDX format")
  let coeff = ints!!2
  let dType' = fromIdxIndicator coeff
  liftAppS $ either Left
                    (\t -> if t == dType
                            then Right ()
                            else Left $ errorMsg coeff dType)
                    dType'

checkHeader :: DataType -> ConduitBS a
checkHeader dType =
    mapC unpack
 .| mapCE fromEnum
 .| mapM_C (compat dType)

-}
