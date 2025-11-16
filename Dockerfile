# syntax=docker/dockerfile:1

# ============================================================================
# Build Arguments
# ============================================================================
ARG UBUNTU_CODENAME=noble

# ============================================================================
# Base Image
# ============================================================================
FROM ghcr.io/linuxserver/baseimage-ubuntu:${UBUNTU_CODENAME} AS base

# Re-declare ARGs needed after FROM
ARG BUILD_DATE
ARG VERSION
ARG OPENSSH_RELEASE
ARG UBUNTU_CODENAME

# ============================================================================
# Metadata
# ============================================================================
LABEL original_repo="https://github.com/linuxserver/docker-openssh-server" \
      current_repo="https://github.com/kapong/docker-openssh-server" \
      maintainer="Phongphan Phienphanich"

# ============================================================================
# System Packages and Configuration
# ============================================================================
RUN echo "**** Installing system dependencies ****" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        logrotate \
        nano \
        netcat-openbsd \
        sudo \
    && echo "**** Installing OpenSSH server ****" \
    && apt-get install -y --no-install-recommends \
        openssh-client \
        openssh-server \
        openssh-sftp-server \
    && echo "**** Configuring OpenSSH ****" \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config \
    && mkdir -p /run/sshd \
    && echo "**** Creating build version file ****" \
    && printf "Linuxserver.io version: %s\nBuild-date: %s\n" "${VERSION}" "${BUILD_DATE}" > /build_version \
    && echo "**** Cleanup ****" \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

# ============================================================================
# Add local configuration files
# ============================================================================
COPY /root /

# ============================================================================
# Configuration
# ============================================================================
# Expose SSH port
EXPOSE 2222

# Configure volumes
VOLUME ["/config", "/workspace"]

# Set up workspace directory
WORKDIR /workspace

FROM base

ARG UBUNTU_CODENAME
ARG PYVERSION=3.13
ARG DEADSNAKES_GPG_KEY=F23C5A6CF475977595C89F51BA6932366A755776

# ============================================================================
# Copy External Binaries
# ============================================================================
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# ============================================================================
# System Packages and Configuration
# ============================================================================
RUN echo "**** Installing system dependencies ****" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        git \
    && echo "**** Adding deadsnakes PPA for Python ${PYVERSION} ****" \
    && gpg --keyserver keyserver.ubuntu.com --recv-keys "${DEADSNAKES_GPG_KEY}" \
    && gpg --export "${DEADSNAKES_GPG_KEY}" | tee /etc/apt/trusted.gpg.d/deadsnakes.gpg > /dev/null \
    && echo "deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/deadsnakes.list \
    && echo "**** Installing Python ${PYVERSION} ****" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        "python${PYVERSION}" \
        "python${PYVERSION}-venv" \
    && echo "**** Setting Python ${PYVERSION} as default ****" \
    && update-alternatives --install /usr/bin/python3 python3 "/usr/bin/python${PYVERSION}" 1 \
    && update-alternatives --set python3 "/usr/bin/python${PYVERSION}" \
    && echo "**** Cleanup ****" \
    && apt-get remove -y gnupg \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf \
        /root/.gnupg \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

# Environment variables
ENV BASH=/usr/bin/bash \
    UV_CACHE_DIR=/cache/uv \
    PYTHONUNBUFFERED=1