# Use Python 3.9 as the base image
FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    sudo \
    binutils \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Create virtual environment
RUN python -m venv /app/venv

# Make sure pip is up-to-date in the virtual environment
RUN /app/venv/bin/pip install --upgrade pip setuptools wheel

# Copy requirements files
COPY requirements.txt requirements-dev.txt /app/

# Install both production and development dependencies
RUN /app/venv/bin/pip install --no-cache-dir -r /app/requirements.txt -r /app/requirements-dev.txt

# Make sure the venv is usable by anyone
RUN chmod -R 777 /app/venv

# Keep the container running
CMD ["tail", "-f", "/dev/null"]