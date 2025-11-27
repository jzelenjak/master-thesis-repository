#!/bin/bash
#
# This script starts a single UE softmodem, which connects to the network with a registered IMSI.
# It can be used to connect a legitimate UE to the OAI 5G network.
# The script can be executed inside the UE container to avoid copying the command from the Docker Compose file.


set -euo pipefail
IFS=$'\n\t'

umask 077

# Command line parameters for OAI NR UE can also be found in the gNB(-DU) logs
# NOTE: The victim UE uses IMSI 001010000000002, because IMSI 001010000000001 is already used by the attacker UE
bin/nr-uesoftmodem --rfsim --rfsimulator.serveraddr 192.168.80.129 -C 3619200000 -r 106 --numerology 1 --band 78 --ssb 516 -E --ue-fo-compensation --uicc0.imsi 001010000000002
