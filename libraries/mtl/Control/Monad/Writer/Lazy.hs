{-# LANGUAGE Safe #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Monad.Writer.Lazy
-- Copyright   :  (c) Andy Gill 2001,
--                (c) Oregon Graduate Institute of Science and Technology, 2001
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  libraries@haskell.org
-- Stability   :  experimental
-- Portability :  non-portable (multi-param classes, functional dependencies)
--
-- Lazy writer monads.
--
--      Inspired by the paper
--      /Functional Programming with Overloading and Higher-Order Polymorphism/,
--        Mark P Jones (<http://web.cecs.pdx.edu/~mpj/pubs/springschool.html>)
--          Advanced School of Functional Programming, 1995.
-----------------------------------------------------------------------------

module Control.Monad.Writer.Lazy (
    -- * MonadWriter class
    MonadWriter.MonadWriter(..),
    MonadWriter.listens,
    MonadWriter.censor,
    -- * The Writer monad
    Writer,
    runWriter,
    execWriter,
    mapWriter,
    -- * The WriterT monad transformer
    WriterT(WriterT),
    runWriterT,
    execWriterT,
    mapWriterT,
    module Control.Monad.Trans,
  ) where

import qualified Control.Monad.Writer.Class as MonadWriter
import Control.Monad.Trans
import Control.Monad.Trans.Writer.Lazy (
        Writer, runWriter, execWriter, mapWriter,
        WriterT(WriterT), runWriterT, execWriterT, mapWriterT)
