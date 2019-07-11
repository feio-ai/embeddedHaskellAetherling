module Aetherling.Rewrites.Sequence_To_Fully_Parallel_Space_Time where
import Aetherling.Rewrites.Rewrite_Helpers
import qualified Aetherling.Languages.Sequence.Deep.Expr as SeqE
import qualified Aetherling.Languages.Sequence.Deep.Types as SeqT
import qualified Aetherling.Languages.Space_Time.Deep.Expr as STE
import qualified Aetherling.Languages.Space_Time.Deep.Types as STT
import Aetherling.Languages.Sequence.Shallow.Expr_Type_Conversions
import Control.Monad.Except
import Control.Monad.Identity
import Data.Maybe
import Data.Either

type Rewrite_StateM = Except Rewrite_Failure

rewrite_to_fully_parallel :: SeqE.Expr -> STE.Expr
rewrite_to_fully_parallel seq_expr = do
  let expr_par = runExcept $ sequence_to_fully_parallel seq_expr
  if isLeft expr_par
    then STE.ErrorN (rw_msg $ fromLeft undefined expr_par)
    else fromRight undefined expr_par

sequence_to_fully_parallel :: SeqE.Expr -> Rewrite_StateM STE.Expr
sequence_to_fully_parallel (SeqE.IdN producer) = parallelize_atom_operator STE.IdN producer
sequence_to_fully_parallel (SeqE.AbsN producer) = parallelize_atom_operator STE.AbsN producer
sequence_to_fully_parallel (SeqE.NotN producer) = parallelize_atom_operator STE.NotN producer
sequence_to_fully_parallel (SeqE.AddN producer) = parallelize_atom_operator STE.AddN producer
sequence_to_fully_parallel (SeqE.SubN producer) = parallelize_atom_operator STE.SubN producer
sequence_to_fully_parallel (SeqE.MulN producer) = parallelize_atom_operator STE.MulN producer
sequence_to_fully_parallel (SeqE.DivN producer) = parallelize_atom_operator STE.DivN producer
sequence_to_fully_parallel (SeqE.EqN t producer) = do
  producer_par <- sequence_to_fully_parallel producer
  t_par <- parallelize_AST_type t
  return $ STE.EqN t_par producer_par

-- generators
sequence_to_fully_parallel node@(SeqE.Lut_GenN _ _ producer) =
  throwError $ Expr_Failure $ "Can't parallelize LUTs: " ++ show node
sequence_to_fully_parallel (SeqE.Const_GenN constant_val constant_type) = do
  t_par <- parallelize_AST_type constant_type
  v_par <- parallelize_AST_value constant_val
  return $ STE.Const_GenN v_par t_par

-- sequence operators
sequence_to_fully_parallel (SeqE.ShiftN n _ shift_amount elem_t producer) =
  parallelize_unary_seq_operator (STE.Shift_sN n shift_amount) elem_t producer
sequence_to_fully_parallel (SeqE.Up_1dN n _ elem_t producer) =
  parallelize_unary_seq_operator (STE.Up_1d_sN n) elem_t producer
sequence_to_fully_parallel (SeqE.Down_1dN n _ sel_idx elem_t producer) =
  parallelize_unary_seq_operator (STE.Down_1d_sN n sel_idx) elem_t producer
sequence_to_fully_parallel (SeqE.PartitionN no ni _ _ elem_t producer) =
  parallelize_unary_seq_operator (STE.Partition_s_ssN no ni) elem_t producer
sequence_to_fully_parallel (SeqE.UnpartitionN no ni _ _ elem_t producer) =
  parallelize_unary_seq_operator (STE.Unpartition_s_ssN no ni) elem_t producer

-- higher order operators
sequence_to_fully_parallel (SeqE.MapN n _ f producer) = do
  f_par <- sequence_to_fully_parallel f
  producer_par <- sequence_to_fully_parallel producer
  return $ STE.Map_sN n f_par producer_par
sequence_to_fully_parallel (SeqE.Map2N n _ f producer_left producer_right) = do
  f_par <- sequence_to_fully_parallel f
  producer_left_par <- sequence_to_fully_parallel producer_left
  producer_right_par <- sequence_to_fully_parallel producer_right
  return $ STE.Map2_sN n f_par producer_left_par producer_right_par
sequence_to_fully_parallel (SeqE.ReduceN n _ f producer) = do
  f_par <- sequence_to_fully_parallel f
  producer_par <- sequence_to_fully_parallel producer
  return $ STE.Reduce_sN n f_par producer_par

-- tuple operations
sequence_to_fully_parallel (SeqE.FstN t0 t1 producer) = do
  producer_par <- sequence_to_fully_parallel producer
  t0_par <- parallelize_AST_type t0
  t1_par <- parallelize_AST_type t1
  return $ STE.FstN t0_par t1_par producer_par

