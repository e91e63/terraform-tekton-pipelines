variable "conf" {
  type = object({
    images = object({
      alpine  = string
      cypress = string
      node    = string
    })
    labels        = map(string)
    namespace     = string
    workflow_name = string
    working_dir   = string
  })
}
