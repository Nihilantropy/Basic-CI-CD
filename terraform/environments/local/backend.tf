# environments/local/backend.tf
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}