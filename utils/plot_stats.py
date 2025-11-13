#!/usr/bin/env python
#
# This script plots the CPU and memory usage for containers, based on the data obtained from the docker stats.
# In order to get the csv file with the stats, run the script log_stats.sh.

import datetime as dt
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt

# The number of CPU cores allocated to containers cannot be obtained from the docker stats output
# For this reason, we hardcode it here, so that it can be used for Y-axis scaling
CPU_CORES = {"ue": 15.0, "gnodeb": 2.0, "amf": 1.0, "gnodeb-du": 2.0, "gnodeb-cu": 1.0, "oai-amf": 1.0}
# More formal names for the entities corresponding to the containers
CONTAINER_NAMES = {"gnodeb": "gNB", "gnodeb-du": "gNB-DU", "gnodeb-cu": "gNB-CU", "amf": "AMF", "ue": "UE", "oai-amf": "AMF"}
# The file is assumed to be comma-separated (i.e. in the csv format)
FILE_SEPARATOR = ","
# The format of the timestamp in the stats file
TIME_FORMAT = "%H:%M:%S"

if len(sys.argv) != 2:
    print(f"Usage: python {sys.argv[0]} stats.csv\n\n\t\tRun log_stats.sh to get stats.csv file")
    exit(1)

prefix_factors = {"KiB": 2**10, "MiB": 2**20, "GiB": 2**30}

def parse_mem_usage(s: str, unit: str = "GiB") -> float:
    """Convert a string like 42.24MiB into the specified unit"""
    split_idx = 0
    for c in s:
        if c.isalpha():
            break
        split_idx += 1
    number = float(s[:split_idx])
    prefix = s[split_idx:].strip()

    if not prefix in prefix_factors:
        raise ValueError(f"Unsupported prefix: {prefix}")
    return number * prefix_factors[prefix] / prefix_factors[unit]


# Print a reminder message about the number of CPU cores allocated to different containers
# (It has to be updated in this script if it is changed in the Docker Compose file)
print("Warning: Using the following values for the number allocated CPU cores:")
for container_name, cpu_cores in CPU_CORES.items():
    print(f"  {container_name}: {cpu_cores}")
print(f"Make sure to change these values if you have updated them in the Docker Compose file.")

# File format
#   Container,Time,CPUPerc,MemPerc,MemUsage
#   gnodeb,16:30:22,0.14%,0.31%,12.64MiB/4GiB
#   ...
containers = dict()
with open(sys.argv[1], "r") as file:
    for line in file.readlines()[1:]:  # Skip the header
        parts = line.split(FILE_SEPARATOR)
        mem_usages = parts[4].split("/")
        name = parts[0]
        if not name in containers:
            containers[name] = {"time": [], "cpu_perc": [], "mem_perc": [], "mem_usage": [], "elapsed_seconds": []}
            containers[name]["mem_limit"] = parse_mem_usage(mem_usages[1])
            containers[name]["start_time"] = dt.datetime.strptime(parts[1], TIME_FORMAT)

        curr_time = dt.datetime.strptime(parts[1], TIME_FORMAT)
        time_diff = curr_time - containers[name]["start_time"]

        containers[name]["elapsed_seconds"].append(int(time_diff.total_seconds()))
        containers[name]["time"].append(curr_time) # Not needed, but just in case
        containers[name]["cpu_perc"].append(float(parts[2].replace("%", "")))
        containers[name]["mem_perc"].append(float(parts[3].replace("%", "")))
        containers[name]["mem_usage"].append(parse_mem_usage(mem_usages[0]))


stats = {
    "cpu_perc": { "title": "CPU Percentage", "color": "red", "unit": "%", "max_value": 100},
    "mem_perc": { "title": "Memory Percentage", "color": "blue", "unit": "%", "max_value": 100},
    "mem_usage": { "title": "Memory Usage", "color": "green", "unit": "GiB", "max_value": 1},
}

for name in containers.keys():
    container = containers[name]
    # Memory limit can be taken from the stats file
    stats["mem_usage"]["max_value"] = container["mem_limit"] 
    # Specify the number of allocated CPU cores to adjust the Y-axis
    stats["cpu_perc"]["max_value"] = 100 * CPU_CORES[name]

    fig, axes = plt.subplots(len(stats))

    for i, metric in enumerate(stats.keys()):
        ax = axes[i]

        # Use timestamps on the X-axis (not recommended)
        # ax.xaxis.set_major_formatter(md.DateFormatter(TIME_FORMAT))
        # ax.xaxis.set_major_locator(md.SecondLocator(interval=5))
        # ax.plot(container["time"], container[metric], color=stats[metric]["color"], marker='o')

        # Use elapsed seconds on the X-axis (recommended)
        ax.set_xlabel("Elapsed seconds", fontsize=14)
        ax.xaxis.set_ticks(range(0, container["elapsed_seconds"][-1] + 4, 5))
        ax.set_xlim(0, container["elapsed_seconds"][-1] + 1)
        ax.plot(container["elapsed_seconds"], container[metric], color=stats[metric]["color"], marker='o')

        ax.set_ylabel(stats[metric]["unit"], fontsize=14)
        ax.set_ylim(0, stats[metric]["max_value"])

        for tick_label in (ax.get_xticklabels() + ax.get_yticklabels()):
            tick_label.set_fontsize(14)

        ax.set_title(stats[metric]["title"], fontsize=16)
        ax.grid()

    # fig.suptitle(f"Resource consumption of the {name} container under the flooding attack over time", fontsize=20)
    fig.suptitle(f"{CONTAINER_NAMES[name]} resource consumption under the flooding attack over time", fontsize=20)

    plt.gcf().set_size_inches(22, 12, forward=True)
    plt.tight_layout()

    plt.savefig(f"stats_{name.replace('-', '_')}.png")
    plt.show()
    # https://stackoverflow.com/questions/8213522/when-to-use-cla-clf-or-close-for-clearing-a-plot 
    plt.close()
