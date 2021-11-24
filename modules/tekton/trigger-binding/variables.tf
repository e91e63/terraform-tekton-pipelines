variable "conf" {
  type = object({
    name      = string
    namespace = string
    spec = object({
      params = tuple([list(object({
        name  = string
        value = string
      }))])
    })
  })
}
