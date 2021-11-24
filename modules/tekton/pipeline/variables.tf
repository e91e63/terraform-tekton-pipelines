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
      tasks = tuple([list(object({
        name = string
        params = tuple([list(object({
          name  = string
          value = string
        }))])
        runAfter = optional(tuple([list(string)]))
        taskRef = object({
          kind = optional(string)
          name = string
        })
        workspaces = optional(tuple([list(object({
          name      = string
          workspace = string
        }))]))
      }))])
      workspaces = optional(tuple([list(object({
        name = string
      }))]))
    })
  })
}
