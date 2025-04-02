# modules/cluster/variables.tf
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "basic-cicd-cluster"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "kubeconfig_path" {
  description = "Path to save the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}