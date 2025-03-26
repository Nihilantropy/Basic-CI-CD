FROM prom/prometheus:v3.2.1

# Copy the template file
COPY ./conf/prometheus.yml.template /etc/prometheus/prometheus.yml.template

# Copy entrypoint script
COPY ./tools/entrypoint.sh /usr/bin/entrypoint.sh

# Set the entrypoint to our script
ENTRYPOINT ["/usr/bin/entrypoint.sh"]