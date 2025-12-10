#!/bin/bash
#
# This script parses the logs from the ue container, extracting the lines with RRC connections and aggregating them into a csv format.
# Specifically, the following information is extracted from the logs:
#   - The number of established RRC connections (incremented when the UE is done processing RRCSetup and sends RRCSetupComplete + NAS Registration Request to the lower layers)
#   - The number of iterations/restarts (incremented when the UE restarts the RA procedure in the RRC layer, i.e. when receiving RRCReject or DLInformationTransfer)
#
# NB! This is quite a "dirty" script and it is very sensitive to the log file format. The original version assumes the following format:
#   [NR_RRC]   [JEGOR] [2025-11-17 19:44:05] Received DLInformationTransfer -- ignore and restart RA (iteration: 63, established RRC connections: 63)
#   [NR_RRC]   [JEGOR] [2025-11-17 19:44:06] Received RRCReject -- ignore and restart RA (iteration: 65, established RRC connections: 64)
# Feel free to use a different logging format, but make sure to change the regex strings (see the lines starting with `NOTE:`)


set -euo pipefail
IFS=$'\n\t'

umask 077


function usage() {
    echo -e "Usage: $0 [OPTION] FILE\n"
    echo -e "Parse the UE logs with RRC connections (provided in the FILE) and convert them to a CSV format"
    echo -e "NB! Depending on the format you used, you might need to change some regex strings in this script\n"
    echo -e "Options:"
    echo -e "\t-o file\t\tWrite the output to a file (default writes to stdout)"
    echo -e "\t-h\t\tDisplay this message and exit"
}

# INFO: This might be different on non-Linux systems
# If you happen to get errors, comment out the final output redirection
OUTPUT_FILE="/dev/stdout"

# Parse the provided options (if any)
# (https://web.archive.org/web/20200507131743/https:/wiki.bash-hackers.org/howto/getopts_tutorial)
# (https://stackoverflow.com/questions/16483119/an-example-of-how-to-use-getopts-in-bash)
while getopts ':o:h' opt; do
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


# Check if exactly one argument has been provided
[[ $# -ne 1 ]] && { usage >&2 ; exit 1; }

# Check if the provided file exists
[[ -f "$1" ]] || { echo "$0: file $1 does not exist." >&2 ; exit 1; }


# Remove ANSI color codes from the logs (if any) (see https://stackoverflow.com/a/54547589)
sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' "$1" |
    # NOTE: Change the regex below to match only the added logs with the UE connections (if necessary)
    grep '\[JEGOR\]' |
    # NOTE: Change the regex below according to the format of the UE logs that you used (if necessary)
    #   [NR_RRC]   [JEGOR] [2025-11-17 19:44:05] Received DLInformationTransfer -- ignore and restart RA (iteration: 63, established RRC connections: 63)
    #   [NR_RRC]   [JEGOR] [2025-11-17 19:44:06] Received RRCReject -- ignore and restart RA (iteration: 65, established RRC connections: 64)
    sed 's/^\[NR_RRC\].*\[JEGOR\] \[....-..-.. \(..:..:..\)\] .* (iteration: \([0-9]\+\), established RRC connections: \([0-9]\+\))$/\1,\2,\3/' |
    # INFO: We take the last value of the number of RRC connections during a particular timestamp
    # You could also take the average value instead (see comments below)
    awk -F',' '
        {
            # Format:   Time,Restarts,Connections
            # Example:  19:47:11,277,64
            restarts[$1] = $2;
            connections[$1] = $3;

            # Use the lines below instead to get the average value
            # restarts[$1] += $2;
            # connections[$1] += $3;
            # count[$1]++;
        }
        END {
            for (time in connections) {
                num_restarts = restarts[time];
                num_connections = connections[time];

                # Use the lines below instead to get the average value
                # num_restarts = restarts[time] / count[time];
                # num_connections = connections[time] / count[time];

                printf("%s,%d,%d\n", time, num_restarts, num_connections);
            }
        }' |
    sort -t ',' -k1,2 |
    awk -F',' '
        BEGIN {
            print "Time,Total_Restarts,Established_Connections";
        }
        {
            print $0;
        }' > "$OUTPUT_FILE"
