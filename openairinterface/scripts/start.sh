#!/bin/bash
#
# This script starts a single UE that is registered in the network.
# The script can be executed inside the UE container to avoid copying the command from the Docker Compose file.


set -euo pipefail
IFS=$'\n\t'

umask 077

bin/nr-uesoftmodem --rfsim --rfsimulator.serveraddr 192.168.80.129 -r 106 --numerology 1 --band 78 -C 3619200000 --ue-fo-compensation --sa -E --uicc0.imsi 001010000000001
