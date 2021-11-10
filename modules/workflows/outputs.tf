output "test" {
  value = module.javascript.test
}

output "info" {
  value = {
    javascript = module.javascript.info
  }
}
