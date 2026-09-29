# run_on_board.tcl - load and start a bare-metal app on the ZedBoard over JTAG
# (what Vitis "Run" does), with the cores halted before any memory access.
# Usage:  xsdb run_on_board.tcl <workspace> <app>
#   e.g.  xsdb run_on_board.tcl C:/Users/hp/HW-AFDM-OTFS/vitis_sw_amd memtest
# Output of the app appears on the UART (COM port, 115200 8N1).
set ws  [lindex $argv 0]
set app [lindex $argv 1]
set hw  $ws/zed_platform/export/zed_platform/hw/sdt
set bit [lindex [glob $hw/*.bit] 0]
set elf $ws/$app/build/$app.elf

connect
targets -set -nocase -filter {name =~ "APU*"}
rst -system
after 1000
foreach c {0 1} {
    targets -set -nocase -filter "name =~ \"*A9*#$c\""
    catch {stop}
}
targets -set -nocase -filter {name =~ "xc7z020*"}
fpga -file $bit
puts "FPGA programmed: $bit"
targets -set -nocase -filter {name =~ "APU*"}
source $hw/ps7_init.tcl
ps7_init
ps7_post_config
puts "PS initialized (ps7_init, ps7_post_config)"
targets -set -nocase -filter {name =~ "*A9*#0"}
rst -processor
dow $elf
puts "Downloaded $elf - running, watch the COM port"
con
after 3000
disconnect
