# environments/local/main.tf
module "infrastructure" {
  source = "../../"
  
  # Pass all variables explicitly to the root module
  cluster_name      = var.cluster_name
  worker_count      = var.worker_count
  kubeconfig_path   = var.kubeconfig_path
  host_machine_ip   = var.host_machine_ip
  nexus_namespace   = var.nexus_namespace
  app_namespace     = var.app_namespace
  # app_release_name  = var.app_release_name
  # app_replica_count = var.app_replica_count
  # app_agent_name    = var.app_agent_name
  # app_version       = var.app_version
  # flask_environment = var.flask_environment
  # app_node_port     = var.app_node_port
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

output "app_namespace" {
  description = "Namespace for application deployment"
  value       = module.infrastructure.app_namespace
}

# output "app_release" {
#   description = "Name of the Helm release"
#   value       = module.infrastructure.app_release
# }

# output "app_version" {
#   description = "Version of the deployed application"
#   value       = module.infrastructure.app_version
# }

# output "app_status" {
#   description = "Status of the application deployment" 
#   value       = module.infrastructure.app_status
# }