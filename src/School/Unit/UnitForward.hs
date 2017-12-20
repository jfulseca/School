module School.Unit.UnitForward
( ForwardStack
, ForwardSource
, unitForward
) where

import Conduit (ConduitM, mapMC)
import Control.Monad.Except (throwError)
import School.Train.AppTrain (AppTrain)
import School.Train.StateFunctions (getParams)
import School.Unit.CostParams (CostParams)
import School.Unit.Unit (Unit(..))
import School.Unit.UnitActivation (UnitActivation(..))
import School.Types.Slinky (Slinky)

type ForwardStack a = ([UnitActivation a], Slinky CostParams)

type ForwardSource a = ConduitM () (ForwardStack a) (AppTrain a) ()

applyUnit :: Unit a
          -> ForwardStack a
          -> AppTrain a (ForwardStack a)
applyUnit _ ([], _) =
  throwError $ "No input activations " ++
               " to forward network unit "
applyUnit unit (activations, cParams) = do
  let input = head activations
  case input of
    (ApplyFail msg) -> throwError msg
    _ -> do
      params <- getParams
      let output = apply unit params input
      return $ (output:activations, cParams)

unitForward :: Unit a -> ConduitM (ForwardStack a)
                                  (ForwardStack a)
                                  (AppTrain a)
                                  ()
unitForward unit = mapMC (applyUnit unit)
