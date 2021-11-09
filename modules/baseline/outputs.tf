output "secret_names" {
  value = {
    age_keys_file          = kubernetes_secret.age_keys_file.metadata[0].name
    terraform_remote_state = kubernetes_secret.terraform_remote_state.metadata[0].name
  }
}
