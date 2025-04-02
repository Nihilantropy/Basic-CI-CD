# modules/app-deployment/main.tf
resource "helm_release" "appflask" {
  name       = var.release_name
  chart      = var.chart_path
  namespace  = var.namespace
  
  # Set values from variables
  # set {
  #   name  = "replicaCount"
  #   value = var.replica_count
  # }
  
  # set {
  #   name  = "agentName"
  #   value = var.agent_name
  # }
  
  # set {
  #   name  = "appVersion"
  #   value = var.app_version
  # }
  
  # set {
  #   name  = "flaskEnv"
  #   value = var.flask_env
  # }
  
  # set {
  #   name  = "nodePort"
  #   value = var.node_port
  # }
  
  # Wait for resources to be ready
  wait       = true
  timeout    = 600  # 10 minutes
  
  # Dependencies
  depends_on = [var.dependencies]
}