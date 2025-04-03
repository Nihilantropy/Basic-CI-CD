# modules/k8s_resources/flux/main.tf

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
  
  # Core Flux configuration
  set {
    name  = "installCRDs"
    value = "true"
  }

  # Wait for Flux to be fully installed
  wait    = true
  timeout = var.helm_timeout

  depends_on = [kubernetes_namespace.flux_system]
}

# Configure Flux Git Repository
resource "kubernetes_manifest" "flux_git_repository" {
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = var.gitops_repo_name
      namespace = var.flux_namespace
    }
    spec = {
      interval = var.sync_interval
      url      = var.gitops_repo_url
      ref = {
        branch = var.gitops_repo_branch
      }
    }
  }

  depends_on = [helm_release.flux]
}

# Configure Flux Kustomization
resource "kubernetes_manifest" "flux_kustomization" {
  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = var.gitops_kustomization_name
      namespace = var.flux_namespace
    }
    spec = {
      interval = var.sync_interval
      path     = var.gitops_app_path
      prune    = true
      sourceRef = {
        kind = "GitRepository"
        name = var.gitops_repo_name
      }
      timeout = "2m"
    }
  }

  depends_on = [kubernetes_manifest.flux_git_repository]
}