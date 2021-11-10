variable "conf" {
  type = object({
    name      = string
    namespace = string
    params = list(object({
      name  = string
      value = string
    }))
  })
}
