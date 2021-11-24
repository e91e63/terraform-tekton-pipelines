variable "conf" {
  type = object({
    name      = string
    namespace = string
    spec = object({
      params = tuple([list(object({
        default     = optional(string)
        description = string
        name        = string
      }))])
      resourcetemplates = tuple([list(object({
        kind = string
        metadata = object({
          generateName = string
          namespace    = string
        })
        spec = object({
          params = tuple([list(object({
            name  = string
            value = string
          }))])
          pipelineRef = object({
            name = string
          })
          serviceAccountName = string
          workspaces = tuple([list(object({
            name = string
            volumeClaimTemplate = object({
              spec = object({
                accessModes = tuple([list(string)])
                resources = object({
                  requests = object({
                    storage = string
                  })
                })
              })
            })
          }))])
        })
      }))])
    })
  })
}
