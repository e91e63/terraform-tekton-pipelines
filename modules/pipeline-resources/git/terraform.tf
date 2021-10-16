terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.5.0"
    }
  }
}
