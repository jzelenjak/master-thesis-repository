#!/bin/bash
#
# This script starts a single UE softmodem, which connects to the network with a registered IMSI via a GEO satellite.
# It can be used to connect a legitimate UE to the OAI 5G network.
# The script can be executed inside the UE container to avoid copying the command from the Docker Compose file.


set -euo pipefail
IFS=$'\n\t'

umask 077

# The path to the configuration file in the Docker container
CONFIG_FILE="/opt/oai-nr-ue/etc/ue.conf"

# Command line parameters for OAI NR UE can also be found in the gNB(-DU) logs
# NOTE: The victim UE uses IMSI 001010000000002, because IMSI 001010000000001 is already used by the attacker UE
bin/nr-uesoftmodem -O "$CONFIG_FILE" --band 254 -C 2488400000 --CO -873500000 -r 25 --numerology 0 --ssb 60 --ue-fo-compensation \
    --rfsim --rfsimulator.serveraddr 192.168.80.129 --rfsimulator.prop_delay 238.74 \
    --uicc0.imsi 001010000000002
