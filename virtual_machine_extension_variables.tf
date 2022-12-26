variable "vm_extension" {
  type = object({
    name                              = string
    publisher                         = string
    type                              = string
    type_handler_version              = string
    auto_upgrade_minor_version        = optional(bool)
    automatic_upgrade_enabled         = optional(bool)
    failure_suppression_enabled       = optional(bool, false)
    settings                          = optional(string)
    protected_settings                = optional(string)
    protected_settings_from_key_vault = optional(object({
      secret_url      = string
      source_vault_id = string
    }))
  })
  description = "Argument to create `azurerm_virtual_machine_extension` resource, the argument descriptions could be found at [the document](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension)."
  default     = null
  sensitive   = true # Because `protected_settings` is sensitive
}
