# modules/k8s-resources/variables.tf
variable "nexus_namespace" {
  description = "Namespace for Nexus resources"
  type        = string
  default     = "nexus"
}

variable "app_namespace" {
  description = "Namespace for application deployment"
  type        = string
  default     = "appflask"
}

variable "host_machine_ip" {
  description = "IP address of host machine for Nexus endpoint"
  type        = string
}

# variable "flask_environment" {
#   description = "Flask application environment"
#   type        = string
#   default     = "production"
# }

variable "cluster_ready" {
  description = "Reference to the resource that indicates the cluster is ready"
  type        = any
  default     = null
}