# Jenkins Monitoring Integration Documentation

This document explains how we've integrated Jenkins with our monitoring stack (Prometheus and Grafana) to track pipeline performance metrics and system health. This covers the implementation of Phase 4.2 from our project roadmap, "Metrics Collection Validation."

## Table of Contents

1. [Overview](#overview)
2. [Jenkins Prometheus Plugin](#jenkins-prometheus-plugin)
3. [Prometheus Configuration](#prometheus-configuration)
4. [Metrics Collection Validation](#metrics-collection-validation)
5. [Available Jenkins Metrics](#available-jenkins-metrics)
6. [Grafana Dashboard](#grafana-dashboard)

## Overview

Our monitoring integration enables real-time tracking of Jenkins pipeline performance and health metrics. The architecture follows this pattern:

1. Jenkins exposes metrics via the Prometheus plugin at `/prometheus/` endpoint
2. Prometheus scrapes these metrics at regular intervals (15s)
3. Pipeline-specific metrics are pushed to Prometheus Pushgateway for persistence
4. Grafana visualizes the metrics through customized dashboards

This setup provides insights into build performance, pipeline health, and system utilization.

## Jenkins Prometheus Plugin

### Installation

The Prometheus plugin and related metrics plugins are installed as part of our Jenkins Docker image:

```
# From srcs/requirements/Jenkins/conf/plugins.txt
prometheus:latest
metrics:latest
metrics-diskusage:latest
build-metrics:latest
```

### Configuration

We configured the Prometheus plugin via the Jenkins initialization script:

```groovy
// srcs/requirements/Jenkins/init_scripts/prometheus-config.groovy
prometheusConfiguration.setPath("prometheus")
prometheusConfiguration.setDefaultNamespace("default")
prometheusConfiguration.setCollectingMetricsPeriodInSeconds(5)
prometheusConfiguration.setProcessingDisabledBuilds(false)
prometheusConfiguration.setPercentiles([50.0d, 95.0d, 99.0d])
prometheusConfiguration.setUseAuthenticatedEndpoint(true)
prometheusConfiguration.setGarbageCollectionMetrics(true)
```

This configuration:
- Sets the metrics endpoint to `/prometheus/`
- Collects metrics every 5 seconds
- Includes metrics from disabled builds
- Calculates 50th, 95th, and 99th percentiles
- Requires authentication for the metrics endpoint
- Includes JVM garbage collection metrics

### Pipeline Integration

Our `Jenkinsfile` includes custom functions in `cicdUtils.groovy` that emit Prometheus-format metrics:

```groovy
// Helper function to output metric in Prometheus format
def prometheusMetric(String name, String type, def value, Map<String,String> labels = [:]) {
    // ...metric formatting code...
    echo "PROMETHEUS_METRIC ${name}{${labelStr}} ${value.toString()}"
}
```

These metrics track pipeline execution time, stage durations, and build outcomes.

## Prometheus Configuration

Prometheus is configured to scrape metrics from Jenkins:

```yaml
# From srcs/requirements/Prometheus/conf/prometheus.yml.template
scrape_configs:
  - job_name: 'jenkins'
    metrics_path: '/prometheus/'
    basic_auth:
      username: "JENKINS_USER_PLACEHOLDER"
      password: "JENKINS_PASS_PLACEHOLDER"
    static_configs:
      - targets: ['jenkins:8080']
```

The configuration includes:
- Job name for identification
- Correct metrics path matching the Jenkins configuration
- Basic authentication credentials
- Target Jenkins server URL

### Pushgateway Integration

For long-term persistence of build metrics (beyond job completion), we push metrics to a Prometheus Pushgateway. This ensures pipeline metrics remain available even after builds finish.

The metrics are pushed from the pipeline with labels that identify the specific build, allowing for historical analysis.

## Metrics Collection Validation

To verify that metrics are being collected correctly:

1. **Check Jenkins Prometheus endpoint**:
   ```bash
   curl -u admin:password http://localhost:8081/prometheus/
   ```
   You should see Prometheus-formatted metrics data.

2. **Verify Prometheus is scraping**:
   - Open Prometheus UI at http://localhost:9090
   - Go to Status > Targets
   - Confirm the jenkins target is "UP"

3. **Validate metrics in Prometheus**:
   - In Prometheus UI, try these queries:
     - `jenkins_executor_count_value`
     - `jenkins_plugins_active`
     - `jenkins_job_count_value`

4. **Check custom pipeline metrics**:
   - Run a pipeline job
   - Query `jenkins_pipeline_duration_milliseconds` in Prometheus
   - Verify the metric exists with the correct job label

## Available Jenkins Metrics

The Jenkins Prometheus plugin exposes many metrics, including:

### System Metrics
- `jenkins_executor_count_value`: Number of executors
- `jenkins_plugins_active`: Count of active plugins
- `jenkins_node_count_value`: Number of Jenkins nodes
- `jenkins_node_online_value`: Status of nodes (1=online, 0=offline)

### Build Metrics
- `jenkins_builds_failed_total`: Count of failed builds
- `jenkins_builds_successful_total`: Count of successful builds
- `jenkins_builds_duration_seconds`: Build duration
- `jenkins_job_build_duration_seconds`: Job-specific build duration
- `jenkins_job_last_successful_build_duration_seconds`: Duration of last successful build

### Queue Metrics
- `jenkins_queue_size_value`: Current build queue size
- `jenkins_queue_buildable_value`: Number of buildable items

### Pipeline Metrics (Custom)
- `jenkins_pipeline_started_total`: Counter of started pipelines
- `jenkins_pipeline_completed_total`: Counter of completed pipelines
- `jenkins_pipeline_duration_milliseconds`: Duration of pipelines
- `jenkins_pipeline_stage_duration_milliseconds`: Duration of pipeline stages

## Grafana Dashboard

We've configured Grafana to visualize Jenkins metrics:

1. **Data Source Configuration**:
   - Prometheus is configured as a data source in Grafana
   - The datasource is provisioned automatically

2. **Jenkins System Dashboard**:
   - Shows overall Jenkins health metrics
   - Includes executor utilization, build queue, and node status
   - Provides system resource usage (CPU, memory)

3. **Pipeline Performance Dashboard**:
   - Displays build duration trends
   - Shows success/failure rates
   - Includes stage performance metrics
   - Highlights bottlenecks in CI/CD pipeline

To access these dashboards:
1. Open Grafana at http://localhost:3000
2. Log in with default credentials (admin/admin)
3. Navigate to "Dashboards" and select "Jenkins Overview" or "Pipeline Performance"

---

By following this documentation, you can verify that Jenkins metrics are being properly collected, understand the available metrics, and access the Grafana dashboards for visualization.