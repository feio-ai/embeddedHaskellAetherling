module Aetherling.Languages.Sequence.Deep.Type_Checker where
import Aetherling.Languages.Sequence.Deep.Types
import Aetherling.Languages.Sequence.Deep.Expr
import Aetherling.Languages.Sequence.Deep.Expr_Type_Conversions
import Control.Monad.Except
import Data.Either

type Type_Checker_Error = Except Expr

check_type :: Expr -> Bool
check_type e = do
  let checked_result = runExcept $ check_type' e
  isRight checked_result

check_type' :: Expr -> Type_Checker_Error AST_Type
check_type' (IdN producer_e) = check_type' producer_e
check_type' consumer_e@(AbsN producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(NotN producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(AddN producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(SubN producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(MulN producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(DivN producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(EqN _ producer_e) =
  check_atom_operator consumer_e producer_e

-- generators
check_type' consumer_e@(Lut_GenN _ _ producer_e) = 
  check_atom_operator consumer_e producer_e
check_type' (Const_GenN _ t) = return t

-- sequence operators
check_type' consumer_e@(ShiftN _ _ _ _ producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(Up_1dN _ _ _ producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(Down_1dN _ _ _ _ producer_e) = 
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(PartitionN _ _ _ _ _ producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(UnpartitionN _ _ _ _ _ producer_e) =
  check_atom_operator consumer_e producer_e

-- higher order operators
check_type' consumer_e@(MapN _ _ f producer_e) = do
  check_type' f
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(Map2N _ _ f producer0_e producer1_e) = do
  check_type' f
  check_binary_operator consumer_e producer0_e producer1_e
check_type' consumer_e@(ReduceN _ _ f producer_e) = do
  check_type' f
  check_atom_operator consumer_e producer_e

-- tuple operators
check_type' consumer_e@(FstN _ _ producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(SndN _ _ producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(ATupleN _ _ producer0_e producer1_e) = do
  check_binary_operator consumer_e producer0_e producer1_e
check_type' consumer_e@(STupleN _ producer0_e producer1_e) = do
  check_binary_operator consumer_e producer0_e producer1_e
 
check_type' consumer_e@(STupleAppendN _ _ producer0_e producer1_e) = do
  check_binary_operator consumer_e producer0_e producer1_e
  
check_type' consumer_e@(STupleToSeqN _ _ _ _ _ producer_e) =
  check_atom_operator consumer_e producer_e
check_type' consumer_e@(SeqToSTupleN _ _ _ _ _ producer_e) =
  check_atom_operator consumer_e producer_e
  
check_type' (InputN t _) = return t
check_type' e@(ErrorN _) = throwError e

check_atom_operator :: Expr -> Expr -> Type_Checker_Error AST_Type
check_atom_operator consumer_op producer_op = do
  producer_output_type <- check_type' producer_op
  let consumer_input_types = e_in_types $ expr_to_types consumer_op
  let consumer_output_type = e_out_type $ expr_to_types consumer_op
  if (length consumer_input_types == 1) &&
    (head consumer_input_types == producer_output_type)
    then return consumer_output_type
    else throwError consumer_op

check_binary_operator :: Expr -> Expr -> Expr -> Type_Checker_Error AST_Type
check_binary_operator consumer_op producer_op0 producer_op1 = do
  producer0_output_type <- check_type' producer_op0
  producer1_output_type <- check_type' producer_op1
  let consumer_input_types = e_in_types $ expr_to_types consumer_op
  let consumer_output_type = e_out_type $ expr_to_types consumer_op
  if (length consumer_input_types == 2) &&
    (consumer_input_types !! 0 == producer0_output_type) &&
    (consumer_input_types !! 1 == producer1_output_type)
    then return consumer_output_type
    else throwError consumer_op