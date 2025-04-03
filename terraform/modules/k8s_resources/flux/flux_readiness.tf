# modules/k8s_resources/flux/flux_readiness.tf
# Ensures Flux CRDs are available before attempting to create custom resources

# Wait for Flux CRDs to be ready
resource "null_resource" "wait_for_flux_crds" {
  depends_on = [helm_release.flux]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Waiting for Flux CRDs to be available..."
      
      # Access kubeconfig directly from the environment where it was created
      KUBECONFIG_PATH="${var.kubeconfig_path}"
      
      # If it's an absolute path, use it directly
      if [[ "$${KUBECONFIG_PATH}" == /* ]]; then
        export KUBECONFIG="$${KUBECONFIG_PATH}"
      # If it has a tilde, expand it
      elif [[ "$${KUBECONFIG_PATH}" == ~/* ]]; then
        export KUBECONFIG="$${KUBECONFIG_PATH/#~/$${HOME}}"
      # If it's relative, make it relative to the terraform execution directory
      else
        export KUBECONFIG="$(pwd)/$${KUBECONFIG_PATH}"
      fi
      
      echo "Using kubeconfig at: $${KUBECONFIG}"
      
      # Verify kubeconfig is accessible
      if [ ! -f "$${KUBECONFIG}" ]; then
        echo "ERROR: Kubeconfig file not found at $${KUBECONFIG}"
        echo "Current directory: $(pwd)"
        echo "Attempting to locate the file..."
        
        # Try common alternative locations
        POSSIBLE_LOCATIONS=(
          "$${HOME}/.kube/config-tf-local"
          "$(pwd)/.kube/config-tf-local"
          "$(pwd)/../.kube/config-tf-local"
          "$(pwd)/../../.kube/config-tf-local"
          "/home/crea/.kube/config-tf-local"
          "/home/crea/Desktop/Basic-CI-CD/.kube/config-tf-local"
        )
        
        for LOCATION in "$${POSSIBLE_LOCATIONS[@]}"; do
          if [ -f "$${LOCATION}" ]; then
            echo "Found kubeconfig at: $${LOCATION}"
            export KUBECONFIG="$${LOCATION}"
            break
          fi
        done
        
        if [ ! -f "$${KUBECONFIG}" ]; then
          # Last resort: try to find it using find command
          echo "Searching for kubeconfig file..."
          REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "/home/crea/Desktop/Basic-CI-CD")
          FOUND_CONFIG=$(find "$${REPO_ROOT}" -name "*config-tf-local*" -type f 2>/dev/null | head -1)
          if [ -n "$${FOUND_CONFIG}" ]; then
            echo "Found kubeconfig at: $${FOUND_CONFIG}"
            export KUBECONFIG="$${FOUND_CONFIG}"
          else
            echo "Failed to locate kubeconfig file."
            exit 1
          fi
        fi
      fi
      
      # Test kubectl connectivity
      echo "Testing kubectl connectivity..."
      kubectl cluster-info || { echo "Failed to connect to cluster"; exit 1; }
      
      # Function to check if a CRD exists
      check_crd() {
        kubectl get crd $1 &>/dev/null
        return $?
      }
      
      # List of required CRDs
      CRDS=(
        "gitrepositories.source.toolkit.fluxcd.io"
        "helmreleases.helm.toolkit.fluxcd.io"
        "kustomizations.kustomize.toolkit.fluxcd.io"
      )
      
      # Maximum number of retries
      MAX_RETRIES=30
      RETRY_INTERVAL=10
      
      for CRD in "$${CRDS[@]}"; do
        echo "Checking for CRD: $${CRD}"
        for i in $(seq 1 $MAX_RETRIES); do
          if check_crd $${CRD}; then
            echo "CRD $${CRD} is available."
            break
          fi
          
          if [ $i -eq $MAX_RETRIES ]; then
            echo "Timed out waiting for CRD $${CRD}."
            exit 1
          fi
          
          echo "CRD $${CRD} not yet available. Waiting $${RETRY_INTERVAL} seconds... (Attempt $i/$${MAX_RETRIES})"
          sleep $${RETRY_INTERVAL}
        done
      done
      
      echo "All required Flux CRDs are available."
      echo "Waiting an additional 10 seconds for CRD controllers to be fully ready..."
      sleep 10
    EOT
  }

  triggers = {
    helm_release_id = helm_release.flux.id
  }
}