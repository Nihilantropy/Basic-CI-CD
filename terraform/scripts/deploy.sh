#!/bin/bash
# deploy.sh - One-command deployment of the Terraform infrastructure

set -e  # Exit on any error

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Set default environment and handle parameter
ENVIRONMENT=${1:-"local"}
echo -e "${BLUE}Setting environment to ${YELLOW}${ENVIRONMENT}${NC}"

# Find the project root directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT_DIR="${PROJECT_ROOT}/environments/${ENVIRONMENT}"

# Check if environment directory exists
if [ ! -d "$ENVIRONMENT_DIR" ]; then
  echo -e "${RED}Error: Environment directory '${ENVIRONMENT}' not found at ${ENVIRONMENT_DIR}${NC}"
  echo -e "Available environments:"
  ls -1 "${PROJECT_ROOT}/environments"
  exit 1
fi

# Change to the environment directory
echo -e "${BLUE}Changing to environment directory: ${ENVIRONMENT_DIR}${NC}"
cd "$ENVIRONMENT_DIR"

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}Deploying Terraform Infrastructure - ${ENVIRONMENT}${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Step 1: Initialize Terraform (always run this first)
echo -e "${YELLOW}Step 1: Initializing Terraform${NC}"
terraform init
echo -e "${GREEN}Initialization successful!${NC}"
echo

# Step 2: Validate the Terraform configuration
echo -e "${YELLOW}Step 2: Validating Terraform Configuration${NC}"
terraform validate
echo -e "${GREEN}Validation successful!${NC}"
echo

# Step 3: Plan and apply - all in one step
echo -e "${YELLOW}Step 3: Planning and applying infrastructure${NC}"
echo -e "${BLUE}Planning...${NC}"
terraform plan -out=deployment.tfplan

echo -e "${BLUE}Applying...${NC}"
terraform apply deployment.tfplan

echo -e "${GREEN}Infrastructure successfully deployed!${NC}"
echo

# Step 4: Verify resources
echo -e "${YELLOW}Step 4: Verifying deployed resources${NC}"

# Get kubeconfig from Terraform outputs if possible
if terraform output -raw kubeconfig_path >/dev/null 2>&1; then
  export KUBECONFIG=$(terraform output -raw kubeconfig_path)
  echo -e "${BLUE}Using kubeconfig: ${KUBECONFIG}${NC}"

  # Verify cluster and resources
  echo -e "${BLUE}Checking nodes:${NC}"
  kubectl get nodes

  echo -e "${BLUE}Checking namespaces:${NC}"
  kubectl get namespaces

  # Check Nexus service if relevant output exists
  if terraform output -raw nexus_namespace >/dev/null 2>&1; then
    NEXUS_NS=$(terraform output -raw nexus_namespace)
    echo -e "${BLUE}Checking Nexus service in namespace ${NEXUS_NS}:${NC}"
    kubectl get service,endpoints -n "$NEXUS_NS" 
  fi
else
  echo -e "${YELLOW}No kubeconfig output found. Skipping Kubernetes verification.${NC}"
fi

echo -e "${GREEN}Deployment complete!${NC}"
echo
echo -e "${BLUE}You can now use your infrastructure.${NC}"
echo -e "${BLUE}To apply changes, run: terraform apply${NC}"
echo -e "${BLUE}To destroy everything, run: ../../scripts/cleanup.sh ${ENVIRONMENT}${NC}"
echo