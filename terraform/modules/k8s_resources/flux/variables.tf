# modules/k8s_resources/flux/variables.tf

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
  default     = "appflask-source"
}

variable "gitops_kustomization_name" {
  description = "Name for the Flux Kustomization resource"
  type        = string
  default     = "appflask"
}

variable "gitops_app_path" {
  description = "Path within the GitOps repository where application manifests are stored"
  type        = string
}

variable "sync_interval" {
  description = "Interval at which to sync the repo"
  type        = string
  default     = "1m"
}