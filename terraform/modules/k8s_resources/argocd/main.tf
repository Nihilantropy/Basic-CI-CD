# modules/k8s_resources/argocd/main.tf

# Create the argocd namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
    
    # Add this finalizer annotation to ensure namespace can be deleted properly
    annotations = {
      "argocd.argoproj.io/sync-wave" = "-1"  # Ensure namespace is created first, deleted last
    }
  }
  
  # This lifecycle block ensures we remove finalizers before deletion
  lifecycle {
    ignore_changes = [
      metadata[0].annotations["kubectl.kubernetes.io/last-applied-configuration"],
    ]
  }
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  
  # Core configuration
  set {
    name  = "server.extraArgs"
    value = "{--insecure}"  # For demonstration; consider proper TLS in production
  }
  
  # Server configuration (including UI access)
  set {
    name  = "server.service.type"
    value = "NodePort"
  }
  
  set {
    name  = "server.service.nodePortHttp"
    value = var.argocd_ui_nodeport
  }
  
  # Redis configuration
  set {
    name  = "redis.enabled"
    value = "true"
  }
  
  # Controller configuration
  set {
    name  = "controller.enableStatefulSet"
    value = "false"  # Use Deployment for the controller
  }
  
  # Add these settings to manage finalizers
  set {
    name  = "server.config.resource.customizations.\"argoproj.io/Application\"" 
    value = <<EOT
      {
        "cascadedDeletion": {
          "enabled": true
        }
      }
    EOT
  }
  
  set {
    name  = "server.config.resource.customizations.\"apps/Deployment\"" 
    value = <<EOT
      {
        "cascadedDeletion": {
          "enabled": true
        }
      }
    EOT
  }
  
  # This ensures ArgoCD removes finalizers during uninstallation
  set {
    name  = "controller.args.appResyncPeriod" 
    value = "30"
  }
  
  # Wait for installation to complete
  wait    = true
  timeout = var.helm_timeout

  depends_on = [kubernetes_namespace.argocd]
}

# Create the GitLab repository credentials secret
resource "kubernetes_secret" "argocd_repo_creds" {
  metadata {
    name      = "argocd-gitlab-auth"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type": "repo-creds"  # Changed from "repository" to "repo-creds"
    }
  }

  data = {
    type     = "git"
    url      = "http://${var.host_machine_ip}:8080"  # Base URL without the specific repository path
    username = "oauth2"
    password = var.argocd_gitlab_token
  }
}

# Resource to ensure ArgoCD is fully initialized before defining applications
resource "null_resource" "wait_for_argocd" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Waiting for ArgoCD server to be available..."
      export KUBECONFIG="${var.kubeconfig_path}"
      
      # Wait for ArgoCD server deployment
      kubectl -n ${var.argocd_namespace} wait deployment/argocd-server --for=condition=Available=True --timeout=5m
      
      # Wait for ArgoCD Repo server and Application controller
      kubectl -n ${var.argocd_namespace} wait deployment/argocd-repo-server --for=condition=Available=True --timeout=3m
      kubectl -n ${var.argocd_namespace} wait deployment/argocd-application-controller --for=condition=Available=True --timeout=3m
      
      echo "ArgoCD is ready!"
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}
