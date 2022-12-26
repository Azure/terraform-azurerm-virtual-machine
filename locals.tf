locals {
  availability_set_id = var.new_availability_set != null ? (
    azurerm_availability_set.vm[0].id) : (
  var.availability_set_id)
  capacity_reservation_group_id = var.new_capacity_reservation_group != null ? (
    azurerm_capacity_reservation_group.vm[0].id) : (
  var.capacity_reservation_group_id)
  is_linux = !local.is_windows
  is_windows = contains(tolist([var.vm_os_simple, var.vm_os_offer]), "WindowsServer") || (
  var.is_windows_image)
  vm_name_format = coalesce(var.vm_name_format, (
    local.is_linux ? "%s-vmLinux-%d" : (
      "%s-vmWindows-%d"
    )
  ))
  patch_mode = coalesce(var.patch_mode, local.is_linux ? "ImageDefault" : "AutomaticByOS")
}
