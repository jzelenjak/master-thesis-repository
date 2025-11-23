# Step-by-step guide to run experiments

**Experiment 1:** Create UEs with the same registered IMSI (using [loop.sh](./scripts/loop.sh) script)

**Experiment 2:** Create UEs with incrementally generated IMSIs (using [flood.sh](./scripts/flood.sh) script)


## Setup

Clone [the OAI fork](https://github.com/jzelenjak/openairinterface5g) with the modifications for the flooding attack.

Compile the (modified) OAI source code by running the `./build_oai_docker.sh` script. This will build a Docker image for the UE and for the gNB.

For more information about building and using OAI, see [BUILD.md](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/BUILD.md) and [tutorial](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/NR_SA_Tutorial_OAI_nrUE.md) in the OAI repository (official or fork).


## Preparation

Start the containers, depending on the directory you are in:
```sh
docker compose up -d                                         # from ./all-in-one/ or ./all-in-one-split/ directories
docker compose -f all-in-one/docker-compose.yml up -d        # from the current directory, for full gNB
docker compose -f all-in-one-split/docker-compose.yml up -d  # from the current directory, for CU-DU split
```

To enter a container, use
```sh
docker exec -it container bash`
```

I recommend using `tmux` (or any other terminal multiplexer) and have at least two tabs:
- **Tab 1:** Enter the `ue` container. For Experiment 1, you will have to run [./loop.sh](./scripts/loop.sh). For Experiment 2, you will have to run [./flood.sh](./scripts/flood.sh). The script [./start.sh](./scripts/start.sh) just starts one UE (the same as starting it manually by running `./nr-uesoftmodem` with the command-line parameters; this script can be used for a victim UE)
- **Tab 2:** Stay in the current directory. To start monitoring the container stats, you need the [./log_stats.sh](../utils/log_stats.sh) script. You could also be in the [all-in-one/](./all-in-one/) or [all-in-one-split/](./all-in-one-split/) directories, however all the needed scripts are in the present directory or in [utils/](./utils). You will have to run `./log_stats.sh -o stats_full_exp1.csv gnodeb oai-amf ue` (or `stats_full_exp2.csv`, analogous for the split, although the file name does not matter). To log the stats without writing them to the file (i.e. just printing them to the terminal), run `./log_stats.sh gnodeb oai-amf ue`. Note that the logging in our OAI fork uses the UTC time, so to make the time consistent, add the `-u` flag, i.e. `./log_stats.sh -u -o stats_full_exp1.csv gnodeb oai-amf ue`
- **Tab 3:** (Optional) Print the logs for the `gnodeb` or `gnodeb-du` containers by running `docker logs -f gnodeb` and `docker logs -f gnodeb-du`, respectively. This can give you an indication of what is going on in the gNB(-DU) container (e.g. errors, warnings, number of connections etc.).
- **Tab 4:** (Optional) This tab can be used for the victim UE. You can enter the container and see if it can connect to the gNB (and the core network) during the attack (this can be done as a separate experiment, not necessarily together with logging the stats)

The gNB (or gNB-DU and gNB-CU) logs for the UE connections will be automatically written in a file for later processing (e.g. `./all-in-one/logs/logs_gnodeb.txt`; see the command in the corresponding `docker-compose.yml` file). *Make sure to rename this file before running another experiment, as otherwise it will be overwritten.*


## Running experiments

*Note: In all the steps below, we use `exp1` for different file names to illustrate the usage. For Experiment 2, you should obviously use `exp2` instead.*

### Generating resource utilization statistics

For each of the two experiments, perform the following steps:

**Step 1.** In the current directory, start logging the stats:
```sh
./log_stats.sh -u -o stats_full_exp1.csv gnodeb oai-amf ue                # For full gNB
./log_stats.sh -u -o stats_split_exp1.csv gnodeb-du gnodeb-cu oai-amf ue  # For the split
```
Wait for around 4-5 iterations (to show the baseline resource utilization before the attack).

**Step 2.** Inside the `ue` container, launch the attack:
```sh
./loop.sh | tee logs/logs_ue_full_exp1.txt   # For Experiment 1 
./flood.sh | tee logs/logs_ue_full_exp2.txt  # For Experiment 2
```
(For the gNB split, replace `full` with `split`.)

**Step 3.** Wait for a total of around 30 iterations and then stop the `log_stats.sh` script (Ctrl+C) and also stop the UE.

### Connecting a legitimate UE during the attack

With the current configuration (see [./core-network/conf/users.conf](./core-network/conf/users.conf)), four users are registered in the network. Experiment 1 (the [./loop.sh](./scripts/loop.sh) script) uses the IMSI `001010000000001`. The [./start.sh](./scripts/start.sh) script, which can be used to start the victim UE, uses the IMSI `001010000000002`.

*NB! Do not forget to rename your files with the logs obtained from any previous runs. Otherwise, they will be overwritten, which is probably not what you want.*

To perform the experiment with connecting a legitimate UE to the network during the attack, you can do the following:

**Step 1.** Inside the `victim_ue` container, start the victim UE:
```sh
./start.sh
```
The victim UE uses the official OAI image, so the UE will behave as normal.

**Step 2.** (Optional) Enter the `victim_ue` container again and start a `ping`, e.g.:
```sh
ping -I oaitun_ue1 google.com
```

**Step 3.** Inside the (attacker) `ue` container, launch the attack:
```sh
./scripts/loop.sh   # Either loop.sh
./scripts/flood.sh  # Or flood.sh
```

**Step 4.** Depending on your goals, you can either wait until the gNB reaches the maximum supported number of UE connections (currently 64 if using at least 40 MHz bandwidth) or connect the victim UE immediately, before the limit on active connections is reached.


## Generating plots

### Resource utilization over time

To plot the resource utilization statistics, run:
```sh
python plot_stats.py stats_full_exp1.csv                      # To plot only one experiment
python plot_stats.py stats_full_exp1.csv stats_full_exp2.csv  # To plot both experiments
```
(For the gNB split, replace `full` with `split`.)

*(If applicable, modify the number of CPU cores used by the containers in the [plot_stats.py](../utils/plot_stats.py) script.)*

### UE connections over time (based on gNB logs)

To plot the active and cumulative (total) RRC contexts over time, follow these steps:

**Step 0.** (If applicable) Get the logs from the gNB (gNB-CU) container as described above. These files should already be present.

**Step 1.** To parse the gNB (gNB-CU) logs with UE connections and save them into a csv file, run:
```sh
# For full gNB
./utils/parse_gnodeb_logs.sh -o connections_gnodeb_full_exp1.csv all-in-one/logs/logs_gnodeb_exp1.txt
# For gNB split (RRC connections are logged by the gNB-CU)
./utils/parse_gnodeb_logs.sh -o connections_gnodeb_split_exp1.csv all-in-one-split/logs/logs_gnodeb_cu_exp1.txt
```
(Without the `-o` option the output is simply written to the standard output.)

*NB! If you use a different logging format, make sure to update the regex strings in the [./parse_gnodeb_logs.sh](./utils/parse_gnodeb_logs.sh) script (see the comments in the script itself).*

**Step 2.** To generate the plots, run:
```sh
# To plot only one experiment (replace "full" with "split" for the split)
python ./utils/plot_gnodeb_connections.py plot_one --start-time HH:MM:SS connections_gnodeb_full_exp1.csv
# To plot both experiments (replace the HH:MM:SS with the corresponding start times; replace "full" with "split" for the split)
python ./utils/plot_gnodeb_connections.py plot_multiple --start-times HH:MM:SS HH:MM:SS connections_gnodeb_full_exp1.csv connections_gnodeb_full_exp2.csv
```
where `HH:MM:SS` is the first timestamp taken from the output of the [log_stats.sh](../utils/log_stats.sh) script
(e.g. use `head -2 stats_full_exp1.csv` and `head -2 stats_full_exp2.csv` to get the start time for the corresponding experiment).
This is needed to align the elapsed seconds on the X-axis with the resource utilization plots generated by the [plot_stats.py](../utils/plot_stats.py) script.
If you don't specify `--start-time` or `--start-times`, then the first timestamp in the provided csv file(s) with the connections will be used.

### UE connections over time (based on UE logs)

To plot the number of established RRC connections and the number of Random Access procedure restarts by the UE over time, follow these steps:

**Step 0.** (If applicable) Get the logs from the UE container as described above. These files should already be present.

**Step 1.** To parse the UE logs with the RRC connections and save them into a csv file, run:
```sh
# For full gNB
./utils/parse_ue_logs.sh -o connections_ue_full_exp1.csv all-in-one/logs/logs_ue_full_exp1.txt
# For gNB split
./utils/parse_ue_logs.sh -o connections_ue_split_exp1.csv all-in-one-split/logs/logs_ue_split_exp1.txt
```
(Without the `-o` option the output is simply written to the standard output.)

*NB! If you use a different logging format, make sure to update the regex strings in the [./parse_ue_logs.sh](./utils/parse_ue_logs.sh) script (see the comments in the script itself).*

**Step 2.** To generate the plots, run:
```sh
# To plot only one experiment (replace "full" with "split" for the split)
python ./utils/plot_ue_connections.py plot_one --start-time HH:MM:SS connections_ue_full_exp1.csv
# To plot both experiments (replace the HH:MM:SS with the corresponding start times; replace "full" with "split" for the split)
python ./utils/plot_ue_connections.py plot_multiple --start-times HH:MM:SS HH:MM:SS connections_ue_full_exp1.csv connections_ue_full_exp2.csv
```
where `HH:MM:SS` is the first timestamp taken from the output of the [log_stats.sh](../utils/log_stats.sh) script
(e.g. use `head -2 stats_full_exp1.csv` and `head -2 stats_full_exp2.csv` to get the start time for the corresponding experiment).
This is needed to align the elapsed seconds on the X-axis with the resource utilization plots generated by the [plot_stats.py](../utils/plot_stats.py) script.
If you don't specify `--start-time` or `--start-times`, then the first timestamp in the provided csv file(s) with the connections will be used.
