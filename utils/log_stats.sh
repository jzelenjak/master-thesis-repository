#!/bin/bash
#
# This script monitors a single Docker container and fetches its stats in a loop.
# The script can be used to track a container (e.g. UE, gNB, AMF) during the flooding attack.


set -euo pipefail
IFS=$'\n\t'

umask 077

function usage() {
    echo -e "Usage: $0 container output_file\n"
    echo -e "\tcontainer\tThe name of the container to monitor"
    echo -e "\toutput_file\tThe name of output file (csv format)\n\t\t\tUse /dev/null to ignore the output file"
}

function print_title() {
    echo -ne "\e[1;91m"
    cat < /dev/stdin
    echo -ne "\e[0m"
}

function print_stats() {
    echo -ne "\e[1;96m"
    cat < /dev/stdin
    echo -ne "\e[0m"
}

function cleanup() {
    LOOP=false
    echo -e "\e[0m"
}

trap cleanup INT


# Check if exactly two arguments have been provided
[[ $# -ne 2 ]] && { usage >&2 ; exit 1; }

# Check if the specified container is running
# (https://stackoverflow.com/questions/43721513/how-to-check-if-the-docker-engine-and-a-docker-container-are-running/43723174#43723174)
if ! [ "$( docker container inspect -f '{{.State.Running}}' $1 )" = "true" ]; then
    echo "Container $1 is not running." >&2
    exit 1;
fi
#docker ps -a | grep -q "$1"  || { echo "Container $1 is not running." >&2 ; exit 1; }

CONTAINER="$1"
OUTPUT_FILE="$2"

echo "Iter,CPUPerc,MemPerc,MemUsage,NetIO" | tee "$OUTPUT_FILE" | tr ',' '\t' | print_title

i=0
LOOP=true
while $LOOP; do
    docker stats --no-stream --format "$i,"'{{ .CPUPerc }},{{ .MemPerc }},{{ .MemUsage }},{{ .NetIO }}' "$CONTAINER" | tr -d ' ' |
        tee -a "$OUTPUT_FILE" | tr ',' '\t' | print_stats
    i=$((i + 1))
done
