# modules/k8s_resources/argocd/variables.tf

# ArgoCD installation variables
variable "argocd_namespace" {
  description = "Namespace for ArgoCD installation"
  type        = string
  default     = "argocd"
}

variable "argocd_version" {
  description = "Version of ArgoCD Helm chart to install"
  type        = string
  default     = "7.8.23"  # Use a specific version for consistency
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 600  # ArgoCD can take time to initialize
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
}

variable "argocd_ui_nodeport" {
  description = "NodePort for accessing the ArgoCD UI"
  type        = number
  default     = 30888  # Consider your port allocation strategy
}

# GitOps repository variables
variable "gitops_repo_url" {
  description = "URL of the Git repository containing GitOps configuration"
  type        = string
}


variable "gitops_repo_target_revision" {
  description = "Branch, tag, or commit to use from the repository"
  type        = string
  default     = "argocd"  # Match your Flux configuration
}

# App-of-Apps configuration
variable "app_name" {
  description = "Name of the app-of-apps CR"
  type        = string
  default     = "app-of-apps"
}

# App-of-Apps deployment variables
variable "app_namespace" {
  description = "Namespace where the app-of-apps should be deployed"
  type        = string
  default     = "argo-app-of-apps"
}

variable "sync_policy_automated" {
  description = "Whether to enable automated sync"
  type        = bool
  default     = true
}

variable "sync_policy_prune" {
  description = "Whether to prune resources when syncing"
  type        = bool
  default     = true
}

variable "sync_policy_self_heal" {
  description = "Whether to enable self-healing"
  type        = bool
  default     = true
}

# GitLab access
variable "argocd_gitlab_username" {
  description = "GitLab username for authentication"
  type        = string
  default     = "oauth2"
}

variable "argocd_gitlab_token" {
  description = "GitLab access token for authentication"
  type        = string
  sensitive   = true
}

# App of Apps configuration
variable "apps_of_apps_path" {
  description = "Path in the repository to the App of Apps directory"
  type        = string
  default     = "argocd-apps/apps"
}