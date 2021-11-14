module "janitor" {
  source = "./janitor"

  conf = {
    name      = var.conf.janitor_name
    namespace = var.conf.namespace
  }
}

module "triggers" {
  source = "./triggers"

  conf = {
    name      = var.conf.triggers_name
    namespace = var.conf.namespace
  }
}

module "workers" {
  source = "./workers"

  conf = {
    secret_names = var.conf.secret_names
    name         = var.conf.workers_name
    namespace    = var.conf.namespace
  }
}
