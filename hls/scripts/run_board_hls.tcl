# run_board_hls.tcl - Part 1 of docs/zedboard_guide.md in batch mode: the
# board wrapper afdm_mod_top (AXI master + AXI-Lite) -> C-sim, synthesis,
# packaged Vivado IP in proj/afdm_mod_top/sol/impl/ip.
# Usage (from hls/):  vitis-run --mode hls --tcl scripts/run_board_hls.tcl

set wd 12
set wr 16
set scen LEOKa

set part   xc7z020clg484-1        ;# ZedBoard
set period 10.0                   ;# 100 MHz

set root [file normalize [file dirname [info script]]/..]
set cfl  "-DWD=$wd -DWR=$wr -I$root/src -I$root/generated/R${wr}_${scen}"

# Run from proj/: see the note in run_hls.tcl (relative design-file paths).
file mkdir $root/proj
cd $root/proj
open_project -reset afdm_mod_top
set_top afdm_mod_top
add_files $root/src/board_top.cpp -cflags $cfl
add_files $root/src/blocks.cpp    -cflags $cfl
add_files -tb $root/tb/tb_board.cpp -cflags $cfl

open_solution -reset sol -flow_target vivado
set_part $part
create_clock -period $period -name default

csim_design -argv $root/generated/W${wd}_R${wr}_${scen}
csynth_design
export_design -rtl verilog -format ip_catalog
exit
