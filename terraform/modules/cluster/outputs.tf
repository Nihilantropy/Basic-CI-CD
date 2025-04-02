# modules/cluster/outputs.tf
output "cluster_name" {
  description = "Name of the created Kubernetes cluster"
  value       = kind_cluster.local.name
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = local_file.kubeconfig.filename
}

output "endpoint" {
  description = "Kubernetes API server endpoint"
  value       = kind_cluster.local.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = kind_cluster.local.cluster_ca_certificate
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate"
  value       = kind_cluster.local.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key"
  value       = kind_cluster.local.client_key
  sensitive   = true
}