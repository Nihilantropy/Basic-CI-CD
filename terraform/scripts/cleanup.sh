#!/bin/bash
# cleanup.sh - Clean up all terraform resources thoroughly

set -e  # Exit on any error

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Get cluster name from terraform state or variable
CLUSTER_NAME="basic-cicd-${ENVIRONMENT}"
if terraform output -json 2>/dev/null | grep -q "cluster_name"; then
  CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "basic-cicd-${ENVIRONMENT}")
fi
echo -e "${BLUE}Cluster name identified as: ${CYAN}${CLUSTER_NAME}${NC}"

# Save kubeconfig path for later cleanup
KUBECONFIG_PATH=""
if terraform output -json 2>/dev/null | grep -q "kubeconfig_path"; then
  KUBECONFIG_PATH=$(terraform output -raw kubeconfig_path 2>/dev/null)
  echo -e "${BLUE}Retrieved kubeconfig path: ${CYAN}${KUBECONFIG_PATH}${NC}"
fi

# Get terra-home directory base path
TERRA_HOME_DIR=$(dirname "$(dirname "${KUBECONFIG_PATH}")")
echo $TERRA_HOME_DIR this is terra home dir
if [[ -z "${TERRA_HOME_DIR}" || "${TERRA_HOME_DIR}" == "." ]]; then
  TERRA_HOME_DIR="${PROJECT_ROOT}/terra-home"
fi
echo -e "${BLUE}Terra-home directory identified as: ${CYAN}${TERRA_HOME_DIR}${NC}"

# # Step 0: Clean up Kubernetes resources that might have finalizers
# echo -e "${YELLOW}Checking for resources with finalizers...${NC}"
# if [[ -n "${KUBECONFIG_PATH}" && -f "${KUBECONFIG_PATH}" ]]; then
#   echo -e "${BLUE}Running pre-destroy cleanup script...${NC}"
#   # Source the pre-destroy script if it exists
#   if [[ -f "${PROJECT_ROOT}/scripts/terraform-k8s-cleanup.sh" ]]; then
#     export KUBECONFIG="${KUBECONFIG_PATH}"
#     bash "${PROJECT_ROOT}/scripts/terraform-k8s-cleanup.sh"
#   else
#     echo -e "${YELLOW}Pre-destroy cleanup script not found. Continuing...${NC}"
#   fi
# fi

# Step 1: Destroy all terraform resources
echo -e "${YELLOW}Destroying all Terraform resources...${NC}"
# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
  echo -e "${YELLOW}Terraform not initialized. Initializing...${NC}"
  terraform init
fi

# Destroy with terraform
terraform destroy -auto-approve || {
  echo -e "${YELLOW}Terraform destroy failed, but continuing with cleanup...${NC}"
}

# Step 2: Check for and remove Kind clusters
echo -e "${YELLOW}Checking for leftover Kind clusters...${NC}"
if command -v kind >/dev/null 2>&1; then
  if kind get clusters | grep -q "${CLUSTER_NAME}"; then
    echo -e "${BLUE}Deleting Kind cluster: ${CLUSTER_NAME}${NC}"
    kind delete cluster --name "${CLUSTER_NAME}"
    echo -e "${GREEN}Kind cluster deleted.${NC}"
  else
    echo -e "${GREEN}No matching Kind cluster found.${NC}"
  fi
else
  echo -e "${YELLOW}Kind command not available. Skipping kind cluster deletion.${NC}"
fi

# Step 3: Force remove Docker containers if they exist
echo -e "${YELLOW}Checking for leftover Docker containers...${NC}"
CONTAINERS=(
  "${CLUSTER_NAME}-control-plane"
  "${CLUSTER_NAME}-worker"
)

# Add numbered worker nodes
for i in {2..5}; do
  CONTAINERS+=("${CLUSTER_NAME}-worker${i}")
done

for CONTAINER in "${CONTAINERS[@]}"; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo -e "${BLUE}Removing container: ${CONTAINER}${NC}"
    docker rm -f "${CONTAINER}"
    echo -e "${GREEN}Container removed.${NC}"
  else
    echo -e "${GREEN}Container not found: ${CONTAINER}${NC}"
  fi
done

# Step 4: Clean up kubeconfig file and terra-home directory
if [[ -n "${KUBECONFIG_PATH}" && -f "${KUBECONFIG_PATH}" ]]; then
  echo -e "${YELLOW}Removing kubeconfig file: ${KUBECONFIG_PATH}${NC}"
  rm -f "${KUBECONFIG_PATH}"
  echo -e "${GREEN}Kubeconfig file removed.${NC}"
fi

if [[ -d "${TERRA_HOME_DIR}" ]]; then
  echo -e "${YELLOW}Removing terra-home directory: ${TERRA_HOME_DIR}${NC}"
  rm -rf "${TERRA_HOME_DIR}"
  echo -e "${GREEN}Terra-home directory removed.${NC}"
fi

# Step 5: Clean up Terraform files and state
echo -e "${YELLOW}Cleaning up Terraform files and state...${NC}"
# Remove plan files
find . -name "*.tfplan" -type f -delete
# Remove state files
rm -f terraform.tfstate terraform.tfstate.backup
# Remove lock file
rm -f .terraform.lock.hcl
# Remove .terraform directory
if [[ -d ".terraform" ]]; then
  rm -rf .terraform
fi

echo -e "${GREEN}✅ Cleanup complete! All resources have been removed.${NC}"
echo