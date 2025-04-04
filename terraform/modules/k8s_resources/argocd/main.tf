# modules/k8s_resources/argocd/main.tf

# Create the argocd namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Create the application namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.app_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
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
  
  # Wait for installation to complete
  wait    = true
  timeout = var.helm_timeout

  depends_on = [kubernetes_namespace.argocd]
}

# Create the GitLab repository credentials secret
resource "kubernetes_secret" "argocd_repo_creds" {
  metadata {
    name      = "argocd-gitlab-auth"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = var.gitops_repo_url
    username      = var.argocd_gitlab_username
    password      = var.argocd_gitlab_token
  }

  depends_on = [helm_release.argocd]
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