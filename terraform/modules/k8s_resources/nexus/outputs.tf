output "nexus_namespace" {
  description = "Name of the created Nexus namespace"
  value       = kubernetes_namespace.nexus.metadata[0].name
}

output "nexus_service_name" {
  description = "Name of the Nexus service"
  value       = kubernetes_service.nexus_headless.metadata[0].name
}

output "nexus_endpoint_ip" {
  description = "IP address used for the Nexus endpoint"
  value       = var.host_machine_ip
}
