# variable "conf" {
#   type = object({
#     description = string
#     name        = string
#     namespace   = string
#     params = optional(list(object({
#       default     = optional(string)
#       description = string
#       name        = string
#       type        = string
#     })))
#     resources = object({
#       inputs = optional(list(object({
#         name = string
#         type = string
#       })))
#       outputs = optional(list(object({
#         name = string
#         type = string
#       })))
#     })
#     results = optional(list(object({
#       name        = string
#       description = string
#     })))
#     steps = list(object({
#       args    = optional(list(string))
#       command = optional(list(string))
#       env = optional(list(object({
#         name  = string
#         value = string
#       })))
#       image = string
#       name  = string
#     }))
#   })
# }
