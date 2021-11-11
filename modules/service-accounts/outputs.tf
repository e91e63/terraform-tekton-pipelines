output "info" {
  value = {
    triggers = module.triggers.info.name
    workers  = module.workers.info.name
  }
}
