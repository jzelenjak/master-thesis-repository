#!/bin/bash
#
# This script monitors running Docker containers and fetches their stats (CPU and memory usage).
# The script can be used to track the CPU and memory consumption of one or multiple container over time.
# With the -o option (see usage below), the stats can be written to a file for later processing.


set -euo pipefail
IFS=$'\n\t'

umask 077

function usage() {
    echo -e "Usage: $0 [OPTIONS] [CONTAINER...]\n"
    echo -e "Display a live stream of container(s) CPU and memory usage statistics\n"
    echo -e "Options:"
    echo -e "\t-o file\t\tWrite the output to a file (default writes only to stdout)"
    echo -e "\t-h\t\tDisplay this message and exit"
}

RED="\e[1;91m"
GREEN="\e[1;92m"
BLUE="\e[1;94m"
GREY="\e[38;5;248m"
RESET="\e[0m"

function colored() {
    echo -ne "$1"
    cat < /dev/stdin
    echo -ne "$RESET"
}

function cleanup() {
    LOOP=false
    echo -e "$RESET"
}

trap cleanup INT


# Parse the provided options (if any)
# (https://web.archive.org/web/20200507131743/https:/wiki.bash-hackers.org/howto/getopts_tutorial)
# (https://stackoverflow.com/questions/16483119/an-example-of-how-to-use-getopts-in-bash)
while getopts ":ho:" opt; do
    case "$opt" in
        o)
            OUTPUT_FILE="${OPTARG}"
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo "$0: invalid option -- '$OPTARG'" >&2
            echo "Try '$0 -h' for more information." >&2
            exit 1
            ;;
        :)
            echo "$0: option requires an argument -- '$OPTARG'" >&2
            echo "Try '$0 -h' for more information." >&2
            exit 1
    esac
done
shift $((OPTIND-1))

# Check if the specified containers (if any) are running
# (https://stackoverflow.com/questions/43721513/how-to-check-if-the-docker-engine-and-a-docker-container-are-running)
# (https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script)
for container in "$@"; do
    if ! [ "$( docker container inspect -f '{{.State.Status}}' ${container} 2>/dev/null )" = "running" ]; then
        echo "Container $container is not running." >&2
        exit 1;
    fi
done

# Check if the variable for the output file is defined
# (https://stackoverflow.com/questions/11362250/in-bash-how-do-i-test-if-a-variable-is-defined-in-u-mode)
[[ -z "${OUTPUT_FILE-}" ]] && { echo "No output file specified -- writing to stdout" | colored "$GREY"; OUTPUT_FILE="/dev/null" ; }


# Print the header with the field titles
echo "Container,Time,CPUPerc,MemPerc,MemUsage" | tee "$OUTPUT_FILE" | tr ',' '\t' | colored "$RED"

# Keep fetching the stats until terminated with Ctrl+C
i=0
LOOP=true
while $LOOP; do
    echo "Iteration $i" | colored "$BLUE"
    docker stats --no-stream --format '{{ .Name }},{{ .CPUPerc }},{{ .MemPerc }},{{ .MemUsage }}' "$@" |
        awk -F ',' -v OFS=',' -v date="$(date +%T)" '{ print $1, date, $2, $3, $4 }' | sed 's/ \/ /\//g' |
        tee -a "$OUTPUT_FILE" | tr ',' '\t' | colored "$GREEN"
    i=$((i + 1))
done
