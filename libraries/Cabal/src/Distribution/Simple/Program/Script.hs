{-# LANGUAGE GADTs #-}

-----------------------------------------------------------------------------

-- |
-- Module      :  Distribution.Simple.Program.Script
-- Copyright   :  Duncan Coutts 2009
--
-- Maintainer  :  cabal-devel@haskell.org
-- Portability :  portable
--
-- This module provides an library interface to the @hc-pkg@ program.
-- Currently only GHC and LHC have hc-pkg programs.
module Distribution.Simple.Program.Script
  ( invocationAsSystemScript
  , invocationAsShellScript
  , invocationAsBatchFile
  ) where

import Distribution.Compat.Prelude
import Prelude ()

import Distribution.Simple.Program.Run
import Distribution.Simple.Utils
import Distribution.System

-- | Generate a system script, either POSIX shell script or Windows batch file
-- as appropriate for the given system.
invocationAsSystemScript :: OS -> ProgramInvocation -> String
invocationAsSystemScript Windows = invocationAsBatchFile
invocationAsSystemScript _ = invocationAsShellScript

-- | Generate a POSIX shell script that invokes a program.
invocationAsShellScript :: ProgramInvocation -> String
invocationAsShellScript
  ProgramInvocation
    { progInvokePath = path
    , progInvokeArgs = args
    , progInvokeEnv = envExtra
    , progInvokeCwd = mcwd
    , progInvokeInput = minput
    } =
    unlines $
      ["#!/bin/sh"]
        ++ concatMap setEnv envExtra
        ++ ["cd " ++ quote cwd | cwd <- maybeToList mcwd]
        ++ [ ( case minput of
                Nothing -> ""
                Just input -> "printf '%s' " ++ quote (iodataToText input) ++ " | "
             )
              ++ unwords (map quote $ path : args)
              ++ " \"$@\""
           ]
    where
      setEnv (var, Nothing) = ["unset " ++ var, "export " ++ var]
      setEnv (var, Just val) = ["export " ++ var ++ "=" ++ quote val]

      quote :: String -> String
      quote s = "'" ++ escape s ++ "'"

      escape [] = []
      escape ('\'' : cs) = "'\\''" ++ escape cs
      escape (c : cs) = c : escape cs

iodataToText :: IOData -> String
iodataToText (IODataText str) = str
iodataToText (IODataBinary lbs) = fromUTF8LBS lbs

-- | Generate a Windows batch file that invokes a program.
invocationAsBatchFile :: ProgramInvocation -> String
invocationAsBatchFile
  ProgramInvocation
    { progInvokePath = path
    , progInvokeArgs = args
    , progInvokeEnv = envExtra
    , progInvokeCwd = mcwd
    , progInvokeInput = minput
    } =
    unlines $
      ["@echo off"]
        ++ map setEnv envExtra
        ++ ["cd \"" ++ cwd ++ "\"" | cwd <- maybeToList mcwd]
        ++ case minput of
          Nothing ->
            [path ++ concatMap (' ' :) args]
          Just input ->
            ["("]
              ++ ["echo " ++ escape line | line <- lines $ iodataToText input]
              ++ [ ") | "
                    ++ "\""
                    ++ path
                    ++ "\""
                    ++ concatMap (\arg -> ' ' : quote arg) args
                 ]
    where
      setEnv (var, Nothing) = "set " ++ var ++ "="
      setEnv (var, Just val) = "set " ++ var ++ "=" ++ escape val

      quote :: String -> String
      quote s = "\"" ++ escapeQ s ++ "\""

      escapeQ [] = []
      escapeQ ('"' : cs) = "\"\"\"" ++ escapeQ cs
      escapeQ (c : cs) = c : escapeQ cs

      escape [] = []
      escape ('|' : cs) = "^|" ++ escape cs
      escape ('<' : cs) = "^<" ++ escape cs
      escape ('>' : cs) = "^>" ++ escape cs
      escape ('&' : cs) = "^&" ++ escape cs
      escape ('(' : cs) = "^(" ++ escape cs
      escape (')' : cs) = "^)" ++ escape cs
      escape ('^' : cs) = "^^" ++ escape cs
      escape (c : cs) = c : escape cs
