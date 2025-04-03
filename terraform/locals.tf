# locals.tf
locals {
  kubeconfig_path  = module.cluster.kubeconfig_path
  chart_path       = "../helm/appflask"
  host_machine_ip  = var.host_machine_ip
}