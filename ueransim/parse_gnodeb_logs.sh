#!/bin/bash
#
# This script parses the logs from the gnodeb container, extracting the lines with UE connections and aggregating them into a csv format.
# NB! This is quite a "dirty" script and it is very sensitive to the log file format. The original version assumes the following format:
#   [2025-09-10 13:10:26.040] [rls-udp] [info] [JEGOR] New UE with ueId: 6. Active UE RLS UDP connections: 6
#   [2025-09-10 13:10:26.041] [rrc] [info] [JEGOR] Create RRC UE Context for UE ID 2. Stored RRC contexts: 1
# Feel free to use a different logging format, but make sure to change the regex strings (see the lines starting with `NOTE:`)


set -euo pipefail
IFS=$'\n\t'

umask 077


function usage() {
    echo -e "Usage: $0 [OPTION] FILE\n"
    echo -e "Parse the gNB logs with UE connections (provided in the FILE) and convert them to a CSV format"
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
    # NOTE: Change the regex below according to the format of the gNB logs that you used (if necessary)
    sed 's/^\[....-..-.. \(..:..:..\)\....\] \[\([a-z-]\+\)\] .* \([0-9]\+\)$/\1,\2,\3/' |
    # INFO: We take the last value of the number of UE connections during a particular timestamp
    # You could also take the average value instead (see comments below)
    awk -F',' '
        {
            # Format:   Time,Protocol,Connections
            # Example:  13:10:26,rls-udp,6
            #           13:10:26,rrc,1
            connections[$1,$2] = $3;

            # Use the lines below instead to get the average value
            # connections[$1,$2] += $3;
            # count[$1,$2]++;
        }
        END {
            for (combined in connections) {
                split(combined, separate, SUBSEP);
                time = separate[1];
                protocol = separate[2];
                num_connections = connections[time,protocol];

                # Use the line below instead to get the average value
                # num_connections = connections[time,protocol] / count[time,protocol]

                printf("%s,%s,%d\n", time, protocol, num_connections);
            }
        }' |
    sort -t ',' -k1,2 |
    awk -F',' '
        BEGIN {
            print "Time,Protocol,Connections";
        }
        {
            print $0;
        }' > "$OUTPUT_FILE"
