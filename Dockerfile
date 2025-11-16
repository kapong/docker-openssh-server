# syntax=docker/dockerfile:1

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OPENSSH_RELEASE
ARG PYVERSION=3.13

FROM ghcr.io/astral-sh/uv:python${PYVERSION}-trixie AS uv

FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# Copy uv from official image
COPY --from=uv /uv /usr/local/bin/uv

RUN \
  echo "**** install runtime packages ****" && \
  # Add deadsnakes PPA for newer Python versions
  add-apt-repository ppa:deadsnakes/ppa && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    logrotate \
    nano \
    netcat-openbsd \
    sudo \
    curl \
    ca-certificates && \
  echo "**** install Python ${PYVERSION} ****" && \
  if apt-cache show python${PYVERSION} >/dev/null 2>&1; then \
    apt-get install -y --no-install-recommends \
      python${PYVERSION} \
      python${PYVERSION}-venv || \
    apt-get install -y --no-install-recommends \
      python${PYVERSION}; \
  else \
    echo "Python ${PYVERSION} not available, trying python3"; \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-venv; \
  fi && \
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
