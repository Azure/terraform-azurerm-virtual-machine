resource "azurerm_network_security_group" "nsg" {
  location            = local.resource_group.location
  name                = "nsg-${random_id.id.hex}"
  resource_group_name = local.resource_group.name

  dynamic "security_rule" {
    for_each = var.create_public_ip ? ["ssh"] : []

    content {
      access                     = "Allow"
      direction                  = "Inbound"
      name                       = "ssh"
      priority                   = 200
      protocol                   = "Tcp"
      destination_address_prefix = "*"
      destination_port_range     = "22"
      source_address_prefix      = local.public_ip
      source_port_range          = "*"
    }
  }
  dynamic "security_rule" {
    for_each = var.create_public_ip ? ["ssh"] : []

    content {
      access                     = "Allow"
      direction                  = "Inbound"
      name                       = "rdp"
      priority                   = 201
      protocol                   = "Tcp"
      destination_address_prefix = "*"
      destination_port_range     = "3389"
      source_address_prefix      = local.public_ip
      source_port_range          = "*"
    }
  }
}
