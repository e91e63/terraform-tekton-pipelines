output "info" {
  value = {
    janitor  = module.janitor.info.name
    triggers = module.triggers.info.name
    workers  = module.workers.info.name
  }
}
