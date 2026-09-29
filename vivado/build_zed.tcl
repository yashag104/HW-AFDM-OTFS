# build_zed.tcl - Part 2 of docs/zedboard_guide.md in batch mode: Zynq PS +
# afdm_mod_top IP -> bitstream, reports, and afdm_zed.xsa for Vitis (Part 3).
# Needs the IP from hls/scripts/run_board_hls.tcl.
# Usage (from vivado/):  vivado -mode batch -source build_zed.tcl

#   ZED_PRESET=amd vivado -mode batch -source build_zed.tcl
#     uses AMD's own ZedBoard PS7 preset (processing_system7_v5_5/preset/
#     ZedBoard.tcl: MT41J128M16 DDR, internal VREF, board delays 0.34-0.41 ns)
#     instead of a board file. Reason: with the Digilent 1.1 board file the
#     lab board's DDR read back 0x0 / 0xFFFFFFFF after a clean ps7_init, and
#     the two presets differ in DDR part, VREF and trace delays (older and
#     newer ZedBoard revisions). Output goes to afdm_zed_amd/.

set here [file normalize [file dirname [info script]]]
set ip   [file normalize $here/../hls/proj/afdm_mod_top/sol/impl/ip]
set amd  [expr {[info exists ::env(ZED_PRESET)] && $::env(ZED_PRESET) eq "amd"}]
set name [expr {$amd ? "afdm_zed_amd" : "afdm_zed"}]
set out  $here/$name

create_project -force $name $out -part xc7z020clg484-1
if {!$amd} {
    # ZedBoard board files: installed from the AMD board store if missing.
    if {[llength [get_board_parts -quiet *zedboard*]] == 0} {
        xhub::refresh_catalog [xhub::get_xstores xilinx_board_store]
        xhub::install [xhub::get_xitems -quiet *zedboard*]
        set_param board.repoPaths [get_property LOCAL_ROOT_DIR [xhub::get_xstores xilinx_board_store]]
    }
    set board [lindex [lsort [get_board_parts *zedboard*]] end]
    puts "Board part: $board"
    set_property board_part $board [current_project]
}
set_property ip_repo_paths $ip [current_project]
update_ip_catalog

# Block design: PS with the board preset, HP0 for the IP's DDR access.
create_bd_design design_1
set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 ps7]
if {$amd} {
    # Pull the CONFIG.* pairs out of AMD's preset file and apply them.
    set f [open $::env(XILINX_VIVADO)/../data/ip/xilinx/processing_system7_v5_5/preset/ZedBoard.tcl]
    set txt [read $f]; close $f
    set cfg {}
    foreach {- k v} [regexp -all -inline {(CONFIG\.PCW_\w+)\s*\{([^\}]*)\}} $txt] { lappend cfg $k $v }
    set_property -dict $cfg $ps
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
        -config {make_external "FIXED_IO, DDR" apply_board_preset "0" Master "Disable" Slave "Disable"} $ps
} else {
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
        -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} $ps
}
set_property -dict {CONFIG.PCW_USE_M_AXI_GP0 1 CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ 100} $ps
set_property CONFIG.PCW_USE_S_AXI_HP0 1 $ps
create_bd_cell -type ip -vlnv [lindex [get_ipdefs *afdm_mod_top*] 0] afdm

# AXI-Lite control from the PS, AXI master of the IP into HP0.
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master /ps7/M_AXI_GP0 Clk_master Auto Clk_slave Auto Clk_xbar Auto intc_ip Auto} \
    [get_bd_intf_pins afdm/s_axi_control]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master /afdm/m_axi_gmem Clk_master Auto Clk_slave Auto Clk_xbar Auto intc_ip Auto} \
    [get_bd_intf_pins ps7/S_AXI_HP0]
assign_bd_address
validate_bd_design
save_bd_design

set wrapper [make_wrapper -files [get_files design_1.bd] -top]
add_files -norecurse $wrapper
set_property top design_1_wrapper [current_fileset]

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "Implementation failed - see $out/$name.runs/impl_1/runme.log"
}

# Reports (the cost numbers for the paper) and the hardware export for Vitis.
open_run impl_1
report_utilization -hierarchical -file $out/utilization_hier.rpt
report_timing_summary -file $out/timing_summary.rpt
report_power -file $out/power.rpt
write_hw_platform -fixed -include_bit -force $here/$name.xsa
puts "Bitstream + XSA: $here/$name.xsa"
