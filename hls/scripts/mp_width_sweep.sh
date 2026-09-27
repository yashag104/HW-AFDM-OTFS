#!/usr/bin/env bash
# mp_width_sweep.sh - word-length sweep of the fixed-point MP detector.
# Runs every width setting over every exported frame file (generated/mp/*.txt)
# and writes one table row per (setting, file) to ../results/mp_width_sweep.txt.
# Run from hls/:  bash scripts/mp_width_sweep.sh
set -euo pipefail

# name | -D flags (unlisted widths keep their defaults in src/mp.h)
SETTINGS=(
  "default|"
  "tap10|-DMP_WT=10"
  "tap8|-DMP_WT=8"
  "prob10|-DMP_WP=10"
  "prob8|-DMP_WP=8"
  "mean14|-DMP_WM=14 -DMP_WV=14"
  "mean12|-DMP_WM=12 -DMP_WV=12"
  "ll12|-DMP_WL=12"
  "small|-DMP_WT=10 -DMP_WP=10 -DMP_WM=14 -DMP_WV=14 -DMP_WL=14"
)

OUT=../results/mp_width_sweep.txt
printf "%-8s %-28s %-4s %8s %8s %9s %9s %7s\n" setting frames S errFix errFlt berFix berFlt agree > "$OUT"

for entry in "${SETTINGS[@]}"; do
  name=${entry%%|*}
  flags=${entry#*|}
  for f in generated/mp/*.txt; do
    s=$(basename "$f" .txt | sed -E 's/.*_S([0-9]+)_.*/\1/')
    make -s build/tb_mp_S${s}_${name} MP_S="$s" MPTAG="$name" MPW="$flags" >/dev/null
    line=$(./build/tb_mp_S${s}_${name} "$f" 1000 | grep '^RESULT')
    errFix=$(sed -E 's/.*errFix=([0-9]+).*/\1/' <<<"$line")
    errFlt=$(sed -E 's/.*errFlt=([0-9]+).*/\1/' <<<"$line")
    bits=$(sed -E 's/.*bits=([0-9]+).*/\1/' <<<"$line")
    agree=$(sed -E 's/.*agree=([0-9.]+).*/\1/' <<<"$line")
    printf "%-8s %-28s %-4s %8s %8s %9.2e %9.2e %7s\n" "$name" "$(basename "$f" .txt)" "$s" \
           "$errFix" "$errFlt" "$(bc -l <<<"$errFix/$bits")" "$(bc -l <<<"$errFlt/$bits")" "$agree" >> "$OUT"
  done
  echo "done: $name"
done
cat "$OUT"
