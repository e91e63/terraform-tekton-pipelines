variable "conf" {
  type = object({
    name      = string
    namespace = string
    params = list(object({
      default     = optional(string)
      description = string
      name        = string
    }))
    resourcetemplates = list(object({
      kind = string
      metadata = object({
        generateName = string
        namespace    = string
      })
      spec = object({
        params = list(object({
          name  = string
          value = string
        }))
        pipelineRef = object({
          name = string
        })
        serviceAccountName = string
        workspaces = list(object({
          name = string
          volumeClaimTemplate = object({
            spec = object({
              accessModes = list(string)
              resources = object({
                requests = object({
                  storage = string
                })
              })
            })
          })
        }))
      })
    }))
  })
}
