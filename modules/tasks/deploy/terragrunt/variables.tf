variable "conf" {
  type = object({
    images = object({
      terragrunt = string
    })
    labels = object({
      age_keys_file       = string
      context_path        = string
      docker_image_digest = string
      git_repo            = string
      git_repo_workspace  = string
      gpg_key             = string
    })
    name      = optional(string)
    namespace = string
    secrets = object({
      names = object({
        age_keys_file          = string
        gpg_key                = string
        terraform_remote_state = string
      })
    })
    working_dir = string
    workspaces = optional(list(object({
      name      = string
      workspace = string
    })))
  })
}
