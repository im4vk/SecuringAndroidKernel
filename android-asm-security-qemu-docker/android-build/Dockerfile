FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Android build dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    python3 \
    python-is-python3 \
    openjdk-11-jdk \
    gcc \
    g++ \
    make \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    cpio \
    rsync \
    zip \
    unzip \
    device-tree-compiler \
    && rm -rf /var/lib/apt/lists/*

# Install repo tool for Android
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo && \
    chmod +x /usr/local/bin/repo

WORKDIR /android

# Create build structure
RUN mkdir -p \
    /android/kernel \
    /android/out \
    /android/modules \
    /android/system

# Download Android kernel source (common kernel)
RUN cd /android/kernel && \
    git clone --depth=1 --branch android-mainline https://android.googlesource.com/kernel/common.git kernel-src

# Copy build scripts
COPY build-kernel.sh /android/
COPY build-system.sh /android/
COPY Makefile /android/

RUN chmod +x /android/*.sh

CMD ["/bin/bash"]

