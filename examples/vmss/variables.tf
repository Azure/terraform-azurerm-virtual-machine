variable "create_resource_group" {
  type     = bool
  default  = true
  nullable = false
}

variable "location" {
  type     = string
  default  = "eastus"
  nullable = false
}

variable "my_public_ip" {
  type    = string
  default = null
}

variable "resource_group_name" {
  type    = string
  default = null
}

variable "size" {
  type     = string
  default  = "Standard_F2"
  nullable = false
}
