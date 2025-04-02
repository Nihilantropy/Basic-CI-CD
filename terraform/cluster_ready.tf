# cluster_ready.tf - Place this in the root module
resource "null_resource" "cluster_ready_check" {
  depends_on = [module.cluster]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Starting Kubernetes cluster readiness check..."
      # Set kubeconfig from the cluster module
      export KUBECONFIG="${module.cluster.kubeconfig_path}"
      
      # Wait for all nodes to be ready
      echo "Waiting for all nodes to be ready..."
      MAX_RETRIES=20
      RETRY_INTERVAL=5
      
      for i in $(seq 1 $MAX_RETRIES); do
        # Check if all nodes are Ready
        READY_NODES=$(kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -o "True" | wc -l)
        TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
        
        echo "Attempt $i/$MAX_RETRIES: $READY_NODES out of $TOTAL_NODES nodes are ready"
        
        if [ "$READY_NODES" -eq "$TOTAL_NODES" ] && [ "$TOTAL_NODES" -gt 0 ]; then
          echo "All nodes are ready!"
          break
        fi
        
        if [ $i -eq $MAX_RETRIES ]; then
          echo "Exceeded maximum retries. Not all nodes are ready."
          exit 1
        fi
        
        echo "Waiting for nodes to be ready..."
        sleep $RETRY_INTERVAL
      done
      
      # Wait for CoreDNS to be ready (essential for K8s operations)
      echo "Waiting for CoreDNS to be ready..."
      for i in $(seq 1 $MAX_RETRIES); do
        READY_COREDNS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -o "True" | wc -l)
        TOTAL_COREDNS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | wc -l)
        
        echo "Attempt $i/$MAX_RETRIES: $READY_COREDNS out of $TOTAL_COREDNS CoreDNS pods are ready"
        
        if [ "$READY_COREDNS" -eq "$TOTAL_COREDNS" ] && [ "$TOTAL_COREDNS" -gt 0 ]; then
          echo "CoreDNS is ready!"
          break
        fi
        
        if [ $i -eq $MAX_RETRIES ]; then
          echo "Exceeded maximum retries. CoreDNS is not ready."
          exit 1
        fi
        
        echo "Waiting for CoreDNS to be ready..."
        sleep $RETRY_INTERVAL
      done
      
      # Final check - make an API call to validate connectivity
      echo "Performing final API connectivity check..."
      if kubectl get namespaces > /dev/null 2>&1; then
        echo "API server is responding correctly."
      else
        echo "API server is not responding correctly."
        exit 1
      fi
      
      echo "Cluster readiness check completed successfully."
    EOT
  }

  # This makes the resource always run
  triggers = {
    always_run = timestamp()
  }
}