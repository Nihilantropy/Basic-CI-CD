#!/bin/sh
set -e

# Generate the config file from the template
echo "Generating Prometheus configuration..."
sed -e "s/JENKINS_USER_PLACEHOLDER/${JENKINS_USER:-admin}/g" \
    -e "s/JENKINS_PASS_PLACEHOLDER/${JENKINS_PASS:-admin}/g" \
    /etc/prometheus/prometheus.yml.template > /etc/prometheus/prometheus.yml

# Ensure correct permissions
chown -R nobody:nobody /etc/prometheus/prometheus.yml

exec /bin/prometheus --config.file=/etc/prometheus/prometheus.yml "$@"