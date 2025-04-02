# modules/k8s-resources/variables.tf
variable "nexus_namespace" {
  description = "Namespace for Nexus resources"
  type        = string
  default     = "nexus"
}

variable "host_machine_ip" {
  description = "IP address of host machine for Nexus endpoint"
  type        = string
}

variable "cluster_ready" {
  description = "Reference to the resource that indicates the cluster is ready"
  type        = any
  default     = null
}