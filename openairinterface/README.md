# OAI 5G stack

*Note: The configuration files and the Docker Compose files in this directory have been taken from the [official OpenAirInterface repository](https://gitlab.eurecom.fr/oai/openairinterface5g), and have been modified by Dr. Enrico Bassetti to have a single Docker Compose file to start all containers (with or without the gNB split). This README file has also been written by Dr. Enrico Bassetti. We adapt it to only include the relevant information for running the stack on a local machine.*

This repository contains an OpenAirInterface 5G stack configured and run using Docker containers.

## Requirements

Refer to the OAI <https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/system_requirements.md> website for requirements.
At the time of writing, various tutorials (such as <https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/NR_SA_Tutorial_OAI_CN5G.md>) state that the minimum requirements for the entire OAI (Core Network, UE, gNodeB) are:

- Linux (recent version, such as >= 6.1)
- Docker Engine (from Docker Inc., e.g., Docker CE)
- 32 GB of RAM
- 8+ CPUs
- `avx2` instruction set
- `sctp` protocol enabled in the Linux kernel of the host machine
- Intel-based or ARM64-based architecture

However, it most likely requires less memory and CPUs than that.

To use the scripts and aliases in this repository, you need:

* On Windows: Git Bash shell
* On Linux: `git`, `bash` and `ssh`
* Docker CLI (no need for Docker Desktop, the CLI suffices)
* Wireshark

## Preparing the environment

Deploying the stack on your local machine:
  1. Be sure that you have all the requirements.
  2. Build the image in the `gnodeb` directory. Refer to its README.
  3. Modify the volume paths inside the `docker-compose.yml` file that you will deploy: all the volume paths starting with `/data` should be remapped to the `core-network/` directory (the one in this repository) using the an absolute path *(note: this has already been done)*.

## Usage

If you use your local machine, use standard docker commands to deploy the stack.

## Data storage (core network)

The Core Network MySQL database is stored in a Docker volume in order to survive to multiple re-deploy. To reset the configuration, remove the volume. Refer to the Docker documentation about volumes.


## Known issues

### gNodeB/UE delays / not connecting

It might happen that the UE is not able to establish a connection on the very first run. Stop and restart the UE should fix it.
The underlying cause is still being investigated.

Note that gNodeB has a delay of 15 seconds on start, and the UE has a delay of 30 seconds to avoid race conditions.

### AVX-512 / Crash on illegal instructions

The gNodeB docker image provided by OAI Alliance is built using AVX-512, which may not be available. In the `gnodeb` directory, there is a `Dockerfile` that describes a docker image where the `nr-softmodem` is recompiled from scratch. By default, the configuration in this repository uses an image from there pre-built in Gitlab.

### "Buffer overflow" on boot in the AMF/gNodeB/SMF

Be sure to have SCTP enabled and loaded in the kernel.

### Unhealthy mysql container

Most likely, the database initialization script did not run (properly). To fix the issue, first go into the MySQL container:
```sh
docker compose exec -it mysql /bin/bash
```

Then connect to the MySQL database (see `docker-compose.yaml` for the password):
```sh
mysql -u root -p oai_db
```

Run the MySQL script to initialize the database:
```sh
mysql> source docker-entrypoint-initdb.d/oai_db.sql
```

Finally, restart the containers.
