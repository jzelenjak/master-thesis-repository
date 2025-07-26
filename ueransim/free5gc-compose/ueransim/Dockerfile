# Note: This Dockerfile has been taken from the official free5gc-compose repository (https://github.com/free5gc/free5gc-compose)
#  and has been adapted to build the local image of UERANSIM (using the local source code).
FROM gcc AS builder

LABEL maintainer="Free5GC <support@free5gc.org>"

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGET_ARCH=x86_64 
# TARGET_ARCH support : x86_64, aarch64(arm64)

# Make sure to have the UERANSIM repository cloned in the free5gc/ directory of this repository
COPY ./UERANSIM/ ./UERANSIM/

# Install dependencies
RUN apt-get update \
    && apt-get install libsctp-dev lksctp-tools iproute2 -y \
    && wget https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-linux-${TARGET_ARCH}.sh -O cmake_installer.sh \
    && chmod +x cmake_installer.sh \
    # Prevent cmake_installer.sh from overwriting the bin/ directory
    && mkdir cmake-files \
    && ./cmake_installer.sh --skip-license --prefix=cmake-files \
    && cp cmake-files/bin/* /bin/ \
    && cp -r cmake-files/share/cmake-3.22/ /usr/share/ \
    # Use the local UERANSIM code
    # && git clone -b master -j `nproc` https://github.com/aligungr/UERANSIM \
    && cd ./UERANSIM \
    && make

FROM ubuntu

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies + ping
RUN apt-get update \
    && apt-get install libsctp-dev lksctp-tools iproute2 iputils-ping procps psmisc -y \
    && apt-get clean

WORKDIR /ueransim

RUN mkdir -p config/ binder/

COPY --from=builder /UERANSIM/build/nr-gnb .
COPY --from=builder /UERANSIM/build/nr-ue .
COPY --from=builder /UERANSIM/build/nr-cli .
COPY --from=builder /UERANSIM/build/nr-binder binder/
COPY --from=builder /UERANSIM/build/libdevbnd.so binder/

VOLUME [ "/ueransim/config" ]