sequence_to_fully_parallel (SeqE.SndN t0 t1 producer) = do
  producer_par <- sequence_to_fully_parallel producer
  t0_par <- parallelize_AST_type t0
  t1_par <- parallelize_AST_type t1
  return $ STE.SndN t0_par t1_par producer_par

sequence_to_fully_parallel (SeqE.ATupleN t0 t1 producer_left producer_right) = do
  producer_left_par <- sequence_to_fully_parallel producer_left
  producer_right_par <- sequence_to_fully_parallel producer_right
  t0_par <- parallelize_AST_type t0
  t1_par <- parallelize_AST_type t1
  return $ STE.ATupleN t0_par t1_par producer_left_par producer_right_par

sequence_to_fully_parallel (SeqE.STupleN elem_t producer_left producer_right) = do
  t_par <- parallelize_AST_type elem_t
  producer_left_par <- sequence_to_fully_parallel producer_left
  producer_right_par <- sequence_to_fully_parallel producer_right
  return $ STE.STupleN t_par producer_left_par producer_right_par

sequence_to_fully_parallel (SeqE.STupleAppendN out_len elem_t producer_left producer_right) = do
  t_par <- parallelize_AST_type elem_t
  producer_left_par <- sequence_to_fully_parallel producer_left
  producer_right_par <- sequence_to_fully_parallel producer_right
  return $ STE.STupleAppendN out_len t_par producer_left_par producer_right_par
  
sequence_to_fully_parallel (SeqE.STupleToSeqN no ni io ii elem_t producer) = do
  t_par <- parallelize_AST_type elem_t
  producer_par <- sequence_to_fully_parallel producer
  return $ STE.Map_sN no (STE.STupleToSSeqN ni t_par (STE.InputN t_par "seq_in")) producer_par
  
sequence_to_fully_parallel (SeqE.SeqToSTupleN no ni io ii elem_t producer) = do
  t_par <- parallelize_AST_type elem_t
  producer_par <- sequence_to_fully_parallel producer
  return $ STE.Map_sN no (STE.SSeqToSTupleN ni t_par (STE.InputN t_par "seq_in")) producer_par

sequence_to_fully_parallel (SeqE.InputN t input_name) = do
  t_par <- parallelize_AST_type t
  return $ STE.InputN t_par input_name

sequence_to_fully_parallel (SeqE.ErrorN s) = return $ STE.ErrorN s

parallelize_AST_type :: SeqT.AST_Type -> Rewrite_StateM STT.AST_Type
parallelize_AST_type SeqT.UnitT = return STT.UnitT
parallelize_AST_type SeqT.BitT = return STT.BitT
parallelize_AST_type SeqT.IntT = return STT.IntT
parallelize_AST_type (SeqT.ATupleT x y) = do
  x_stt <- parallelize_AST_type x
  y_stt <- parallelize_AST_type y
  return $ (STT.ATupleT x_stt y_stt) 
parallelize_AST_type (SeqT.SeqT n _ t) = do
  inner_type <- parallelize_AST_type t
  return $ STT.SSeqT n inner_type
parallelize_AST_type (SeqT.STupleT n t) = do
  inner_type <- parallelize_AST_type t
  return $ STT.STupleT n inner_type

parallelize_AST_value :: SeqT.AST_Value -> Rewrite_StateM STT.AST_Value
parallelize_AST_value SeqT.UnitV = return STT.UnitV
parallelize_AST_value (SeqT.BitV b) = return (STT.BitV b)
parallelize_AST_value (SeqT.IntV i) = return (STT.IntV i)
parallelize_AST_value (SeqT.ATupleV x y) = do
  x_stv <- parallelize_AST_value x
  y_stv <- parallelize_AST_value y
  return $ (STT.ATupleV x_stv y_stv) 
parallelize_AST_value (SeqT.SeqV xs _) = do
  xs_par <- mapM parallelize_AST_value xs
  return $ STT.SSeqV xs_par
parallelize_AST_value (SeqT.STupleV xs) = do
  xs_par <- mapM parallelize_AST_value xs
  return $ STT.STupleV xs_par

parallelize_atom_operator :: (STE.Expr -> STE.Expr) -> SeqE.Expr -> Rewrite_StateM STE.Expr
parallelize_atom_operator atom_op_gen producer = do
  producer_par <- sequence_to_fully_parallel producer
  return $ atom_op_gen producer_par
  
parallelize_unary_seq_operator :: (STT.AST_Type -> STE.Expr -> STE.Expr) -> SeqT.AST_Type ->
                                  SeqE.Expr -> Rewrite_StateM STE.Expr
parallelize_unary_seq_operator unary_seq_op_gen t producer = do
  producer_par <- sequence_to_fully_parallel producer
  t_par <- parallelize_AST_type t
  return $ unary_seq_op_gen t_par producer_par
