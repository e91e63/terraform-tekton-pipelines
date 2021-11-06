variable "pipeline_conf" {
  type = object({
    namespace = string
    tasks = object({
      test   = string
      build  = string
      deploy = string
    })
  })
}
