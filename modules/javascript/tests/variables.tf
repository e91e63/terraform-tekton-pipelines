variable "conf" {
  type = object({
    images = object({
      alpine  = string
      cypress = string
      node    = string
    })
    labels    = map(string)
    name      = string
    namespace = string
  })
}
