variable "conf" {
  type = object({
    name      = string
    namespace = string
    spec = object({
      serviceAccountName = string
      triggers = tuple([list(object({
        bindings = tuple([list(object({
          kind = optional(string)
          ref  = string
        }))])
        interceptors = tuple([list(object({
          params = tuple([
            list(object({
              name  = string
              value = tuple([list(string)])
            })),
            list(object({
              name = string
              value = object({
                secretKey  = string
                secretName = string
              })
            })),
          ])
          ref = object({
            kind = string
            name = string
          })
        }))])
        name = string
        template = object({
          ref = string
        })
      }))])
    })
  })
}
