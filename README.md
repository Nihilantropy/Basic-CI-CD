# Basic CI/CD Pipeline Project

![CI/CD Pipeline](https://img.shields.io/badge/CI%2FCD-Pipeline-blue)
![Jenkins](https://img.shields.io/badge/Jenkins-v2.492.1-red)
![GitLab](https://img.shields.io/badge/GitLab-CE-orange)
![Nexus](https://img.shields.io/badge/Nexus-3-green)
![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-blueviolet)
![Prometheus](https://img.shields.io/badge/Prometheus-v3.2.1-red)
![Grafana](https://img.shields.io/badge/Grafana-11.5.2-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

A robust end-to-end CI/CD (Continuous Integration/Continuous Delivery) pipeline implementation demonstrating modern DevOps practices. This project integrates industry-standard tools to automate building, testing, packaging, deploying, and monitoring a Python Flask application with advanced features.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Components](#components)
  - [Base Environment](#base-environment)
  - [Python Application](#python-application)
  - [Jenkins Pipeline](#jenkins-pipeline)
  - [Helm Chart](#helm-chart)
  - [Kubernetes Setup](#kubernetes-setup)
  - [Monitoring Stack](#monitoring-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
- [Usage](#usage)
  - [Accessing Monitoring Dashboards](#accessing-monitoring-dashboards)
  - [Triggering the Pipeline](#triggering-the-pipeline)
  - [Monitoring the Pipeline](#monitoring-the-pipeline)
  - [Deploying the Application](#deploying-the-application)
  - [Testing Metrics and Alerts](#testing-metrics-and-alerts)
- [Workflow](#workflow)
- [Directory Structure](#directory-structure)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project showcases a complete CI/CD pipeline with integrated monitoring that automates the software development lifecycle from code commit to production deployment and observability. By leveraging Docker Compose, Jenkins, GitLab, Nexus, Kubernetes, Prometheus, and Grafana, the project provides a scalable, maintainable, and secure solution for continuous delivery and monitoring of a Python Flask application.

The pipeline handles code quality checks, security scans, artifact management, version control, Kubernetes deployment, and comprehensive metrics collection, demonstrating best practices in modern DevOps workflows.

## Architecture

The architecture consists of the following main components:

1. **Development Environment**: Dockerized services for local development
2. **Source Control**: GitLab for version control and code hosting
3. **CI/CD Server**: Jenkins for pipeline automation
4. **Artifact Repository**: Nexus for storing build artifacts
5. **Deployment Target**: Kubernetes (K3s) for container orchestration
6. **Monitoring Stack**: Prometheus and Grafana for metrics collection, visualization, and alerting

The workflow follows a typical CI/CD pattern with monitoring integration:
- Code changes are pushed to GitLab
- Jenkins detects changes and triggers the pipeline
- Tests, code quality, and security checks are performed
- Application is built and packaged as a binary
- Binary is stored in Nexus with version control
- Helm deploys the application to Kubernetes
- Prometheus collects metrics from the application, Jenkins, and containers
- Grafana dashboards visualize performance and health metrics
- Alertmanager handles alert notifications when thresholds are exceeded

## Key Features

- **Complete CI/CD Automation**: End-to-end pipeline from code commit to deployment
- **Containerized Development Environment**: Docker Compose setup for all services
- **Advanced Flask Application**: Features rate limiting, versioning, and metrics exposure
- **Comprehensive Testing**: Automated tests for functionality, security, and metrics
- **Code Quality Enforcement**: Static analysis with Ruff and security scanning with Bandit
- **Artifact Management**: Versioned storage of binaries in Nexus
- **Automated Versioning**: Timestamp-based versioning with Git tags
- **Kubernetes Deployment**: Helm charts for declarative application deployment
- **GitLab Integration**: Merge requests, status updates, and integration triggers
- **Notification System**: Build status notifications via Telegram
- **Metrics Collection**: Prometheus monitoring for application, CI/CD pipeline, and infrastructure
- **Performance Visualization**: Custom Grafana dashboards for real-time monitoring
- **Container Resource Monitoring**: cAdvisor integration for container metrics
- **Alerting**: Configurable alerts for rate limits and system health issues

## Components

### Base Environment

The foundation of the project is a Docker Compose environment that includes:

- **Jenkins**: Automation server running on port `8081`
- **GitLab**: Version control platform accessible at `http://gitlab.local:8080`
- **Nexus**: Artifact repository to store build artifacts on port `8082`
- **Prometheus**: Metrics collection and storage system on port `9090`
- **Grafana**: Metrics visualization dashboard on port `3000`
- **cAdvisor**: Container resource monitoring tool
- **Alertmanager**: Alert handling and notification system on port `9093`
- **Pushgateway**: Short-lived job metrics collector on port `9091`

This containerized setup ensures consistency across environments and simplifies development.

### Python Application

A Flask-based microservice with:

- **Greeting Endpoint (`/`)**: Returns a customizable message with agent name, version, and time
- **Health Check Endpoint (`/health`)**: For monitoring and liveness probes
- **Metrics Endpoint (`/metrics`)**: Exposes Prometheus-formatted metrics for monitoring
- **Global Rate Limiting**: Protection against DoS with 100 requests per minute limit
- **Version Management**: Dynamic version information included in responses
- **Performance Metrics**: Request counts, durations, rate limit statistics, and application info

The application follows a modular architecture with:
- Application factory pattern
- Blueprint-based routing
- Environment-specific configuration
- Comprehensive error handling
- Prometheus client integration for metrics collection

### Jenkins Pipeline

A sophisticated CI/CD pipeline that:

1. **Runs Tests**: Executes pytest test suite for application verification
2. **Performs Code Quality Checks**: Uses Ruff for static analysis
3. **Conducts Security Scanning**: Employs Bandit for security vulnerability detection
4. **Updates Version Information**: Updates version tags in the code and repository
5. **Builds the Application**: Packages the Flask app as a standalone binary using PyInstaller
6. **Archives Executable**: Stores artifacts in Jenkins
7. **Uploads Artifacts**: Stores binaries in Nexus with both `latest` and timestamped versions
8. **Creates Git Tags**: Adds timestamp-based version tags to the repository
9. **Generates Merge Requests**: Creates merge requests to the main branch
10. **Updates GitLab Status**: Provides real-time build status in GitLab UI
11. **Sends Notifications**: Delivers build status via Telegram
12. **Emits Metrics**: Records pipeline execution metrics for Prometheus monitoring
13. **Measures Performance**: Tracks build durations, success rates, and stage times

The pipeline is defined in a Jenkinsfile with modular utility functions and supports configuration via parameters or `jenkins-config.yml`. Pipeline metrics are collected via custom utility functions and exposed to Prometheus for monitoring and visualization.

### Helm Chart

A Kubernetes deployment solution that:

- **Configures Deployments**: Manages replica count and environment variables
- **Handles Service Exposure**: Exposes the application via NodePort
- **Supports Version Selection**: Deploys specific application versions
- **Implements Health Monitoring**: Configures liveness probes
- **Manages Environment Variables**: Passes configuration to the application
- **Downloads from Nexus**: Fetches the appropriate binary version at startup
- **Exposes Metrics**: Ensures metrics endpoints are accessible for Prometheus scraping

The chart is designed for flexibility, allowing customization through `values.yaml`.

### Kubernetes Setup

A lightweight Kubernetes deployment using:

- **K3s**: A certified Kubernetes distribution that's lightweight and easy to install
- **Headless Services**: Connect to external resources like Nexus
- **Custom Endpoints**: Map to host machine services
- **Namespaces**: Organize resources by functionality
- **Prometheus Annotations**: Enable metrics scraping from pods
- **Monitoring Endpoints**: Expose application metrics for collection

### Monitoring Stack

A comprehensive monitoring solution that includes:

- **Prometheus**: Central time-series database for metrics storage and querying
- **Grafana**: Visualization platform with custom dashboards for application and CI/CD metrics
- **cAdvisor**: Container resource monitoring with detailed metrics
- **Alertmanager**: Alert handling and notification system
- **Pushgateway**: Metrics collector for short-lived jobs like pipeline stages

Key monitoring features include:
- Application metrics collection from the Flask `/metrics` endpoint
- Jenkins metrics from Prometheus plugin integration
- Container resource monitoring via cAdvisor
- Custom dashboards for different aspects of the system
- Alerting based on metric thresholds

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Git
- Kubernetes cluster (K3s, Minikube, or Docker Desktop Kubernetes)
- kubectl CLI
- Helm
- Web browser for accessing Grafana dashboards

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Basic-CI-CD.git
   cd Basic-CI-CD
   ```

2. Start the base environment (this will also start Prometheus, Grafana, and other monitoring services):
   ```bash
   make all
   ```

3. Configure GitLab:
   - Access GitLab at http://gitlab.local:8080
   - Set up a user and create a project
   - Configure integrations for Jenkins automation

4. Configure Jenkins:
   - Access Jenkins at http://localhost:8081
   - Install suggested plugins
   - Configure GitLab and Nexus credentials
   - Set up pipeline job pointing to Jenkinsfile

5. Configure Nexus:
   - Access Nexus at http://localhost:8082
   - Create RAW repository for storing artifacts

6. Configure Kubernetes:
   **IMPORTANT!** Change the IP address from the default one to your node's one 
   ```bash
   kubectl create namespace nexus
   kubectl apply -f k3s/service/nexus-headless-service.yaml
   kubectl apply -f k3s/service/nexus-headless-endpoint.yaml
   ```

7. Verify Prometheus and Grafana:
   - Access Prometheus at http://localhost:9090
   - Access Grafana at http://localhost:3000 (default: admin/admin)
   - Verify data sources are configured
   - Check pre-configured dashboards are available

For detailed, step-by-step setup and configuration instructions, please refer to our comprehensive [How to Use Guide](docs/how-to-use.md).

### Configuration

1. Update the IP address in `k3s/service/nexus-headless-endpoint.yaml` to your host machine's IP

2. Configure environment-specific settings in `values.yaml`:
   ```yaml
   appVersion: "latest"
   flaskEnv: "default"
   replicaCount: 2
   agentName: "default Agent"
   nodePort: 30080
   ```

3. Adjust pipeline behavior in `jenkins-config.yml`:
   ```yaml
   runTests: true
   runRuffCheck: true
   runBanditCheck: true
   updateVersion: true
   buildExecutable: true
   # Additional options...
   enableMetrics: true  # Enable Prometheus metrics recording
   ```

4. Configure Prometheus alert thresholds in `srcs/requirements/Prometheus/conf/alert_rules/`:
   ```yaml
   groups:
     - name: flask-app-alerts
       rules:
       - alert: FlaskRateLimitExceeded
         expr: appflask_rate_limit_hits_total >= 200
         for: 1m
         labels:
           severity: warning
         annotations:
           summary: "Flask Application Rate Limit Exceeded"
   ```

## Usage

### Accessing Monitoring Dashboards

1. **Prometheus**:
   - Open http://localhost:9090 in your browser
   - Use the Query interface to explore available metrics
   - Check Targets status at http://localhost:9090/targets to ensure all components are being scraped

2. **Grafana**:
   - Open http://localhost:3000 in your browser
   - Log in with default credentials (admin/admin)
   - Navigate to Dashboards section to access:
     - Flask Application Metrics Dashboard
     - Jenkins Pipeline Performance Dashboard
     - Container Monitoring Dashboard

3. **Testing Metrics Collection**:
   - Use provided test scripts:
     ```bash
     # Test application rate limiting and metrics recording
     bash appflask/test_scripts/comprehensive-rate-test.sh
     
     # Test Prometheus queries
     bash appflask/test_scripts/test_query.sh
     
     # Test alerting functionality
     bash appflask/test_scripts/alert-testing-script.sh
     ```

4. **Available Metrics**:
   - **Flask Application**: Request counts, durations, rate limits, version info
   - **Jenkins Pipeline**: Build counts, durations, stage performance, success rates
   - **Container Resources**: CPU, memory, network usage via cAdvisor
   - **System**: Process and service health metrics

### Triggering the Pipeline

1. Push changes to the GitLab repository:
   ```bash
   git add .
   git commit -m "Update application code"
   git push origin main
   ```

2. Monitor the pipeline in Jenkins at http://localhost:8081

3. View build status in the GitLab UI

### Monitoring the Pipeline

1. **View pipeline progress in Jenkins**:
   - Click on the running build in Jenkins
   - Select `Console Output` to see detailed logs
   - Or use Blue Ocean interface for a visual representation

2. **Check build status in GitLab**:
   - If GitLab integration is set up correctly, you'll see build status in:
     - GitLab commit history
     - GitLab merge requests (if applicable)

3. **Monitor pipeline metrics in Grafana**:
   - Open the Jenkins Pipeline Performance Dashboard in Grafana
   - View real-time metrics for pipeline execution time, stage duration, and success rates

4. **View build metrics in Prometheus**:
   - Query pipeline metrics directly in Prometheus:
     ```
     jenkins_pipeline_duration_milliseconds{job="appflask-pipeline"}
     jenkins_pipeline_stage_duration_milliseconds{job="appflask-pipeline"}
     ```

### Deploying the Application

1. **Deploy using Helm**:
   ```bash
   helm install appflask ./helm/appflask
   ```

2. **Deploy a specific version**:
   ```bash
   helm install appflask ./helm/appflask --set appVersion=20240317123456
   ```

3. **Verify the deployment**:
   ```bash
   kubectl get pods
   kubectl get svc
   ```

4. **Test the application endpoints**:
   ```bash
   curl http://<NODE_IP>:30080/              # Main greeting endpoint
   curl http://<NODE_IP>:30080/health        # Health check
   curl http://<NODE_IP>:30080/metrics       # Prometheus metrics endpoint
   ```
   
5. **Check metrics in Prometheus**:
   ```bash
   # Open in browser
   http://localhost:9090/graph?g0.expr=appflask_http_requests_total
   
   # Or via command line
   curl -s "http://localhost:9090/api/v1/query?query=appflask_http_requests_total" | jq
   ```

### Testing Metrics and Alerts

1. **Generate load to test metrics**:
   ```bash
   # Generate controlled traffic to see rate limiting and metrics
   bash appflask/test_scripts/comprehensive-rate-test.sh
   ```

2. **Test alerts**:
   ```bash
   # Trigger rate limit alerts and verify in Prometheus/Alertmanager
   bash appflask/test_scripts/alert-testing-script.sh
   ```

3. **View alert status**:
   - Open http://localhost:9090/alerts in Prometheus
   - Or check http://localhost:9093 for Alertmanager
   - Verify alert rules in Grafana dashboards

4. **Query custom metrics**:
   ```bash
   # Verify Prometheus queries for custom metrics
   bash appflask/test_scripts/test-prometheus-queries.sh
   ```

For complete instructions on using the pipeline, deploying applications, and monitoring, refer to our [How to Use Guide](docs/how-to-use.md).

## Workflow

The typical workflow in this environment:

1. Developer pushes code changes to GitLab
2. GitLab integration triggers Jenkins pipeline
3. Jenkins runs tests, quality checks, and security scans
4. If checks pass, Jenkins builds the application
5. Binary is uploaded to Nexus with version information
6. Version information is updated in Git repo and tagged
7. Optionally, a merge request is created
8. DevOps deploys application using Helm
9. Helm pulls appropriate binary version from Nexus
10. Application runs in Kubernetes with specified configuration
11. Prometheus scrapes metrics from the deployed application
12. Monitoring dashboards update with new application and pipeline data
13. Alerts trigger if any metrics exceed thresholds
14. Performance is analyzed through Grafana dashboards

## Directory Structure

```
basic-ci-cd/
├── appflask/                     # Flask application source
│   ├── agent/                    # Jenkins agent configuration
│   │   └── Dockerfile            # Agent container definition
│   ├── appflask/                 # Application source code
│   │   ├── app.py                # Application factory
│   │   ├── config.py             # Configuration management
│   │   ├── errors.py             # Error handling
│   │   ├── __init__.py           # Package marker
│   │   ├── limiter.py            # Rate limiting implementation
│   │   ├── metrics.py            # Prometheus metrics implementation
│   │   ├── routes.py             # Flask routes/endpoints
│   │   └── version.py            # Version management
│   ├── hook-appflask.py          # PyInstaller hook
│   ├── Jenkinsfile               # CI/CD pipeline definition
│   ├── jenkinsfile-includes/     # Jenkins pipeline utilities
│   │   └── cicdUtils.groovy      # Utility functions for pipeline
│   ├── main.py                   # Application entry point
│   ├── requirements.txt          # Dependencies
│   ├── requirements-dev.txt      # Development dependencies
│   ├── tests/                    # Test suites
│   │   ├── conftest.py           # Test configuration
│   │   ├── __init__.py           # Package marker
│   │   ├── test_app.py           # App functionality tests
│   │   ├── test_metrics.py       # Metrics implementation tests
│   │   └── test_rate_limit.py    # Rate limiting tests
│   ├── test_scripts/             # Monitoring test scripts
│   │   ├── alert-testing-script.sh     # Tests alert triggers
│   │   ├── comprehensive-rate-test.sh  # Tests rate limits
│   │   ├── test-prometheus-queries.sh  # Tests prometheus queries
│   │   ├── test_query.sh               # Tests metric queries
│   │   └── test_rate_limit.sh          # Tests rate limiting
│   └── version.info              # Application version file
│
├── docs/                         # Documentation files
│   ├── how-to-use.md             # Comprehensive usage guide
│   ├── Infrastracture_architecture.md  # Monitoring architecture
│   ├── monitoring/               # Monitoring documentation
│   │   ├── custom-pipeline-metrics.md  # Pipeline metrics guide
│   │   └── prometheus-conf.md    # Prometheus configuration
│   ├── progresses/               # Project progress tracking
│   ├── requirement-analysis/     # Requirements analysis
│   ├── STANDARD_CODE.md          # Code standards document
│   ├── subjects/                 # Project requirements
│   ├── Technologies/             # Tool-specific documentation
│   ├── technology & strategy.md  # Monitoring strategy
│   └── workflows/                # Workflow documentation
│
├── helm/                         # Kubernetes Helm charts
│   ├── appflask/                 # AppFlask chart
│   │   ├── templates/            # Kubernetes resource templates
│   │   ├── Chart.yaml            # Chart metadata
│   │   └── values.yaml           # Configurable values
│   └── README.md                 # Helm documentation
│
├── k3s/                          # Kubernetes configurations
│   └── service/                  # Service definitions
│       ├── nexus-headless-endpoint.yaml  # Nexus endpoint config
│       └── nexus-headless-service.yaml   # Nexus service config
│
├── srcs/                         # Docker environment files
│   ├── docker-compose.yaml       # Service composition
│   └── requirements/             # Service-specific files
│       ├── Alertmanager/         # Alert manager configuration
│       │   └── alertmanager.yml  # Alert configuration
│       ├── Cadvisor/             # Container monitoring
│       │   ├── Dockerfile
│       │   └── tools/
│       ├── GitLab/               # GitLab configuration
│       ├── Grafana/              # Grafana configuration
│       │   ├── Dockerfile
│       │   └── provisioning/     # Pre-configured dashboards
│       │       ├── dashboards/
│       │       │   ├── json/     # Dashboard definitions
│       │       │   │   ├── appflask-metrics.json
│       │       │   │   ├── cadvisor.json
│       │       │   │   └── jenkins-pipeline-performance.json
│       │       └── datasources/  # Data source configuration
│       ├── Jenkins/              # Jenkins configuration
│       │   ├── conf/
│       │   ├── Dockerfile
│       │   └── init_scripts/     # Jenkins initialization
│       ├── Nexus/                # Nexus configuration
│       ├── Prometheus/           # Prometheus configuration
│       │   ├── conf/
│       │   │   ├── alert_rules/  # Alert definitions
│       │   │   └── prometheus.yml.template
│       │   ├── Dockerfile
│       │   └── tools/
│       └── Scripts/              # Testing scripts
│           └── test_monitoring.sh  # Monitoring test script
│
├── Makefile                      # Build automation
├── README.md                     # This documentation
├── RoadMap.md                    # Project roadmap and progress
└── TODO                          # Task list
```

## Documentation

Comprehensive documentation is available in the `docs` directory:

- **[How to Use Guide](docs/how-to-use.md)**: Detailed instructions for setting up and using the CI/CD pipeline
- **[Infrastructure Architecture](docs/Infrastracture_architecture.md)**: Monitoring system architecture
- **[Technology & Strategy](docs/technology%20%26%20strategy.md)**: Monitoring implementation approach
- **Monitoring Documentation**:
  - **[Prometheus Configuration](docs/monitoring/prometheus-conf.md)**: Metrics collection setup
  - **[Custom Pipeline Metrics](docs/monitoring/custom-pipeline-metrics.md)**: Jenkins metrics
- **[Code Standards](docs/STANDARD_CODE.md)**: Project coding standards and guidelines
- **Technologies**: Documentation for each tool (GitLab, Jenkins, Nexus)
- **Progress**: Development history and milestones in `docs/progresses/`
- **Requirements**: Project requirements in `docs/subjects/`

Additional documentation:
- **[Helm Chart README](helm/README.md)**: Instructions for deploying with Helm
- **Application README**: Documentation for the Flask application in `appflask/README.md`
- **Test Scripts**: Monitoring validation scripts in `appflask/test_scripts/`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Developed with ❤️ by [Nihilantropy]