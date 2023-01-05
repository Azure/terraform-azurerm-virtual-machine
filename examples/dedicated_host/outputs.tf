output "dedicated_host_group_id" {
  value = module.dedicate_host_group.vm_dedicated_host_group_id
}

output "dedicated_host_group_vm_id" {
  value = module.dedicate_host_group.vm_id
}

output "dedicated_host_id" {
  value = module.dedicate_host.vm_dedicated_host_id
}

output "dedicated_host_vm_id" {
  value = module.dedicate_host.vm_id
}
