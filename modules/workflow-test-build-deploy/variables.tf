variable "conf" {
  type = object({
    interceptors = object({
      git = object({
        name        = string
        event_types = list(string)
        secret_names = object({
          webhook_token     = string
          webhook_token_key = string
        })
      })
    })
    namespace = string
    tasks = object({
      build = object({
        images = object({
          kaniko = string
        })
      })
      deploy = object({
        images = object({
          terragrunt = string
        })
        secret_names = object({
          age_keys_file          = string
          terraform_remote_state = string
        })
      })
      test = object({
        images = object({
          default = string
        })
        steps = object({
          dependencies = object({
            image  = optional(string)
            script = string
          })
          fmt = object({
            image  = optional(string)
            script = string
          })
          lint = object({
            image  = optional(string)
            script = string
          })
          unit = object({
            image  = optional(string)
            script = string
          })
          e2e = object({
            image  = optional(string)
            script = string
          })
          version_tag = object({
            image  = optional(string)
            script = string
          })
        })
      })
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
