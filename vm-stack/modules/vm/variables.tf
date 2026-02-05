variable "name" {
  type = string
}

variable "mac_address" {
  type    = string
  default = null
}

variable "image_name" {
  type = string
}

variable "flavor_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "key_pair" {
  type = string
}

variable "security_groups" {
  type    = list(string)
  default = []
}

variable "disks" {
  type    = list(object({ name = string, size = number }))
  default = []
}

variable "user_data" {
  type        = string
  description = "Cloud-init user data for the VM"
  default     = null
}