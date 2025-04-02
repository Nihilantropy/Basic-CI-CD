# modules/app-deployment/outputs.tf
# output "release_name" {
#   description = "Name of the Helm release"
#   value       = helm_release.appflask.name
# }

output "namespace" {
  description = "Namespace where the application is deployed"
  value       = helm_release.appflask.namespace
}

# output "version" {
#   description = "Version of the deployed application"
#   value       = var.app_version
# }

output "status" {
  description = "Status of the Helm release"
  value       = helm_release.appflask.status
}
