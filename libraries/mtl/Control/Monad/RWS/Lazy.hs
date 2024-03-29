{-# LANGUAGE Safe #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Monad.RWS.Lazy
-- Copyright   :  (c) Andy Gill 2001,
--                (c) Oregon Graduate Institute of Science and Technology, 2001
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  libraries@haskell.org
-- Stability   :  experimental
-- Portability :  non-portable (multi-param classes, functional dependencies)
--
-- Lazy RWS monad.
--
--      Inspired by the paper
--      /Functional Programming with Overloading and Higher-Order Polymorphism/,
--        Mark P Jones (<http://web.cecs.pdx.edu/~mpj/>)
--          Advanced School of Functional Programming, 1995.
-----------------------------------------------------------------------------

module Control.Monad.RWS.Lazy (
    -- * The RWS monad
    RWS,
    rws,
    runRWS,
    evalRWS,
    execRWS,
    mapRWS,
    withRWS,
    -- * The RWST monad transformer
    RWST(RWST),
    runRWST,
    evalRWST,
    execRWST,
    mapRWST,
    withRWST,
    -- * Lazy Reader-writer-state monads
    module Control.Monad.RWS.Class,
    module Control.Monad.Trans,
  ) where

import Control.Monad.RWS.Class

import Control.Monad.Trans
import Control.Monad.Trans.RWS.Lazy (
    RWS, rws, runRWS, evalRWS, execRWS, mapRWS, withRWS,
    RWST(RWST), runRWST, evalRWST, execRWST, mapRWST, withRWST)
