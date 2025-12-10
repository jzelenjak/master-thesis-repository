#!/usr/bin/env python
#
# This script plots the CPU and memory usage for containers, based on the data obtained from docker stats.
# The script can be used to plot statistics for one or multiple experiments (based on the number of stats files that are provided).
#   Note that at most two experiments are currently supported, but this can be extended by modifying the relevant parts of the code.
# In order to get the csv file with the stats, run the script log_stats.sh.

import datetime as dt
import sys

import matplotlib.pyplot as plt
from termcolor import colored

# INFO: The number of CPU cores allocated to containers cannot be obtained from the docker stats output
# For this reason, we hardcode them here, so that they can be used for Y-axis scaling
# INFO: These are the values for UERANSIM experiments
# CPU_CORES = { "ue": 15.0, "gnodeb": 2.0, "amf": 1.0 }
# INFO: These are the values for OAI experiments
CPU_CORES = { "ue": 15.0, "gnodeb": 3.0, "gnodeb-du": 3.0, "gnodeb-cu": 1.0, "oai-amf": 1.0 }

# The names to be used in plot titles
CONTAINER_NAMES = { "gnodeb": "gNB", "gnodeb-du": "gNB-DU", "gnodeb-cu": "gNB-CU", "amf": "AMF", "ue": "UE", "oai-amf": "AMF" }
# The file is assumed to be comma-separated (i.e. in the csv format)
FILE_SEPARATOR = ","
# The format of the timestamps in the stats file
TIME_FORMAT = "%H:%M:%S"
# The format of the output file (e.g. png, pdf, svg)
OUTPUT_FILE_EXTENSION = "pdf"

# Parameters for different elements of a figure
FONT_SIZE_TEXT = 16
FONT_SIZE_SUBTITLE = 20
FONT_SIZE_TITLE = 22
MARKER_SIZE = 8
LINE_WIDTH = 4
LINE_ALPHA = 0.6

# Elapsed seconds before the attack started
# Must be > 0, otherwise the line will not be drawn
ATTACK_START = 10

# A helper function to parse and convert memory usage into the specified unit
PREFIX_FACTORS = {"KiB": 2**10, "MiB": 2**20, "GiB": 2**30}
def parse_mem_usage(s: str, output_unit: str = "GiB") -> float:
    """Convert a string like 42.24MiB into the specified unit"""
    split_idx = 0
    for c in s:
        if c.isalpha():
            break
        split_idx += 1
    number = float(s[:split_idx])
    prefix = s[split_idx:].strip()

    if not prefix in PREFIX_FACTORS:
        raise ValueError(colored(f"Unsupported prefix: {prefix}", color="red"))
    # First convert to bytes (multiply by the prefix), then convert to the output unit (divide by the prefix)
    return (number * PREFIX_FACTORS[prefix]) / PREFIX_FACTORS[output_unit]


# Check that either one or two files have been provided
# INFO: Currently, at most two experiments are supported
if len(sys.argv) < 2 or len(sys.argv) > 3:
    print(f"Usage: python {sys.argv[0]} stats_exp1.csv [stats_exp2.csv]\n")
    print("\tRun log_stats.sh to get stats_expX.csv file")
    print("\tNote that currently at most two experiments are supported (but this can be extended in the code)")
    exit(1)

# File format
#   Container,Time,CPUPerc,MemPerc,MemUsage
#   gnodeb,16:30:22,0.14%,0.31%,12.64MiB/4GiB
#   ...
experiments = []
for i, exp_file_name in enumerate(sys.argv[1:]):
    containers = dict()
    with open(exp_file_name, "r") as exp_file:
        for line in exp_file.readlines()[1:]:  # INFO: Skip the header
            parts = line.split(FILE_SEPARATOR)
            mem_usages = parts[4].split("/")
            container_name = parts[0]

            # INFO: A friendly check to prevent future mistakes
            assert container_name in CPU_CORES, f"Container {container_name} is not defined in CPU_CORES. Are you plotting UERANSIM or OAI experiments?"

            if not container_name in containers:
                containers[container_name] = {"elapsed_seconds": [], "cpu_perc": [], "mem_perc": [], "mem_usage": []}
                containers[container_name]["mem_limit"] = parse_mem_usage(mem_usages[1])
                containers[container_name]["start_time"] = dt.datetime.strptime(parts[1], TIME_FORMAT)

            timestamp = dt.datetime.strptime(parts[1], TIME_FORMAT)
            time_diff = timestamp - containers[container_name]["start_time"]

            containers[container_name]["elapsed_seconds"].append(int(time_diff.total_seconds()))
            containers[container_name]["cpu_perc"].append(float(parts[2].replace("%", "")))
            containers[container_name]["mem_perc"].append(float(parts[3].replace("%", "")))
            containers[container_name]["mem_usage"].append(parse_mem_usage(mem_usages[0]))
    experiments.append(containers)

