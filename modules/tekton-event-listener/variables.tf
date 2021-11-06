variable "event_listener_conf" {
  type = object({
    name                 = string
    namespace            = string
    service_account_name = string
    triggers = list(object({
      bindings = list(object({
        kind = string
        ref  = string
      }))
      interceptors = list(object({
        params = list(object({
          name  = string
          value = any
        }))
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
