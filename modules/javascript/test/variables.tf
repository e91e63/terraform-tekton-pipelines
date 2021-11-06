variable "task_conf" {
  type = object({
    namespace = string
    images = object({
      alpine  = string
      cypress = string
      node    = string
    })
  })
}
