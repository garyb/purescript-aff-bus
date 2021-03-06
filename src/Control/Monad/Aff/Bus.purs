{-
Copyright 2016 SlamData, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-}

module Control.Monad.Aff.Bus
  ( make
  , read
  , write
  , split
  , kill
  , Cap
  , Bus
  , BusRW
  , BusR
  , BusR'
  , BusW
  , BusW'
  ) where

import Prelude
import Control.Monad.Aff (Aff, Error)
import Control.Monad.Aff.AVar (AVar, AVAR, makeEmptyVar, takeVar, tryPutVar, readVar, killVar)
import Data.Tuple (Tuple(..))

data Cap

newtype Bus (r ∷ # Type) a = Bus (AVar a)

type BusR = BusR' ()

type BusR' r = Bus (read ∷ Cap | r)

type BusW = BusW' ()

type BusW' r = Bus (write ∷ Cap | r)

type BusRW = Bus (read ∷ Cap, write ∷ Cap)

-- | Creates a new bidirectional Bus which can be read from and written to.
make ∷ ∀ eff a. Aff (avar ∷ AVAR | eff) (BusRW a)
make = Bus <$> makeEmptyVar

-- | Blocks until a new value is pushed to the Bus, returning the value.
read ∷ ∀ eff a r. BusR' r a → Aff (avar ∷ AVAR | eff) a
read (Bus avar) = readVar avar

-- | Pushes a new value to the Bus, yieldig immediately.
write ∷ ∀ eff a r. a → BusW' r a → Aff (avar ∷ AVAR | eff) Unit
write a (Bus avar) = tryPutVar a avar *> void (takeVar avar)

-- | Splits a bidirectional Bus into separate read and write Buses.
split ∷ ∀ a. BusRW a → Tuple (BusR a) (BusW a)
split (Bus avar) = Tuple (Bus avar) (Bus avar)

-- | Kills the Bus and propagates the exception to all consumers.
kill ∷ ∀ eff a r. Error → BusW' r a → Aff (avar ∷ AVAR | eff) Unit
kill err (Bus avar) = killVar err avar
