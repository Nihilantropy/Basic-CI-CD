#!/bin/bash
# terraform-apply.sh

set -e  # Exit on any errors

echo "Step 1: Creating Kind cluster..."
terraform apply -target=module.infrastructure.module.cluster -auto-approve

echo "Waiting for cluster to initialize..."
sleep 15

echo "Step 2: Applying remaining resources..."
terraform apply -auto-approve

if [ $? -eq 0 ]; then
  echo "Terraform apply completed successfully!"
  
  # Verify the cluster and resources
  export KUBECONFIG=~/.kube/config-tf-local
  
  echo "Checking cluster nodes:"
  kubectl get nodes
  
  echo "Checking namespaces:"
  kubectl get ns
  
  echo "Checking pods:"
  kubectl get pods -A
  
  echo "Setup complete!"
else
  echo "Terraform apply failed. Check the error messages above."
fi