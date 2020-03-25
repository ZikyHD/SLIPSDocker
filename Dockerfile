FROM debian:buster-slim AS build

# Copyright (c) 2019 Battelle Energy Alliance, LLC.  All rights reserved.

ENV DEBIAN_FRONTEND noninteractive

ENV SRC_BASE_DIR "/usr/local/src"
ENV ZEEK_VERSION "3.1.1"
ENV ZEEK_DIR "/opt/zeek"
ENV ZEEK_SRC_DIR "${SRC_BASE_DIR}/zeek-${ZEEK_VERSION}"
ENV ZEEK_PATCH_DIR "${SRC_BASE_DIR}/zeek-patches"
ENV PATH="${ZEEK_DIR}/bin:${PATH}"

ADD https://old.zeek.org/downloads/zeek-$ZEEK_VERSION.tar.gz $SRC_BASE_DIR/zeek.tar.gz
ADD zeek_install_plugins.sh /usr/local/bin/

RUN sed -i "s/buster main/buster main contrib non-free/g" /etc/apt/sources.list && \
    apt-get -q update && \
    apt-get install -q -y --no-install-recommends \
        binutils \
        bison \
        cmake \
        curl \
        file \
        flex \
        g++ \
        gcc \
        git \
        libkrb5-dev \
        libpcap0.8-dev \
        libssl-dev \
        make \
        ninja-build \
        patch \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        swig \
        zlib1g-dev && \
  pip3 install --no-cache-dir zkg && \
  cd "${SRC_BASE_DIR}" && \
    tar -xvf "zeek.tar.gz" && \
    cd "./zeek-${ZEEK_VERSION}" && \
    bash -c "for i in ${ZEEK_PATCH_DIR}/* ; do patch -p 1 -r - --no-backup-if-mismatch < \$i || true; done" && \
    ./configure --prefix="${ZEEK_DIR}" --generator=Ninja && \
    cd build && \
    ninja && \
    ninja install && \
    bash -c "file ${ZEEK_DIR}/{lib,bin}/* ${ZEEK_DIR}/lib/zeek/plugins/packages/*/lib/* ${ZEEK_DIR}/lib/zeek/plugins/*/lib/* | grep 'ELF 64-bit' | sed 's/:.*//' | xargs -l -r strip -v --strip-unneeded" && \
    zkg autoconfig && \
    bash /usr/local/bin/zeek_install_plugins.sh && \
    bash -c "find ${ZEEK_DIR}/lib -type d -name CMakeFiles -exec rm -rf '{}' \; 2>/dev/null || true"

FROM debian:buster-slim

LABEL maintainer="cedric.hien@gmail.com"
LABEL org.opencontainers.image.authors='cedric.hien@gmail.com'
LABEL org.opencontainers.image.url='https://github.com/ZikyHD/SLIPDocker'
LABEL org.opencontainers.image.documentation='https://github.com/ZikyHD/SLIPSDocker/blob/master/README.md'
LABEL org.opencontainers.image.source='https://github.com/ZikyHD/SLIPDocker'
LABEL org.opencontainers.image.vendor='Idaho National Laboratory'
LABEL org.opencontainers.image.title='cedric/SLIPS'
LABEL org.opencontainers.image.description='Docker container with SLIPS'

ENV DEBIAN_FRONTEND noninteractive

ENV ZEEK_DIR "/opt/zeek"

COPY --from=build $ZEEK_DIR $ZEEK_DIR

RUN sed -i "s/buster main/buster main contrib non-free/" /etc/apt/sources.list && \
    apt-get -q update && \
    apt-get install -q -y --no-install-recommends \
      curl \
      file \
      libkrb5-3 \
      libpcap0.8 \
      libssl1.0 \
      libzmq5 \
      procps \
      psmisc \
      python \
      python3 \
      python3-pip \
      python3-setuptools \
      python3-wheel \
      git \
      software-properties-common \
      redis \
      vim-tiny && \
    pip3 install --no-cache-dir redis watchdog maxminddb sklearn progress_bar pandas urllib3 certifi && \
    apt-get -q -y --purge remove gcc gcc-8 cpp cpp-8 libssl-dev && \
      apt-get -q -y autoremove && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install --no-install-recommends -y nodejs
RUN npm i npm@latest -g && \
    npm i blessed blessed-contrib && \
    npm i redis && \
    npm i async && \
    npm i ansi-colors && \
    npm i clipboardy && \
    npm i fs

WORKDIR /opt
RUN git clone https://github.com/stratosphereips/StratosphereLinuxIPS.git

RUN ln -s /opt/zeek/bin/zeek /usr/local/bin/bro

WORKDIR /opt/StratosphereLinuxIPS

ENTRYPOINT redis-server --daemonize yes && /bin/bash
