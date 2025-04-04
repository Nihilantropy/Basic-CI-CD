# modules/k8s_resources/argocd/argocd_app.tf

# Define an ArgoCD Application CR 
# This will be managed by the kubectl provider since the Application CRD is installed by ArgoCD

resource "kubectl_manifest" "argocd_application" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = var.app_name
      namespace  = var.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]  # Enable cascade deletion
    }
    spec = {
      project = "default"  # Use the default project for simplicity
      
      # Source defines where to get the application manifests from
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_target_revision
        path           = var.gitops_repo_path
        helm = {
          # Override values.yaml from the Helm chart
          parameters = [
            {
              name  = "replicaCount"
              value = tostring(var.app_replica_count)
            },
            {
              name  = "agentName"
              value = var.app_agent_name
            },
            {
              name  = "flaskEnv"
              value = var.app_env
            },
            {
              name  = "nodePort"
              value = tostring(var.app_nodeport)
            }
          ]
        }
      }
      
      # Destination defines where the application will be deployed
      destination = {
        server    = "https://kubernetes.default.svc"  # In-cluster deployment
        namespace = var.app_namespace
      }
      
      # Sync policy defines how ArgoCD should sync the application
      syncPolicy = {
        automated = var.sync_policy_automated ? {
          prune    = var.sync_policy_prune
          selfHeal = var.sync_policy_self_heal
        } : null
        
        syncOptions = [
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]
        
        retry = {
          limit = 5
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "3m"
          }
        }
      }
    }
  })

  depends_on = [
    null_resource.wait_for_argocd,
    kubernetes_secret.argocd_repo_creds
  ]
}