# gNodeB image

*Note: This README file has originally been written by Dr. Enrico Bassetti. We adapt it to only include the relevant information for running the stack on a local machine and using our OAI fork. Since the original README (and other configuration files) used OAI version 2024.w40, we keep that version in this README, but note the updates for the more recent versions.*

The image built using the `Dockerfile` in this directory contains the software modem for the gNodeB. This image can be used in Intel-based environments using processors without AVX-512 instruction set. Refer to the main README for the motivation.

Differently from the official distribution, this image also embeds the example configurations that are available in the `PROJECTS` directory.

Note: The `PROJECTS` directory includes the configuration files for the OAI version `2024.w40`.
To use the configuration files from more recent OAI versions, you can replace this directory with the `targets/PROJECTS` directory from the official OAI repository at
<https://gitlab.eurecom.fr/oai/openairinterface5g/-/tree/develop/targets/PROJECTS> (using the OAI version you need).
We keep the gNodeB/gNodeB-DU/gNodeB-CU configuration files used with the `2024.w40` version in the `./conf-2024-w40/` directory.
If you use those files, make sure to update the paths in `docker-compose.yml` files in this repository.


## Build the image

To build the image, use the following command:

```sh
docker build -t oai-gnodeb-local:2024.w40 .
```

If needed, you can replace `2024.w40` with a different tag. When using a different tag, make sure to update it in the `docker-compose.yml` files in this repository.


## Important notes

### Running software modems

The `Dockerfile` in this directory uses the OpenAirInterface version `2024.w40`.

From tag `2024.w45`, OAI NR UE and gNodeB run by default in standalone (SA) mode (see <https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/NR_SA_Tutorial_OAI_nrUE.md>).

If using this `Dockerfile` as is, make sure to run the `nr-uesoftmodem` (UE) and `nr-softmodem` (gNodeB/gNodeB-DU/gNodeB-CU) with the `--sa` option.
Update the `docker-compose.yml` files in this repository to specify this option.

If you use the OAI version `2024.w45` or later, **do not** specify the `--sa` option, as otherwise the softmodem will crash due to an unknown option.

### gNodeB configuration files

For the `2024.w40` version, use `./conf-2024-w40/` directory.

For the newer versions, you can use `./conf/` directory (tested with `2025.w45`).

Note: Depending on the OAI development, you might have to update the configuration file names.
For the most up-to-date information, always refer to the official OpenAirInterface repository at
<https://gitlab.eurecom.fr/oai/openairinterface5g/>.
