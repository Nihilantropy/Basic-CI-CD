FROM prom/prometheus:v3.2.1

# Copy the template file
COPY ./conf/prometheus.yml.template /etc/prometheus/prometheus.yml.template

RUN mkdir -p /etc/prometheus/alert_rules

COPY ./conf/alert_rules/* /etc/prometheus/alert_rules/

# Copy entrypoint script
COPY ./tools/entrypoint.sh /usr/bin/entrypoint.sh

# Set the entrypoint to our script
ENTRYPOINT ["/usr/bin/entrypoint.sh"]