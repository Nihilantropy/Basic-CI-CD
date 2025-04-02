# modules/cluster/main.tf
resource "kind_cluster" "local" {
  name            = var.cluster_name
  wait_for_ready  = true
  kubeconfig_path = var.kubeconfig_path
  
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    
    node {
      role = "control-plane"
      
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }
    
    # Worker nodes
    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }
  }
}

# Add a local file resource to save kubeconfig
resource "local_file" "kubeconfig" {
  depends_on = [kind_cluster.local]
  content    = kind_cluster.local.kubeconfig
  filename   = var.kubeconfig_path
  file_permission = "0600"
}