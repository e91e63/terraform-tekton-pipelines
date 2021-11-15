output "info" {
  value = {
    names = {
      age_keys_file          = kubernetes_secret.age_keys_file.metadata[0].name
      docker_credentials     = kubernetes_secret.docker_credentials.metadata[0].name
      git_ssh_key            = kubernetes_secret.git_ssh_key.metadata[0].name
      terraform_remote_state = kubernetes_secret.terraform_remote_state.metadata[0].name
    }
  }
}
