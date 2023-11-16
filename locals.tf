locals {
  is_linux                                               = var.image_os == "linux"
  is_windows                                             = var.image_os == "windows"
  network_interface_ip_configuration_indexes             = var.new_network_interface == null ? [] : toset(range(length(var.new_network_interface.ip_configurations)))
  patch_mode                                             = coalesce(var.patch_mode, local.is_linux ? "ImageDefault" : "AutomaticByOS")
  bypass_platform_safety_checks_on_user_schedule_enabled = local.patch_mode == "AutomaticByPlatform" ? var.bypass_platform_safety_checks_on_user_schedule_enabled : false
  reboot_setting                                         = local.patch_mode == "AutomaticByPlatform" ? var.reboot_setting : null
}
