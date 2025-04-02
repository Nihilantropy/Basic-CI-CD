# environments/local/main.tf
module "infrastructure" {
  source = "../../"
  
  # Pass all variables explicitly to the root module
  cluster_name      = var.cluster_name
  worker_count      = var.worker_count
  kubeconfig_path   = var.kubeconfig_path
  host_machine_ip   = var.host_machine_ip
  nexus_namespace   = var.nexus_namespace
}

# Output all the outputs from the root module
output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.infrastructure.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.infrastructure.cluster_endpoint
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = module.infrastructure.kubeconfig_path
}

output "nexus_namespace" {
  description = "Namespace for Nexus resources"
  value       = module.infrastructure.nexus_namespace
}
