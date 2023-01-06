locals {
  is_linux                                   = var.image_os == "linux"
  is_windows                                 = var.image_os == "windows"
  network_interface_ip_configuration_indexes = var.new_network_interface == null ? [] : toset(range(length(var.new_network_interface.ip_configurations)))
  patch_mode                                 = coalesce(var.patch_mode, local.is_linux ? "ImageDefault" : "AutomaticByOS")
}
