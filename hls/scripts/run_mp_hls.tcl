# run_mp_hls.tcl - C-sim, synthesis and Vivado implementation of the MP
# detector (mp_detect) on the same part and clock as the transform blocks.
# Usage (from hls/):  MP_S=16 MPTAG=small MPW="-DMP_WT=10 ..." vitis-run --mode hls --tcl scripts/run_mp_hls.tcl
#   MP_S  : taps per row; MPTAG : name of the word-length setting;
#   MPW   : -D word-length overrides (empty = defaults in src/mp.h)
# C-sim runs the exported frames of generated/mp/ against the float MP decisions.

set s    $::env(MP_S)
set tag  $::env(MPTAG)
set mpw  [expr {[info exists ::env(MPW)] ? $::env(MPW) : ""}]

set part   xc7z020clg484-1
set period 10.0

set root [file normalize [file dirname [info script]]/..]
set cfl  "-DMP_S=$s $mpw -I$root/src"

# Run from proj/: see the note in run_hls.tcl (relative design-file paths).
file mkdir $root/proj
cd $root/proj
open_project -reset mp_S${s}_${tag}
set_top mp_detect
add_files $root/src/mp.cpp -cflags $cfl
add_files -tb $root/tb/tb_mp.cpp -cflags $cfl

open_solution -reset sol -flow_target vivado
set_part $part
create_clock -period $period -name default

# MP_CSIM=0 skips C-sim (10 min in Vitis); make mp-check runs the same test with g++.
if {![info exists ::env(MP_CSIM)] || $::env(MP_CSIM) != 0} {
    csim_design -argv "$root/generated/mp/LEOKa_AFDM_S${s}_12dB.txt"
}
csynth_design
export_design -flow impl -rtl verilog -format ip_catalog
exit
