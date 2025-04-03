# modules/cluster/versions.tf
terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
    }
    local = {
      source  = "hashicorp/local"
    }
  }
}