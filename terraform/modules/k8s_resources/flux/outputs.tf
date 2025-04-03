# modules/k8s_resources/flux/outputs.tf

output "flux_namespace" {
  description = "The namespace where Flux is installed"
  value       = kubernetes_namespace.flux_system.metadata[0].name
}

output "flux_status" {
  description = "Status of the Flux installation"
  value       = helm_release.flux.status
}

output "flux_installed" {
  description = "Whether Flux was successfully installed"
  value       = helm_release.flux.status == "deployed"
}

output "gitops_repo_name" {
  description = "Name of the configured GitRepository"
  value       = var.gitops_repo_name
}

output "gitops_kustomization_name" {
  description = "Name of the configured Kustomization"
  value       = var.gitops_kustomization_name
}