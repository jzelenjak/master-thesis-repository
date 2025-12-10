#!/bin/bash
#
# This script parses the logs from the gnodeb container, extracting the lines with UE connections and aggregating them into a csv format.
# NOTE: Given that OpenAirInterface has a limit on the number of UEs per gNB (as defined by MAX_MOBILES_PER_GNB, with the maximum supported value of 64),
#   we log the number of active RRC contexts and their cumulative count. We can do this because OAI creates an RRC context when receiving RRCSetupRequest
#   and removes this context when generating RRCReject if the maximum number of UEs has been reached.
#   If this changes in the future versions, the logging might have to be adjusted accordingly (e.g. by logging in the MAC layer during the RA procedure).
# Also note that we still keep the protocol field in the output, even though it is (currently) only NR_RRC. Other protocols following the same format could also be added.
#
# NB! This is quite a "dirty" script and it is very sensitive to the log file format. The original version assumes the following format:
#   [NR_RRC]   [JEGOR] [2025-11-15 09:52:18] Create RRC UE Context for UE with RNTI 03ba. Active RRC contexts: 65. Cumulative RRC contexts: 67
#   [NR_RRC]   [JEGOR] [2025-11-15 09:52:18] Remove RRC UE Context for UE with RNTI 03ba. Active RRC contexts: 64. Cumulative RRC contexts: 67
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
    #   [NR_RRC]   [JEGOR] [2025-11-15 09:52:18] Create RRC UE Context for UE with RNTI 03ba. Active RRC contexts: 65. Cumulative RRC contexts: 67
    #   [NR_RRC]   [JEGOR] [2025-11-15 09:52:18] Remove RRC UE Context for UE with RNTI 03ba. Active RRC contexts: 64. Cumulative RRC contexts: 67
    # The line below is a small hint on how to read the regex. '_' is used for alignment (not a literal symbol)
    #        [__protocol___]   [JEGOR_] _[YYYY-MM-DD __HH:MM:SS___] ?? Active ______: __[act]____. Cumulative ______: __[cum]____
    sed 's/^\[\([A-Z_]\+\)\].*\[JEGOR\] \[....-..-.. \(..:..:..\)\] .* Active [^:]\+: \([0-9]\+\). Cumulative [^:]\+: \([0-9]\+\)$/\2,\1,\3,\4/' |
    # INFO: We take the last value of the number of UE connections during a particular timestamp
    # You could also take the average value instead (see comments below)
    awk -F',' '
        {
            # Format:   Time,Protocol,Active,Cumulative
            # Example:  09:52:31,NR_RRC,65,752
            active_connections[$1,$2] = $3;
            cumulative_connections[$1,$2] = $4;

            # Use the lines below instead to get the average value
            # active_connections[$1,$2] += $3;
            # cumulative_connections[$1,$2] += $4;
            # count[$1,$2]++;
        }
        END {
            for (combined in active_connections) {
                split(combined, separate, SUBSEP);
                time = separate[1];
                protocol = separate[2];
                num_active_connections = active_connections[time,protocol];
                num_cumulative_connections = cumulative_connections[time,protocol];

                # Use the lines below instead to get the average value
                # num_active_connections = active_connections[time,protocol] / count[time,protocol]
                # num_cumulative_connections = cumulative_connections[time,protocol] / count[time,protocol]

                printf("%s,%s,%d,%d\n", time, protocol, num_active_connections, num_cumulative_connections);
            }
        }' |
    sort -t ',' -k1,2 |
    awk -F',' '
        BEGIN {
            print "Time,Protocol,Active_Connections,Cumulative_Connections";
        }
        {
            print $0;
        }' > "$OUTPUT_FILE"
