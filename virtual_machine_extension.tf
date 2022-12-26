resource "azurerm_virtual_machine_extension" "extension" {
  count = var.vm_extension == null ? 0 : var.nb_instances

  name                        = var.vm_extension.name
  publisher                   = var.vm_extension.publisher
  type                        = var.vm_extension.type
  type_handler_version        = var.vm_extension.type_handler_version
  virtual_machine_id          = local.is_windows ? azurerm_windows_virtual_machine.vm_windows[count.index].id : azurerm_linux_virtual_machine.vm_linux[count.index].id
  auto_upgrade_minor_version  = var.vm_extension.auto_upgrade_minor_version
  automatic_upgrade_enabled   = var.vm_extension.automatic_upgrade_enabled
  failure_suppression_enabled = var.vm_extension.failure_suppression_enabled
  protected_settings          = var.vm_extension.protected_settings
  settings                    = var.vm_extension.settings
  tags                        = var.tags

  dynamic "protected_settings_from_key_vault" {
    for_each = var.vm_extension.protected_settings_from_key_vault == null ? [] : [
      "protected_settings_from_key_vault"
    ]

    content {
      secret_url      = var.vm_extension.protected_settings_from_key_vault.secret_url
      source_vault_id = var.vm_extension.protected_settings_from_key_vault.source_vault_id
    }
  }
}
