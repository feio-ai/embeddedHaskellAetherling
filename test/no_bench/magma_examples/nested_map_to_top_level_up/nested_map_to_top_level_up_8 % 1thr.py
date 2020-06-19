import fault
import aetherling.helpers.fault_helpers as fault_helpers
from aetherling.space_time import *
from aetherling.space_time.reshape_st import DefineReshape_ST
import magma as m
import json


@cache_definition 
def Module_0() -> DefineCircuitKind:
    class _Module_0(Circuit):
        name = "top"
        IO = ['I', In(ST_SSeq(1, ST_TSeq(2, 0, ST_SSeq(2, ST_Int(8, True)))).magma_repr()),'O', Out(ST_SSeq(4, ST_TSeq(2, 0, ST_SSeq(2, ST_Int(8, True)))).magma_repr())] + ClockInterface(has_ce=False,has_reset=False) + valid_ports
        st_in_t = [ST_SSeq(1, ST_TSeq(2, 0, ST_SSeq(2, ST_Int(8, True))))]
        st_out_t = ST_SSeq(4, ST_TSeq(2, 0, ST_SSeq(2, ST_Int(8, True))))
        binary_op = False
        @classmethod
        def definition(cls):
            n1 = DefineFIFO(ST_SSeq(1, ST_TSeq(2, 0, ST_SSeq(2, ST_Int(8, True)))), 1, has_valid=True)()
            wire(cls.I, n1.I)
            wire(cls.valid_up, n1.valid_up)
            n8 = DefineMap_S(1, DefineMap_T(2, 0, DefineMap_S(2, DefineAbs_Atom(True),True)),True)()
            wire(n1.O, n8.I)
            wire(n1.valid_down, n8.valid_up)
            n9 = DefineUp_S(4, ST_TSeq(2, 0, ST_SSeq(2, ST_Int(8, True))), has_valid=True)()
            wire(n8.O, n9.I)
            wire(n8.valid_down, n9.valid_up)
            n10 = DefineFIFO(ST_SSeq(4, ST_TSeq(2, 0, ST_SSeq(2, ST_Int(8, True)))), 1, has_valid=True)()
            wire(n9.O, n10.I)
            wire(n9.valid_down, n10.valid_up)
            n11 = DefineFIFO(ST_SSeq(4, ST_TSeq(2, 0, ST_SSeq(2, ST_Int(8, True)))), 1, has_valid=True)()
            wire(n10.O, n11.I)
            wire(n10.valid_down, n11.valid_up)
            n12 = DefineFIFO(ST_SSeq(4, ST_TSeq(2, 0, ST_SSeq(2, ST_Int(8, True)))), 1, has_valid=True)()
            wire(n11.O, n12.I)
            wire(n11.valid_down, n12.valid_up)
            wire(n12.O, cls.O)
            wire(n12.valid_down, cls.valid_down)
    return _Module_0

Main = Module_0

fault_helpers.compile(Main(), "v./home/durst/dev/embeddedHaskellAetherling//test/no_bench/magma_examples/nested_map_to_top_level_up/nested_map_to_top_level_up_8 % 1thr.py")