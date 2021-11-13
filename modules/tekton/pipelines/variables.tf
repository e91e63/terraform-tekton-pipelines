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
    resources = list(object({
      name = string
      type = string
    }))
    tasks = list(object({
      name = string
      params = list(object({
        name  = string
        value = string
      }))
      resources = optional(object({
        inputs = optional(list(object({
          name     = string
          resource = string
        })))
        outputs = optional(list(object({
          name     = string
          resource = string
        })))
      }))
      runAfter = optional(list(string))
      taskRef = object({
        kind = optional(string)
        name = string
      })
      workspaces = optional(list(object({
        name      = string
        workspace = string
      })))
    }))
    workspaces = optional(list(object({
      name = string
    })))
  })
}
