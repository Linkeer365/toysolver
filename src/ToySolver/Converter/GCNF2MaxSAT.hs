{-# OPTIONS_GHC -Wall #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  ToySolver.Converter.GCNF2MaxSAT
-- Copyright   :  (c) Masahiro Sakai 2016
-- License     :  BSD-style
-- 
-- Maintainer  :  masahiro.sakai@gmail.com
-- Stability   :  experimental
-- Portability :  portable
--
-----------------------------------------------------------------------------
module ToySolver.Converter.GCNF2MaxSAT
  ( convert
  ) where

import qualified Data.Vector.Generic as VG
import qualified ToySolver.SAT.Types as SAT
import qualified ToySolver.Text.GCNF as GCNF
import qualified ToySolver.Text.WCNF as WCNF

convert :: GCNF.GCNF -> WCNF.WCNF
convert
  GCNF.GCNF
  { GCNF.gcnfNumVars        = nv
  , GCNF.gcnfNumClauses     = nc
  , GCNF.gcnfLastGroupIndex = lastg
  , GCNF.gcnfClauses        = cs
  }
  =
  WCNF.WCNF
  { WCNF.wcnfTopCost = top
  , WCNF.wcnfClauses = [(top, if g==0 then c else VG.cons (-(nv+g)) c) | (g,c) <- cs] ++ [(1, SAT.packClause [v]) | v <- [nv+1..nv+lastg]]
  , WCNF.wcnfNumVars = nv + lastg
  , WCNF.wcnfNumClauses = nc + lastg
  }
  where
    top :: WCNF.Weight
    top = fromIntegral (lastg + 1)
