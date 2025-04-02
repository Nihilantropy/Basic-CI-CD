# modules/cluster/provider_config.tf
# This file helps with initialization of Kubernetes providers
# after the cluster is available

# Create a data structure that can be used by Kubernetes providers
# to ensure they have correct configuration
output "provider_config" {
  description = "Configuration information for downstream Kubernetes providers"
  value = {
    host                   = kind_cluster.local.endpoint
    cluster_ca_certificate = kind_cluster.local.cluster_ca_certificate
    client_certificate     = kind_cluster.local.client_certificate
    client_key             = kind_cluster.local.client_key
  }
  sensitive = true
}