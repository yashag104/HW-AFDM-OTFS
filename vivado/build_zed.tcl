# build_zed.tcl - Part 2 of docs/zedboard_guide.md in batch mode: Zynq PS +
# afdm_mod_top IP -> bitstream, reports, and afdm_zed.xsa for Vitis (Part 3).
# Needs the IP from hls/scripts/run_board_hls.tcl.
# Usage (from vivado/):  vivado -mode batch -source build_zed.tcl

set here [file normalize [file dirname [info script]]]
set ip   [file normalize $here/../hls/proj/afdm_mod_top/sol/impl/ip]
set out  $here/afdm_zed

# ZedBoard board files: installed from the AMD board store if missing. They
# carry the DDR, clock and MIO settings the board preset applies to the PS.
if {[llength [get_board_parts -quiet *zedboard*]] == 0} {
    xhub::refresh_catalog [xhub::get_xstores xilinx_board_store]
    xhub::install [xhub::get_xitems -quiet *zedboard*]
    set_param board.repoPaths [get_property LOCAL_ROOT_DIR [xhub::get_xstores xilinx_board_store]]
}
set board [lindex [lsort [get_board_parts *avnet*zedboard*]] end]
puts "Board part: $board"

create_project -force afdm_zed $out -part xc7z020clg484-1
set_property board_part $board [current_project]
set_property ip_repo_paths $ip [current_project]
update_ip_catalog

# Block design: PS with the board preset, HP0 for the IP's DDR access.
create_bd_design design_1
set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 ps7]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} $ps
set_property CONFIG.PCW_USE_S_AXI_HP0 1 $ps
create_bd_cell -type ip -vlnv [lindex [get_ipdefs *afdm_mod_top*] 0] afdm

# AXI-Lite control from the PS, AXI master of the IP into HP0.
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master /ps7/M_AXI_GP0 Clk_master Auto Clk_slave Auto Clk_xbar Auto intc_ip New} \
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
    error "Implementation failed - see $out/afdm_zed.runs/impl_1/runme.log"
}

# Reports (the cost numbers for the paper) and the hardware export for Vitis.
open_run impl_1
report_utilization -hierarchical -file $here/utilization_hier.rpt
report_timing_summary -file $here/timing_summary.rpt
report_power -file $here/power.rpt
write_hw_platform -fixed -include_bit -force $here/afdm_zed.xsa
puts "Bitstream + XSA: $here/afdm_zed.xsa"
