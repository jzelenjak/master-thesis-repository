#!/bin/bash
#
# This script continuously starts background UE processes, with the IMSI that is registered in the network (in uecfg.yaml).
# The script corresponds to Experiment 1 (UEs are registered in the network).


set -euo pipefail
IFS=$'\n\t'

umask 077

while true; do
# for i in $(seq 1 500); do
    ./nr-ue -c config/uecfg.yaml &
done
