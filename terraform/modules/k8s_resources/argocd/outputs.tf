# modules/k8s_resources/argocd/outputs.tf

output "argocd_namespace" {
  description = "The namespace where ArgoCD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "app_namespace" {
  description = "The namespace where the application is deployed"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}

output "argocd_ui_url" {
  description = "URL to access the ArgoCD UI"
  value       = "http://<node-ip>:${var.argocd_ui_nodeport}"
}

output "application_url" {
  description = "URL to access the deployed application"
  value       = "http://<node-ip>:${var.app_nodeport}"
}

output "argocd_server_service" {
  description = "Name of the ArgoCD server service"
  value       = "argocd-server.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local"
}

output "argocd_initial_password_command" {
  description = "Command to get the initial ArgoCD admin password"
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}