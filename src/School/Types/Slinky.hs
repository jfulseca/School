module School.Types.Slinky
( Slinky(..)
, slinkyAppend
, slinkyConcat
, slinkyPrepend
, slinkySingleton
, toSlinky
) where

data Slinky a =
   SNode a (Slinky a)
 | SNil deriving (Eq, Show)

slinkySingleton :: a -> Slinky a
slinkySingleton val = SNode val SNil

slinkyPrepend :: a
              -> Slinky a
              -> Slinky a
slinkyPrepend val SNil =
  slinkySingleton val
slinkyPrepend val (SNode first rest)
  = SNode val (SNode first rest)

slinkyAppend :: a
              -> Slinky a
              -> Slinky a
slinkyAppend val SNil =
  slinkySingleton val
slinkyAppend val (SNode first rest)
  = slinkyAppend first (SNode val rest)

slinkyConcat :: Slinky a -> Slinky a -> Slinky a
slinkyConcat xs SNil = xs
slinkyConcat xs (SNode y SNil) = slinkyAppend y xs
slinkyConcat xs (SNode y ys) =
  slinkyConcat (slinkyAppend y xs) ys

toSlinky :: [a] -> Slinky a
toSlinky = foldl (flip slinkyPrepend) SNil
