# outputs.tf (Root Module)

# Cluster outputs
output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.cluster.endpoint
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = module.cluster.kubeconfig_path
}

# Nexus outputs
output "nexus_namespace" {
  description = "Namespace for Nexus resources"
  value       = module.nexus.nexus_namespace
}

# Flux outputs
output "flux_namespace" {
  description = "Namespace where Flux is installed"
  value       = module.flux.flux_namespace
}

output "flux_installed" {
  description = "Whether Flux was successfully installed"
  value       = module.flux.flux_installed
}

output "gitops_repo_name" {
  description = "Name of the configured GitRepository"
  value       = module.flux.gitops_repo_name
}

# ArgoCD outputs
output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = module.argocd.argocd_namespace
}

output "argocd_app_namespace" {
  description = "Namespace where ArgoCD deploys the application"
  value       = module.argocd.app_namespace
}

output "argocd_ui_url" {
  description = "URL to access the ArgoCD UI"
  value       = module.argocd.argocd_ui_url
}

output "argocd_initial_password_command" {
  description = "Command to get the initial ArgoCD admin password"
  value       = module.argocd.argocd_initial_password_command
}