#!/bin/bash
#
# This script builds a local OAI NR UE image based on the local source code.
# Make sure to run it from the root directory of the official openairinterface repository (https://gitlab.eurecom.fr/oai/openairinterface5g/).


docker build -t ran-base --file ./docker/Dockerfile.base.ubuntu22 --build-arg TARGETARCH=amd64 .
DOCKER_BUILDKIT=1 docker build -t ran-build --file ./docker/Dockerfile.build.ubuntu22 .
# DOCKER_BUILDKIT=1 docker build -t ran-build --file ./docker/Dockerfile.build.ubuntu22 --no-cache .
DOCKER_BUILDKIT=1 docker build -t rogue-ue --file ./docker/Dockerfile.nrUE.ubuntu22 --build-arg TARGETPLATFORM="linux/amd64" .
