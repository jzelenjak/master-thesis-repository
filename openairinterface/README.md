# OAI 5G stack

*Note: The configuration files and the Docker Compose files in this directory have been taken from the [official OpenAirInterface repository](https://gitlab.eurecom.fr/oai/openairinterface5g), and have been modified by Dr. Enrico Bassetti to have a single Docker Compose file to start all containers (with or without the gNB split). This README file has also been written by Dr. Enrico Bassetti. We adapt it to only include the relevant information for running the stack on a local machine and using our OAI fork.*

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


## Setup

For 5G Core Network, use the official OAI images (they are already specified in `docker-compose.yml` files).

For NR UE and gNodeB, you can either use the OAI official images or build your own images, according to your needs.

### Using OpenAirInterface repository (modified source code)

You can use the OpenAirInterface repository and build the images for your modified source code.
This subsection describes the process using our OAI fork for the flooding attack.
However, the Dockerfiles and build scripts in that fork should also work for the official OAI repository (tested for the `2025.w45` version).

1. Clone the OAI fork for the flooding attack from <https://github.com/jzelenjak/openairinterface5g>.
2. Run `./build-oai-docker.sh` script in the fork repository to build the Docker images for NR UE and gNodeB.
   Feel free to modify the image names and/or Dockerfiles according to your needs.
3. Check that `docker-compose.yml` files refer to correct image names for NR UE and gNodeB (by default, the image names are consistent).

### Using official OpenAirInterface images (original source code)

To use the official OpenAirInterface images (for normal behaviour), make sure that `docker-compose.yml` files specify the official images (see the comments in those files).

Note: If your machine does not support the AVX-512 instruction set, you can compile the gNodeB image locally. See README.md in the `gnodeb/` directory.


## Usage

Use standard Docker (Compose) commands to deploy the stack.


## Data storage (core network)

The Core Network MySQL database is stored in a Docker volume in order to survive to multiple re-deploy. To reset the configuration, remove the volume. Refer to the Docker documentation about volumes.


## Known issues

### gNodeB/UE delays / not connecting

It might happen that the UE is not able to establish a connection on the very first run. Stop and restart the UE should fix it.
The underlying cause is still being investigated.

Note that gNodeB has a delay of 15 seconds on start, and the UE has a delay of 30 seconds to avoid race conditions.

### AVX-512 / Crash on illegal instructions

The gNodeB docker image provided by OAI Alliance is built using AVX-512, which may not be available. In the `gnodeb` directory, there is a `Dockerfile` that describes a docker image where the `nr-softmodem` is recompiled from scratch.

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
