variable "conf" {
  type = object({
    secrets = object({
      data = object({
        age = object({
          keys_file_base64 = string
        })
        docker = object({
          credentials_write = string
          server_url        = string
        })
        git_ssh_key = object({
          domain             = string
          known_hosts        = string
          private_key_base64 = string
        })
        gpg = object({
          key_id             = string
          private_key_base64 = string
          trust_level_base64 = string
        })
        terraform_remote_state = object({
          access_key_id     = string
          secret_access_key = string
        })
      })
    })
    namespace = string
  })
}
