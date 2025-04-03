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
  default     = "~/.kube/config"
}

# GitOps repository variables

variable "gitops_repo_url" {
  description = "URL of the Git repository containing GitOps configuration"
  type        = string
}

variable "gitops_repo_branch" {
  description = "Branch of the GitOps repository to use"
  type        = string
  default     = "main"
}

variable "gitops_repo_name" {
  description = "Name for the Flux GitRepository resource"
  type        = string
  default     = "pipeline-project"
}

variable "sync_interval" {
  description = "Interval at which to sync the repo"
  type        = string
  default     = "1m"
}

# Helm release variables

variable "helm_release_name" {
  description = "Name of the HelmRelease to create"
  type        = string
  default     = "appflask"
}

variable "helm_chart_path" {
  description = "Path in the repository where the Helm chart is located"
  type        = string
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

# SSH key variables for GitLab access

variable "flux_private_key_path" {
  description = "Path to private SSH key for Flux GitLab access"
  type        = string
  default     = "~/.flux/keys/flux-gitlab"
}

variable "flux_public_key_path" {
  description = "Path to private SSH key for Flux GitLab access"
  type        = string
  default     = "~/.flux/keys/flux-gitlab.pub"
}

variable "flux_known_hosts_path" {
  description = "Path to known_hosts file for GitLab SSH verification"
  type        = string
  default     = "~/.flux/known_hosts"
}
