
variable "name" {
  type = string
}
variable "zone" {
  type = string
}
variable "instance_self_links" {
  type = list(string)
}
variable "named_ports" {
  type = list(object({
    name = string
    port = number
  }))
}