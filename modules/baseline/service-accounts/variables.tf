variable "conf" {
  type = object({
    namespace = string
    secrets   = map(map(string))
    service_accounts = optional(object({
      janitor  = optional(string)
      triggers = optional(string)
      workers  = optional(string)
    }))
  })
}
