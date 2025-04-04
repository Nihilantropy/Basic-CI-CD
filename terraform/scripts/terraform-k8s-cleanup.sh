#!/bin/bash
# terraform-k8s-cleanup.sh

echo "Cleaning up Kubernetes resources before Terraform destroy..."

# Remove finalizers from Flux resources
if kubectl get namespace flux-system &>/dev/null; then
  echo "Cleaning up Flux resources..."
  # Remove finalizers from GitRepository
  kubectl get gitrepositories -n flux-system -o name | xargs -I{} kubectl patch {} -n flux-system --type json -p '[{"op":"remove","path":"/metadata/finalizers"}]'
  
  # Remove finalizers from HelmRelease
  kubectl get helmreleases -n flux-system -o name | xargs -I{} kubectl patch {} -n flux-system --type json -p '[{"op":"remove","path":"/metadata/finalizers"}]'
  
  # Force delete any remaining custom resources
  kubectl delete gitrepositories --all -n flux-system --force --grace-period=0
  kubectl delete helmreleases --all -n flux-system --force --grace-period=0
fi

# Remove finalizers from ArgoCD resources
if kubectl get namespace argocd &>/dev/null; then
  echo "Cleaning up ArgoCD resources..."
  # Remove finalizers from Applications
  kubectl get applications -n argocd -o name | xargs -I{} kubectl patch {} -n argocd --type json -p '[{"op":"remove","path":"/metadata/finalizers"}]'
  
  # Force delete any remaining applications
  kubectl delete applications --all -n argocd --force --grace-period=0
fi

echo "Cleanup completed. You can now run terraform destroy."