FROM jenkins/jenkins:2.492.1-jdk17

USER root

# Install Docker CLI
RUN apt-get update && apt-get install -y lsb-release

RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg

RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

RUN apt-get update && apt-get install -y docker-ce-cli

# Create directory for plugins list
RUN mkdir -p /usr/share/jenkins/ref/conf
# Copy plugins.txt to appropriate directory
COPY conf/plugins.txt /usr/share/jenkins/ref/conf/plugins.txt

# Create init scripts directory
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d/
COPY init_scripts/*.groovy /usr/share/jenkins/ref/init.groovy.d/


USER jenkins

# Install plugins from plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/conf/plugins.txt