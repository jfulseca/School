module School.App.AppS
( AppS
, FullConduitAppS
, liftAppS
, maybeToAppS
, runAppSConduit
, runAppSConduitDefState
, throw
, throwConduit
) where 

import Conduit (ConduitM, ResourceT, runConduitRes)
import Control.Monad.State.Lazy (StateT, runStateT)
import Control.Monad.Trans.Class (lift)
import Control.Monad.Trans.Except (ExceptT(..), runExceptT)
import Data.Void (Void)
import School.Train.TrainState (TrainState, def)
import School.Utils.Either (mapRight)

type AppS a = ResourceT (StateT (TrainState a)
                                (ExceptT String
                                         IO))

liftAppS :: Either String b -> AppS a b
liftAppS = lift . lift . ExceptT . return

type FullConduitAppS a = ConduitM ()
                                  Void
                                  (AppS a)
                                  ()

runAppSConduit :: ConduitM ()
                           Void
                           (AppS a)
                           b
               -> (TrainState a)
               -> IO (Either String (b, TrainState a))
runAppSConduit conduit state = runExceptT $
  runStateT (runConduitRes conduit) state

runAppSConduitDefState :: (Num a)
                       => ConduitM ()
                                   Void
                                   (AppS a)
                                   b
                       -> IO (Either String b)
runAppSConduitDefState conduit = do
  result <- runAppSConduit conduit
                           def
  return $ mapRight fst result

throw :: String -> AppS a b
throw = liftAppS . Left

throwConduit :: String -> ConduitM i o (AppS a) ()
throwConduit = lift . throw

maybeToAppS :: String -> Maybe b -> AppS a b
maybeToAppS msg =
  maybe (throw msg) (liftAppS . Right)
