# modules/app-deployment/main.tf
resource "helm_release" "appflask" {
  name       = var.release_name
  chart      = var.chart_path

  # Wait for resources to be ready
  wait       = true
  timeout    = 600  # 10 minutes
  
  # Dependencies
  depends_on = [var.dependencies]
}