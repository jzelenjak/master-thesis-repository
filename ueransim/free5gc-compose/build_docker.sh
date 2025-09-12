#!/bin/bash
#
# This script builds a local UERANSIM image based on the local source code.
#
# NB! Make sure to have the UERANSIM repository in the current directory (as UERANSIM/ directory).
#     Otherwise, you will need to modify the Dockerfile in the ./ueransim directory.


docker build -t rogue-ueransim --file ./ueransim/Dockerfile --build-arg TARGET_ARCH=x86_64 .
