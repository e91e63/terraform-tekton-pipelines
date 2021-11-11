output "info" {
  value = {
    webhook_url   = local.webhook_url
    workflow_name = local.conf.workflow_name
  }
}
