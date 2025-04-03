# modules/k8s_resources/nexus/main.tf

# Create Nexus namespace
resource "kubernetes_namespace" "nexus" {
  metadata {
    name = var.nexus_namespace
  }
}

# Create Nexus headless service
resource "kubernetes_service" "nexus_headless" {
  metadata {
    name      = var.service_name
    namespace = kubernetes_namespace.nexus.metadata[0].name
  }
  
  spec {
    selector = {}  # Empty selector for headless service
    
    port {
      port        = var.service_port
      target_port = var.service_port
      name        = "http"
      protocol    = "TCP"
    }
    
    cluster_ip = "None"  # This makes it a headless service
  }
}

# Create Nexus endpoint
resource "kubernetes_endpoints" "nexus_endpoint" {
  metadata {
    name      = var.service_name
    namespace = kubernetes_namespace.nexus.metadata[0].name
  }
  
  subset {
    address {
      ip = var.host_machine_ip  # Host machine IP where Nexus is running
    }
    
    port {
      port     = var.service_port
      name     = "http"
      protocol = "TCP"
    }
  }
}