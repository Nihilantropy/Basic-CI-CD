# modules/k8s_resources/flux/variables.tf

# Variables for Flux installation and configuration

variable "flux_namespace" {
  description = "Namespace for Flux installation"
  type        = string
  default     = "flux-system"
}

variable "flux_version" {
  description = "Version of Flux to install"
  type        = string
  default     = "2.12.2"
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 300
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "terra-home/.kube/config"
}

# GitOps repository variables

variable "gitops_repo_url" {
  description = "URL of the Git repository containing GitOps configuration"
  type        = string
  default     = "http://192.168.1.27:8080/pipeline-project-group/pipeline-project.git"
}

variable "gitops_repo_branch" {
  description = "Branch of the GitOps repository to use"
  type        = string
  default     = "argocd"
}

variable "gitops_repo_name" {
  description = "Name for the Flux GitRepository resource"
  type        = string
  default     = "pipeline-project"
}

variable "gitops_repo_tag" {
  description = "Tag to track in the GitOps repository (e.g., latest, TIMESTAMP)"
  type        = string
  default     = "latest"
  
}

variable "sync_interval" {
  description = "Interval at which to sync the repo"
  type        = string
  default     = "30s"
}

# Helm release variables

variable "helm_release_name" {
  description = "Name of the HelmRelease to create"
  type        = string
  default     = "flux-helm-release"
}

variable "helm_chart_path" {
  description = "Path in the repository where the Helm chart is located"
  type        = string
  default     = "./helm/appflask"
}

variable "app_namespace" {
  description = "Namespace where the application should be deployed"
  type        = string
  default     = "appflask"
}

variable "app_replica_count" {
  description = "Number of application replicas to deploy"
  type        = number
  default     = 2
}

variable "app_agent_name" {
  description = "Agent name to display in the application"
  type        = string
  default     = "TerraformFlux"
}

variable "app_env" {
  description = "Environment for the application (e.g., production, development)"
  type        = string
  default     = "production"
}

variable "service_port" {
  description = "NodePort for the application service"
  type        = number
  default     = 30080
}

# GitLab access

variable "flux_gitlab_username" {
  description = "GitLab username for authentication"
  type        = string
  default     = "oauth2"
}

variable "flux_gitlab_token" {
  description = "GitLab access token for authentication"
  type        = string
  sensitive   = true
}
