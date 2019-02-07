module StencilExamples where
import Data.Bits
import DataTypes
import Data.Proxy
import Data.Maybe
import GHC.TypeLits
import GHC.TypeLits.Extra
import ModulesDecl
import Data.List.Split
import Data.Types.Injective
import Data.Types.Isomorphic
import Isomorphism
import Control.Monad.State
import Control.Monad.Except
import Control.Monad.Identity
import Data.Typeable
import Data.Either
import Debug.Trace
import MagmaCompiler
import MagmaNodeTextGenerator
import LineBuffer
import Data.List
import ReadyValid
import qualified Data.Map.Strict as Map
import qualified Data.Vector.Sized as V

downsampleLB8x8 = (lineBuffer (Proxy :: Proxy (Atom Int)) (Proxy @2) (Proxy @2) (Proxy @8) (Proxy @8)
                   (Proxy @2) (Proxy @2) (Proxy @0) (Proxy @0))
unscheduledDownsampleLB8x8CData = buildCompilationData downsampleLB8x8
downsampleLB4x4 = (lineBuffer (Proxy :: Proxy (Atom Int)) (Proxy @2) (Proxy @2) (Proxy @4) (Proxy @4)
                   (Proxy @2) (Proxy @2) (Proxy @0) (Proxy @0))
unscheduledDownsampleLB4x4CData = buildCompilationData downsampleLB4x4
downsampleLB2x2 = (lineBuffer (Proxy :: Proxy (Atom Int)) (Proxy @2) (Proxy @2) (Proxy @2) (Proxy @2)
                   (Proxy @2) (Proxy @2) (Proxy @0) (Proxy @0))
unscheduledDownsampleLB2x2CData = buildCompilationData downsampleLB2x2

scalableConvMuls lengthProxy = iterC lengthProxy $ mapC (Proxy @2) $ mapC (Proxy @2) $ mulC
scalableConvConsts lengthProxy = iterC lengthProxy $ 
  (constGenIntC (Int 1) >***< constGenIntC (Int 2)) >***<
  (constGenIntC (Int 3) >***< constGenIntC (Int 4)) >>>
  reshapeC (Proxy :: Proxy (Atom (Atom (Atom Int, Atom Int), Atom (Atom Int, Atom Int))))
  (Proxy :: Proxy (Atom (V.Vector 2 (Atom (V.Vector 2 (Atom Int))))))
-- need to pair consts with a noop as can't get consts to type match with a downsampling 
-- linebuffer. The different seq in and out lengths of the downsample lb mean it
-- can't be zipped with the consts that have the same lengths in and out
scalableConvConstsForLB lengthProxy = (iterC lengthProxy addUnitType) >>>
  ((iterC lengthProxy noop) >***< (scalableConvConsts lengthProxy))

scalableNTuplesToFlatSSeq lengthProxy = iterC lengthProxy $
  reshapeC (Proxy :: Proxy (Atom (V.Vector 2 (Atom (V.Vector 2 (Atom Int))))))
  (Proxy :: Proxy (SSeq 4 (Atom Int)))

scalableConvFold lengthProxy = iterC lengthProxy $ seq_to_sseqC $
  foldC (Proxy @4) addC (constGenIntC (Int 0))

-- downsampleLB8x8 >>> scalableConvConstsForLB lengthProxy >>>
firstConv = iterC lengthProxy addUnitType >>>
  (downsampleLB8x8 >***< scalableConvConsts lengthProxy) >>>
  scalableConvMuls lengthProxy >>> scalableNTuplesToFlatSSeq lengthProxy >>>
  scalableConvFold lengthProxy
  where
    lengthProxy = Proxy @16

secondConv = iterC lengthProxy addUnitType >>>
  (downsampleLB4x4 >***< scalableConvConsts lengthProxy) >>>
  scalableConvMuls lengthProxy >>> scalableNTuplesToFlatSSeq lengthProxy >>>
  scalableConvFold lengthProxy
  where
    lengthProxy = Proxy @4

thirdConv = iterC lengthProxy addUnitType >>>
  (downsampleLB2x2 >***< scalableConvConsts lengthProxy) >>>
  scalableConvMuls lengthProxy >>> scalableNTuplesToFlatSSeq lengthProxy >>>
  scalableConvFold lengthProxy
  where
    lengthProxy = Proxy @1

--downsampleConvChain = firstConv >>> secondConv >>> thirdConv
downsampleStencilChain =
  seq_to_sseqC firstConv >>> reshapeImplicitC >>>
  seq_to_sseqC secondConv >>> reshapeImplicitC >>>
  seq_to_sseqC thirdConv

writeAllStencils = do
  writeProgramToFile "parallelConvChain" preludeLocationStrForEx epilogueLocationStrForEx
    "pyExamples/parallelConvChain.py" False downsampleStencilChain
