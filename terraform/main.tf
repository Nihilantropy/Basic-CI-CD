# main.tf (in root module)
module "cluster" {
  source         = "./modules/cluster"
  cluster_name   = var.cluster_name
  worker_count   = var.worker_count
  kubeconfig_path = var.kubeconfig_path
}

module "k8s_resources" {
  source          = "./modules/k8s-resources"
  nexus_namespace = var.nexus_namespace
  app_namespace   = var.app_namespace
  host_machine_ip = local.host_machine_ip
  # Pass the cluster_ready reference
  # Removed cluster_ready as it is not expected
  
  depends_on = [module.cluster, null_resource.cluster_ready_check]
}

module "app_deployment" {
  source       = "./modules/app-deployment"
  # release_name = var.app_release_name
  namespace    = module.k8s_resources.app_namespace
  chart_path   = local.chart_path
  # replica_count = var.app_replica_count
  # agent_name    = var.app_agent_name
  # app_version   = var.app_version
  # flask_env     = var.flask_environment
  # node_port     = var.app_node_port
  
  # Pass the cluster_ready reference
  
  depends_on = [module.k8s_resources, null_resource.cluster_ready_check]
}

# Configure providers AFTER the null_resource has verified the cluster
provider "kubernetes" {
  host                   = module.cluster.endpoint
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
  client_certificate     = module.cluster.client_certificate
  client_key             = module.cluster.client_key
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.endpoint
    cluster_ca_certificate = module.cluster.cluster_ca_certificate
    client_certificate     = module.cluster.client_certificate
    client_key             = module.cluster.client_key
  }
}