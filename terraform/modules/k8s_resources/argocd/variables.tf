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
  default     = "5.46.7"  # Use a specific version for consistency
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

# Application deployment variables
variable "app_namespace" {
  description = "Namespace where the application should be deployed"
  type        = string
  default     = "appflask-argo"  # Different from the Flux-managed namespace
}

variable "app_nodeport" {
  description = "NodePort for the application service"
  type        = number
  default     = 30180  # As requested, different from Flux deployment
}

# GitOps repository variables
variable "gitops_repo_url" {
  description = "URL of the Git repository containing GitOps configuration"
  type        = string
}

variable "gitops_repo_path" {
  description = "Path in the repository where the Helm chart is located"
  type        = string
  default     = "./helm/appflask"
}

variable "gitops_repo_target_revision" {
  description = "Branch, tag, or commit to use from the repository"
  type        = string
  default     = "helm-charts"  # Match your Flux configuration
}

# Application configuration
variable "app_name" {
  description = "Name of the Application CR"
  type        = string
  default     = "appflask-argo"
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
  default     = "oauth2"  # Similar to Flux configuration
}

variable "argocd_gitlab_token" {
  description = "GitLab access token for authentication"
  type        = string
  sensitive   = true
}

# Application-specific configuration
variable "app_replica_count" {
  description = "Number of application replicas to deploy"
  type        = number
  default     = 2
}

variable "app_agent_name" {
  description = "Agent name to display in the application"
  type        = string
  default     = "ArgoCD"
}

variable "app_env" {
  description = "Environment for the application (e.g., production, development)"
  type        = string
  default     = "production"
}