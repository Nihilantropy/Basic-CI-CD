# modules/app-deployment/variables.tf
variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "appflask"
}

variable "chart_path" {
  description = "Path to the Helm chart"
  type        = string
}

variable "dependencies" {
  description = "Resources this module depends on"
  type        = any
  default     = []
}