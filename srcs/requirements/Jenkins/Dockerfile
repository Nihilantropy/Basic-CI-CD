# Use the official Jenkins LTS image as base
FROM jenkins/jenkins:lts

# Switch to root to install dependencies
USER root

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    sudo

# Create a Jenkins user with sudo privileges
RUN echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch back to Jenkins user
USER jenkins

# Set up initial plugins and configuration (optional)
COPY /conf/plugins.txt /usr/share/jenkins/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/plugins.txt

# Expose necessary ports
EXPOSE 8080 50000

# Define default startup command
CMD ["jenkins.sh"]
