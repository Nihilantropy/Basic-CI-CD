# Terraform Implementation for Basic CI/CD Project

This README documents the Terraform implementation that automates the provisioning of a local Kubernetes cluster and essential CI/CD infrastructure for the Basic CI/CD project.

## Table of Contents

- [Introduction to Terraform and Kind](#introduction-to-terraform-and-kind)
- [Project Structure](#project-structure)
- [Environment Separation](#environment-separation)
- [Nexus Integration](#nexus-integration)
- [Flux GitOps](#flux-gitops)
- [Getting Started](#getting-started)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)

## Introduction to Terraform and Kind

### What is Terraform?

Terraform is an open-source Infrastructure as Code (IaC) tool created by HashiCorp that allows you to define and provision infrastructure using a declarative configuration language. With Terraform, you can:

- Define infrastructure in human-readable configuration files
- Version control your infrastructure alongside application code
- Apply changes incrementally without disrupting existing resources
- Manage resources across multiple cloud providers and on-premises systems

### Why Use Terraform for a Local Kubernetes Cluster?

We're using Terraform to provision a local Kubernetes cluster via Kind (Kubernetes IN Docker) for several compelling reasons:

1. **Consistency**: The same Terraform workflow can be used for both local development and production environments
2. **Reproducibility**: Infrastructure code ensures that everyone has the same environment configuration
3. **Automation**: Reduces manual steps and potential human errors
4. **Documentation**: The code itself documents the infrastructure requirements
5. **Testing**: Enables easier testing of Kubernetes configurations locally before production deployment
6. **GitOps Practices**: Aligns with our GitOps approach where everything is stored in Git

Kind specifically allows us to run lightweight Kubernetes clusters inside Docker containers, making it ideal for local development and testing without requiring significant resources.

## Project Structure

The Terraform implementation follows a modular structure to promote reuse, separation of concerns, and maintainability:

```
terraform/
├── cluster_ready.tf         # Ensures cluster is ready before proceeding
├── environments/            # Environment-specific configurations
│   └── local/               # Local development environment
│       ├── backend.tf       # State storage configuration
│       ├── main.tf          # Entry point for the environment
│       ├── terraform.tfvars # Default values for variables
│       └── variables.tf     # Environment-specific variables
├── locals.tf                # Local variables for reuse
├── main.tf                  # Main configuration file
├── modules/                 # Reusable Terraform modules
│   ├── cluster/             # Kind cluster creation module
│   │   ├── main.tf          # Cluster configuration
│   │   ├── outputs.tf       # Module outputs
│   │   ├── provider_config.tf # Provider configuration helpers
│   │   ├── providers.tf     # Provider requirements
│   │   └── variables.tf     # Module inputs
│   └── k8s_resources/       # Kubernetes resource modules
│       ├── flux/            # Flux GitOps controller module
│       │   ├── custom_resources.tf # Flux custom resources
│       │   ├── flux_readiness.tf   # Ensures Flux is ready
│       │   ├── main.tf      # Flux installation
│       │   ├── outputs.tf   # Module outputs
│       │   ├── variables.tf # Module inputs
│       │   └── versions.tf  # Provider requirements
│       └── nexus/           # Nexus integration module
│           ├── main.tf      # Nexus resources
│           ├── outputs.tf   # Module outputs
│           ├── variables.tf # Module inputs
│           └── versions.tf  # Provider requirements
├── outputs.tf               # Root module outputs
├── providers.tf             # Provider configurations
├── RoadMap.md               # Implementation roadmap
├── scripts/                 # Helper scripts
│   ├── cleanup.sh           # Environment cleanup script
│   └── deploy.sh            # Deployment script
└── variables.tf             # Root module variables
```

This structured approach allows us to:

- **Modularize common functionality**: Each module handles a specific aspect of the infrastructure
- **Maintain clear dependencies**: The dependency chain is explicit and managed
- **Enable reuse**: Modules can be reused across environments
- **Simplify management**: Scripts automate common operations

## Environment Separation

The `environments` directory contains environment-specific configurations, allowing us to maintain separate state and variables for different deployment targets (local development, staging, production, etc.).

### Local Environment

The `environments/local` directory contains configuration specific to local development:

- **backend.tf**: Configures Terraform to store state locally (in `terraform.tfstate`)
- **main.tf**: Calls the root module with environment-specific settings
- **terraform.tfvars**: Default values for the environment (e.g., host IP address)
- **variables.tf**: Declares variables specific to this environment

This structure makes it easy to:

- Run the same code with different settings per environment
- Isolate changes to a single environment
- Test configurations locally before applying to higher environments
- Add new environments by creating additional directories with appropriate configurations

## Nexus Integration

The Nexus module (`modules/k8s_resources/nexus`) creates Kubernetes resources that enable the cluster to connect to our external Nexus repository. This is a critical component that allows our deployed applications to retrieve artifacts built during CI/CD pipelines.

### Resources Created

1. **Namespace**: A dedicated `nexus` namespace to organize Nexus-related resources
2. **Headless Service**: A service with `clusterIP: None` that provides DNS resolution without load balancing
3. **Endpoints**: Maps the service to the host machine's IP address where Nexus is running

### How It Works

1. The module creates a Kubernetes service named `nexus-service` in the `nexus` namespace
2. Instead of selecting pods, the service is manually mapped to endpoints
3. The endpoints point to the host machine's IP (defined in `terraform.tfvars`)
4. Applications in the cluster can access Nexus using DNS: `nexus-service.nexus.svc.cluster.local:8082`

This approach allows pods in the Kubernetes cluster to resolve and connect to the external Nexus server using Kubernetes DNS, which is important for artifact retrieval during deployment.

## Flux GitOps

The Flux module (`modules/k8s_resources/flux`) implements our GitOps approach by installing and configuring Flux CD, which continuously synchronizes the Kubernetes cluster with our Git repository.

### Components

1. **Flux Controllers**: Installed via Helm in the `flux-system` namespace
2. **Authentication**: Secret for GitLab access
3. **Git Repository**: Custom resource that monitors our GitLab repository
4. **Helm Release**: Custom resource that manages Helm-based deployments

### GitOps Workflow

Flux operates on a pull-based model:

1. Flux continuously monitors the specified Git repository branch (`helm-charts`)
2. When changes are detected, Flux automatically applies them to the cluster
3. The Git repository becomes the single source of truth for the cluster state
4. The CI/CD pipeline (Jenkins) updates the `helm-charts` branch when new versions are built

### Critical Consideration: Chart Versioning

A critical point to understand about Flux and Helm chart upgrades:

- Flux determines whether to upgrade a release primarily based on the `version` field in `Chart.yaml`, not the `appVersion` field
- The CI/CD pipeline automatically updates `appVersion` to reflect the application version
- However, the `version` field (representing the Helm chart version) must be manually incremented to trigger Flux to perform an upgrade

Without updating the `version` field, Flux will not detect that the chart has changed and won't perform an upgrade, even if the `appVersion` has been updated.

## Getting Started

### Prerequisites

- Docker installed and running
- Git
- Terraform (v1.0.0+)
- kubectl

### Deploying the Infrastructure

Use the provided deployment script:

```bash
cd terraform
./scripts/deploy.sh local
```

This script:
1. Changes to the correct environment directory
2. Initializes Terraform
3. Validates the configuration
4. Creates an execution plan
5. Applies the changes
6. Verifies the deployed resources

### Verifying Deployment

After deployment, you can check the status of your resources:

```bash
# Change workspace
cd environments/local

# use the local kube-config
export KUBECONFIG=\~/.kube/config-tf-local

# View the local cluster
kubectl get nodes

# Check Flux installation
kubectl get pods -n flux-system

# Verify Nexus connection
kubectl get service,endpoints -n nexus

kubectl get all -A
```

To have an overall view

```bash
kubectl get all -A
```

## Common Operations

### Updating Infrastructure

To apply changes to your infrastructure:

```bash
cd terraform/environments/local
terraform apply
```

### Destroying Infrastructure

To clean up all resources:

```bash
cd terraform
./scripts/cleanup.sh local
```

### Adding New Resources

1. Create appropriate Terraform configurations
2. Apply changes using `terraform apply`
3. Verify resources were created correctly

## Troubleshooting

### Common Issues

- **Cluster creation fails**: Ensure Docker is running and has sufficient resources
- **Flux fails to sync**: Check GitLab credentials and repository accessibility
- **Helm chart not updating**: Ensure the Chart.yaml version field is incremented
- **Nexus connection issues**: Verify the host IP address is correct in terraform.tfvars

### Logs and Debugging

- Terraform logs: Use `TF_LOG=DEBUG` environment variable
- Kubernetes logs: `kubectl logs -n flux-system deployment/source-controller`
- Flux status: `kubectl get gitrepositories,helmreleases -A`

---

This Terraform implementation provides a consistent, repeatable way to provision and manage our Kubernetes infrastructure for the Basic CI/CD project, ensuring that our development environments precisely match our Infrastructure as Code definitions.