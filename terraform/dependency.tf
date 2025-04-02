# dependency.tf (in root module)
resource "null_resource" "cluster_ready_check" {
  depends_on = [module.cluster]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Kubernetes cluster to be ready..."
      sleep 10
      export KUBECONFIG=${module.cluster.kubeconfig_path}
      kubectl get nodes
      echo "Kubernetes cluster is ready!"
    EOT
  }

  # This ensures it runs every time
  triggers = {
    always_run = "${timestamp()}"
  }
}