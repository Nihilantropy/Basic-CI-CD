# In modules/k8s_resources/flux/custom_resources.tf
resource "kubectl_manifest" "flux_git_repository" {
  yaml_body = yamlencode({
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = var.gitops_repo_name
      namespace = var.flux_namespace
    }
    spec = {
      interval = var.sync_interval
      url      = var.gitops_repo_url  # Use just the base URL without credentials
      secretRef = {
        name = kubernetes_secret.flux_gitlab_auth.metadata[0].name
      }
      ref = {
        branch = var.gitops_repo_branch
      }
    }
  })

  depends_on = [null_resource.wait_for_flux_crds, kubernetes_secret.flux_gitlab_auth]
  wait = true
  server_side_apply = true
  force_conflicts = true
}

resource "kubectl_manifest" "flux_helm_release" {
  yaml_body = yamlencode({
    apiVersion = "helm.toolkit.fluxcd.io/v2beta1"
    kind       = "HelmRelease"
    metadata = {
      name      = var.helm_release_name
      namespace = var.flux_namespace
    }
    spec = {
      interval = var.sync_interval
      chart = {
        spec = {
          chart = var.helm_chart_path  # Path to helm chart in the repo
          sourceRef = {
            kind = "GitRepository"
            name = var.gitops_repo_name
          }
        }
      }
      # Values to use for the Helm chart
      values = {
        replicaCount = var.app_replica_count
        agentName    = var.app_agent_name
        flaskEnv     = "production"
        nodePort     = 30080
        # This can include any values you want to set
      }
      # Install or upgrade configuration
      install = {
        createNamespace = true
        remediation = {
          retries = 3
        }
      }
      # Automatic upgrades when source changes
      upgrade = {
        remediation = {
          remediateLastFailure = true
        }
      }
    }
  })

  depends_on = [kubectl_manifest.flux_git_repository]
  wait = true
  server_side_apply = true
}