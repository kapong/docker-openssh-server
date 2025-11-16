# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-debian:bullseye

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OPENSSH_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

RUN \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    logrotate \
    nano \
    netcat-openbsd \
    sudo \
    curl \
    ca-certificates && \
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
