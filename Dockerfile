# The Radiant Blockchain Developers
# The purpose of this image is to be able to host ElectrumX for radiantd (RXD)
# Build with: `docker build -t electrumx .`
# Public images at: https://hub.docker.com/repository/docker/radiantblockchain

FROM ubuntu:22.04

LABEL maintainer="radiantblockchain@protonmail.com"
LABEL version="1.2.0"
LABEL description="Docker image for electrumx radiantd node"

ARG DEBIAN_FRONTEND=nointeractive
RUN apt update
RUN apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs

# Create root folder for electrumx
RUN mkdir /app

# Copy relevant files and folders
COPY setup.py /app
COPY requirements.txt /app
COPY electrumx/ /app/electrumx
COPY electrumx_server /app
COPY electrumx_rpc /app
COPY electrumx_compact_history /app

ENV PACKAGES="\
  build-essential \
  libcurl4-openssl-dev \
  software-properties-common \
  ubuntu-drivers-common \
  pkg-config \
  libtool \
  openssh-server \
  git \
  clinfo \
  autoconf \
  automake \
  vim \
  wget \
  cmake \
  python3 \
  python3-pip \
  python3-dev \
  libleveldb-dev \
  libsnappy-dev \
  liblz4-dev \
  libbz2-dev \
  zlib1g-dev \
  librocksdb-dev"

# Note can remove the opencl and ocl packages above when not building on a system for GPU/mining
# Included only for reference purposes if this container would be used for mining as well.
RUN apt update && apt install --no-install-recommends -y $PACKAGES  && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean

# Create directory for DB
RUN mkdir /app/electrumxdb

WORKDIR /app

# required for python rocksdb
RUN python3 -m pip install Cython==0.29.37
# install electrumx
RUN python3 setup.py install

# Create SSL
WORKDIR /app/electrumxdb
RUN openssl genrsa -out server.key 2048
RUN openssl req -new -key server.key -out server.csr -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=radiantblockchain.org"
RUN openssl x509 -req -days 1825 -in server.csr -signkey server.key -out server.crt

# expose ports for services
EXPOSE 50010 50020 8000

WORKDIR /app

ENTRYPOINT ["electrumx_server"]
