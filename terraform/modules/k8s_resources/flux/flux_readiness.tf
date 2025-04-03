# In modules/k8s_resources/flux/flux_readiness.tf
resource "null_resource" "wait_for_flux_crds" {
  depends_on = [helm_release.flux]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Waiting for Flux CRDs to be available..."
      export KUBECONFIG="${var.kubeconfig_path}"
      
      # Wait for GitRepository CRD specifically 
      for i in {1..30}; do
        if kubectl get crd gitrepositories.source.toolkit.fluxcd.io &> /dev/null; then
          echo "GitRepository CRD is available!"
          break
        fi
        
        if [ $i -eq 30 ]; then
          echo "Timed out waiting for GitRepository CRD"
          exit 1
        fi
        
        echo "Waiting for GitRepository CRD to be registered (attempt $i/30)..."
        sleep 10
      done
      
      # Additionally wait for the controller to be ready
      kubectl -n ${var.flux_namespace} wait deployment/source-controller --for=condition=Available=True --timeout=2m
      
      # Extra delay to ensure full readiness
      echo "CRDs found, waiting 15 more seconds for controllers to be fully operational..."
      sleep 15
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}