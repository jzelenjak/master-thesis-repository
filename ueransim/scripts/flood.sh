#!/bin/bash
#
# This script continuously starts background UE processes, with incrementally generated IMSIs (not registered in the network).
# The script corresponds to Experiment 2 (UEs are not registered in the network).


set -euo pipefail
IFS=$'\n\t'

umask 077

FLOODING_RATE=100

# Start with IMSI ..3, because IMSIs ..1 and ..2 are registered in the network
NUM=2
while true ; do
	for i in range $(seq 1 "$FLOODING_RATE"); do
	    NUM=$((NUM + 1))
	    PAD_NUM=$(printf %010d $NUM)
	    IMSI="20893${PAD_NUM}"
	    ./nr-ue -c config/uecfg.yaml --imsi "$IMSI" &
	done
	sleep 1
done
