# modules/k8s_resources/flux/main.tf
# Contains core Flux installation resources

# Create the flux-system namespace
resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = var.flux_namespace
  }
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

resource "kubernetes_secret" "flux_gitlab_auth" {
  metadata {
    name      = "flux-gitlab-auth"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }

  # For basic authentication with HTTP, we need username and password
  data = {
    username = var.flux_gitlab_username
    password = var.flux_gitlab_token
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.flux_system]
}
