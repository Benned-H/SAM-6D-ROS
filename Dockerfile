# Docker configuration to replace SAM-6D's conda-based setup

# Allow overriding default CUDA version and flavor
# Reference: https://hub.docker.com/r/nvidia/cuda
ARG CUDA_VERSION=12.4.1

# We need devel to access nvcc. See https://github.com/NVIDIA/nvidia-docker/issues/1160
ARG CUDA_FLAVOR=devel

# Stage 1: Install ROS 1 Noetic Desktop (not full) onto the base image
FROM nvidia/cuda:${CUDA_VERSION}-${CUDA_FLAVOR}-ubuntu20.04 AS noetic-desktop
ENV ROS_DISTRO=noetic

# Ensure that any failure in a pipe (|) causes the stage to fail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Stage 1: Install ROS Noetic, using the standard instructions (without sudo)
# Reference: https://wiki.ros.org/noetic/Installation/Ubuntu
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends lsb-release curl && \
    sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > \
        /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | \
    apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-noetic-desktop \
        python3-rosdep \
        python3-rosinstall \
        python3-rosinstall-generator \
        python3-wstool \
        build-essential \
        python3-pip \
        # Provide the `catkin build` command
        # Reference: https://catkin-tools.readthedocs.io/en/latest/installing.html
        python3-catkin-tools

RUN rosdep init && \
    rosdep update && \
    echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

# Stage 2: Install all dependencies for SAM-6D alongside ROS 1 Noetic
FROM noetic-desktop AS sam-6d-ros

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ninja-build wget

# We cannot stick with the pinned versions they provide, unless we want to
#    downgrade all of our machine's CUDA to 11.something... is that possible?
RUN pip install --no-cache-dir --upgrade \
    # Specify version-constrained dependencies first
    numpy>=1.23.0 pillow>=9.0.1 matplotlib>=3.4 psutil>=5.6.0 PyYAML>=5.4 \
    python-dateutil>=2.8.2 \
    torch torchvision fvcore torchmetrics blenderproc opencv-python \
    omegaconf ruamel.yaml hydra-colorlog hydra-core gdown pandas imageio pyrender \
    pytorch-lightning pycocotools distinctipy \
    git+https://github.com/facebookresearch/segment-anything.git \
    ultralytics timm gorilla-core trimesh gpustat imgaug einops

# Reference: https://github.com/facebookresearch/xformers#installing-xformers
RUN pip install --no-cache-dir -U xformers --index-url https://download.pytorch.org/whl/cu124

##### Final attempt above: Combine all installs unless not allowed #####

# TODO: Possibly blenderproc>=2.7.0
#      # Was: blenderproc==2.6.1

RUN echo "alias python=python3" >> ~/.bashrc

WORKDIR /docker/sam6d

# Set entrypoint to bash for interactive use
ENTRYPOINT ["/bin/bash"]
