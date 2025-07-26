#!/bin/bash
#
# This script continuously starts background UE processes, with the IMSI that is registered in the network.
# The script corresponds to Experiment 1 (UEs are registered in the network).


set -euo pipefail
IFS=$'\n\t'

umask 077

LOW=1
HIGH=30
WAIT_SEC=2
ITER=500

# NOTE: Due to the high memory consumption of a single process, we launch them in batches.
# This is done to prevent the kernel from killing the new UE processes due to running out of memory.
# TODO: This might have to be changed.
for i in $(seq 0 "$ITER"); do
    #for j in $(seq -f "%05g" "$LOW" "$HIGH"); do
    for j in $(seq "$LOW" "$HIGH"); do
        bin/nr-uesoftmodem --rfsim --rfsimulator.serveraddr 192.168.80.129 -r 106 --numerology 1 --band 78 -C 3619200000 --ue-fo-compensation -E --uicc0.imsi 001010000000001 1>/dev/null & # --sa 2>&1
    done
    echo "Iteration $i done. Waiting..."
    sleep "$WAIT_SEC"
done
