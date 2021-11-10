output "info" {
  value = {
    service_account_names = {
      triggers = module.triggers_service_account.info.name
      workers  = module.workers_service_account.info.name
    }
    secret_names = { age_keys_file = kubernetes_secret.age_keys_file.metadata[0].name
      terraform_remote_state = kubernetes_secret.terraform_remote_state.metadata[0].name
    }
  }
}
