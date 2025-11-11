#!/bin/bash
#
# This script starts a single UE softmodem, which sends registration requests with the same IMSI (registered in the network).
# It corresponds to Experiment 1 (UEs are registered in the network).
#
# The script should be used with the full gNB option, due to the required radio parameters (as hardcoded below).
# It can be executed inside the UE container to avoid copying the command from the Docker Compose file.


set -euo pipefail
IFS=$'\n\t'

umask 077

# Command line parameters for OAI UE can also be found in the gNB logs
# The (commented out) options below can be used to control the log levels for different layers
bin/nr-uesoftmodem --rfsim --rfsimulator.serveraddr 192.168.80.129 -C 3619200000 -r 106 --numerology 1 --band 78 --ssb 516 -E --ue-fo-compensation \
    --uicc0.imsi 001010000000001 \
    --log_config.global_log_level info
    #--log_config.global_log_options level,thread,function \
    #--log_config.nr_rrc_log_level debug \
    #--log_config.pdcp_log_level debug \
    #--log_config.rlc_log_level debug \
    #--log_config.nr_mac_log_level info \
    #--log_config.nr_mac_dci_log_level error \
    #--log_config.nr_phy_dci_log_level error \
    #--log_config.nr_phy_log_level error \
    #--log_config.hw_log_level error \
    #--log_config.util_log_level error
    
    # To check all options, enter an invalid one, e.g.:
    # --log_config.NRRRC_debug
    # To print in a file (does not work for me):
    # --log_config.nr_rrc_log_infile 1

# For configuring log levels, see:
#   https://github.com/OPENAIRINTERFACE/openairinterface5g/blob/develop/common/utils/LOG/DOC/rtusage.md
