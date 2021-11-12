terraform {
  experiments = [module_variable_optional_attrs]
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
  required_version = "~> 1"
}
