# Step-by-step guide to run experiments

**Experiment 1:** Create UEs with the same registered IMSI (using [loop.sh](./scripts/loop.sh) script)

**Experiment 2:** Create UEs with random incrementing IMSIs (using [flood.sh](./scripts/flood.sh) script)


## Setup

Clone [the UERANSIM fork](https://github.com/jzelenjak/UERANSIM) with the modifications for the flooding attack.

Compile the (modified) UERANSIM source code by running the `./build_docker.sh` script. This will build a Docker image with the UE and the gNB.

For more information about building and using UERANSIM with free5gc, see the [README.md](./free5gc-compose/README.md) in the [free5gc-compose/](./free5gc-compose/) directory.


## Preparation

Start the containers, depending on the directory you are in:
```sh
docker compose up -d  # or
docker compose -f free5gc-compose/docker-compose.yaml up -d
```

To enter a container, use
```sh
docker exec -it container bash`
```

I recommend using `tmux` (or any other terminal multiplexer) and have four tabs:
- **Tab 1:** Enter the `gnodeb` container. To start the gNB, you will have to run `./nr-gnb -c config/gnbcfg.yaml`. To store the logs for the UE connections for later processing, you can pipe the gNB output to a file, e.g. `./nr-gnb -c config/gnbcfg.yaml | tee logs/gnodeb_logs_full.txt`
- **Tab 2:** Enter the `ue` container. For Experiment 1, you will have to run [./loop.sh](./scripts/loop.sh). For Experiment 2, you will have to run [./flood.sh](./scripts/flood.sh). The script [./start.sh](./scripts/start.sh) just starts one UE (the same as starting it manually by running `./nr-ue -c config/uecfg.yaml`)
- **Tab 3:** Stay in the current directory. To start monitoring the container stats, you need the [./log_stats.sh](../utils/log_stats.sh) script. You could also be in the [free5gc-compose/](./free5gc-compose/) directory, however all the needed scripts are in the present directory. You will have to run `./log_stats.sh -o stats_exp1.csv gnodeb amf ue` (or `stats_exp2.csv`, although the file name does not matter). To log the stats without writing them to the file (i.e. just printing them to the terminal), run `./log_stats.sh gnodeb amf ue`. Note that the UERANSIM logging seems to use the UTC time, so to make the time consistent, add the `-u` flag, i.e. `./log_stats.sh -u -o stats_exp1.csv gnodeb amf ue`
- **Tab 4:** This tab can be used for the AMF or the victim UE. For the AMF, you can check the logs (`docker logs -f amf`) to see if the UE Registration Requests are reaching the AMF. For the victim UE, you can enter the container and see if it can connect to the gNB (and the core network) during the attack (this can be done as a separate experiment, not necessarily together with logging the stats)


## Running experiments

*Note: In all the steps below, we use `exp1` for different file names to illustrate the usage. For Experiment 2, you should obviously use `exp2` instead.*

### Generating resource utilization statistics

For each of the two experiments, perform the following steps:

**Step 1.** Inside the `gnodeb` container, start the gNB:
```sh
./nr-gnb -c config/gnbcfg.yaml | tee logs/gnodeb_logs_full_exp1.txt
```

**Step 2.** In the current directory, start logging the stats:
```sh
./log_stats.sh -u -o stats_exp1.csv gnodeb amf ue
```
Wait for around 4-5 iterations (to show the baseline resource utilization before the attack).

**Step 3.** Inside the `ue` container, launch the attack:
```sh
./scripts/loop.sh   # For Experiment 1 
./scripts/flood.sh  # For Experiment 2
```

**Step 4.** Wait for a total of around 30 iterations and then stop the gNB and the `log_stats.sh` script (Ctrl+C); also stop the UE.
In case the gNB crashes during the attack (due to the Segmentation fault), just restart it and repeat all the steps again. You could also try reducing the flooding rate in the attack script (indicated by the `FLOODING_RATE`).

### Connecting a legitimate UE during the attack

To perform the experiment with connecting a legitimate UE to the network during the attack, you can do the following:

**Step 0.** Register the victim UE in the free5gc WebUI (see the instructions in the [free5gc-compose/README.md](./free5gc-compose/README.md); use `imsi-208930000000002`).

**Step 1.** Inside the `gnodeb` container, start the gNB:
```sh
./nr-gnb -c config/gnbcfg.yaml # Logs are not needed in this case
```

**Step 2.** Inside the `victim_ue` container, start the victim UE:
```sh
./nr-ue -c config/uecfg.yaml
```
The victim UE uses the official UERANSIM image, so the UE will behave as normal.

Note: If the victim UE cannot successfully establish a PDU session, check if the [gtp5g](https://github.com/free5gc/gtp5g) kernel module is loaded.

**Step 3.** (Optional) Enter the `victim_ue` container again and start a `ping`, e.g.:
```sh
ping -I uesimtun0 google.com
```

**Step 4.** Inside the (attacker) `ue` container, launch the attack:
```sh
./scripts/loop.sh   # Either loop.sh
./scripts/flood.sh  # Or flood.sh
```

**Step 5.** Wait for some time.
When I was trying to run this experiment, the gNB kept crashing (with the same Segmentation fault). 
If that happens, you can try to first launch the attack, then wait for around 5 seconds, and then try to start the victim UE.
In this case, assuming the flooding rate is not too low, the victim UE will most likely keep hanging and retrying the registration due to timeouts (at least, this was the case for me).


## Generating plots

### Resource utilization over time

To plot the resource utilization statistics, run:
```sh
python plot_stats.py stats_exp1.csv                 # To plot only one experiment
python plot_stats.py stats_exp1.csv stats_exp2.csv  # To plot both experiments
```
*(If necessary, modify the number of CPU cores used by the UE container in the [plot_stats.py](../utils/plot_stats.py) script.)*

### UE connections over time

To plot the active RLS UDP connections and the total stored RRC contexts over time, follow these steps:

**Step 0.** (If applicable) Get the logs from the gNB container as described above.

**Step 1.** To parse the gNB logs with UE connections and save them into a csv file, run:
```sh
./parse_gnodeb_logs.sh -o connections_exp1.csv free5gc-compose/logs/gnodeb_logs_full_exp1.txt
```
(Without the `-o` option the output is simply written to the standard output.)

*NB! If you use a different logging format, make sure to update the regex strings in the [./parse_gnodeb_logs.sh](./parse_gnodeb_logs.sh) script (see the comments in the script itself).*

**Step 2.** To generate the plots, run:
```sh
python plot_connections.py plot_one --start-time HH:MM:SS connections_exp1.csv                                      # To plot only one experiment
python plot_connections.py plot_multiple --start-times HH:MM:SS HH:MM:SS connections_exp1.csv connections_exp2.csv  # To plot both experiments
```
where `HH:MM:SS` is the first timestamp taken from the output of the [log_stats.sh](../utils/log_stats.sh) script
(e.g. use `head -2 stats_exp1.csv` and `head -2 stats_exp2.csv`to get the start time for the corresponding experiment).
This is needed to align the elapsed seconds on the X-axis with the resource utilization plots generated by the [plot_stats.py](../utils/plot_stats.py) script.
If you don't specify `--start-time` or `--start-times`, then the first timestamp in the provided csv file(s) with the connections will be used.
