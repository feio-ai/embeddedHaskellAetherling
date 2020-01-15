module Aetherling.Interpretations.Backend_Execute.Chisel.Expr_To_String where
import Aetherling.Interpretations.Backend_Execute.Expr_To_String_Helpers
import Aetherling.Interpretations.Backend_Execute.Value_To_String
import qualified Aetherling.Rewrites.Rewrite_Helpers as RH
import qualified Aetherling.Monad_Helpers as MH
import Aetherling.Languages.Space_Time.Deep.Expr
import Aetherling.Languages.Space_Time.Deep.Types
import qualified Aetherling.Languages.Sequence.Deep.Expr_Type_Conversions as Seq_Conv
import qualified Aetherling.Languages.Space_Time.Deep.Expr_Type_Conversions as ST_Conv
import Control.Monad.Except
import Control.Monad.State
import Control.Monad.Identity
import Aetherling.Monad_Helpers
import Data.Either
import Debug.Trace
import Data.List

chisel_prelude :: String
chisel_prelude =
  "package aetherling.modules\n" ++
  "import aetherling.modules.helpers._\n" ++
  "import aetherling.modules.higherorder._\n" ++
  "import aetherling.types._\n" ++
  "import chisel3._\n\n"

chisel_verilog_output_epilogue :: String
chisel_verilog_output_epilogue =
  "object Top extends App {\n" ++
  tab_str ++ "chisel3.Driver.execute(Array[String](), () => new Top)\n" ++
  "}"

module_to_chisel_string :: Expr -> Backend_String_Results
module_to_chisel_string e = do
  let prelude = chisel_prelude
  let (outer_module_ref, lines) = runState (runExceptT $ startEvalMemoT $ print_module e) empty_print_data
  if isLeft outer_module_ref
    then Backend_String_Results
         (RH.rw_msg $ fromLeft undefined outer_module_ref)
         error_module_ref
    else do
    let mod_body = foldl (++) "" $ fmap (\line -> line ++ "\n") $ modules lines
   -- epilogue <- magma_epilogue
    Backend_String_Results
      (prelude ++ "\n" ++ mod_body)
      (fromRight undefined outer_module_ref)

-- this handles creating a module
print_module :: Expr -> Memo_Print_StateM Backend_Module_Ref Backend_Module_Ref
print_module new_module = do
  -- get state at start of module
  start_data <- lift get

  -- setup state for inside module
  let inner_data = start_data {
        cur_module_output_lines = [],
        cur_module_inputs = [],
        cur_module_num_non_inputs = 0,
        is_top_module = False
        }
  lift $ put inner_data

  -- a reference to the last operator in the module (the result)
  cur_module_result_ref <- module_to_string_inner new_module

  -- get state after executing inside module
  end_data <- lift get
  let cur_inputs = sortBy (\x y -> compare (port_name x) (port_name y)) $
                   cur_module_inputs end_data
        
  if cur_module_num_non_inputs end_data == 1 && (not $ is_top_module start_data)
    then do
    -- setup for outer module
    lift $ put $ start_data {
      next_module_index = next_module_index end_data,
      modules = modules end_data
      }
    return $ Backend_Module_Ref (cur_module_last_op_no_assign end_data) ""
      (in_ports cur_module_result_ref) (out_port cur_module_result_ref)
    else do
    let cur_module_index = next_module_index end_data
    let cur_module_name = if is_top_module start_data
          then "Top"
          else "Module_" ++ show cur_module_index

    -- module declaration as scala class
    {-
    let interface_str = 
          if length cur_inputs == 0 then "NullaryInterface"
          else if length cur_inputs == 1 then "UnaryInterface"
          else "BinaryInterface"
    -}
    use_valids <- use_valid_port
    let valid_ports_str = if use_valids then " with ValidInterface" else ""
    let port_trait = case length cur_inputs of
                       0 -> " with NullaryInterface"
                       1 -> " with UnaryInterface"
                       _ -> " with BinaryInterface"
    let module_class_string = "class " ++ cur_module_name ++ "() extends " ++
          "MultiIOModule " ++ port_trait ++ valid_ports_str ++ " {\n"

    -- chisel interface declaration of module IO ports
    let cur_inputs_str =
          if length cur_inputs >= 1
          then foldl (\port_accum next_port -> port_accum ++
                       tab_str ++ "val " ++ port_name next_port ++
                       " = IO(Input(" ++ type_to_chisel (port_type next_port) ++
                       ".chiselRepr()))\n")
              "" cur_inputs
          else ""
    let cur_output_str = tab_str ++ "val O = IO(Output(" ++
                         (type_to_chisel $ port_type $
                           out_port cur_module_result_ref) ++ ".chiselRepr()))\n"

    -- build module body
    let module_body = foldl (++) "" $ fmap (\b -> tab_str ++ b ++ "\n") $
                      cur_module_output_lines end_data

    -- wire up operator in body to output ports
    let cur_module_result_str = get_module_out_port_str cur_module_result_ref
    let module_wire_output = tab_str ++ "O := "  ++ cur_module_result_str ++ "\n"
    let cur_module_valid_str = get_module_valid_down_str cur_module_result_ref
    let module_valid_output =
          if use_valids
          then tab_str ++ "valid_down := " ++ cur_module_valid_str ++ "\n"
          else ""

    -- compose strings for module into one string
    let module_end = "}\n"
    let module_str = module_class_string ++ cur_inputs_str ++ cur_output_str ++
                    module_body ++ module_wire_output ++ module_valid_output ++
                    module_end

    -- setup for outer module
    lift $ put $ start_data {
      next_module_index = cur_module_index + 1,
      modules = modules end_data ++ [module_str]
      }
    --traceShowM $ "module " ++ cur_module_name
    --traceShowM $ show cur_inputs
    --traceShowM $ show cur_module_result_ref
    return $ Backend_Module_Ref (cur_module_name ++ "()") "" cur_inputs
      (out_port cur_module_result_ref)


