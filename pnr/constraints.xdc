create_clock -period 5.000 -name clk -waveform {0.000 2.500} [get_ports * -filter "name == CLK || name == ap_clk"]
set_property HD.CLK_SRC BUFGCTRL_X0Y16 [get_ports * -filter "name == CLK || name == ap_clk"]
