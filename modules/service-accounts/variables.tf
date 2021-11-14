variable "conf" {
  type = object({
    namespace     = string
    secret_names  = any
    janitor_name  = optional(string)
    triggers_name = optional(string)
    workers_name  = optional(string)
  })
}
