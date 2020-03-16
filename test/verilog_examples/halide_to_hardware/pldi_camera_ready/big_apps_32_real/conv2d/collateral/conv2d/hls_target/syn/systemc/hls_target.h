// ==============================================================
// RTL generated by Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC
// Version: 2017.2
// Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
// 
// ===========================================================

#ifndef _hls_target_HH_
#define _hls_target_HH_

#include "systemc.h"
#include "AESL_pkg.h"

#include "linebuffer_1.h"
#include "Loop_1_proc.h"
#include "fifo_w288_d1_S.h"
#include "start_for_Loop_1_ibs.h"

namespace ap_rtl {

struct hls_target : public sc_module {
    // Port declarations 18
    sc_in< sc_lv<32> > hw_input_V_value_V;
    sc_in< sc_lv<1> > hw_input_V_last_V;
    sc_out< sc_lv<32> > hw_output_V_value_V;
    sc_out< sc_lv<1> > hw_output_V_last_V;
    sc_in_clk ap_clk;
    sc_in< sc_logic > ap_rst;
    sc_in< sc_logic > hw_input_V_value_V_ap_vld;
    sc_out< sc_logic > hw_input_V_value_V_ap_ack;
    sc_in< sc_logic > hw_input_V_last_V_ap_vld;
    sc_out< sc_logic > hw_input_V_last_V_ap_ack;
    sc_out< sc_logic > hw_output_V_value_V_ap_vld;
    sc_in< sc_logic > hw_output_V_value_V_ap_ack;
    sc_out< sc_logic > hw_output_V_last_V_ap_vld;
    sc_in< sc_logic > hw_output_V_last_V_ap_ack;
    sc_out< sc_logic > ap_done;
    sc_in< sc_logic > ap_start;
    sc_out< sc_logic > ap_ready;
    sc_out< sc_logic > ap_idle;
    sc_signal< sc_logic > ap_var_for_const0;


    // Module declarations
    hls_target(sc_module_name name);
    SC_HAS_PROCESS(hls_target);

    ~hls_target();

    sc_trace_file* mVcdFile;

    ofstream mHdltvinHandle;
    ofstream mHdltvoutHandle;
    linebuffer_1* linebuffer_1_U0;
    Loop_1_proc* Loop_1_proc_U0;
    fifo_w288_d1_S* p_hw_input_stencil_st_U;
    start_for_Loop_1_ibs* start_for_Loop_1_ibs_U;
    sc_signal< sc_logic > linebuffer_1_U0_ap_start;
    sc_signal< sc_logic > linebuffer_1_U0_start_full_n;
    sc_signal< sc_logic > linebuffer_1_U0_ap_ready;
    sc_signal< sc_logic > linebuffer_1_U0_start_out;
    sc_signal< sc_logic > linebuffer_1_U0_start_write;
    sc_signal< sc_lv<288> > linebuffer_1_U0_out_stream_V_value_V_din;
    sc_signal< sc_logic > linebuffer_1_U0_out_stream_V_value_V_write;
    sc_signal< sc_logic > linebuffer_1_U0_in_axi_stream_V_value_V_ap_ack;
    sc_signal< sc_logic > linebuffer_1_U0_in_axi_stream_V_last_V_ap_ack;
    sc_signal< sc_logic > linebuffer_1_U0_ap_done;
    sc_signal< sc_logic > linebuffer_1_U0_ap_idle;
    sc_signal< sc_logic > linebuffer_1_U0_ap_continue;
    sc_signal< sc_logic > Loop_1_proc_U0_ap_start;
    sc_signal< sc_logic > Loop_1_proc_U0_ap_done;
    sc_signal< sc_logic > Loop_1_proc_U0_ap_continue;
    sc_signal< sc_logic > Loop_1_proc_U0_ap_idle;
    sc_signal< sc_logic > Loop_1_proc_U0_ap_ready;
    sc_signal< sc_logic > Loop_1_proc_U0_p_hw_input_stencil_stream_V_value_V_read;
    sc_signal< sc_lv<32> > Loop_1_proc_U0_hw_output_V_value_V;
    sc_signal< sc_logic > Loop_1_proc_U0_hw_output_V_value_V_ap_vld;
    sc_signal< sc_lv<1> > Loop_1_proc_U0_hw_output_V_last_V;
    sc_signal< sc_logic > Loop_1_proc_U0_hw_output_V_last_V_ap_vld;
    sc_signal< sc_logic > ap_sync_continue;
    sc_signal< sc_logic > p_hw_input_stencil_st_full_n;
    sc_signal< sc_lv<288> > p_hw_input_stencil_st_dout;
    sc_signal< sc_logic > p_hw_input_stencil_st_empty_n;
    sc_signal< sc_logic > ap_sync_done;
    sc_signal< sc_logic > ap_sync_ready;
    sc_signal< sc_lv<1> > start_for_Loop_1_proc_U0_din;
    sc_signal< sc_logic > start_for_Loop_1_proc_U0_full_n;
    sc_signal< sc_lv<1> > start_for_Loop_1_proc_U0_dout;
    sc_signal< sc_logic > start_for_Loop_1_proc_U0_empty_n;
    sc_signal< sc_logic > Loop_1_proc_U0_start_full_n;
    sc_signal< sc_logic > Loop_1_proc_U0_start_write;
    static const sc_lv<32> ap_const_lv32_0;
    static const sc_lv<1> ap_const_lv1_0;
    static const sc_logic ap_const_logic_1;
    static const sc_logic ap_const_logic_0;
    // Thread declarations
    void thread_ap_var_for_const0();
    void thread_Loop_1_proc_U0_ap_continue();
    void thread_Loop_1_proc_U0_ap_start();
    void thread_Loop_1_proc_U0_start_full_n();
    void thread_Loop_1_proc_U0_start_write();
    void thread_ap_done();
    void thread_ap_idle();
    void thread_ap_ready();
    void thread_ap_sync_continue();
    void thread_ap_sync_done();
    void thread_ap_sync_ready();
    void thread_hw_input_V_last_V_ap_ack();
    void thread_hw_input_V_value_V_ap_ack();
    void thread_hw_output_V_last_V();
    void thread_hw_output_V_last_V_ap_vld();
    void thread_hw_output_V_value_V();
    void thread_hw_output_V_value_V_ap_vld();
    void thread_linebuffer_1_U0_ap_continue();
    void thread_linebuffer_1_U0_ap_start();
    void thread_linebuffer_1_U0_start_full_n();
    void thread_start_for_Loop_1_proc_U0_din();
    void thread_hdltv_gen();
};

}

using namespace ap_rtl;

#endif
