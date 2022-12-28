output "linux_vm_id" {
  value = module.linux.vm_id
}

output "windows_vm_id" {
  value = module.windows.vm_id
}

output "windows_vm_password" {
  value     = random_password.win_password.result
  sensitive = true
}

output "linux_public_ips" {
  value = module.linux.public_ip_addresses
}

output "windows_public_ips" {
  value = module.windows.public_ip_addresses
}

output "linux_network_security_group_id" {
  value = module.linux.network_security_group_id
}

output "windows_network_security_group_id" {
  value = module.windows.network_security_group_id
}
