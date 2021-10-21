terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
  }
}
