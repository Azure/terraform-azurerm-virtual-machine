resource "random_pet" "pet" {
  length = 1
}

data "curl" "public_ip" {
  count = var.create_public_ip && var.nsg_rule_source_address_prefix == null ? 1 : 0

  http_method = "GET"
  uri         = "https://api.ipify.org?format=json"
}

resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = "terraform-azurerm_virtual-machine-${random_pet.pet.id}"
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["192.168.0.0/24"]
  location            = var.location
  name                = "vnet-vm-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["192.168.0.0/28"]
  name                 = "subnet-${random_pet.pet.id}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

module "linux" {
  source = "../.."

  location                    = var.location
  image_os                    = "linux"
  resource_group_name         = azurerm_resource_group.rg.name
  create_public_ip            = var.create_public_ip
  nsg_public_open_port        = var.create_public_ip ? "22" : null
  nsg_source_address_prefixes = var.create_public_ip ? (var.nsg_rule_source_address_prefix == null ? [jsondecode(data.curl.public_ip[0].response).ip] : [var.nsg_rule_source_address_prefix]) : null
  vm_admin_ssh_key            = [
    {
      public_key = tls_private_key.ssh.public_key_openssh
      username   = "azureuser"
    }
  ]
  vm_name    = "ubuntu-${random_pet.pet.id}"
  vm_os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  vm_os_simple   = "UbuntuServer"
  vm_size        = var.size
  vnet_subnet_id = azurerm_subnet.subnet.id
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

  location            = var.location
  image_os            = "windows"
  resource_group_name = azurerm_resource_group.rg.name
  create_public_ip            = var.create_public_ip
  nsg_public_open_port        = var.create_public_ip ? "3389" : null
  nsg_source_address_prefixes = var.create_public_ip ? (var.nsg_rule_source_address_prefix == null ? [jsondecode(data.curl.public_ip[0].response).ip] : [var.nsg_rule_source_address_prefix]) : null
  admin_password      = random_password.win_password.result
  vm_name             = "windows-${random_pet.pet.id}"
  vm_os_disk          = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  vm_os_simple   = "WindowsServer"
  vm_size        = var.size
  vnet_subnet_id = azurerm_subnet.subnet.id
}

resource "local_file" "ssh_private_key" {
  filename = "${path.module}/key.pem"
  content  = tls_private_key.ssh.private_key_pem
}
