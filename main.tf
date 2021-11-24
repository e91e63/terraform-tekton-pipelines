terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
}

module "baseline" {
  source = "./modules/baseline"

  conf = var.conf
}

module "javascript" {
  source = "./modules/workflows/javascript"

  conf        = module.baseline.info
  domain_info = var.domain_info
}
