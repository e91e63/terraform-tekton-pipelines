variable "conf" {
  type = object({
    description = string
    name        = string
    namespace   = string
    params = list(object({
      default     = optional(string)
      description = string
      name        = string
      type        = optional(string)
    }))
    results = optional(list(object({
      name        = string
      description = string
    })))
    steps = list(object({
      args    = optional(list(string))
      command = optional(list(string))
      env = optional(list(object({
        name  = string
        value = optional(string)
        valueFrom = optional(object({
          secretKeyRef = object({
            name = string
            key  = string
          })
        }))
      })))
      image = string
      name  = string
      resources = optional(object({
        limits = optional(object({
          cpu    = string
          memory = string
        }))
        requests = optional(object({
          cpu    = string
          memory = string
        }))
      }))
      script = optional(string)
      volumeMounts = optional(list(object({
        name      = string
        mountPath = string
      })))
      workingDir = optional(string)
    }))
    volumes = optional(list(object({
      name = string
      secret = object({
        secretName = string
      })
    })))
    workspaces = optional(list(object({
      name = string
    })))
  })
}
