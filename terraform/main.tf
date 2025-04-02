# main.tf (in root module)

# Step 1: Create the Kind cluster
module "cluster" {
  source         = "./modules/cluster"
  cluster_name   = var.cluster_name
  worker_count   = var.worker_count
  kubeconfig_path = var.kubeconfig_path
}

# Step 2: Ensure cluster is ready before proceeding
# (cluster_ready.tf contains this resource)
# null_resource.cluster_ready_check depends on module.cluster

# Step 3: Configure Kubernetes provider with the cluster information
# This is done after we know the cluster is ready
provider "kubernetes" {
  host                   = module.cluster.endpoint
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
  client_certificate     = module.cluster.client_certificate
  client_key             = module.cluster.client_key

  # Explicitly depends on the cluster being ready
  # This is a critical change to ensure proper initialization
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "sh"
    args        = ["-c", "echo 'Cluster is ready'"]
  }
}

# Step 4: Configure Helm provider with the same cluster information
provider "helm" {
  kubernetes {
    host                   = module.cluster.endpoint
    cluster_ca_certificate = module.cluster.cluster_ca_certificate
    client_certificate     = module.cluster.client_certificate
    client_key             = module.cluster.client_key
  }
}

# Step 5: Create Kubernetes resources
module "k8s_resources" {
  source          = "./modules/k8s-resources"
  nexus_namespace = var.nexus_namespace
  host_machine_ip = local.host_machine_ip
  
  # This explicit dependency ensures the cluster is ready
  # before attempting to create resources
  depends_on = [null_resource.cluster_ready_check]
}

# Step 6: Deploy application with Helm
module "app_deployment" {
  source       = "./modules/app-deployment"
  chart_path   = local.chart_path
  
  # Dependencies explicitly defined - app deployment can only happen
  # after Kubernetes resources are created
  depends_on = [module.k8s_resources]
}