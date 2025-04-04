# Use the official Python image as the base image
FROM python:3.9-slim

# Install necessary packages and remove cache to reduce image size
RUN apt-get update && \
    apt-get install -y sudo binutils && \
    rm -rf /var/lib/apt/lists/*

RUN 
# Set the working directory
WORKDIR /usr/src/app
