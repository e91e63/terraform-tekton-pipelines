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
      working_dir         = string
    })
    name      = optional(string)
    namespace = string
    secret_names = object({
      age_keys_file          = string
      terraform_remote_state = string
    })
    workspaces = optional(list(object({
      name      = string
      workspace = string
    })))
  })
}
