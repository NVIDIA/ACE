
variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "port" {
  type = number
}

variable "protocol" {
  type = string
}

variable "instance_ids" {
  type = list(string)
}

variable "health_checks" {
  type = list(object({
    healthy_threshold   = number
    unhealthy_threshold = number
    interval            = number
    matcher             = string
    path                = string
    port                = number
    protocol            = string
    timeout             = number
  }))
}

variable "stickiness" {
  type = list(object({
    cookie_duration = number
    type            = string
    cookie_name     = string
    enabled         = bool
  }))
  default = []
}

variable "deregistration_delay" {
  type    = number
  default = 60
}