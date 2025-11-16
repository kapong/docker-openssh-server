# syntax=docker/dockerfile:1

FROM ghcr.io/astral-sh/uv:latest AS uv

FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

ARG BUILD_DATE
ARG VERSION
ARG OPENSSH_RELEASE
ARG PYVERSION=3.13

LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# Copy uv from official image
COPY --from=uv /uv /usr/local/bin/uv

RUN \
  echo "**** install Python ${PYVERSION} ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg && \
  # Add deadsnakes PPA manually (without software-properties-common)
  gpg --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 && \
  gpg --export F23C5A6CF475977595C89F51BA6932366A755776 | tee /etc/apt/trusted.gpg.d/deadsnakes.gpg > /dev/null && \
  echo "deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu noble main" > /etc/apt/sources.list.d/deadsnakes.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    python${PYVERSION} \
    python${PYVERSION}-venv && \
  # Set Python ${PYVERSION} as default python3
  update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYVERSION} 1 && \
  update-alternatives --set python3 /usr/bin/python${PYVERSION} && \
  echo "**** install runtime packages ****" && \
  apt-get install -y --no-install-recommends \
    logrotate \
    nano \
    netcat-openbsd \
    sudo \
    git && \
  echo "**** install openssh-server ****" && \
  apt-get install -y --no-install-recommends \
    openssh-client \
    openssh-server \
    openssh-sftp-server && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** setup openssh environment ****" && \
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
  mkdir -p /run/sshd && \
  apt-get clean && \
  rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# add local files
COPY /root /

EXPOSE 2222

VOLUME /config

RUN mkdir -p /workspace
WORKDIR /workspace

ENV HOME=/workspace
ENV BASH=/bin/bash
