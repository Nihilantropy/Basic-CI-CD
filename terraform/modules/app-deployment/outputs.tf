# modules/app-deployment/outputs.tf

output "status" {
  description = "Status of the Helm release"
  value       = helm_release.appflask.status
}
