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
      url      = var.gitops_repo_url
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
    apiVersion = "helm.toolkit.fluxcd.io/v2beta2"  # Updated to v2beta2
    kind       = "HelmRelease"
    metadata = {
      name      = var.helm_release_name
      namespace = var.flux_namespace
    }
    spec = {
      interval = var.sync_interval
      targetNamespace = var.app_namespace
      chart = {
        spec = {
          chart = var.helm_chart_path
          sourceRef = {
            kind = "GitRepository"
            name = var.gitops_repo_name
          }
        }
      }
      # Use values.yaml from the Git repository (uncomment to use custom values applied by terraform)
      # values = {
      #   replicaCount = var.app_replica_count
      #   agentName    = var.app_agent_name
      #   flaskEnv     = var.app_env
      #   nodePort     = var.service_port
      # }
      install = {
        createNamespace = true
        remediation = {
          retries = 3
        }
      }
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