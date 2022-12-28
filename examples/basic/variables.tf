variable "location" {
  type     = string
  default  = "eastus"
  nullable = false
}

variable "size" {
  type     = string
  default  = "Standard_F2"
  nullable = false
}

variable "create_public_ip" {
  type     = bool
  default  = false
  nullable = false
}

variable "nsg_rule_source_address_prefix" {
  type    = string
  default = null
}