# INFO: Perform some friendly consistency checks
for i in range(len(experiments)):
    assert len(experiments[i]) == len(experiments[0]), f"Experiment {i+1} has a different number of containers than Experiment 1"
    for container_name in experiments[i]:
        assert experiments[i][container_name]["mem_limit"] == experiments[0][container_name]["mem_limit"], f"Experiment {i+1} has a different mem_limit than Experiment 1"

# INFO: Print a friendly reminder message about the number of CPU cores allocated to different containers
# NOTE: This number has to be updated in this script if it is changed in the Docker Compose file(s)
print(colored("Warning: Using the following values for the number allocated CPU cores:", color="yellow"))
for container_name, cpu_cores in CPU_CORES.items():
    print(colored(f"  {container_name}: {cpu_cores}", color="yellow"))
print(colored(f"Make sure to change these values if you have updated them in the Docker Compose file(s)", color="yellow"))
print(colored(f"Warning: Using {ATTACK_START} seconds as the start of the attack", color="yellow"))

# INFO: Define some values for the metrics that will be plotted
# NOTE: "color" is only used when a single experiment file has been provided
stats = {
    "cpu_perc": { "title": "CPU Percentage", "color": "red", "unit": "%", "max_value": 100 },
    "mem_perc": { "title": "Memory Percentage", "color": "blue", "unit": "%", "max_value": 100 },
    "mem_usage": { "title": "Memory Usage", "color": "green", "unit": "GiB", "max_value": 1 },
}

# NOTE: These values will be used if multiple experiment files have been provided
exp_colors = ["red", "blue"]
exp_labels = ["Valid IMSI", "Invalid IMSIs"]

# INFO: Take the first experiment as a reference, but plot all experiments
containers = experiments[0]
# INFO: One plot is generated for each container
for container_name in containers:
    # INFO: Memory limit can be taken from the stats file
    stats["mem_usage"]["max_value"] = containers[container_name]["mem_limit"]
    # INFO: Specify the number of allocated CPU cores to adjust the Y-axis
    stats["cpu_perc"]["max_value"] = 100 * CPU_CORES[container_name]

    # INFO: One subplot for each metric (cpu_perc, mem_perc, mem_usage)
    fig, axes = plt.subplots(len(stats))
    for i, metric in enumerate(stats.keys()):
        ax = axes[i]
        max_elapsed_seconds = 60

        # INFO: Plot the metric for each experiment
        for index in range(len(experiments)):
            container = experiments[index][container_name]
            max_elapsed_seconds = max(max_elapsed_seconds, container["elapsed_seconds"][-1])
            color = stats[metric]["color"] if len(experiments) == 1 else exp_colors[index]
            # INFO: If the time period is short, add circles for markers and make the dashes bigger
            # NOTE: Feel free to use a different number for the threshold
            if max_elapsed_seconds <= 300:
                ax.plot(container["elapsed_seconds"], container[metric], color=color, marker='o', markersize=MARKER_SIZE, \
                    linestyle="dashed", dashes=(3 + index, 2), linewidth=LINE_WIDTH, alpha=LINE_ALPHA, label=f"Experiment {index + 1} ({exp_labels[index]})")
            else:
                ax.plot(container["elapsed_seconds"], container[metric], color=color, linestyle="dashed", dashes=(0.75 + index * 0.25, 0.75), \
                    linewidth=LINE_WIDTH, alpha=LINE_ALPHA, label=f"Experiment {index + 1} ({exp_labels[index]})")

        # INFO: Plot the start of the attack (to give an indication of the baseline)
        if ATTACK_START > 0:
            ax.axvline(x=ATTACK_START, color="grey", linestyle="dashed", dashes=(2, 2), linewidth=LINE_WIDTH + 1, alpha=LINE_ALPHA, label="Attack start")

        ax.set_xlabel("Elapsed seconds", fontsize=FONT_SIZE_TEXT)
        # NOTE: Feel free to use a different number for the threshold
        step_size = 5 if max_elapsed_seconds <= 300 else 50
        ax.xaxis.set_ticks(range(0, max_elapsed_seconds + 4, step_size))
        ax.set_xlim(left=0, right=max_elapsed_seconds + 1)

        ax.set_ylabel(stats[metric]["unit"], fontsize=FONT_SIZE_TEXT)
        ax.set_ylim(bottom=0, top=stats[metric]["max_value"])

        for tick_label in (ax.get_xticklabels() + ax.get_yticklabels()):
            tick_label.set_fontsize(FONT_SIZE_TEXT)

        # INFO: Drawing the legend for only one experiment does not make sense
        if len(experiments) > 1:
            ax.legend(fontsize=FONT_SIZE_TEXT)
        ax.set_title(stats[metric]["title"], fontsize=FONT_SIZE_SUBTITLE)
        ax.grid()

    fig.suptitle(f"{CONTAINER_NAMES[container_name]} resource consumption under the flooding attack over time", fontsize=FONT_SIZE_TITLE)

    plt.gcf().set_size_inches(20, 11, forward=True)
    plt.tight_layout()

    plt.savefig(f"stats_{container_name.replace('-', '_')}.{OUTPUT_FILE_EXTENSION}")
    plt.show()
    plt.close()
