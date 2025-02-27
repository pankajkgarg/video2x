# Name: Video2X Dockerfile
# Creator: K4YT3X
# Date Created: February 3, 2022
# Last Modified: August 28, 2022

# stage 1: build the python components into wheels
FROM docker.io/nvidia/vulkan:1.3-470 AS builder
ENV DEBIAN_FRONTEND=noninteractive

COPY . /video2x
WORKDIR /video2x
RUN gpg --keyserver=keyserver.ubuntu.com --receive-keys A4B469963BF863CC \
    && gpg --export A4B469963BF863CC > /etc/apt/trusted.gpg.d/cuda.gpg
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.9 python3-pip python3-opencv python3-pil \
        python3.9-dev libvulkan-dev glslang-dev glslang-tools \
        build-essential swig \
    && python3.9 -m pip wheel -w /wheels wheel pdm-pep517 .

# stage 2: install wheels into the final image
FROM docker.io/nvidia/vulkan:1.3-470
LABEL maintainer="K4YT3X <i@k4yt3x.com>" \
      org.opencontainers.image.source="https://github.com/k4yt3x/video2x" \
      org.opencontainers.image.description="A lossless video/GIF/image upscaler"
ENV DEBIAN_FRONTEND=noninteractive
ENV VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json\
:/usr/share/vulkan/icd.d/radeon_icd.x86_64.json\
:/usr/share/vulkan/icd.d/intel_icd.x86_64.json

COPY --from=builder /var/lib/apt/lists* /var/lib/apt/lists/
COPY --from=builder /wheels /wheels
COPY . /video2x
WORKDIR /video2x
RUN apt-get install -y --no-install-recommends \
        python3-pip python3.9-dev \
        python3-opencv python3-pil \
        mesa-vulkan-drivers cuda-drivers ffmpeg \
    && python3.9 -m pip install --no-cache-dir --no-index -f /wheels . \
    && apt-get clean \
    && rm -rf /wheels /video2x /var/lib/apt/lists/*

WORKDIR /host
ENTRYPOINT ["/usr/bin/python3.9", "-m", "video2x"]