-- this handles the strings inside a module
module_to_string_inner :: Expr -> Memo_Print_StateM Backend_Module_Ref Backend_Module_Ref
module_to_string_inner (IdN producer_e cur_idx) = throwError $ RH.Print_Failure "id not supported to chisel"
module_to_string_inner consumer_e@(AbsN producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let cur_ref = Backend_Module_Ref cur_ref_name ("Abs" ++ valid_str ++
                                                 "(STInt(" ++ int_width ++ "))")
                [Module_Port "I" IntT] (Module_Port "O" IntT)
  print_unary_operator cur_ref producer_ref
  return cur_ref
module_to_string_inner consumer_e@(NotN producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let cur_ref = Backend_Module_Ref cur_ref_name ("Not" ++ valid_str ++ "()")
                [Module_Port "I" BitT] (Module_Port "O" BitT)
  print_unary_operator cur_ref producer_ref
  return cur_ref
module_to_string_inner consumer_e@(AddN producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let cur_ref = Backend_Module_Ref cur_ref_name ("Add" ++ valid_str ++
                                                 "(STInt(" ++ int_width ++ "))")
                [Module_Port "I" IntT] (Module_Port "O" IntT)
  print_unary_operator cur_ref producer_ref
  return cur_ref
module_to_string_inner consumer_e@(SubN producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let cur_ref = Backend_Module_Ref cur_ref_name ("Sub" ++ valid_str ++
                                                 "(STInt(" ++ int_width ++ "))")
                [Module_Port "I" IntT] (Module_Port "O" IntT)
  print_unary_operator cur_ref producer_ref
  return cur_ref
module_to_string_inner consumer_e@(LSRN producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let cur_ref = Backend_Module_Ref cur_ref_name ("RShift" ++ valid_str ++
                                                 "(STInt(" ++ int_width ++ "))")
                [Module_Port "I" IntT] (Module_Port "O" IntT)
  print_unary_operator cur_ref producer_ref
  return cur_ref
module_to_string_inner consumer_e@(LSLN producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let cur_ref = Backend_Module_Ref cur_ref_name ("LShift" ++ valid_str ++
                                                 "(STInt(" ++ int_width ++ "))")
                [Module_Port "I" IntT] (Module_Port "O" IntT)
  print_unary_operator cur_ref producer_ref
  return cur_ref
module_to_string_inner consumer_e@(LtN producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let cur_ref = Backend_Module_Ref cur_ref_name ("Lt" ++ valid_str ++
                                                 "(STInt(" ++ int_width ++ "))")
                [Module_Port "I" (ATupleT IntT IntT)] (Module_Port "O" BitT)
  print_unary_operator cur_ref producer_ref
  return cur_ref
module_to_string_inner consumer_e@(EqN t producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let cur_ref = Backend_Module_Ref cur_ref_name ("Eq" ++ valid_str ++
                                                 "(" ++ type_to_chisel t ++ "))")
                [Module_Port "I" (port_type $ out_port producer_ref)]
                (Module_Port "O" BitT)
  print_unary_operator cur_ref producer_ref
  return cur_ref
module_to_string_inner consumer_e@(IfN t producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let cur_ref = Backend_Module_Ref cur_ref_name ("If" ++ valid_str ++
                                                 "(" ++ type_to_chisel t ++ ")")
                [Module_Port "I" (ATupleT BitT (ATupleT t t))]
                (Module_Port "O" t)
  print_unary_operator cur_ref producer_ref
  return cur_ref
  
-- generators
module_to_string_inner consumer_e@(Const_GenN constant t delay cur_idx) = do
  -- the chisel const_gen is not a module. It's just a function that
  -- adds some properties. Therefore, it doesn't get wrapped in a Module
  -- with a new call
  let cur_ref_name = "const" ++ print_index cur_idx
  let const_values_str =
        convert_seq_val_to_st_val_string (flatten_ast_value constant)
        (TSeqT 1 0 t) chisel_hardware_conf
  let gen_str = "Const(" ++ type_to_chisel t ++
                ", " ++ st_values const_values_str ++
                ", " ++ show delay ++ ", valid_up)"
  let out_port_name = (cur_ref_name ++ "_O")
  let cur_ref_valid_str = cur_ref_name ++ "_valid_up"
  let cur_ref = Backend_Module_Ref cur_ref_name gen_str
                [] (Module_Port out_port_name t)
  add_to_cur_module $ "val (" ++ out_port_name ++ ", " ++
    cur_ref_name ++ "_valid_down) = " ++ gen_call cur_ref
  update_output $ Module_Port out_port_name t
  -- no need for valid_up wiring as valid is passed to function call
  return cur_ref

-- sequence operators

-- higher order operators
module_to_string_inner consumer_e@(Map_sN n f producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  Backend_Module_Ref f_name f_gen_call f_in_ports f_out_port <- memo f $ print_module f
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let gen_str = "MapS" ++ valid_str ++ "(" ++ show n ++ ", new " ++ f_name ++ ")"
  let map_in_ports =
        map (\port -> port {port_type = SSeqT n (port_type port)}) f_in_ports
  let map_out_port = f_out_port {port_type = SSeqT n (port_type f_out_port)}
  let cur_ref = Backend_Module_Ref cur_ref_name gen_str map_in_ports map_out_port
  print_unary_operator cur_ref producer_ref
  return cur_ref

module_to_string_inner consumer_e@(Map_tN n i f producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  Backend_Module_Ref f_name f_gen_call f_in_ports f_out_port <- memo f $ print_module f
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let gen_str = "MapT" ++ valid_str ++ "(new " ++ f_name ++ ")"
  let map_in_ports =
        map (\port -> port {port_type = TSeqT n i (port_type port)}) f_in_ports
  let map_out_port = f_out_port {port_type = TSeqT n i (port_type f_out_port)}
  let cur_ref = Backend_Module_Ref cur_ref_name gen_str map_in_ports map_out_port
  print_unary_operator cur_ref producer_ref
  return cur_ref

module_to_string_inner consumer_e@(Map2_sN n f producer0_e producer1_e cur_idx) = do
  producer0_ref <- memo producer0_e $ module_to_string_inner producer0_e
  producer1_ref <- memo producer1_e $ module_to_string_inner producer1_e
  Backend_Module_Ref f_name f_gen_call f_in_ports f_out_port <- memo f $ print_module f
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = show use_valids
  let valid_str = if use_valids then "" else "NoValid"
  let gen_str = "Map2S" ++ valid_str ++ "(" ++ show n ++ ",new " ++ f_name ++ ")"
  let map_in_ports =
        map (\port -> port {port_type = SSeqT n (port_type port)}) f_in_ports
  let map_out_port = f_out_port {port_type = SSeqT n (port_type f_out_port)}
  let cur_ref = Backend_Module_Ref cur_ref_name gen_str map_in_ports map_out_port
  print_binary_operator cur_ref producer0_ref producer1_ref
  return cur_ref

module_to_string_inner consumer_e@(Map2_tN n i f producer0_e producer1_e cur_idx) = do
  producer0_ref <- memo producer0_e $ module_to_string_inner producer0_e
  producer1_ref <- memo producer1_e $ module_to_string_inner producer1_e
  Backend_Module_Ref f_name f_gen_call f_in_ports f_out_port <- memo f $ print_module f
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = show use_valids
  let valid_str = if use_valids then "" else "NoValid"
  let gen_str = "Map2T" ++ valid_str ++ "(new " ++ f_name ++ ")"
  let map_in_ports =
        map (\port -> port {port_type = TSeqT n i (port_type port)}) f_in_ports
  let map_out_port = f_out_port {port_type = TSeqT n i (port_type f_out_port)}
  let cur_ref = Backend_Module_Ref cur_ref_name gen_str map_in_ports map_out_port
  print_binary_operator cur_ref producer0_ref producer1_ref
  return cur_ref
  
module_to_string_inner consumer_e@(ATupleN t0 t1 producer0_e producer1_e cur_idx) = do
  producer0_ref <- memo producer0_e $ module_to_string_inner producer0_e
  producer1_ref <- memo producer1_e $ module_to_string_inner producer1_e
  let cur_ref_name = "n" ++ print_index cur_idx
  use_valids <- use_valid_port
  let valid_str = if use_valids then "" else "NoValid"
  let gen_str = "AtomTuple" ++ valid_str ++ "(" ++ type_to_chisel t0 ++ ", " ++
                type_to_chisel t1 ++ ")"
  let tup_in_ports = [Module_Port "I0" t0, Module_Port "I1" t1]
  let tup_out_port = Module_Port "O" (ATupleT t0 t1)
  let cur_ref = Backend_Module_Ref cur_ref_name gen_str tup_in_ports tup_out_port
  print_binary_operator cur_ref producer0_ref producer1_ref
  return cur_ref

module_to_string_inner (InputN t name cur_idx) = do
  cur_data <- lift get
  lift $ put $ cur_data {
    cur_module_inputs = cur_module_inputs cur_data ++ [Module_Port name t]
    }
  return $ Backend_Module_Ref "cls" "" [] (Module_Port name t)
module_to_string_inner e@(ErrorN msg cur_idx) = do
  let cur_ref_name = "n" ++ print_index cur_idx
  add_to_cur_module $ "ERROR " ++ msg
  incr_num_non_inputs_cur_module $ "ERROR " ++ msg
  return $ Backend_Module_Ref cur_ref_name "" [Module_Port "error" BitT]
    (Module_Port "error" BitT)
module_to_string_inner consumer_e@(FIFON t delay_clks producer_e cur_idx) = do
  producer_ref <- memo producer_e $ module_to_string_inner producer_e
  let cur_ref_name = "n" ++ print_index cur_idx
  let gen_str = "FIFO(" ++ type_to_chisel t ++
                ", " ++ show delay_clks ++ ")"
  let cur_ref = Backend_Module_Ref cur_ref_name gen_str
                [Module_Port "I" t] (Module_Port "O" t)
  print_unary_operator cur_ref producer_ref
  return cur_ref
module_to_string_inner consumer_e = error $ "don't support yet: " ++
                                    show consumer_e 

print_unary_operator :: Backend_Module_Ref -> Backend_Module_Ref ->
                        Memo_Print_StateM Backend_Module_Ref ()
print_unary_operator cur_ref producer_ref = do
  add_to_cur_module $ "val " ++ var_name cur_ref ++ " = Module(new " ++
    gen_call cur_ref ++ ")"
  update_output $ out_port cur_ref
  let producer_out_str = get_module_out_port_str producer_ref
  let cur_ref_in_str = var_name cur_ref ++ "." ++
                       (port_name $ in_ports cur_ref !! 0) 
  add_to_cur_module $ cur_ref_in_str ++ " := " ++ producer_out_str
  incr_num_non_inputs_cur_module $ gen_call cur_ref
  valid_bool <- use_valid_port
  if valid_bool
    then do
    let producer_valid_str = get_module_valid_down_str producer_ref
    let cur_ref_valid_str = var_name cur_ref ++ ".valid_up"
    add_to_cur_module $ cur_ref_valid_str ++ " := " ++ producer_valid_str
    else return ()

print_binary_operator :: Backend_Module_Ref -> Backend_Module_Ref ->
                         Backend_Module_Ref -> Memo_Print_StateM Backend_Module_Ref ()
print_binary_operator cur_ref producer_ref_left producer_ref_right = do
  add_to_cur_module $ "val " ++ var_name cur_ref ++ " = Module(new " ++
    gen_call cur_ref ++ ")"
  update_output $ out_port cur_ref
  let producer_out_str_left = get_module_out_port_str producer_ref_left
  let producer_out_str_right = get_module_out_port_str producer_ref_right
  let cur_ref_in_str_left = var_name cur_ref ++ "." ++
                            (port_name $ in_ports cur_ref !! 0) 
  let cur_ref_in_str_right = var_name cur_ref ++ "." ++
                             (port_name $ in_ports cur_ref !! 1) 
  add_to_cur_module $ cur_ref_in_str_left ++ " := " ++ producer_out_str_left
  add_to_cur_module $ cur_ref_in_str_right ++ " := " ++ producer_out_str_right
  incr_num_non_inputs_cur_module $ gen_call cur_ref
  valid_bool <- use_valid_port
  if valid_bool
    then do
    let producer_valid_str_left = get_module_valid_down_str producer_ref_left
    let producer_valid_str_right = get_module_valid_down_str producer_ref_right
    let producer_valid_str = producer_valid_str_left ++ " & " ++
                             producer_valid_str_right
    let cur_ref_valid_str = var_name cur_ref ++ ".valid_up"
    add_to_cur_module $ cur_ref_valid_str ++ " := " ++ producer_valid_str
    else return ()

get_module_out_port_str :: Backend_Module_Ref -> String
get_module_out_port_str ref | var_name ref == "cls" = port_name $ out_port ref
get_module_out_port_str ref | isPrefixOf "const" (var_name ref) =
                              port_name $ out_port ref
get_module_out_port_str ref =
  var_name ref ++ "." ++ (port_name $ out_port ref)
  
get_module_valid_down_str :: Backend_Module_Ref -> String
get_module_valid_down_str ref | var_name ref == "cls" = "valid_up"
get_module_valid_down_str ref | isPrefixOf "const" (var_name ref) =
                              var_name ref ++ "_valid_down"
get_module_valid_down_str ref =
  var_name ref ++ "." ++ "valid_down"

type_to_chisel :: AST_Type -> String
type_to_chisel UnitT = "undefined"
type_to_chisel BitT = "STBit()"
type_to_chisel IntT = "STInt(8)"
type_to_chisel (ATupleT t0 t1) =
  "STAtomTuple(" ++
  type_to_chisel t0 ++ ", " ++
  type_to_chisel t1 ++
  ")"
type_to_chisel (STupleT n t) =
  "SSeq_Tuple(" ++ show n ++ ", " ++ type_to_chisel t ++ ")"
type_to_chisel (SSeqT n t) =
  "SSeq(" ++ show n ++ ", " ++ type_to_chisel t ++ ")"
type_to_chisel (TSeqT n i t) =
  "TSeq(" ++ show n ++ ", " ++ show i ++ ", " ++ type_to_chisel t ++ ")"
