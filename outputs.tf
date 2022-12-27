output "availability_set_id" {
  description = "Id of the availability set where the vm belong to."
  value       = local.availability_set_id
}

output "capacity_reservation_group_id" {
  description = "Id of the capacity reservation group where the vm belong to."
  value       = local.capacity_reservation_group_id
}

output "dedicated_host_group_id" {
  value = local.dedicated_host_group_id
}

output "network_interface_id" {
  description = "Id of the vm nics provisoned."
  value       = azurerm_network_interface.vm.id
}

output "network_interface_private_ip" {
  description = "private ip addresses of the vm nics"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "network_security_group_id" {
  description = "id of the security group provisioned"
  value       = local.network_security_group_id
}

output "network_security_group_name" {
  description = "Name of the security group provisioned, `null` if no security group was created."
  value       = try(azurerm_network_security_group.vm[0].name, null)
}

output "public_ip_address" {
  description = "The actual ip address allocated for the resource."
  value       = try(data.azurerm_public_ip.vm[0].ip_address, null)
}

output "public_ip_dns_name" {
  description = "fqdn to connect to the first vm provisioned."
  value       = try(azurerm_public_ip.vm[0].fqdn, null)
}

output "public_ip_id" {
  description = "id of the public ip address provisoned."
  value       = try(azurerm_public_ip.vm[0].id, null)
}

output "vm_identity" {
  description = "map with key `Virtual Machine Id`, value `list of identity` created for the Virtual Machine."
  value       = local.virtual_machine.identity
}

output "vm_id" {
  description = "Virtual machine ids created."
  value       = local.virtual_machine.id
}

output "vm_name" {
  description = "Virtual machine names created."
  value       = local.virtual_machine.name
}

output "vm_zone" {
  description = "The Availability Zones in which this Virtual Machine is located."
  value       = local.virtual_machine.zone
}
