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

variable "resource_group_name" {
  type    = string
  default = null
}

variable "size" {
  type     = string
  default  = "Standard_F2"
  nullable = false
}
