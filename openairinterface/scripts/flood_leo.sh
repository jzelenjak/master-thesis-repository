#!/bin/bash
#
# This script starts a single UE softmodem, which sends registration requests with incrementally generated IMSIs (not registered in the network) via a LEO satellite.
# It corresponds to Experiment 2 (UEs are not registered in the network).
# The script can be executed inside the UE container to avoid copying the command from the Docker Compose file.


set -euo pipefail
IFS=$'\n\t'

umask 077

# The path to the configuration file in the Docker container
CONFIG_FILE="/opt/oai-nr-ue/etc/ue.conf"

# Command line parameters for OAI NR UE can also be found in the gNB(-DU) logs
# NOTE: We start with IMSI 001010000000004 (which will become 001010000000005 for the first Registration Request)
#  because IMSIs 001010000000001 - 001010000000004 are registered in the network (see the ../core-network/ directory)
bin/nr-uesoftmodem -O "$CONFIG_FILE" --band 254 -C 2488400000 --CO -873500000 -r 25 --numerology 0 --ssb 60 --ue-fo-compensation \
    --rfsim --rfsimulator.prop_delay 20 --rfsimulator.options chanmod --rfsimulator.serveraddr 192.168.80.129 \
    --time-sync-I 0.1 --ntn-initial-time-drift -46 --autonomous-ta --initial-fo 57340 --cont-fo-comp 2 \
    --uicc0.imsi 001010000000004 --uicc0.inc_imsi 1
