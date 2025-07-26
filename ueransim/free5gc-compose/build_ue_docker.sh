#!/bin/bash
#
# This script builds a local UERANSIM image based on the local source code.


docker build -t rogue-ue-ueransim --file ./ueransim/Dockerfile --build-arg TARGET_ARCH=x86_64 .
