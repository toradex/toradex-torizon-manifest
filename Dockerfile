FROM ubuntu:16.04
MAINTAINER Andy Doan <andy.doan@linaro.org>

# bitbake requires a utf8 filesystem encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	  android-tools-fsutils chrpath cpio diffstat file gawk g++ iproute2 iputils-ping less libmagickwand-dev libmath-prime-util-perl libsdl1.2-dev libssl-dev locales openssh-client python-requests python3 repo texinfo vim-tiny wget whiptail \
	&& apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& locale-gen en_US.UTF-8

# Create the user which will run the SDK binaries.
RUN useradd -c builder \
		-d /home/builder \
		-m \
		-s /bin/bash \
		builder
