#!/bin/bash
#
# This script continuously starts background UE processes, with incrementally generated IMSIs (not registered in the network).
# The script corresponds to Experiment 2 (UEs are not registered in the network).


set -euo pipefail
IFS=$'\n\t'

umask 077

LOW=1
HIGH=30
WAIT_SEC=3
ITER=500

# NOTE: Due to the high memory consumption of a single process, we launch them in batches.
# This is done to prevent the kernel from killing the new UE processes due to running out of memory.
# TODO: This might have to be changed.
for i in $(seq 0 "$ITER"); do
    #for j in $(seq -f "%05g" "$LOW" "$HIGH"); do
    for j in $(seq "$LOW" "$HIGH"); do
        NUM=$((i * HIGH + j))
        PAD_NUM=$(printf %010d $NUM)
        IMSI="00202${PAD_NUM}"
        echo "Rogue UE with IMSI $IMSI"
        bin/nr-uesoftmodem --rfsim --rfsimulator.serveraddr 192.168.80.129 -r 106 --numerology 1 --band 78 -C 3619200000 --ue-fo-compensation -E --uicc0.imsi "$IMSI" 1>/dev/null & # 2>&1
    done
    echo "Iteration $i done. Waiting..."
    sleep "$WAIT_SEC"
done
