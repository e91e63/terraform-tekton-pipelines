variable "conf" {
  type = object({
    name      = string
    namespace = string
    params = optional(list(object({
      default     = optional(string)
      description = string
      name        = string
    })))
    resourcetemplates = list(object({
      apiVersion = optional(string)
      kind       = string
      spec = object({
        pipelineRef = optional(object({
          name = string
        }))
        resources = optional(list(object({
          name = string
          resourceRef = optional(object({
            name = string
          }))
          resourceSpec = optional(object({
            params = optional(list(object({
              name  = string
              value = string
            })))
            type = string
          }))
        })))
        serviceAccountName = string
      })
    }))
  })
}
