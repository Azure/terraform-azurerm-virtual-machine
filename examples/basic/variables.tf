variable "create_public_ip" {
  type     = bool
  default  = false
  nullable = false
}

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

variable "managed_identity_principal_id" {
  type    = string
  default = null
}

variable "my_public_ip" {
  type    = string
  default = null
}

variable "nsg_rule_source_address_prefix" {
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
