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

output "app_namespace" {
  description = "Namespace for application deployment"
  value       = module.k8s_resources.app_namespace
}

# output "app_release" {
#   description = "Name of the Helm release"
#   value       = module.app_deployment.release_name
# }

# output "app_version" {
#   description = "Version of the deployed application"
#   value       = module.app_deployment.version
# }

# output "app_status" {
#   description = "Status of the application deployment"
#   value       = module.app_deployment.status
# }