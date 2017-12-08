module School.Unit.UnitBackward
( BackwardStack
, unitBackward ) where

import Conduit (ConduitM, mapMC)
import School.App.AppS (AppS, throw)
import School.Train.AppTrain (getParams, putParamDerivs)
import School.Unit.Unit (Unit(..))
import School.Unit.UnitActivation (UnitActivation(..))
import School.Unit.UnitForward (ForwardStack)
import School.Unit.UnitGradient (UnitGradient(..))

type BackwardStack a =
  ( ForwardStack a
  , UnitGradient a
  )

derivUnit :: Unit a 
          -> BackwardStack a
          -> AppS a (BackwardStack a)
derivUnit _ ([], _) =
  throw $ "No input activations " ++
          "to backward network unit "
derivUnit _ (_, GradientFail msg) = throw msg
derivUnit unit (acts, inGrad) = do
  let input = head acts
  case input of
    (ApplyFail msg) -> throw $ "ERROR: " ++ msg
    _ -> do
      params <- getParams
      let (gradient, derivs) = deriv unit params inGrad input
      putParamDerivs derivs
      return $ ( tail acts
               , gradient
               )

unitBackward :: Unit a -> ConduitM (BackwardStack a)
                                   (BackwardStack a)
                                   (AppS a)
                                   ()

unitBackward unit = mapMC (derivUnit unit)
