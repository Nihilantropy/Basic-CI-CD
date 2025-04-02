# modules/app-deployment/variables.tf
variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "appflask"
}

variable "namespace" {
  description = "Kubernetes namespace for deployment"
  type        = string
}

variable "chart_path" {
  description = "Path to the Helm chart"
  type        = string
}

# variable "replica_count" {
#   description = "Number of replicas"
#   type        = number
#   default     = 2
# }

# variable "agent_name" {
#   description = "Name displayed in the application's greeting"
#   type        = string
#   default     = "Terraform Agent"
# }

# variable "app_version" {
#   description = "Version of the application to deploy"
#   type        = string
#   default     = "latest"
# }

# variable "flask_env" {
#   description = "Flask environment"
#   type        = string
#   default     = "production"
# }

# variable "node_port" {
#   description = "NodePort for exposing the service"
#   type        = number
#   default     = 30080
# }

variable "dependencies" {
  description = "Resources this module depends on"
  type        = any
  default     = []
}