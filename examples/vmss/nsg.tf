resource "azurerm_network_security_group" "nsg" {
  location            = local.resource_group.location
  name                = "nsg-${random_id.id.hex}"
  resource_group_name = local.resource_group.name
}
