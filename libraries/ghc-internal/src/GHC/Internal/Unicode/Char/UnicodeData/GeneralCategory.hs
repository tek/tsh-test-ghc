-- DO NOT EDIT: This file is automatically generated by the internal tool ucd2haskell,
-- with data from: https://www.unicode.org/Public/15.1.0/ucd/UnicodeData.txt.

{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE MagicHash #-}
{-# OPTIONS_HADDOCK hide #-}

-----------------------------------------------------------------------------
-- |
-- Module      : GHC.Internal.Unicode.Char.UnicodeData.GeneralCategory
-- Copyright   : (c) 2020 Composewell Technologies and Contributors
-- License     : BSD-3-Clause
-- Maintainer  : streamly@composewell.com
-- Stability   : internal
-----------------------------------------------------------------------------

module GHC.Internal.Unicode.Char.UnicodeData.GeneralCategory
(generalCategory)
where

import GHC.Internal.Base (Char, Int, Ord(..), ord)
import GHC.Internal.Unicode.Bits (lookupIntN)

{-# INLINE generalCategory #-}
generalCategory :: Char -> Int
generalCategory c = let n = ord c in if n >= 1114110 then 29 else lookup_bitmap n
{-# NOINLINE lookup_bitmap #-}
lookup_bitmap :: Int -> Int
lookup_bitmap n = lookupIntN bitmap# n
  where
