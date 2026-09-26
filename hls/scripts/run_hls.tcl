# run_hls.tcl - C simulation, synthesis and Vivado implementation of ONE block.
# All blocks use the same part, clock and tool settings (fair comparison).
#
# Usage (from hls/), Vitis 2024.2 or later:
#   TOP=afdm_mod WD=12 WR=16 SCEN=LEOKa vitis-run --mode hls --tcl scripts/run_hls.tcl
# Older releases:  same variables, then  vitis_hls -f scripts/run_hls.tcl
#
# TOP  : afdm_mod | afdm_demod | otfs_zak_mod | otfs_zak_demod | otfs_isfft_mod | otfs_sfft_demod
# WD   : data word length,  WR : ROM word length,  SCEN : ROM set (LEOKa, LEOS, ...)

set top  $::env(TOP)
set wd   $::env(WD)
set wr   $::env(WR)
set scen $::env(SCEN)

set part   xc7z020clg400-1        ;# Zynq-7020 (PYNQ-Z2)
set period 10.0                   ;# 100 MHz target clock [ns]

set root [file normalize [file dirname [info script]]/..]
set rom  $root/generated/R${wr}_${scen}
set vec  $root/generated/W${wd}_R${wr}_${scen}
set cfl  "-DWD=$wd -DWR=$wr -I$root/src -I$rom"

open_project -reset $root/proj/${top}_W${wd}_R${wr}_${scen}
set_top $top
add_files $root/src/blocks.cpp -cflags $cfl
add_files -tb $root/tb/tb_blocks.cpp -cflags $cfl

open_solution -reset sol -flow_target vivado
set_part $part
create_clock -period $period -name default

csim_design -argv $vec             ;# bit-exact check against MATLAB vectors
csynth_design
export_design -flow impl -rtl verilog -format ip_catalog   ;# Vivado place & route
exit
