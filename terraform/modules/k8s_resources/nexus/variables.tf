# modules/k8s-resources/variables.tf
variable "nexus_namespace" {
  description = "Namespace for Nexus resources"
  type        = string
  default     = "nexus"
}

variable "service_name" {
  description = "Name of the Nexus headless service"
  type        = string
  default     = "nexus-service"
}

variable "service_port" {
  description = "Port for the Nexus service"
  type        = number
  default     = 8082
}

variable "host_machine_ip" {
  description = "IP address of host machine for Nexus endpoint"
  type        = string
}