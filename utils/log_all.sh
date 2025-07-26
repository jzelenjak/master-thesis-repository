#!/bin/bash
#
# This script monitors the UE container and all containers that are attacked (e.g. UE, gNB, AMF).
# The script can be used to track these containers during the flooding attack.

set -euo pipefail
IFS=$'\n\t'

umask 077

# trap 'kill $(jobs -p); sleep 1' INT
trap 'pkill -P $$' INT

../utils/log_stats.sh ue stats_ue.csv > /dev/null &
../utils/log_stats.sh gnodeb stats.csv &
# For the split
# ../utils/log_stats.sh gnodeb-du stats_du.csv &
# ../utils/log_stats.sh gnodeb-cu stats_cu.csv > /dev/null &
../utils/log_stats.sh amf stats_amf.csv > /dev/null &

while true; do
    sleep 1
done
