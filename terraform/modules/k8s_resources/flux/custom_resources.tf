# Use kubectl_manifest instead of kubernetes_manifest
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
        name = kubernetes_secret.flux_gitlab_ssh.metadata[0].name
      }
      ref = {
        branch = var.gitops_repo_branch
      }
    }
  })

  depends_on = [null_resource.wait_for_flux_crds]
  
  # The kubectl provider has built-in wait/retry functionality
  wait = true
  server_side_apply = true
}

# Similarly replace other kubernetes_manifest resources
resource "kubectl_manifest" "git_repository_tag_tracking" {
  yaml_body = yamlencode({
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = "${var.gitops_repo_name}-tags"
      namespace = var.flux_namespace
    }
    spec = {
      interval = var.sync_interval
      url      = var.gitops_repo_url
      secretRef = {
        name = kubernetes_secret.flux_gitlab_ssh.metadata[0].name
      }
      ref = {
        # For numeric tags, we can use semver with custom sorting
        semver = ">0.0.0-0" # This matches any tag and will sort numerically
      }
    }
  })

  depends_on = [null_resource.wait_for_flux_crds]
  wait = true
  server_side_apply = true
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
          chart = var.helm_chart_path
          sourceRef = {
            kind = "GitRepository"
            name = "${var.gitops_repo_name}-tags"
          }
          interval = var.sync_interval
        }
      }
      upgrade = {
        remediation = {
          remediateLastFailure = true
        }
      }
      install = {
        remediation = {
          retries = 3
        }
      }
      values = {
        replicaCount = var.app_replica_count
        agentName    = var.app_agent_name
      }
    }
  })

  depends_on = [kubectl_manifest.git_repository_tag_tracking]
  wait = true
  server_side_apply = true
}