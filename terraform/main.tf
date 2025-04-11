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

provider "kubectl" {
  host                   = module.cluster.endpoint
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
  client_certificate     = module.cluster.client_certificate
  client_key             = module.cluster.client_key
  load_config_file       = false
}

# Step 5: Create Kubernetes resources
module "nexus" {
  source          = "./modules/k8s_resources/nexus"
  nexus_namespace = var.nexus_namespace
  host_machine_ip = local.host_machine_ip
  service_name    = "nexus-service"
  service_port    = 8082
  
  depends_on = [null_resource.cluster_ready_check]
}


# Step 6: Install Flux
# module "flux" {
#   source                 = "./modules/k8s_resources/flux"
#   flux_namespace         = "flux-system"
#   kubeconfig_path        = abspath(module.cluster.kubeconfig_path)
#   flux_gitlab_token      = chomp(file("~/.tokens/gitlab/gitlab.local/flux/flux.token"))
#   gitops_repo_url        = "http://${local.host_machine_ip}:8080/pipeline-project-group/pipeline-project.git"

#   depends_on = [
#     null_resource.cluster_ready_check,
#     module.nexus
#   ]
# }

# Step 7: Install ArgoCD 
module "argocd" {
  source                 = "./modules/k8s_resources/argocd"
  host_machine_ip        = local.host_machine_ip
  kubeconfig_path        = abspath(module.cluster.kubeconfig_path)
  argocd_gitlab_token    = chomp(file("~/.tokens/gitlab/gitlab.local/personal/root.token"))
  gitops_repo_url        = "http://${local.host_machine_ip}:8080/pipeline-project-group/pipeline-project.git"
  
  # Customize ArgoCD and application settings
  argocd_ui_nodeport     = 30888  # Choose an available NodePort for ArgoCD UI
  
  depends_on = [
    null_resource.cluster_ready_check,
    module.nexus
  ]
}