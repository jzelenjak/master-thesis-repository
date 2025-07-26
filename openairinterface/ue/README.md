# gNodeB image

This directory contains a helper script `build_ue_docker.sh` to build a local UE image (e.g. with a modified source code).


## Build the image

To build the image:
1. Clone [the official OpenAirInterface repository](https://gitlab.eurecom.fr/oai/openairinterface5g/)
2. Copy the `build_ue_docker.sh` script to the root directory of the OAI repository (or create a symlink to this file)
3. Run the script from the root directory of the OAI repository: `./build_ue_docker.sh` (feel free to change the image name, but also update it in the `docker-compose.yaml` files).

Just in case, the relevant Dockerfiles have been copied from [the official OAI repository](https://gitlab.eurecom.fr/oai/openairinterface5g/) into the `./docker/` directory.
However, to avoid the problems related to paths, it is easier to just copy the `build_ue_docker.sh` script to the OAI root directory and run it there.
