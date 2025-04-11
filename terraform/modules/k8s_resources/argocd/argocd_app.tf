# modules/k8s_resources/argocd/argocd_app.tf

# Root Application for App of Apps pattern
resource "kubectl_manifest" "argocd_root_application" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = var.app_name
      namespace  = var.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      
      # Source configuration points to the directory containing app definitions
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_target_revision
        path           = var.apps_of_apps_path # Directory containing child app definitions
      }
      
      # Destination defines where the APPLICATION RESOURCES will be synchronized to
      # (This is where the child Application CRs will be created)
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.argocd_namespace # Child Application CRs will be created in ArgoCD namespace
      }
      
      # Sync policy for root application
      syncPolicy = {
        automated = {
          prune     = true
          selfHeal  = true
          allowEmpty = true # Important for app of apps - allows deletion of all child apps if needed
        }
        
        syncOptions = [
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "RespectIgnoreDifferences=true"
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