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

output "vm_availability_set_id" {
  description = "The ID of the Availability Set in which the Virtual Machine exists."
  value       = local.virtual_machine.availability_set_id
}

output "vm_dedicated_host_group_id" {
  description = "The ID of a Dedicated Host Group that this Linux Virtual Machine runs within"
  value       = local.virtual_machine.dedicated_host_group_id
}

output "vm_dedicated_host_id" {
  description = "The ID of a Dedicated Host where this machine runs on"
  value       = local.virtual_machine.dedicated_host_id
}

output "vm_id" {
  description = "Virtual machine ids created."
  value       = local.virtual_machine.id
}

output "vm_identity" {
  description = "map with key `Virtual Machine Id`, value `list of identity` created for the Virtual Machine."
  value       = local.virtual_machine.identity
}

output "vm_name" {
  description = "Virtual machine names created."
  value       = local.virtual_machine.name
}

output "vm_virtual_machine_scale_set_id" {
  description = "The Orchestrated Virtual Machine Scale Set id that this Virtual Machine was created within."
  value       = local.virtual_machine.virtual_machine_scale_set_id
}

output "vm_zone" {
  description = "The Availability Zones in which this Virtual Machine is located."
  value       = local.virtual_machine.zone
}
