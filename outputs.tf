output "info" {
  sensitive = true
  value = {
    javascript = module.javascript.info
  }
}
