variable "default_mac" {
  type    = string
  default = null
}

variable "default_image_name" {
  type = string
}

variable "default_flavor_id" {
  type = string
}

variable "default_network_id" {
  type = string
}

variable "default_key_pair" {
  type = string
}

variable "default_security_groups" {
  type = list(string)
}

variable "default_disks" {
  type = list(object({
    name = string
    size = number
  }))
}

variable "default_user_data" {
  type        = string
  description = "Default cloud-init user data"
  default     = null
}

variable "vms" {
  type = map(object({
    mac             = optional(string)
    image_name      = optional(string)
    flavor_id       = optional(string)
    network_id      = optional(string)
    key_pair        = optional(string)
    security_groups = optional(list(string))
    disks = optional(list(object({
      name = string
      size = number
    })))
    user_data = optional(string) # Per-VM cloud-init override
  }))
}
