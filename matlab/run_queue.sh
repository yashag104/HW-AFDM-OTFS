#!/usr/bin/env bash
# run_queue.sh - run MATLAB study jobs from a queue file, at most MAXJ at a time.
#   bash run_queue.sh <queue_file> <MAXJ>
# Each line of the queue file is:  <log name> <MATLAB command>
#   e.g.  taps_LEO-Ka study_taps('LEO-Ka')
# Logs go to ../results/<log name>.log and end with "EXIT <code>". A job counts
# as running while any results/*.log lacks its EXIT line, so jobs started
# outside this script are counted too (memory allows ~3 MATLAB sessions).
set -uo pipefail
QUEUE=$1
MAXJ=$2
MATLAB="/mnt/c/Program Files/MATLAB/R2026a/bin/matlab.exe"
cd "$(dirname "$0")"
LOGDIR=$(cd ../results && pwd)

running() {
  local n=0
  for f in "$LOGDIR"/*.log; do
    [ -e "$f" ] || continue
    grep -q '^EXIT' "$f" || n=$((n + 1))
  done
  echo "$n"
}

while IFS= read -r line; do
  [ -z "${line// }" ] && continue
  name=${line%% *}
  cmd=${line#* }
  while [ "$(running)" -ge "$MAXJ" ]; do sleep 30; done
  echo "starting $name"
  # stdin from /dev/null: otherwise the job would swallow the rest of the queue file
  ( "$MATLAB" -batch "setup_paths; $cmd" > "$LOGDIR/$name.log" 2>&1 < /dev/null
    echo "EXIT $?" >> "$LOGDIR/$name.log" ) < /dev/null &
  sleep 20                                  # let the log appear before counting again
done < "$QUEUE"
wait
echo "queue done"
