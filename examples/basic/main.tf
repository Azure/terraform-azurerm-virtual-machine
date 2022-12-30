resource "random_id" "id" {
  byte_length = 2
}

resource "azurerm_resource_group" "rg" {
  count = var.create_resource_group ? 1 : 0

  location = var.location
  name     = coalesce(var.resource_group_name, "terraform-azurerm_virtual-machine-${random_id.id.hex}")
}

locals {
  resource_group = {
    name     = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
    location = var.location
  }
}

module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.0.0"

  resource_group_name = local.resource_group.name
  use_for_each        = true
  vnet_location       = local.resource_group.location
  address_space       = ["192.168.0.0/24"]
  vnet_name           = "vnet-vm-${random_id.id.hex}"
  subnet_names        = ["subnet-virtual-machine"]
  subnet_prefixes     = ["192.168.0.0/28"]
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_public_ip" "pip" {
  count = var.create_public_ip ? 2 : 0

  allocation_method   = "Dynamic"
  location            = local.resource_group.location
  name                = "pip-${random_id.id.hex}-${count.index}"
  resource_group_name = local.resource_group.name
}

module "linux" {
  source = "../.."

  location                             = local.resource_group.location
  image_os                             = "linux"
  resource_group_name                  = local.resource_group.name
  allow_extension_operations           = false
  new_boot_diagnostics_storage_account = {
    customer_managed_key = {
      key_vault_key_id          = azurerm_key_vault_key.storage_account_key.id
      user_assigned_identity_id = azurerm_user_assigned_identity.storage_account_key_vault.id
    }
  }
  new_network_interface = {
    ip_forwarding_enabled = false
    ip_configurations     = [
      {
        public_ip_address_id = try(azurerm_public_ip.pip[0].id, null)
        primary              = true
      }
    ]
  }
  nsg_public_open_port        = var.create_public_ip ? "22" : null
  nsg_source_address_prefixes = var.create_public_ip ? (var.nsg_rule_source_address_prefix == null ? [
    try(jsondecode(data.curl.public_ip[0].response).ip, var.my_public_ip)
  ] : [var.nsg_rule_source_address_prefix]) : null
  admin_ssh_keys = [
    {
      public_key = tls_private_key.ssh.public_key_openssh
      username   = "azureuser"
    }
  ]
  name    = "ubuntu-${random_id.id.hex}"
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  os_simple = "UbuntuServer"
  size      = var.size
  subnet_id = module.vnet.vnet_subnets[0]
}

resource "random_password" "win_password" {
  length      = 20
  lower       = true
  upper       = true
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_special = 1
}

module "windows" {
  source = "../.."

  location                             = local.resource_group.location
  image_os                             = "windows"
  resource_group_name                  = local.resource_group.name
  allow_extension_operations           = false
  new_boot_diagnostics_storage_account = {
    customer_managed_key = {
      key_vault_key_id          = azurerm_key_vault_key.storage_account_key.id
      user_assigned_identity_id = azurerm_user_assigned_identity.storage_account_key_vault.id
    }
  }
  new_network_interface = {
    ip_forwarding_enabled = false

    ip_configurations = [
      {
        public_ip_address_id = try(azurerm_public_ip.pip[1].id, null)
        primary              = true
      }
    ]
  }
  nsg_public_open_port        = var.create_public_ip ? "3389" : null
  nsg_source_address_prefixes = var.create_public_ip ? (var.nsg_rule_source_address_prefix == null ? [
    try(jsondecode(data.curl.public_ip[0].response).ip, var.my_public_ip)
  ] : [var.nsg_rule_source_address_prefix]) : null
  admin_password = random_password.win_password.result
  name           = "windows-${random_id.id.hex}"
  os_disk        = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  os_simple = "WindowsServer"
  size      = var.size
  subnet_id = module.vnet.vnet_subnets[0]
}

resource "local_file" "ssh_private_key" {
  filename = "${path.module}/key.pem"
  content  = tls_private_key.ssh.private_key_pem
}

data "azurerm_public_ip" "pip" {
  count = var.create_public_ip ? 2 : 0

  name                = azurerm_public_ip.pip[count.index].name
  resource_group_name = local.resource_group.name

  depends_on = [module.linux, module.windows]
}
