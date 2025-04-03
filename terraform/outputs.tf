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
# output "flux_namespace" {
#   description = "Namespace where Flux is installed"
#   value       = module.flux.flux_namespace
# }

# output "flux_installed" {
#   description = "Whether Flux was successfully installed"
#   value       = module.flux.flux_installed
# }

# output "gitops_repo_name" {
#   description = "Name of the configured GitRepository"
#   value       = module.flux.gitops_repo_name
# }