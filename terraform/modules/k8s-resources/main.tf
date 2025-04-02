# modules/k8s-resources/main.tf
resource "kubernetes_namespace" "nexus" {
  metadata {
    name = var.nexus_namespace
  }

  depends_on = [var.cluster_ready]
}

resource "kubernetes_service" "nexus_headless" {
  metadata {
    name      = "nexus-service"
    namespace = kubernetes_namespace.nexus.metadata[0].name
  }
  
  spec {
    selector = {}  # Empty selector for headless service
    
    port {
      port        = 8082
      target_port = 8082
      name        = "http"
      protocol    = "TCP"
    }
    
    cluster_ip = "None"  # This makes it a headless service
  }

  depends_on = [var.cluster_ready]
}

resource "kubernetes_endpoints" "nexus_endpoint" {
  metadata {
    name      = "nexus-service"
    namespace = kubernetes_namespace.nexus.metadata[0].name
  }
  
  subset {
    address {
      ip = var.host_machine_ip  # Host machine IP where Nexus is running
    }
    
    port {
      port     = 8082
      name     = "http"
      protocol = "TCP"
    }
  }

  depends_on = [var.cluster_ready]
}