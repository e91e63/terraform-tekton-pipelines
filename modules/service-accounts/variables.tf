variable "conf" {
  type = object({
    namespace     = string
    secret_names  = any
    triggers_name = optional(string)
    workers_name  = optional(string)
  })
}
