variable "conf" {
  type = object({
    name      = optional(string)
    namespace = string
  })
}
