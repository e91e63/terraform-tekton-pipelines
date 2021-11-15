output "info" {
  value = merge(
    local.conf,
    {
      tasks = {
        build     = module.task_build_kaniko.info.name
        deploy    = module.task_deploy_terragrunt.info.name
        git_clone = module.task_git_clone.info.name
      }
      secrets          = module.secrets.info
      service_accounts = module.service_accounts.info
    },
  )
}
