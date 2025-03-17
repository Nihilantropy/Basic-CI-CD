# Basic CI/CD Pipeline Project

![CI/CD Pipeline](https://img.shields.io/badge/CI%2FCD-Pipeline-blue)
![Jenkins](https://img.shields.io/badge/Jenkins-v2.492.1-red)
![GitLab](https://img.shields.io/badge/GitLab-CE-orange)
![Nexus](https://img.shields.io/badge/Nexus-3-green)
![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-blueviolet)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

A robust end-to-end CI/CD (Continuous Integration/Continuous Delivery) pipeline implementation demonstrating modern DevOps practices. This project integrates industry-standard tools to automate building, testing, packaging, and deploying a Python Flask application with advanced features.

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
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
- [Usage](#usage)
- [Workflow](#workflow)
- [Directory Structure](#directory-structure)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project showcases a complete CI/CD pipeline that automates the software development lifecycle from code commit to production deployment. By leveraging Docker Compose, Jenkins, GitLab, Nexus, and Kubernetes, the project provides a scalable, maintainable, and secure solution for continuous delivery of a Python Flask application.

The pipeline handles code quality checks, security scans, artifact management, version control, and Kubernetes deployment, demonstrating best practices in modern DevOps workflows.

## Architecture

The architecture consists of the following main components:

1. **Development Environment**: Dockerized services for local development
2. **Source Control**: GitLab for version control and code hosting
3. **CI/CD Server**: Jenkins for pipeline automation
4. **Artifact Repository**: Nexus for storing build artifacts
5. **Deployment Target**: Kubernetes (K3s) for container orchestration

The workflow follows a typical CI/CD pattern:
- Code changes are pushed to GitLab
- Jenkins detects changes and triggers the pipeline
- Tests, code quality, and security checks are performed
- Application is built and packaged as a binary
- Binary is stored in Nexus with version control
- Helm deploys the application to Kubernetes

## Key Features

- **Complete CI/CD Automation**: End-to-end pipeline from code commit to deployment
- **Containerized Development Environment**: Docker Compose setup for all services
- **Advanced Flask Application**: Features rate limiting and versioning
- **Comprehensive Testing**: Automated tests for functionality and security
- **Code Quality Enforcement**: Static analysis with Ruff and security scanning with Bandit
- **Artifact Management**: Versioned storage of binaries in Nexus
- **Automated Versioning**: Timestamp-based versioning with Git tags
- **Kubernetes Deployment**: Helm charts for declarative application deployment
- **GitLab Integration**: Merge requests, status updates, and integration triggers
- **Notification System**: Build status notifications via Telegram

## Components

### Base Environment

The foundation of the project is a Docker Compose environment that includes:

- **Jenkins**: Automation server running on port `8081`
- **GitLab**: Version control platform accessible at `http://gitlab.local:8080`
- **Nexus**: Artifact repository to store build artifacts on port `8082`

This containerized setup ensures consistency across environments and simplifies development.

### Python Application

A Flask-based microservice with:

- **Greeting Endpoint (`/`)**: Returns a customizable message with agent name, version, and time
- **Health Check Endpoint (`/health`)**: For monitoring and liveness probes
- **Global Rate Limiting**: Protection against DoS with 100 requests per minute limit
- **Version Management**: Dynamic version information included in responses

The application follows a modular architecture with:
- Application factory pattern
- Blueprint-based routing
- Environment-specific configuration
- Comprehensive error handling

### Jenkins Pipeline

A sophisticated CI/CD pipeline that:

1. **Runs Tests**: Executes pytest test suite for application verification
2. **Performs Code Quality Checks**: Uses Ruff for static analysis
3. **Conducts Security Scanning**: Employs Bandit for security vulnerability detection
4. **Builds the Application**: Packages the Flask app as a standalone binary using PyInstaller
5. **Uploads Artifacts**: Stores binaries in Nexus with both `latest` and timestamped versions
6. **Updates Version Information**: Updates version tags in the code and repository
7. **Creates Git Tags**: Adds timestamp-based version tags to the repository
8. **Generates Merge Requests**: Creates merge requests to the main branch
9. **Updates GitLab Status**: Provides real-time build status in GitLab UI
10. **Sends Notifications**: Delivers build status via Telegram

The pipeline is defined in a Jenkinsfile with modular utility functions and supports configuration via parameters or `jenkins-config.yml`.

### Helm Chart

A Kubernetes deployment solution that:

- **Configures Deployments**: Manages replica count and environment variables
- **Handles Service Exposure**: Exposes the application via NodePort
- **Supports Version Selection**: Deploys specific application versions
- **Implements Health Monitoring**: Configures liveness probes
- **Manages Environment Variables**: Passes configuration to the application
- **Downloads from Nexus**: Fetches the appropriate binary version at startup

The chart is designed for flexibility, allowing customization through `values.yaml`.

### Kubernetes Setup

A lightweight Kubernetes deployment using:

- **K3s**: A certified Kubernetes distribution that's lightweight and easy to install
- **Headless Services**: Connect to external resources like Nexus
- **Custom Endpoints**: Map to host machine services
- **Namespaces**: Organize resources by functionality

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Git
- Kubernetes cluster (K3s, Minikube, or Docker Desktop Kubernetes)
- kubectl CLI
- Helm

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Nihilantropy/Basic-CI-CD.git
   cd Basic-CI-CD
   ```

2. Start the base environment:
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
   ```bash
   kubectl create namespace nexus
   kubectl apply -f k3s/service/nexus-headless-service.yaml
   kubectl apply -f k3s/service/nexus-headless-endpoint.yaml
   ```

For detailed, step-by-step setup and configuration instructions, please refer to our comprehensive [How to Use Guide](Docs/how-to-use.md).

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
   ```

## Usage

### Triggering the Pipeline

1. Push changes to the GitLab repository:
   ```bash
   git add .
   git commit -m "Update application code"
   git push origin main
   ```

2. Monitor the pipeline in Jenkins at http://localhost:8081

3. View build status in the GitLab UI

### Deploying the Application

1. Deploy using Helm:
   ```bash
   helm install appflask ./helm/flask-app
   ```

2. Deploy a specific version:
   ```bash
   helm install appflask ./helm/flask-app --set appVersion=20240317123456
   ```

3. Verify the deployment:
   ```bash
   kubectl get pods
   kubectl get svc
   ```

4. Test the application:
   ```bash
   curl http://<NODE_IP>:30080/
   curl http://<NODE_IP>:30080/health
   ```

For complete instructions on using the pipeline, deploying applications, and troubleshooting, refer to our [How to Use Guide](Docs/how-to-use.md).

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

## Directory Structure

```
basic-ci-cd/
├── Docs/                         # Documentation files
│   ├── Technologies/             # Tool-specific documentation
│   │   ├── GitLab/
│   │   ├── Jenkins/
│   │   └── Nexus/
│   ├── how-to-use.md             # Comprehensive usage guide
│   ├── progresses/               # Project progress tracking
│   ├── subjects/                 # Project requirements
│   └── workflows/                # Workflow documentation
├── flask-app/                    # Flask application source
│   ├── agent/                    # Jenkins agent configuration
│   ├── includes/                 # Pipeline utility functions
│   ├── srcs/                     # Application source code
│   │   ├── main/                 # Core application modules
│   │   └── tests/                # Test suites
│   ├── Jenkinsfile               # CI/CD pipeline definition
│   └── version.info              # Application version file
├── helm/                         # Kubernetes Helm charts
│   ├── flask-app/                # AppFlask chart
│   │   ├── templates/            # Kubernetes resource templates
│   │   ├── Chart.yaml            # Chart metadata
│   │   └── values.yaml           # Configurable values
│   └── README.md                 # Helm documentation
├── k3s/                          # Kubernetes configurations
│   └── service/                  # Service definitions
├── srcs/                         # Docker environment files
│   ├── docker-compose.yaml       # Service composition
│   └── requirements/             # Service-specific files
│       ├── GitLab/
│       ├── Jenkins/
│       └── Nexus/
├── Makefile                      # Build automation
├── README.md                     # Project documentation
└── .gitignore                    # Git exclusion patterns
```

## Documentation

Comprehensive documentation is available in the `Docs` directory:

- **[How to Use Guide](Docs/how-to-use.md)**: Detailed instructions for setting up and using the CI/CD pipeline
- **Technologies**: Detailed documentation for each tool
- **Workflows**: Pipeline and process documentation
- **Subjects**: Original project requirements
- **Progress**: Development history and milestones

Additional documentation:
- **[Helm Chart README](helm/README.md)**: Instructions for deploying with Helm
- **Flask App README**: Details of the application architecture and features
- **Jenkinsfile**: Commented pipeline stages and configurations

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