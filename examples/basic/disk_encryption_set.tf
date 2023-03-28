data "azurerm_client_config" "current" {}

resource "random_string" "key_vault_prefix" {
  length  = 6
  special = false
  upper   = false
  numeric = false
}

data "curl" "public_ip" {
  count = var.my_public_ip == null ? 1 : 0

  http_method = "GET"
  uri         = "https://api.ipify.org?format=json"
}

locals {
  public_ip = try(jsondecode(data.curl.public_ip[0].response).ip, var.my_public_ip)
}

resource "azurerm_key_vault" "example" {
  location                    = local.resource_group.location
  name                        = random_string.key_vault_prefix.result
  resource_group_name         = local.resource_group.name
  sku_name                    = "premium"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = [local.public_ip]
  }
}

resource "azurerm_key_vault_key" "storage_account_key" {
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  key_type        = "RSA-HSM"
  key_vault_id    = azurerm_key_vault.example.id
  name            = "sakey"
  expiration_date = timeadd("${formatdate("YYYY-MM-DD", timestamp())}T00:00:00Z", "168h")
  key_size        = 2048

  depends_on = [
    azurerm_key_vault_access_policy.current_user
  ]

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

resource "azurerm_user_assigned_identity" "storage_account_key_vault" {
  location            = local.resource_group.location
  name                = "storage_account_${random_id.id.hex}"
  resource_group_name = local.resource_group.name
}

resource "azurerm_key_vault_access_policy" "storage_account" {
  key_vault_id = azurerm_key_vault.example.id
  object_id    = azurerm_user_assigned_identity.storage_account_key_vault.principal_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.example.id
  object_id    = coalesce(var.managed_identity_principal_id, data.azurerm_client_config.current.object_id)
  tenant_id    = data.azurerm_client_config.current.tenant_id
  key_permissions = [
    "Get",
    "Create",
    "Delete",
    "GetRotationPolicy",
  ]
}

resource "azurerm_key_vault_key" "des_key" {
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  key_type        = "RSA-HSM"
  key_vault_id    = azurerm_key_vault.example.id
  name            = "deskey"
  expiration_date = timeadd("${formatdate("YYYY-MM-DD", timestamp())}T00:00:00Z", "168h")
  key_size        = 2048

  depends_on = [
    azurerm_key_vault_access_policy.current_user
  ]

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

resource "azurerm_disk_encryption_set" "example" {
  key_vault_key_id    = azurerm_key_vault_key.des_key.id
  location            = local.resource_group.location
  name                = "des"
  resource_group_name = local.resource_group.name

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault_access_policy" "des" {
  key_vault_id = azurerm_key_vault.example.id
  object_id    = azurerm_disk_encryption_set.example.identity[0].principal_id
  tenant_id    = azurerm_disk_encryption_set.example.identity[0].tenant_id
  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey",
  ]
}
