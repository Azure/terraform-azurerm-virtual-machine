locals {
  availability_set_id           = try(azurerm_availability_set.vm[0].id, var.availability_set_id)
  capacity_reservation_group_id = try(azurerm_capacity_reservation_group.vm[0].id, var.capacity_reservation_group_id)
  dedicated_host_group_id       = try(azurerm_dedicated_host_group.vm[0].id, var.dedicated_host_group_id)
  is_linux                      = var.image_os == "linux"
  is_windows                    = var.image_os == "windows"
  network_interface_ip_configuration_indexes =  toset(range(length(var.new_network_interface.ip_configurations)))
  patch_mode                    = coalesce(var.patch_mode, local.is_linux ? "ImageDefault" : "AutomaticByOS")
}
