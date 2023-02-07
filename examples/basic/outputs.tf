output "linux_public_ip" {
  value = try(data.azurerm_public_ip.pip[0].ip_address, null)
}

output "linux_vm_id" {
  value = module.linux.vm_id
}

output "windows_public_ip" {
  value = try(data.azurerm_public_ip.pip[1].ip_address, null)
}

output "windows_vm_id" {
  value = module.windows.vm_id
}

output "windows_vm_password" {
  value     = random_password.win_password.result
  sensitive = true
}
