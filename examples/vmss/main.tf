resource "random_id" "id" {
  byte_length = 2
}

resource "azurerm_resource_group" "rg" {
  count = var.create_resource_group ? 1 : 0

  location = var.location
  name     = coalesce(var.resource_group_name, "tf-vmmod-vmss-${random_id.id.hex}")
}

locals {
  resource_group = {
    name     = try(azurerm_resource_group.rg[0].name, var.resource_group_name)
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

resource "azurerm_orchestrated_virtual_machine_scale_set" "vmss" {
  location                    = local.resource_group.location
  name                        = "vmssflex-${random_id.id.hex}"
  platform_fault_domain_count = 1
  resource_group_name         = local.resource_group.name

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    offer     = "UbuntuServer"
    publisher = "Canonical"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

module "linux" {
  source = "../.."

  location                   = local.resource_group.location
  image_os                   = "linux"
  resource_group_name        = local.resource_group.name
  allow_extension_operations = false
  boot_diagnostics           = false
  new_network_interface = {
    ip_forwarding_enabled = false
    ip_configurations = [
      {
        primary = true
      }
    ]
  }
  admin_username = "azureuser"
  admin_ssh_keys = [
    {
      public_key = tls_private_key.ssh.public_key_openssh
    }
  ]
  name = "ubuntu-${random_id.id.hex}"
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  os_simple                    = "UbuntuServer"
  size                         = var.size
  subnet_id                    = module.vnet.vnet_subnets[0]
  virtual_machine_scale_set_id = azurerm_orchestrated_virtual_machine_scale_set.vmss.id
}

resource "azurerm_network_interface_security_group_association" "vmss" {
  network_interface_id      = module.linux.network_interface_id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "local_file" "ssh_private_key" {
  filename = "${path.module}/key.pem"
  content  = tls_private_key.ssh.private_key_pem
}
