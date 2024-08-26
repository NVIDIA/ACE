
variable "lb_arn" {
  type = string
}

variable "port" {
  type = number
}

variable "protocol" {
  type = string
}

variable "ssl_policy" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "default_action" {
  type = string
}

variable "fixed_response_action_configs" {
  type = object({
    content_type = string
    status_code  = number
  })
  default = {
    content_type = "text/plain"
    status_code  = 404
  }
}

variable "redirect_action_configs" {
  type = object({
    port        = number
    protocol    = string
    status_code = string
  })
  default = {
    port        = 443
    protocol    = "HTTPS"
    status_code = "HTTP_301"
  }
}

variable "forward_action_configs" {
  type = object({
    target_group_arn = string
  })
  default = {
    target_group_arn = ""
  }
}