-----------------------------------------------------------------------------
-- |
-- Module      :  SAT.MUS
-- Copyright   :  (c) Masahiro Sakai 2012
-- License     :  BSD-style
-- 
-- Maintainer  :  masahiro.sakai@gmail.com
-- Stability   :  provisional
-- Portability :  non-portable
--
-- Minimal Unsatifiable Subset (MUS) Finder
--
-----------------------------------------------------------------------------
module SAT.MUS
  ( Options (..)
  , defaultOptions
  , findMUS
  ) where

import Data.List
import qualified Data.IntSet as IS
import SAT

-- | Options for 'findMUS' function
data Options
  = Options
  { optLogger     :: String -> IO ()
  , optUpdater    :: [Lit] -> IO ()
  , optLitPrinter :: Lit -> String
  }

-- | default 'Options' value
defaultOptions :: Options
defaultOptions =
  Options
  { optLogger     = \_ -> return ()
  , optUpdater    = \_ -> return ()
  , optLitPrinter = show
  }

-- | Find a minimal set of assumptions that causes a conflict.
-- Initial set of assumptions is taken from 'SAT.getBadAssumptions'.
findMUS
  :: SAT.Solver
  -> Options
  -> IO [Lit]
findMUS solver opt = do
  log "computing a minimally unsatisfiable subformula"
  core <- SAT.getBadAssumptions solver
  mus <- loop core IS.empty
  return $ IS.toList mus

  where
    log :: String -> IO ()
    log = optLogger opt

    update :: [Lit] -> IO ()
    update = optUpdater opt

    showLit :: Lit -> String
    showLit = optLitPrinter opt

    showLits :: IS.IntSet -> String
    showLits ls = "{" ++ intercalate ", " (map showLit (IS.toList ls)) ++ "}"

    loop :: IS.IntSet -> IS.IntSet -> IO IS.IntSet
    loop ls1 fixed = do
      let core = ls1 `IS.union` fixed
      update $ IS.toList core
      log $ "core = " ++ showLits core
      case IS.minView ls1 of
        Nothing -> do
          log $ "found a minimal unsatisfiable core"
          return fixed
        Just (l,ls) -> do
          log $ "trying to remove " ++ showLit l
          ret <- SAT.solveWith solver (IS.toList ls)
          if not ret
            then do
              ls2 <- SAT.getBadAssumptions solver
              log $ "successed to remove " ++ showLits (ls1 `IS.difference` ls2)
              loop ls2 fixed
            else do
              log $ "failed to remove " ++ showLit l
              SAT.addClause solver [l]
              loop ls (IS.insert l fixed)