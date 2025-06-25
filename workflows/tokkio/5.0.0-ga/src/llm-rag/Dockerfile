# Use an official Python runtime as a parent image
FROM nvcr.io/nvidia/base/ubuntu:jammy-20250415.1

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/app/.cache/huggingface \
    UV_CACHE_DIR=/app/.cache/uv

# Install system dependencies and Python in a single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        curl \
        libgl1-mesa-glx \
        git \
        gnupg && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3.12 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    # Install pip and setuptools
    curl https://bootstrap.pypa.io/get-pip.py | python3 - "pip==24.3.1" "setuptools==78.1.1" && \
    rm -rf get-pip.py && \
    pip install setuptools==78.1.1 uv && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create app directory and set permissions
WORKDIR /app
RUN chown -R 1000:1000 /app

USER 1000:1000

# Copy dependency files
COPY --chown=1000:1000 LICENSE third_party_oss_license.txt pyproject.toml uv.lock ./

# Install Python dependencies
RUN uv venv && uv sync --frozen --no-dev --no-cache

# Copy application code
COPY --chown=1000:1000 src/ ./src/
COPY --chown=1000:1000 entrypoint.sh ./

ENV PATH="/app/.venv/bin:$PATH"

CMD ["/bin/bash", "entrypoint.sh"]
