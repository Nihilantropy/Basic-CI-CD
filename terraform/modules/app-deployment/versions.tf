# modules/app-deployment/versions.tf
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
    }
  }
}