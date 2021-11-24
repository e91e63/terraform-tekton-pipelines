variable "conf" {
  type = object({
    description = string
    name        = string
    namespace   = string
    spec = object({
      params = tuple([list(object({
        default     = optional(string)
        description = string
        name        = string
        type        = optional(string)
      }))])
      results = optional(tuple([list(object({
        name        = string
        description = string
      }))]))
      steps = tuple([list(object({
        args    = optional(tuple([list(string)]))
        command = optional(tuple([string]))
        env = optional(tuple([list(object({
          name  = string
          value = optional(string)
          valueFrom = optional(object({
            secretKeyRef = object({
              name = string
              key  = string
            })
          }))
        }))]))
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
        volumeMounts = optional(tuple([list(object({
          name      = string
          mountPath = string
        }))]))
        workingDir = optional(string)
      }))])
      volumes = optional(tuple([list(object({
        name = string
        secret = object({
          secretName = string
        })
      }))]))
      workspaces = optional(tuple([list(object({
        name = string
      }))]))
    })
  })
}
