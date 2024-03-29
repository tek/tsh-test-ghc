{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RankNTypes #-}

-----------------------------------------------------------------------------

-- |
-- Module      :  Distribution.Simple.Program.Hpc
-- Copyright   :  Thomas Tuegel 2011
--
-- Maintainer  :  cabal-devel@haskell.org
-- Portability :  portable
--
-- This module provides an library interface to the @hpc@ program.
module Distribution.Simple.Program.Hpc
  ( markup
  , union
  ) where

import Distribution.Compat.Prelude
import Prelude ()

import System.Directory (makeRelativeToCurrentDirectory)

import Distribution.ModuleName
import Distribution.Pretty
import Distribution.Simple.Program.Run
import Distribution.Simple.Program.Types
import Distribution.Simple.Utils
import Distribution.Verbosity
import Distribution.Version

-- | Invoke hpc with the given parameters.
--
-- Prior to HPC version 0.7 (packaged with GHC 7.8), hpc did not handle
-- multiple .mix paths correctly, so we print a warning, and only pass it the
-- first path in the list. This means that e.g. test suites that import their
-- library as a dependency can still work, but those that include the library
-- modules directly (in other-modules) don't.
markup
  :: ConfiguredProgram
  -> Version
  -> Verbosity
  -> FilePath
  -- ^ Path to .tix file
  -> [FilePath]
  -- ^ Paths to .mix file directories
  -> FilePath
  -- ^ Path where html output should be located
  -> [ModuleName]
  -- ^ List of modules to include in the report
  -> IO ()
markup hpc hpcVer verbosity tixFile hpcDirs destDir included = do
  hpcDirs' <-
    if withinRange hpcVer (orLaterVersion version07)
      then return hpcDirs
      else do
        warn verbosity $
          "Your version of HPC ("
            ++ prettyShow hpcVer
            ++ ") does not properly handle multiple search paths. "
            ++ "Coverage report generation may fail unexpectedly. These "
            ++ "issues are addressed in version 0.7 or later (GHC 7.8 or "
            ++ "later)."
            ++ if null droppedDirs
              then ""
              else
                " The following search paths have been abandoned: "
                  ++ show droppedDirs
        return passedDirs

  -- Prior to GHC 8.0, hpc assumes all .mix paths are relative.
  hpcDirs'' <- traverse makeRelativeToCurrentDirectory hpcDirs'

  runProgramInvocation
    verbosity
    (markupInvocation hpc tixFile hpcDirs'' destDir included)
  where
    version07 = mkVersion [0, 7]
    (passedDirs, droppedDirs) = splitAt 1 hpcDirs

markupInvocation
  :: ConfiguredProgram
  -> FilePath
  -- ^ Path to .tix file
  -> [FilePath]
  -- ^ Paths to .mix file directories
  -> FilePath
  -- ^ Path where html output should be
  -- located
  -> [ModuleName]
  -- ^ List of modules to include
  -> ProgramInvocation
markupInvocation hpc tixFile hpcDirs destDir included =
  let args =
        [ "markup"
        , tixFile
        , "--destdir=" ++ destDir
        ]
          ++ map ("--hpcdir=" ++) hpcDirs
          ++ [ "--include=" ++ prettyShow moduleName
             | moduleName <- included
             ]
   in programInvocation hpc args

union
  :: ConfiguredProgram
  -> Verbosity
  -> [FilePath]
  -- ^ Paths to .tix files
  -> FilePath
  -- ^ Path to resultant .tix file
  -> [ModuleName]
  -- ^ List of modules to exclude from union
  -> IO ()
union hpc verbosity tixFiles outFile excluded =
  runProgramInvocation
    verbosity
    (unionInvocation hpc tixFiles outFile excluded)

unionInvocation
  :: ConfiguredProgram
  -> [FilePath]
  -- ^ Paths to .tix files
  -> FilePath
  -- ^ Path to resultant .tix file
  -> [ModuleName]
  -- ^ List of modules to exclude from union
  -> ProgramInvocation
unionInvocation hpc tixFiles outFile excluded =
  programInvocation hpc $
    concat
      [ ["sum", "--union"]
      , tixFiles
      , ["--output=" ++ outFile]
      , [ "--exclude=" ++ prettyShow moduleName
        | moduleName <- excluded
        ]
      ]
