#!/bin/bash
#
# This script continuously starts background UE processes, with incrementally generated IMSIs (not registered in the network).
# The script corresponds to Experiment 2 (UEs are not registered in the network).


set -euo pipefail
IFS=$'\n\t'

umask 077

# Start with the IMSI ..2, because the IMSI ..1 is registered in the network
NUM=1
while true ; do
    NUM=$((NUM + 1))
    PAD_NUM=$(printf %010d $NUM)
    IMSI="20893${PAD_NUM}"
    ./nr-ue -c config/uecfg.yaml --imsi "$IMSI" &
done
