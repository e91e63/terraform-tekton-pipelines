variable "conf" {
  type = object({
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
      git_repo            = string
      git_repo_code       = string
      git_repo_code_url   = string
      git_repo_infra      = string
      git_repo_infra_url  = string
      version_tag         = string
      webhook_token       = string
    })
    name          = string
    namespace     = string
    pipeline_name = optional(string)
    tasks = object({
      build  = string
      deploy = string
      tests  = string
    })
    service_accounts = object({
      triggers = string
      workers  = string
    })
    webhooks_subdomain = string
    workflow_name      = string
  })
}

variable "domain_info" {
  type = any
}
