#!/bin/bash
# update.sh - Apply changes to existing Terraform infrastructure

# Define cleanup function to handle removing plan files
cleanup() {
  local status=$?
  # Remove the update.tfplan file
  if [ -f update.tfplan ]; then
    echo -e "${BLUE}Cleaning up temporary files...${NC}"
    rm -f update.tfplan
    echo -e "${GREEN}Temporary plan file removed.${NC}"
  fi
  exit $status
}

# Register the cleanup function to run on exit
trap cleanup EXIT

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

# Check if terraform state exists (indicating previous deployment)
if [ ! -f "${ENVIRONMENT_DIR}/terraform.tfstate" ]; then
  echo -e "${RED}Error: No existing terraform state found in ${ENVIRONMENT_DIR}${NC}"
  echo -e "Please run deploy.sh first to create the infrastructure before updating."
  exit 1
fi

# Change to the environment directory
echo -e "${BLUE}Changing to environment directory: ${ENVIRONMENT_DIR}${NC}"
cd "$ENVIRONMENT_DIR"

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}Updating Terraform Infrastructure - ${ENVIRONMENT}${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Step 1: Plan changes
echo -e "${YELLOW}Step 1: Planning infrastructure changes${NC}"
echo -e "${BLUE}Detecting configuration changes...${NC}"
terraform plan -out=update.tfplan

# Check if there are any changes
HAS_CHANGES=$(terraform show -no-color update.tfplan | grep -c "Plan: " || true)
if [ "$HAS_CHANGES" -eq "0" ] || grep -q "Plan: 0 to add, 0 to change, 0 to destroy" <(terraform show -no-color update.tfplan); then
  echo -e "${GREEN}No changes detected. Infrastructure is up to date!${NC}"
  # No need to manually remove update.tfplan here, the cleanup function will handle it
  exit 0
fi

# Step 2: Apply changes if detected
echo -e "${YELLOW}Step 2: Applying infrastructure changes${NC}"
echo -e "${BLUE}Applying changes...${NC}"
terraform apply update.tfplan

echo -e "${GREEN}Infrastructure successfully updated!${NC}"
echo

# Step 3: Verify resources
echo -e "${YELLOW}Step 3: Verifying updated resources${NC}"

# Get kubeconfig from Terraform outputs if possible
if terraform output -raw kubeconfig_path >/dev/null 2>&1; then
  export KUBECONFIG=$(terraform output -raw kubeconfig_path)
  echo -e "${BLUE}Using kubeconfig: ${KUBECONFIG}${NC}"

  # Verify cluster and resources
  echo -e "${BLUE}Checking Flux system status:${NC}"
  kubectl get helmreleases -A
  
  echo -e "${BLUE}Checking application pods:${NC}"
  kubectl get pods -n appflask
  
  # Check Nexus service if relevant output exists
  if terraform output -raw nexus_namespace >/dev/null 2>&1; then
    NEXUS_NS=$(terraform output -raw nexus_namespace)
    echo -e "${BLUE}Checking Nexus service in namespace ${NEXUS_NS}:${NC}"
    kubectl get service,endpoints -n "$NEXUS_NS" 
  fi
else
  echo -e "${YELLOW}No kubeconfig output found. Skipping Kubernetes verification.${NC}"
fi

# Note: No need to explicitly remove update.tfplan here since the cleanup function will handle it

echo -e "${GREEN}Update complete!${NC}"
echo
echo -e "${BLUE}Your infrastructure has been updated with the latest changes.${NC}"
echo -e "${BLUE}To make additional changes, modify the Terraform files and run this script again.${NC}"
echo -e "${BLUE}To destroy everything, run: ../../scripts/cleanup.sh ${ENVIRONMENT}${NC}"
echo

# Note: The cleanup function will run automatically on exit due to the trap