variable "conf" {
  type = object({
    name      = string
    namespace = string
    params = list(object({
      default     = string
      description = string
      name        = string
      type        = string
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
      resources = object({
        inputs = list(object({
          name     = string
          resource = string
        }))
        outputs = list(object({
          name     = string
          resource = string
        }))
      })
      runAfter = optional(list(string))
      taskRef = {
        kind  = optional(string)
        value = string
      }
    }))
  })
}
