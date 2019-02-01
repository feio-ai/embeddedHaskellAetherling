module LineBuffer where
import GHC.TypeLits
import GHC.TypeLits.Extra
import GHC.Exts (Constraint)
import Data.Typeable
import DataTypes

-- | first arg is pixels per clock in each dimension. First value in list is
-- outer most dimension that iterating over (rows first, columns second in 2d
-- case). second arg is window width in each dimension. Same indexing order.
-- third arg is the size of the image. Same indexing order. This is necessary
-- for internal buffer sizing. Fourth is how far apart each window is from
-- the last one. Origin is the location of the window relative to the pixel
-- that's being moved along the image. Last is the type of the pixel element
data LineBufferData = LineBufferData {
  lbWindow :: (Int, Int),
  lbImage :: (Int, Int),
  lbStride :: (Int, Int),
  lbOrigin :: (Int, Int),
  lbToken :: TypeRep
} deriving (Eq, Show)

linebufferDataValid :: Int -> LineBufferData -> [String]
linebufferDataValid par lbData = yParOkReason ++ xParOkReason ++ onlyYParIfXFullyParReason ++
  yStrideFitsImageReason ++ xStrideFitsImageReason ++ strideOrPixelsDivideEachOtherReason ++
  yOriginFitsInWindowReason ++ xOriginFitsInWindowReason ++ yOriginOnlyBackwardReason ++
  xOriginOnlyBackwardReason ++ yWindowAndOriginFitInImageReason ++
  xWindowAndOriginFitInImageReason
  where
    lbPxPerClk = (max (par `div` (snd $ lbImage lbData)) 1, par `mod` (snd $ lbImage lbData))
    yParOk = (fst $ lbImage lbData) `mod` (fst $ lbPxPerClk) == 0
    yParOkReason = if yParOk then [] else ["y parallelism doesn't divide the y image dimension. "]
    xParOk = (snd $ lbImage lbData) `mod` (snd $ lbPxPerClk) == 0
    xParOkReason = if xParOk then [] else ["x parallelism doesn't divide the x image dimension. "]
    onlyYParIfXFullyPar = ((fst lbPxPerClk) == 1) || 
      ((snd $ lbImage lbData) == (snd lbPxPerClk))
    onlyYParIfXFullyParReason = if onlyYParIfXFullyPar then [] else ["y parallelism must be 1 unless x parallelism equals x dimension size. "]
    yStrideFitsImage = (fst $ lbImage lbData) `mod` (fst $ lbStride lbData) == 0
    yStrideFitsImageReason = if yStrideFitsImage then [] else ["y stride must fit in y image size. "]
    xStrideFitsImage = (snd $ lbImage lbData) `mod` (snd $ lbStride lbData) == 0
    xStrideFitsImageReason = if xStrideFitsImage then [] else ["x stride must fit in x image size. "]
    strideOrPixelsDivideEachOther =
      (((fst $ lbStride lbData) * (snd $ lbStride lbData)) `mod`
       ((fst $ lbPxPerClk) * (snd $ lbPxPerClk)) == 0) ||
      (((fst $ lbPxPerClk) * (snd $ lbPxPerClk)) `mod`
       ((fst $ lbStride lbData) * (snd $ lbStride lbData)) == 0)
    strideOrPixelsDivideEachOtherReason = if strideOrPixelsDivideEachOther
      then []
      else ["either the stride area must divide the parallelism area or vice versa. "]
    yOriginFitsInWindow = (fst $ lbWindow lbData) > (fst $ lbOrigin lbData)
    yOriginFitsInWindowReason = if yOriginFitsInWindow
      then []
      else ["y origin offset must be less than 1 window in y dimension. "]
    xOriginFitsInWindow = (snd $ lbWindow lbData) > (snd $ lbOrigin lbData)
    xOriginFitsInWindowReason = if xOriginFitsInWindow
      then []
      else ["x origin offset must be less than 1 window in x dimension. "]
    yOriginOnlyBackward = (fst $ lbOrigin lbData) >= 0
    yOriginOnlyBackwardReason = if yOriginOnlyBackward
      then []
      else ["y origin must be non-negative as proxies can only have positive " ++
            "knownnat's and thus the number must negated when printed to magma. "]
    xOriginOnlyBackward = (snd $ lbOrigin lbData) >= 0
    xOriginOnlyBackwardReason = if xOriginOnlyBackward
      then []
      else ["x origin must be non-negative as proxies can only have positive " ++
            "knownnat's and thus the number must negated when printed to magma. "]
    yWindowAndOriginFitInImage = ((fst $ lbWindow lbData) +
                                  (fst $ lbOrigin lbData)) < (fst $ lbImage lbData)
    yWindowAndOriginFitInImageReason = if yWindowAndOriginFitInImage then []
      else ["y window plus positive origin must fit in the image, this doesn't. "]
    xWindowAndOriginFitInImage = ((snd $ lbWindow lbData) +
                                  (snd $ lbOrigin lbData)) < (snd $ lbImage lbData)
    xWindowAndOriginFitInImageReason = if xWindowAndOriginFitInImage then []
      else ["x window plus positive origin must fit in the image, this doesn't. "]

{-
lineBufferInputType :: (AtomBaseType a) => LineBufferData a -> Seq 
lineBufferInputType lbData =
  let
    (yPerClk, xPerClk) = lbPxPerClk lbData
    inArea = yPerClk * xPerClk
    (imgY, imgX) = lbImage lbData
    imgArea = imgY * imgX
    seqLen = imgArea `div` inArea
    arrayToken = T_Array yPerClk (T_Array xPerClk (lbToken lbData))
  in
    if imgY `mod` yPerClk /= 0 || imgX `mod` xPerClk /= 0 then
      error "px/clk width/height must divide image width/height."
    else
      [T_Port "I" seqLen arrayToken 1 False]

outPorts (LineBuffer lbData) = let
    (yPerClk, xPerClk) = lbPxPerClk lbData
    (strideY, strideX) = lbStride lbData
    (imgY, imgX) = lbImage lbData
    (winY, winX) = lbWindow lbData
    strideArea = strideX * strideY
    imgArea = imgX * imgY

    -- The number of parallel window outputs needed.
    parallelism = getLineBufferParallelism lbData

    windowCount = div imgArea strideArea
    seqLen = div windowCount parallelism
    windowToken = T_Array winY $ T_Array winX (lbToken lbData)
    arrayToken = T_Array parallelism $ windowToken
  in
    if yPerClk /= 1 then
      error "Expected pxPerClk to have height 1."
    else if xPerClk `mod` strideArea /= 0 && strideArea `mod` xPerClk /= 0 then
      error "Window throughput must be integer (or reciprocal of integer)."
    else
[T_Port "O" seqLen arrayToken 1 False]

-- The number of parallel window outputs needed.
getLineBufferParallelism :: LineBufferData -> Int
getLineBufferParallelism lb =
  let
    (yPerClk, xPerClk) = lbPxPerClk lb
    (strideY, strideX) = lbStride lb
    strideArea = strideY * strideX
  in
max 1 (div (xPerClk * yPerClk) strideArea)
-}
