# free5GC-compose files

This directory contains the free5GC compose files taken directly from [the official free5gc compose repository](https://github.com/free5gc/free5gc-compose).
We keep the files needed for pulling the images and running free5GC, and modify the corresponding configurations as needed for our experiments.
We do not include some files from the official repository that are not needed for our experiments (e.g. Dockerfiles for a local free5GC build, ULCL configuration etc.).

For further information, please refer to the [the official free5gc compose repository](https://github.com/free5gc/free5gc-compose).

## Preparing the environment

1. Pull the free5GC images from Docker Hub: `docker compose pull`
2. In order to run UPF, you need to install [gtp5g kernel module](https://github.com/free5gc/gtp5g) (see [this post](https://forum.free5gc.org/t/erro-upf-main-upf-cli-run-error-open-gtp5g-open-link-create-operation-not-supported/1795))
3. A separate UE container has already been added in `docker-compose.yaml`. As listed in [the instructions on running UE on a separate container](https://github.com/free5gc/free5gc-compose?tab=readme-ov-file#option-2-run-ue-on-a-separate-container)):
    - Add a subscriber using the WebUI. WebUI should be accessible on [http://127.0.0.1:5000](http://127.0.0.1:5000).
    To run the WebUI container: `docker compose up -d free5gc-webui`
    - You can use the IMSI that is already in `config/uecfg.yaml` or you can create a new one (make sure to update the UE config)
    - Follow the steps on [this page](https://free5gc.org/guide/5-install-ueransim/#4-use-webconsole-to-add-an-ue) or [this page](https://free5gc.org/guide/Webconsole/Create-Subscriber-via-webconsole/#4-open-webconsole)
    - If you have changed the "Operator Code Type" to "OP" in WebUI, then don't forget to also change it in `config/uecfg.yaml`
4. In the config files, keep the FQDNs that are already there (e.g. `gnb.free5gc.org`)

## Building a local UE image

To use the local version of UERANSIM:
1. Clone [the official UERANSIM repository](https://github.com/aligungr/UERANSIM).
2. Build the executables for the UE and the gNB, as specified in the official repository.

For the flooding attack, use the modified UERANSIM source code:
1. Clone [the UERANSIM fork](https://github.com/jzelenjak/UERANSIM) with the modifications for the flooding attack.
2. Build a Docker image for the UE and the gNB by running the `./build_docker.sh` script. This script can also be used to build the original source code.

## Usage

Use standard docker commands to run free5GC: `docker compose up -d` (see [the official instructions](https://github.com/free5gc/free5gc-compose?tab=readme-ov-file#run-free5gc) for more information).

To run the UE:
1. Enter the UE container: `docker exec -it ue bash`
2. Run `./nr-ue -c config/uecfg.yaml` (or use a [start.sh](../scripts/start.sh) script in the [../scripts/](../scripts/) directory)

## Decoding NR RRC messages in Wireshark

RRC messages are encapsulated in RLS PDU. RLS (Radio Link Simulation) is a protocol designed by [UERANSIM](https://github.com/aligungr/UERANSIM).

RLS PDU can contain:

1. RLS control messages
2. IPv4 data packets
3. RRC messages

For more information, see [this post](https://github.com/aligungr/UERANSIM/issues/275).

To decode RRC messages, you need a Wireshark dissector. Luckily, it has already been written: [nextmn/RLS-wireshark-dissector](https://github.com/nextmn/RLS-wireshark-dissector). Follow the installation instructions.

## Capturing UE attach messages in Wireshark

To capture the UE registration procedure:

1. Stop the UE container: `docker compose down ue`
2. Start Wireshark capture on `br-free5gc` interface
3. Start the UE container: `docker compose up -d ue`
4. If the UE container is a dummy container (i.e. does not start the UE process):
    - Enter the UE container: `docker exec -it ue bash`
    - Run `./nr-ue -c config/uecfg.yaml`

In a separate terminal tab:

1. Attach to the UE container: `docker exec -it ue bash`
2. Ping some website on the Internet: `ping -I uesimtun0 google.com -c 1`
   (use `ip addr` to check the name of the tunnel interface)
3. Deregister the UE: `./nr-cli imsi-208930000000001 --exec "deregister switch-off"` (see also [this post](https://github.com/aligungr/UERANSIM/discussions/738))

Now you can stop the Wireshark capture.
To filter out the relevant packets, you can use the following display filter: `nr-rrc or nas-5gs or icmp or ngap`.
While I was able to capture NAS Deregistration Request message, I was not able to capture NAS Deregistration accept message.

You can export the displayed packets in `File>Export specified packets`.
Check "Displayed" (instead of "Captured"). If you want, you can choose `pcap` instead of `pcapng` as the export option.
