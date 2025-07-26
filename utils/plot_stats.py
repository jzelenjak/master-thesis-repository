#!/usr/bin/env python
#
# This script plots the CPU and memory usage data obtained from the docker stats.
# In order to get the csv file with the stats, run the script log_stats.sh (or log_all.sh for all containers).

import sys

import matplotlib.pyplot as plt

# TODO: Make this a command-line argument
CONTAINER="gNB-DU"
CONTAINER="gNB-CU"
#CONTAINER="gNB"
CONTAINER="AMF"
CONTAINER="UE"

# The file is assumed to be comma-separated (i.e. in the csv format)
file_separator = ","
if len(sys.argv) != 2:
    print(f"Usage: python {sys.argv[0]} stats.csv\n\n       Run log_stats.sh to get stats.csv file")
    exit(1)

factors_bin = {"KiB": 2**10, "MiB": 2**20, "GiB": 2**30}
factors_dec = {"B": 1, "kB": 10**3, "MB": 10**6, "GB": 10**9}

def convert_to_gib_or_gb(s: str) -> float:
    split_idx = 0
    for c in s:
        if c.isalpha():
            break
        split_idx += 1
    num = float(s[:split_idx])
    prefix = s[split_idx:]

    if prefix in factors_bin:
        return num * factors_bin[prefix] / factors_bin["GiB"]
    elif prefix in factors_dec:
        return num * factors_dec[prefix] / factors_dec["GB"]
    else:
        raise ValueError(f"Unsupported prefix: {prefix}")


# File format
# Iter,CPUPerc,MemPerc,MemUsage,NetIO
# 0,47.05%,29.31%,1.172GiB/4GiB,39.1kB/1.03kB
iterations, cpu_perc, mem_perc, mem_usage, net_io = [], [], [], [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines()[1:]:  # Skip the header
        parts = line.split(file_separator)
        iterations.append(int(parts[0]))
        cpu_perc.append(float(parts[1].replace("%", "")))
        mem_perc.append(float(parts[2].replace("%", "")))
        mem_usage.append(convert_to_gib_or_gb(parts[3].split("/")[0]))
        # TODO: Network I/O is most likely not needed
        #net_i = convert_to_gib_or_gb(parts[3].split("/")[0])
        #net_o = convert_to_gib_or_gb(parts[3].split("/")[1])
        #net_io.append((net_i, net_o))


fig, axes = plt.subplots(3)

titles = ["CPU Percentage", "Memory Percentage", "Memory Usage"]
stats = [cpu_perc, mem_perc, mem_usage]
colours = ["red", "blue", "green"]
units = ["%", "%", "GiB"]
y_axis_ranges = [(0, 100), (0, 100), (0, 4)]
# These are for the UE
y_axis_ranges = [(0, 2000), (0, 100), (0, 16)]

for i in range(len(stats)):
    ax = axes[i]
    y_values = stats[i]

    # Increase font (credits to https://stackoverflow.com/questions/3899980/how-to-change-the-font-size-on-a-matplotlib-plot)
    for item in (ax.get_xticklabels() + ax.get_yticklabels()):
        item.set_fontsize(14)

    ax.set_xticks(iterations, labels=iterations)

    ax.set_ylim(y_axis_ranges[i][0], y_axis_ranges[i][1])

    # ax.set_xlabel("Iterations", fontsize=14)
    ax.set_ylabel(units[i], fontsize=14)

    ax.plot(iterations, y_values, color=colours[i], marker='o')
    ax.axvline(x=5, color="black", linestyle="dashed")
    ax.text(5.2, max(y_values), "Attack", rotation=0, ha="left", va="top", fontsize=14)
    ax.set_title(titles[i], fontsize=15)
    ax.grid()


fig.suptitle(f"{CONTAINER} resource consumption under the flooding attack over iterations", fontsize=20)
#fig.suptitle(f"Attacker resource consumption under the flooding attack over iterations", fontsize=20)


plt.gcf().set_size_inches(22, 12, forward=True)
plt.tight_layout()

## plt.savefig("stats_gnodeb.png")
plt.show()
