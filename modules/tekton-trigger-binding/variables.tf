variable "trigger_binding_conf" {
  type = object({
    name      = string
    namespace = string
    params = list(object({
      name      = string
      namespace = string
    }))
  })
}
