#!/bin/bash
#
# This script starts a single UE softmodem, which sends registration requests with incrementally generated IMSIs (not registered in the network).
# It corresponds to Experiment 2 (UEs are not registered in the network).
# The script can be executed inside the UE container to avoid copying the command from the Docker Compose file.


set -euo pipefail
IFS=$'\n\t'

umask 077

# Command line parameters for OAI NR UE can also be found in the gNB(-DU) logs
# The (commented out) options below can be used to control the log levels for different layers
# NOTE: We start with IMSI 001010000000004 (which will become 001010000000005 for the first Registration Request)
#  because IMSIs 001010000000001 - 001010000000004 are registered in the network (see the ../core-network/ directory)
bin/nr-uesoftmodem --rfsim --rfsimulator.serveraddr 192.168.80.129 -C 3619200000 -r 106 --numerology 1 --band 78 --ssb 516 -E --ue-fo-compensation \
    --uicc0.imsi 001010000000004 --uicc0.inc_imsi 1 \
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

# For configuring log levels, see:
#   https://github.com/OPENAIRINTERFACE/openairinterface5g/blob/develop/common/utils/LOG/DOC/rtusage.md
