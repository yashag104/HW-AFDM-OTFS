#!/usr/bin/env bash
# run_all_hls.sh - put every transform block through run_hls.tcl (C-sim,
# synthesis, Vivado implementation) and collect the post-implementation
# resources and timing into one table. Two blocks run at a time (memory).
# Run from hls/:  bash scripts/run_all_hls.sh [block ...]
set -uo pipefail
cd "$(dirname "$0")/.."
BLOCKS=${*:-"afdm_demod ofdm_mod ofdm_demod otfs_zak_mod otfs_zak_demod otfs_isfft_mod otfs_sfft_demod otfs_ps_mod"}
WD=12; WR=16; SCEN=LEOKa
LOG=../results/hw
mkdir -p "$LOG"

run_one() {                                # one block, Windows Vitis through cmd.exe
  cmd.exe /c "cd /d C:\\Users\\hp\\HW-AFDM-OTFS\\hls && set TOP=$1&& set WD=$WD&& set WR=$WR&& set SCEN=$SCEN&& D:\\2025.2\\Vitis\\bin\\vitis-run.bat --mode hls --tcl scripts/run_hls.tcl" \
    > "$LOG/$1.log" 2>&1 < /dev/null
  echo "EXIT $?" >> "$LOG/$1.log"
}

n=0
for b in $BLOCKS; do
  run_one "$b" &
  n=$((n + 1))
  if [ $((n % 2)) -eq 0 ]; then wait; fi
done
wait

# Summary: one row per block that has an implementation report.
OUT=$LOG/summary.txt
printf "%-18s %6s %6s %4s %5s %8s %9s\n" block LUT FF DSP BRAM CP_ns latency > "$OUT"
for r in proj/*_W${WD}_R${WR}_${SCEN}/sol/impl/report/verilog/*_export.rpt; do
  b=$(basename "$r" _export.rpt)
  syn=$(dirname "$r")/../../../syn/report/${b}_csynth.rpt
  lat=$(grep -A6 "Latency (cycles)" "$syn" | grep -m1 -E '^\s*\|\s*[0-9]' | awk -F'|' '{gsub(/ /,"",$2); print $2}')
  printf "%-18s %6s %6s %4s %5s %8s %9s\n" "$b" \
    "$(awk '/^LUT:/{print $2}' "$r")" "$(awk '/^FF:/{print $2}' "$r")" \
    "$(awk '/^DSP:/{print $2}' "$r")" "$(awk '/^BRAM:/{print $2}' "$r")" \
    "$(awk '/post-implementation:/{print $3}' "$r")" "$lat" >> "$OUT"
done
cat "$OUT"
