# modules/k8s-resources/outputs.tf
output "nexus_namespace" {
  description = "Name of the created Nexus namespace"
  value       = kubernetes_namespace.nexus.metadata[0].name
}

output "app_namespace" {
  description = "Name of the created application namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "nexus_service_name" {
  description = "Name of the Nexus service"
  value       = kubernetes_service.nexus_headless.metadata[0].name
}