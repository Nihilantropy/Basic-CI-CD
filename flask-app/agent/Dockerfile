# Use Python 3.9 as the base image
FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    sudo \
    binutils \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    pytest \
    pyinstaller \
    ruff \
    bandit \
    flask \
    flask-limiter \
    requests

# Set the working directory
WORKDIR /app

# Keep the container running
CMD ["tail", "-f", "/dev/null"]