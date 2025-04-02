# outputs.tf
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

output "nexus_namespace" {
  description = "Namespace for Nexus resources"
  value       = module.k8s_resources.nexus_namespace
}
