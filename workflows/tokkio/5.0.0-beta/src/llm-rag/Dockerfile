# Use an official Python runtime as a parent image
FROM nvcr.io/nvidia/base/ubuntu:20.04_x64_2022-09-23 AS build
ENV DEBIAN_FRONTEND noninteractive

RUN apt update && \
    apt-get install -y software-properties-common curl && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt update && \
    apt-get install -y python3.12 && \
    apt install -y git && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    rm -rf /var/lib/apt/lists/* 

RUN curl https://bootstrap.pypa.io/get-pip.py | python3 - "pip==24.3.1" "setuptools==65.5.1" && \
    rm -rf get-pip.py
RUN pip install setuptools==70.0.0
# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN apt update && apt install -y libgl1-mesa-glx ffmpeg
# RUN apt install gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gobject-introspection libgirepository1.0-dev libgstreamer1.0-dev gstreamer1.0-plugins-base ffmpeg
RUN pip install uv
WORKDIR /app
ADD ./third_party_oss_license.txt ./third_party_oss_license.txt
ADD ./pyproject.toml ./pyproject.toml
ADD ./uv.lock ./uv.lock
RUN --mount=type=cache,target=/root/.cache/uv \
    uv venv && uv sync --frozen --no-dev
ADD ./src ./src
ADD ./entrypoint.sh ./entrypoint.sh
ENV PATH="/app/.venv/bin:$PATH"
CMD ["/bin/bash", "entrypoint.sh"]
