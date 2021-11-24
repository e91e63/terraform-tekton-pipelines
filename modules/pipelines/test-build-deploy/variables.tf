variable "conf" {
  type = object({
    bindings = object({
      git_repo_infra_url = string
    })
    container_registry_endpoint = string
    interceptors = object({
      git = object({
        name        = string
        event_types = list(string)
      })
    })
    labels = object({
      context_path        = string
      context_path_code   = string
      context_path_infra  = string
      docker_image        = string
      docker_image_digest = string
      docker_image_url    = string
      git_clone_code      = string
      git_clone_infra     = string
      git_repo            = string
      git_repo_code       = string
      git_repo_code_name  = string
      git_repo_code_url   = string
      git_repo_infra      = string
      git_repo_infra_url  = string
      git_repo_url        = string
      git_repo_workspace  = string
      version_tag         = string
      webhook_token       = string
    })
    namespace     = string
    pipeline_name = optional(string)
    tasks = object({
      build     = string
      deploy    = string
      git_clone = string
      tests     = string
    })
    service_accounts = object({
      triggers = string
      workers  = string
    })
    webhooks = object({
      middlewares = list(map(string))
      subdomain   = string
    })
    workflow_name = string
  })
}

variable "domain_info" {
  type = any
}
