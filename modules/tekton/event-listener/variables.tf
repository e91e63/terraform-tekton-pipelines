variable "conf" {
  type = object({
    name               = string
    namespace          = string
    serviceAccountName = string
    triggers = list(object({
      bindings = list(object({
        kind = optional(string)
        ref  = string
      }))
      interceptors = list(object({
        # due to terraform type limitations and multiple types for params.value, params must be any type
        params = any
        # params = list(object({
        #   name = string
        #   value = optional(object({
        #     secretKey  = string
        #     secretName = string
        #   }))
        #   value = string
        # }))
        ref = object({
          kind = string
          name = string
        })
      }))
      name = string
      template = object({
        ref = string
      })
    }))
  })
}
