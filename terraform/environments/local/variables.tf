# environments/local/variables.tf
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "basic-cicd-local"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 1
}

variable "kubeconfig_path" {
  description = "Path to save the kubeconfig file"
  type        = string
  default     = "~/.kube/config-tf-local"
}

variable "host_machine_ip" {
  description = "IP address of the host machine for Nexus endpoint"
  type        = string
}

variable "nexus_namespace" {
  description = "Namespace for Nexus resources"
  type        = string
  default     = "nexus"
}
