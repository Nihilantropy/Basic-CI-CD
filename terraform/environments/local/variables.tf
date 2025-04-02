# environments/local/variables.tf
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "basic-cicd-local"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
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

variable "app_namespace" {
  description = "Namespace for application deployment"
  type        = string
  default     = "appflask"
}

# variable "app_release_name" {
#   description = "Name for the Helm release"
#   type        = string
#   default     = "appflask-local"
# }

# variable "app_replica_count" {
#   description = "Number of application replicas"
#   type        = number
#   default     = 1
# }

# variable "app_agent_name" {
#   description = "Name displayed in application greeting"
#   type        = string
#   default     = "Local Terraform Agent"
# }

# variable "app_version" {
#   description = "Application version to deploy"
#   type        = string
#   default     = "latest"
# }

# variable "flask_environment" {
#   description = "Flask application environment"
#   type        = string
#   default     = "development"
# }

# variable "app_node_port" {
#   description = "NodePort for exposing the application"
#   type        = number
#   default     = 30080
# }