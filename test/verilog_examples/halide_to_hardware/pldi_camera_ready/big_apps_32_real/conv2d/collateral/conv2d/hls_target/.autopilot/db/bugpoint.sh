export PATH=/cad/xilinx/vivado/2017.2/Vivado/2017.2/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/gcc/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/msys/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/clang/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/tps/lnx64/libxslt/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/tps/lnx64/jre/bin:/cad/xilinx/vivado/2017.2/SDK/2017.2/bin:/cad/xilinx/vivado/2017.2/Vivado/2017.2/bin:/cad/xilinx/vivado/2017.2/petalinux/tools/linux-i386//petalinux/bin:/cad/xilinx/vivado/2017.2/petalinux/tools/linux-i386//gcc-arm-none-eabi-r5/bin:/cad/xilinx/vivado/2017.2/petalinux/tools/linux-i386//gcc-arm-linux-gnueabi/bin:/cad/xilinx/vivado/2017.2/petalinux/tools/linux-i386//gcc-arm-none-eabi/bin:/cad/xilinx/vivado/2017.2/petalinux/tools/linux-i386//aarch64-linux-gnu/bin:/cad/xilinx/vivado/2017.2/petalinux/tools/linux-i386//aarch64-none-elf/bin:/cad/xilinx/vivado/2017.2/petalinux/tools/common/petalinux/bin:/cad/xilinx/vivado/2017.2/SDK/2017.2/gnu/aarch64/lin/aarch64-linux/bin:/cad/xilinx/vivado/2017.2/SDK/2017.2/gnu/arm/lin/bin:/usr/local/miniconda3/bin:/cad/synopsys/syn/L-2016.03-SP5-5/amd64/syn/bin/:/cad/synopsys/vcs-mx/O-2018.09-SP1/bin:/cad/synopsys/vcs-mx/O-2018.09-SP1/gui/dve/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/cad/cadence/INCISIVE15.20.022/tools/bin:/cad/cadence/INCISIVE15.20.022/tools/dfII/bin:/cad/common/Linux/x86_64/bin
export LD_LIBRARY_PATH=/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/graphviz/lib:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/bin:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/tps/lnx64/libxslt/lib:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lib/lnx64.o:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/tps/lnx64/jre/lib/amd64:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/tps/lnx64/jre/lib/amd64/server:/cad/cadence/INCISIVE15.20.022/tools/lib:/cad/cadence/INCISIVE15.20.022/tools/dfII/lib:/cad/common/Linux/x86_64/lib:/cad/synopsys/syn/L-2016.03-SP5-5/lib:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/bin/../lnx64/tools/dot/lib:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/fpo_v6_1:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/fpo_v7_0:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/fft_v9_0:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/opencv:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/fir_v7_0:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/dds_v6_0:/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/gdb_v7_2
export HDI_APPROOT=/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2
export XILINX_OPENCL_CLANG=/cad/xilinx/vivado/2017.2/Vivado_HLS/2017.2/lnx64/tools/clang
export RDI_PLATFORM=lnx64
bugpoint -mlimit=32000  --load libhls_support.so  --load libhls_bugpoint.so  -hls -strip  -function-uniquify -auto-function-inline -globaldce  -ptrArgReplace -mem2reg -instcombine -dce  -reset-lda  -loop-simplify -indvars -licm -loop-dep  -loop-bound -licm -loop-simplify -flattenloopnest  -array-flatten -gvn -instcombine -dce  -array-map -dce -func-legal  -gvn -adce -instcombine -cfgopt -simplifycfg -loop-simplify   -array-burst -promote-global-argument -dce  -axi4-lower -array-seg-normalize  -basicaa -aggrmodref-aa -globalsmodref-aa -aggr-aa -gvn -gvn  -basicaa -aggrmodref-aa -globalsmodref-aa -aggr-aa -dse -adse -adce -licm  -inst-simplify -dce  -globaldce -instcombine -array-stream -eliminate-keepreads -instcombine  -dce   -deadargelim -doublePtrSimplify  -doublePtrElim -dce -doublePtrSimplify -promote-dbg-pointer  -dce -scalarrepl -mem2reg -disaggr -norm-name -mem2reg  -instcombine  -dse -adse -adce -ptrLegalization -dce -auto-rom-infer -array-flatten -dce -instcombine -check-doubleptr  -loop-rot -constprop -cfgopt -simplifycfg -loop-simplify -indvars -pointer-simplify -dce -loop-bound  -loop-simplify -loop-preproc  -constprop -global-constprop -gvn -mem2reg -instcombine -dce  -loop-bound  -loop-merge -dce  -bitwidthmin  -deadargelim -dce  -canonicalize-dataflow -dce  -scalar-propagation -deadargelim -globaldce -mem2reg   -interface-preproc -interface-gen  -deadargelim -directive-preproc -inst-simplify -dce  -gvn -mem2reg -instcombine -dce -adse  -loop-bound  -instcombine -cfgopt -simplifycfg -loop-simplify  -clean-region -io-protocol  -find-region -mem2reg  -bitop-raise  -inst-simplify -inst-rectify -instcombine -adce -deadargelim  -loop-simplify -phi-opt -bitop-raise  -cfgopt -simplifycfg -strip-dead-prototypes  -interface-lower -bitop-lower -intrinsic-lower -auto-function-inline  -basicaa -aggrmodref-aa -globalsmodref-aa -aggr-aa  -inst-simplify -simplifycfg   -loop-simplify  -mergereturn -inst-simplify -inst-rectify  -dce -bitop-lower  -loop-rewind -pointer-simplify -dce -cfgopt  -read-loop-dep -dce -bitwidth -loop-dep -norm-name -legalize  -validate-dataflow  /home/dhuff/Halide-HLS/apps/hls_examples/camera_ready_synthesis/app_files/big_apps_32_real/conv2d/conv2d/hls_target/.autopilot/db/a.o.2.bc
llvm-dis bugpoint-reduced-simplified.bc 
