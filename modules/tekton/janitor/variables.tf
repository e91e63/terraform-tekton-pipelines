variable "conf" {
  type = object({
    name      = optional(string)
    namespace = string
    images = object({
      kubectl = string
    })
    service_accounts = object({
      janitor = string
    })
  })
}
