# Docker configuration to replace SAM-6D's conda-based setup

# Allow overriding default versions of CUDA and Ubuntu
ARG CUDA_VERSION=12.6.2
ARG UBUNTU_VERSION=24.04

# Construct the base image dynamically based on build arguments
FROM nvidia/cuda:${CUDA_VERSION}-cudnn-runtime-ubuntu${UBUNTU_VERSION} AS sam2

# Install dependencies of the Segment Anything Model 2 (SAM 2) and its notebook demos
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3-pip \
    # Reference: https://stackoverflow.com/a/63377623
    ffmpeg libsm6 libxext6 && \
    pip3 install --break-system-packages torch torchvision torchaudio \
    "matplotlib>=3.9.1" \
    "jupyter>=1.0.0" \
    "opencv-python>=4.7.0" \
    "eva-decord>=0.6.1" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*



FROM python:3.9.6 AS sam6d

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        git \
        curl && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
        torch==2.0.0 \
        torchvision==0.15.1 \
        fvcore \
        xformers==0.0.18 \
        torchmetrics==0.10.3 \
        blenderproc==2.6.1

# Break up `pip install` purely to save progress
RUN pip install --no-cache-dir \
        opencv-python \
        omegaconf \
        ruamel.yaml \
        hydra-colorlog \
        hydra-core \
        gdown \
        pandas \
        imageio \
        pyrender

RUN pip install --no-cache-dir \
        pytorch-lightning==1.8.1 \
        pycocotools \
        distinctipy \
        'git+https://github.com/facebookresearch/segment-anything.git' \
        ultralytics==8.0.135 \
        timm \
        gorilla-core==0.2.7.8 \
        trimesh==4.0.8 \
        gpustat==1.0.0 \
        imgaug \
        einops

WORKDIR /docker/sam6d

# Set entrypoint to bash for interactive use
ENTRYPOINT ["/bin/bash"]
