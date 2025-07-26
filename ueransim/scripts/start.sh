#!/bin/bash
#
# This script starts a single UE that is registered in the network.
# The script can be executed inside the UE container to avoid copying the command from the Docker Compose file.


set -euo pipefail
IFS=$'\n\t'

umask 077

./nr-ue -c config/uecfg.yaml
