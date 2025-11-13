FROM ubuntu:22.04

COPY PROJECTS /PROJECTS
RUN apt-get update -yq && \
	apt-get install -yq git ca-certificates curl wget build-essential autoconf automake build-essential ccache cmake cpufrequtils doxygen ethtool g++ git inetutils-tools libboost-all-dev libncurses5 libncurses5-dev libusb-1.0-0 libusb-1.0-0-dev libusb-dev python3-dev python3-mako python3-numpy python3-requests python3-scipy python3-setuptools python3-ruamel.yaml libforms-dev libforms-bin

RUN git clone https://github.com/EttusResearch/uhd.git /src/uhd && \
	cd /src/uhd && \
	git checkout v4.6.0.0 && \
	cd host && \
	mkdir build && \
	cd build && \
	cmake ../ && \
	make -j $(nproc) && \
	make install && \
	ldconfig && \
	uhd_images_downloader

RUN git clone https://gitlab.eurecom.fr/oai/openairinterface5g /src/oai5g && \
	cd /src/oai5g && \
	git checkout 2024.w40 && \
	cd /src/oai5g/cmake_targets && \
	./build_oai -I && \
	./build_oai -w USRP --ninja --nrUE --gNB --build-lib "nrscope" -C

# NOTE: These lines copy the relevant files to the same location as the other Dockerfiles (from our OAI fork)
# This is done so that docker-compose.yml files can use the same commands with this image
WORKDIR /opt/oai-gnb/bin
RUN cp /src/oai5g/cmake_targets/ran_build/build/nr-softmodem .

WORKDIR /opt/oai-gnb/etc
RUN cp /PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf .

WORKDIR /opt/oai-gnb

ENTRYPOINT ["/opt/oai-gnb/bin/nr-softmodem"]
