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
    tasks = list(object({
      name = string
      params = list(object({
        name  = string
        value = string
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
