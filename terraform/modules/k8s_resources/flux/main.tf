# modules/k8s_resources/flux/main.tf
# Contains core Flux installation resources

# Create the flux-system namespace
resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = var.flux_namespace
  }
}

# Create a secret for GitLab SSH access
resource "kubernetes_secret" "flux_gitlab_ssh" {
  metadata {
    name      = "flux-gitlab-ssh"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }

  data = {
    "identity"    = file(var.flux_private_key_path)
    "identity.pub" = file(var.flux_public_key_path)
    "known_hosts" = file(var.flux_known_hosts_path)
  }

  depends_on = [kubernetes_namespace.flux_system]
}

# Install Flux using Helm
resource "helm_release" "flux" {
  name       = "flux"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  namespace  = kubernetes_namespace.flux_system.metadata[0].name
  version    = var.flux_version
  
  set {
    name  = "installCRDs"
    value = "true"
  }

  wait    = true
  timeout = var.helm_timeout

  depends_on = [kubernetes_namespace.flux_system]
}