# Basic CI/CD Pipeline Project

![CI/CD Pipeline](https://img.shields.io/badge/CI%2FCD-Pipeline-blue)
![Jenkins](https://img.shields.io/badge/Jenkins-v2.492.1-red)
![GitLab](https://img.shields.io/badge/GitLab-CE-orange)
![Nexus](https://img.shields.io/badge/Nexus-3-green)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Kind-blueviolet)
![Terraform](https://img.shields.io/badge/Terraform-1.7.0-purple)
![ArgoCD](https://img.shields.io/badge/ArgoCD-v2.8.0-lightblue)
![Sonarqube](https://img.shields.io/badge/Sonarqube-9.9-blue)
![Prometheus](https://img.shields.io/badge/Prometheus-v3.2.1-red)
![Grafana](https://img.shields.io/badge/Grafana-11.5.2-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

A robust end-to-end CI/CD pipeline demonstrating modern DevOps practices through the integration of industry-standard tools. This project automates the complete software development lifecycle from code commit to production deployment and observability of a Python Flask application.

> **🔍 For detailed setup and usage instructions, please see [How to Use Guide](docs/how-to-use.md).**

## Table of Contents

- [Overview](#overview)
- [Core Principles](#core-principles)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Components](#components)
- [Workflow](#workflow)
- [Directory Structure](#directory-structure)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## 🌟 Overview

This project showcases a complete CI/CD pipeline with integrated monitoring that automates the software development lifecycle. It leverages modern DevOps tools to create a scalable, maintainable, and secure solution for continuous delivery and monitoring of a Python Flask application.

The implementation focuses on DevOps best practices including:
- Infrastructure as Code (IaC)
- Containerization
- Continuous Integration
- Continuous Deployment with GitOps
- Automated Testing
- Code Quality Enforcement
- Comprehensive Monitoring
- Multi-Environment Support

## 🧩 Core Principles

This project embodies several core DevOps principles:

1. **Automation** 🔄: Eliminate manual processes through automation of building, testing, and deployment
2. **Continuous Integration** 🛠️: Frequent code integration with automated verification
3. **Continuous Delivery** 🚀: Reliable, low-risk deployments through automation
4. **GitOps** 📝: Git as the single source of truth for infrastructure and application deployment
5. **Shift Left** 🔍: Early testing, security scanning, and quality checks
6. **Infrastructure as Code** 🏗️: Define and version infrastructure alongside application code
7. **Observability** 📊: Comprehensive monitoring and metrics collection
8. **Environment Parity** 🔄: Consistent configurations across environments

## 🏛️ Architecture

The architecture integrates several key components:

1. **Version Control (GitLab)**: Central repository for application code, Helm charts, and deployment configurations
2. **CI Pipeline (Jenkins)**: Orchestrates building, testing, and artifact creation processes
3. **Artifact Storage (Nexus)**: Securely stores versioned application binaries
4. **Quality Gates (Sonarqube)**: Enforces code quality standards and test coverage
5. **Infrastructure Provisioning (Terraform)**: Manages Kubernetes infrastructure declaratively
6. **GitOps Engine (ArgoCD)**: Ensures deployment state matches Git definitions
7. **Container Orchestration (Kubernetes)**: Manages application containers
8. **Monitoring Stack**: Tracks application and infrastructure health and performance

The workflow connects these components into a seamless pipeline where code changes automatically flow through verification, building, and deployment stages while maintaining observability.

## ✨ Key Features

- **Complete CI/CD Automation**: End-to-end pipeline from code commit to deployment
- **GitOps with ArgoCD**: App of Apps pattern for multi-environment deployments
- **Infrastructure as Code**: Terraform-managed Kubernetes with reusable modules
- **Multi-Environment Support**: Separate dev and prod configurations
- **Advanced Flask Application**: Rate limiting, metrics collection, and health monitoring
- **Comprehensive Testing**: Automated functional, security, and metrics tests
- **Code Quality Enforcement**: Static analysis, security scanning, and Sonarqube integration
- **Artifact Management**: Versioned binary storage with Nexus
- **Containerized Development**: Docker Compose for consistent local environment
- **Detailed Monitoring**: Prometheus metrics collection with Grafana dashboards
- **Alerting**: Configurable thresholds with Alertmanager integration

## 🧰 Components

### 📝 Version Control with GitLab

GitLab serves as the central source code repository, providing:
- Version control for application code
- CI/CD integration with Jenkins
- Repository for deployment configurations
- Separate branch for ArgoCD configurations

### 🔄 Continuous Integration with Jenkins

Jenkins orchestrates the CI process with a pipeline that:
- Runs automated tests with pytest
- Performs static code analysis with Ruff
- Conducts security scanning with Bandit
- Analyzes code quality with Sonarqube
- Builds application binaries with PyInstaller
- Uploads artifacts to Nexus repository
- Updates deployment configurations
- Creates dedicated ArgoCD branch

### 📦 Artifact Management with Nexus

Nexus provides a central repository for:
- Storing versioned application binaries
- Managing latest and timestamped releases
- Providing a reliable artifact source for deployments

### 🏗️ Infrastructure Management with Terraform

Terraform enables infrastructure as code by:
- Creating and configuring Kind Kubernetes clusters
- Setting up ArgoCD with the App of Apps pattern
- Managing Kubernetes resources with reusable modules
- Connecting cluster to external services like Nexus

### 🚀 GitOps Deployment with ArgoCD

ArgoCD implements GitOps practices by:
- Using the App of Apps pattern for hierarchical management
- Automatically synchronizing Git changes to the cluster
- Supporting multiple environments (dev, prod)
- Self-healing deployments that maintain desired state
- Providing visibility into deployment status and history

### ⚙️ Application Deployment with Helm

Helm charts provide declarative application management:
- Environment-specific configurations via values files
- Consistent deployment templates
- Support for versioned releases
- Integration with Nexus for artifact retrieval

### 📊 Monitoring with Prometheus and Grafana

The monitoring stack delivers comprehensive observability:
- Application metrics from the Flask `/metrics` endpoint
- Pipeline performance metrics from Jenkins
- Container and system metrics from cAdvisor
- Custom dashboards for different aspects of the system
- Alerting based on defined thresholds

## 🔄 Workflow

The CI/CD workflow follows these steps:

1. **Code Commit** 📝: Developer pushes changes to GitLab main branch
2. **CI Pipeline** 🧪: Jenkins tests, analyzes, builds and packages the application
3. **Artifact Storage** 📦: Binary is versioned and stored in Nexus
4. **GitOps Update** 🔄: Jenkins updates Helm chart and ArgoCD branch
5. **Automatic Deployment** 🚀: ArgoCD detects changes and syncs applications to Kubernetes
6. **Multi-Environment Deployment** 🌐: Applications deploy to dev and prod environments
7. **Continuous Monitoring** 📊: Prometheus collects metrics from all components
8. **Performance Visualization** 📈: Grafana displays real-time metrics and trends

This workflow embodies the principle of continuous delivery by providing a reliable, repeatable path to production with built-in quality gates and observability.

## 📁 Directory Structure

```
basic-ci-cd/
├── appflask/                     # Flask application source
│   ├── agent/                    # Jenkins agent configuration
│   ├── appflask/                 # Application source code
│   ├── argocd-apps/              # ArgoCD application definitions
│   │   ├── apps/                 # App of Apps child applications
│   │   └── helm/                 # Helm charts for applications
│   ├── tests/                    # Test suites
│   └── test_scripts/             # Monitoring test scripts
│
├── docs/                         # Documentation files
│   ├── how-to-use.md             # Comprehensive usage guide
│   ├── monitoring/               # Monitoring documentation
│   ├── progresses/               # Project progress tracking
│   └── subjects/                 # Project requirements
│
├── srcs/                         # Docker environment files
│   ├── docker-compose.yaml       # Service composition
│   └── requirements/             # Service-specific files
│
├── terraform/                    # Terraform configurations
│   ├── environments/             # Environment-specific configs
│   ├── modules/                  # Reusable modules
│   │   ├── cluster/              # Kind cluster module
│   │   └── k8s_resources/        # Kubernetes resources modules
│   └── scripts/                  # Helper scripts
│
├── Makefile                      # Build automation
└── README.md                     # This documentation
```

## 📚 Documentation

Comprehensive documentation is available in the `docs` directory:

- **[How to Use Guide](docs/how-to-use.md)**: Detailed setup and usage instructions
- **[Infrastructure Architecture](docs/Infrastracture_architecture.md)**: Monitoring system architecture
- **[Monitoring Documentation](docs/monitoring/)**: Metrics collection setup and pipeline metrics
- **[Code Standards](docs/STANDARD_CODE.md)**: Coding standards and guidelines
- **[Technologies](docs/Technologies/)**: Documentation for GitLab, Jenkins, and Nexus
- **[Project Requirements](docs/subjects/)**: Original project requirements

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Developed with ❤️ by [Nihilantropy]