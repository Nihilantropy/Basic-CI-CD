#!/bin/bash
# cleanup.sh - Clean up all terraform resources

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
echo -e "${BLUE}Cleaning up Terraform Infrastructure - ${ENVIRONMENT}${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Confirmation
read -p "This will destroy all resources. Are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}Operation cancelled.${NC}"
  exit 1
fi

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
  echo -e "${YELLOW}Terraform not initialized. Initializing...${NC}"
  terraform init
fi

# Save kubeconfig path for later cleanup
if terraform output -raw kubeconfig_path >/dev/null 2>&1; then
  KUBECONFIG_PATH=$(terraform output -raw kubeconfig_path)
  echo -e "${BLUE}Retrieved kubeconfig path: ${KUBECONFIG_PATH}${NC}"
fi

# Step 1: Destroy all resources
echo -e "${YELLOW}Destroying all resources...${NC}"
terraform destroy -auto-approve

# Step 2: Check for kind clusters that might not have been cleaned up
echo -e "${YELLOW}Checking for leftover Kind clusters...${NC}"
if command -v kind >/dev/null 2>&1 && kind get clusters >/dev/null 2>&1; then
  kind delete clusters --all
  echo -e "${GREEN}Kind clusters deleted.${NC}"
else
  echo -e "${GREEN}No Kind clusters found or kind command not available.${NC}"
fi

# Step 3: Clean up kubeconfig file if it exists
if [ -n "$KUBECONFIG_PATH" ] && [ -f "$KUBECONFIG_PATH" ]; then
  echo -e "${YELLOW}Removing kubeconfig file: ${KUBECONFIG_PATH}${NC}"
  rm -f "$KUBECONFIG_PATH"
  echo -e "${GREEN}Kubeconfig file removed.${NC}"
fi

# Step 4: Clean up Terraform files
echo -e "${YELLOW}Cleaning up Terraform state files...${NC}"
rm -f *.tfplan

echo -e "${GREEN}Cleanup complete!${NC}"
echo