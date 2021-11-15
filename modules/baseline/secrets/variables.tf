variable "conf" {
  type = object({
    secrets = object({
      data = object({
        age = object({
          keys_file_base64 = string
        })
        docker = object({
          credentials_write = string
          registry_name     = string
          server_url        = string
        })
        git = object({
          domain          = string
          known_hosts     = string
          private_key_pem = string
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
