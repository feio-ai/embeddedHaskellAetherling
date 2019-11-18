#include "hls_target.h"

#include "Linebuffer.h"
#include "halide_math.h"
void hls_target(
hls::stream<AxiPackedStencil<uint8_t, 4, 1> > &hw_input,
hls::stream<AxiPackedStencil<uint8_t, 4, 1> > &hw_output)
{
#pragma HLS DATAFLOW
#pragma HLS INLINE region
#pragma HLS INTERFACE ap_hs port=hw_input
#pragma HLS INTERFACE ap_hs port=hw_output

 // alias the arguments
 hls::stream<AxiPackedStencil<uint8_t, 4, 1> > &_hw_input_stencil_stream = hw_input;
 hls::stream<AxiPackedStencil<uint8_t, 4, 1> > &_hw_output_stencil_stream = hw_output;

 // dispatch_stream(_hw_input_stencil_stream, 2, 4, 4, 200, 1, 1, 1, 1, "hw_output", 1, 0, 200, 0, 1);
 hls::stream<AxiPackedStencil<uint8_t, 4, 1> > _hw_input_stencil_stream_to_hw_output;
#pragma HLS STREAM variable=_hw_input_stencil_stream_to_hw_output depth=1
#pragma HLS RESOURCE variable=_hw_input_stencil_stream_to_hw_output core=FIFO_SRL

 for (int _dim_1 = 0; _dim_1 <= 0; _dim_1 += 1)
 for (int _dim_0 = 0; _dim_0 <= 196; _dim_0 += 4)
 {
#pragma HLS PIPELINE
  PackedStencil<uint8_t, 4, 1> _tmp_stencil = _hw_input_stencil_stream.read();
  if (_dim_0 >= 0 && _dim_0 <= 196 && _dim_1 >= 0 && _dim_1 <= 0)
  {
   _hw_input_stencil_stream_to_hw_output.write(_tmp_stencil);
  }
 }
 (void)0;
 // produce hw_output.stencil.stream
 for (int _hw_output_y___scan_dim_1 = 0; _hw_output_y___scan_dim_1 < 0 + 1; _hw_output_y___scan_dim_1++)
 {
  for (int _hw_output_x___scan_dim_0 = 0; _hw_output_x___scan_dim_0 < 0 + 50; _hw_output_x___scan_dim_0++)
  {
#pragma HLS PIPELINE II=1
   Stencil<uint8_t, 4, 1> _hw_input_stencil;
#pragma HLS ARRAY_PARTITION variable=_hw_input_stencil.value complete dim=0

   _hw_input_stencil = _hw_input_stencil_stream_to_hw_output.read();
   (void)0;
   Stencil<uint8_t, 4, 1> _hw_output_stencil;
#pragma HLS ARRAY_PARTITION variable=_hw_output_stencil.value complete dim=0

   uint8_t _252 = _hw_input_stencil(0, 0);
   uint8_t _253 = (uint8_t)(5);
   uint8_t _254 = _252 + _253;
   _hw_output_stencil(0, 0) = _254;
   uint8_t _255 = _hw_input_stencil(1, 0);
   uint8_t _256 = (uint8_t)(5);
   uint8_t _257 = _255 + _256;
   _hw_output_stencil(1, 0) = _257;
   uint8_t _258 = _hw_input_stencil(2, 0);
   uint8_t _259 = (uint8_t)(5);
   uint8_t _260 = _258 + _259;
   _hw_output_stencil(2, 0) = _260;
   uint8_t _261 = _hw_input_stencil(3, 0);
   uint8_t _262 = (uint8_t)(5);
   uint8_t _263 = _261 + _262;
   _hw_output_stencil(3, 0) = _263;
   AxiPackedStencil<uint8_t, 4, 1> _hw_output_stencil_packed = _hw_output_stencil;
   if (_hw_output_x___scan_dim_0 == 49 && _hw_output_y___scan_dim_1 == 0) {
    _hw_output_stencil_packed.last = 1;
   } else {
    _hw_output_stencil_packed.last = 0;
   }
   _hw_output_stencil_stream.write(_hw_output_stencil_packed);
   (void)0;
  } // for _hw_output_x___scan_dim_0
 } // for _hw_output_y___scan_dim_1
} // kernel hls_target_hls_target


