module "os" {
  source       = "./os"
  vm_os_simple = var.vm_os_simple
}

locals {
  ssh_keys = compact(concat([var.ssh_key], var.extra_ssh_keys))
}

resource "random_id" "vm_sa" {
  keepers = {
    vm_hostname = var.vm_hostname
  }

  byte_length = 6
}

resource "azurerm_storage_account" "vm_sa" {
  count = var.boot_diagnostics && var.external_boot_diagnostics_storage == null ? 1 : 0

  account_replication_type = element(split("_", var.boot_diagnostics_sa_type), 1)
  account_tier             = element(split("_", var.boot_diagnostics_sa_type), 0)
  location                 = local.location
  name                     = "bootdiag${lower(random_id.vm_sa.hex)}"
  resource_group_name      = var.resource_group_name
  tags                     = var.tags
}

resource "azurerm_linux_virtual_machine" "vm_linux" {
  count = local.is_linux ? var.nb_instances : 0

  admin_username        = var.admin_username
  location              = var.location
  license_type          = var.license_type
  name                  = format(local.vm_name_format, var.vm_hostname, count.index)
  network_interface_ids = [
    azurerm_network_interface.vm[count.index].id
  ]
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_password                  = var.admin_password
  allow_extension_operations      = var.allow_extension_operations
  availability_set_id             = local.availability_set_id
  capacity_reservation_group_id   = local.capacity_reservation_group_id
  computer_name                   = var.computer_name_format == null ? null : format(var.computer_name_format, var.vm_hostname, "vmLinux", count.index)
  custom_data                     = var.custom_data
  dedicated_host_id               = var.dedicated_host_id
  dedicated_host_group_id         = var.dedicated_host_group_id
  disable_password_authentication = var.disable_password_authentication
  edge_zone                       = var.edge_zone
  encryption_at_host_enabled      = var.encryption_at_host_enabled
  eviction_policy                 = var.eviction_policy
  extensions_time_budget          = var.extensions_time_budget
  patch_assessment_mode           = var.patch_assessment_mode
  patch_mode                      = local.patch_mode
  platform_fault_domain           = var.platform_fault_domain
  priority                        = var.priority
  provision_vm_agent              = var.provision_vm_agent
  proximity_placement_group_id    = var.proximity_placement_group_id
  secure_boot_enabled             = var.secure_boot_enabled
  source_image_id                 = var.source_image_id
  user_data                       = var.user_data
  max_bid_price                   = var.max_bid_price
  vtpm_enabled                    = var.vtpm_enabled
  virtual_machine_scale_set_id    = var.virtual_machine_scale_set_id
  tags                            = var.tags
  zone                            = var.zone

  os_disk {
    caching                          = var.vm_os_disk.caching
    storage_account_type             = var.vm_os_disk.storage_account_type
    disk_encryption_set_id           = var.vm_os_disk.disk_encryption_set_id
    disk_size_gb                     = var.vm_os_disk.disk_size_gb
    name                             = var.vm_os_disk.name
    secure_vm_disk_encryption_set_id = var.vm_os_disk.secure_vm_disk_encryption_set_id
    security_encryption_type         = var.vm_os_disk.security_encryption_type
    write_accelerator_enabled        = var.vm_os_disk.write_accelerator_enabled
    dynamic "diff_disk_settings" {
      for_each = var.vm_os_disk.diff_disk_settings == null ? [] : [
        "diff_disk_settings"
      ]

      content {
        option    = var.vm_os_disk.diff_disk_settings.option
        placement = var.vm_os_disk.diff_disk_settings.placement
      }
    }
  }

  dynamic "additional_capabilities" {
    for_each = var.vm_additional_capabilities == null ? [] : [
      "additional_capabilities"
    ]

    content {
      ultra_ssd_enabled = var.vm_additional_capabilities.ultra_ssd_enabled
    }
  }
  dynamic "admin_ssh_key" {
    for_each = var.vm_admin_ssh_key

    content {
      public_key = admin_ssh_key.value.public_key
      username   = admin_ssh_key.value.username
    }
  }
  dynamic "boot_diagnostics" {
    for_each = var.vm_boot_diagnostics == null ? [] : ["boot_diagnostics"]

    content {
      storage_account_uri = var.vm_boot_diagnostics.storage_account_uri
    }
  }
  dynamic "gallery_application" {
    for_each = var.vm_gallery_application

    content {
      version_id             = gallery_application.value.version_id
      configuration_blob_uri = gallery_application.value.configuration_blob_uri
      order                  = gallery_application.value.order
      tag                    = gallery_application.value.tag
    }
  }
  dynamic "identity" {
    for_each = var.vm_identity == null ? [] : ["identity"]

    content {
      type         = var.vm_identity.type
      identity_ids = var.vm_identity.identity_ids
    }
  }
  dynamic "plan" {
    for_each = var.vm_plan == null ? [] : ["plan"]

    content {
      name      = var.vm_plan.name
      product   = var.vm_plan.product
      publisher = var.vm_plan.publisher
    }
  }
  dynamic "secret" {
    for_each = toset(var.vm_secrets)

    content {
      key_vault_id = secret.value.key_vault_id
      dynamic "certificate" {
        for_each = secret.value.certificate

        content {
          url = certificate.value.url
        }
      }
    }
  }
  dynamic "source_image_reference" {
    for_each = var.source_image_reference == null ? [] : [
      "source_image_reference"
    ]

    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }
  dynamic "termination_notification" {
    for_each = var.vm_termination_notification == null ? [] : [
      "termination_notification"
    ]

    content {
      enabled = var.vm_termination_notification.enabled
      timeout = var.vm_termination_notification.timeout
    }
  }
}

resource "azurerm_windows_virtual_machine" "vm_windows" {
  count = local.is_windows ? var.nb_instances : 0

  admin_password        = var.admin_password
  admin_username        = var.admin_username
  location              = var.location
  license_type          = var.license_type
  name                  = format(local.vm_name_format, var.vm_hostname, count.index)
  network_interface_ids = [
    azurerm_network_interface.vm[count.index].id
  ]
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  allow_extension_operations      = var.allow_extension_operations
  availability_set_id             = local.availability_set_id
  capacity_reservation_group_id   = local.capacity_reservation_group_id
  computer_name                   = var.computer_name_format == null ? null : format(var.computer_name_format, var.vm_hostname, "vmWindows", count.index)
  custom_data                     = var.custom_data
  dedicated_host_id               = var.dedicated_host_id
  dedicated_host_group_id         = var.dedicated_host_group_id
  disable_password_authentication = var.disable_password_authentication
  edge_zone                       = var.edge_zone
  enable_automatic_updates        = var.vm_automatic_updates_enabled
  encryption_at_host_enabled      = var.encryption_at_host_enabled
  eviction_policy                 = var.eviction_policy
  extensions_time_budget          = var.extensions_time_budget
  hotpatching_enabled             = var.vm_hotpatching_enabled
  patch_assessment_mode           = var.patch_assessment_mode
  patch_mode                      = local.patch_mode
  platform_fault_domain           = var.platform_fault_domain
  priority                        = var.priority
  provision_vm_agent              = var.provision_vm_agent
  proximity_placement_group_id    = var.proximity_placement_group_id
  secure_boot_enabled             = var.secure_boot_enabled
  source_image_id                 = var.source_image_id
  user_data                       = var.user_data
  max_bid_price                   = var.max_bid_price
  vtpm_enabled                    = var.vtpm_enabled
  virtual_machine_scale_set_id    = var.virtual_machine_scale_set_id
  tags                            = var.tags
  timezone                        = var.vm_timezone
  zone                            = var.zone

  os_disk {
    caching                          = var.vm_os_disk.caching
    storage_account_type             = var.vm_os_disk.storage_account_type
    disk_encryption_set_id           = var.vm_os_disk.disk_encryption_set_id
    disk_size_gb                     = var.vm_os_disk.disk_size_gb
    name                             = var.vm_os_disk.name
    secure_vm_disk_encryption_set_id = var.vm_os_disk.secure_vm_disk_encryption_set_id
    security_encryption_type         = var.vm_os_disk.security_encryption_type
    write_accelerator_enabled        = var.vm_os_disk.write_accelerator_enabled
    dynamic "diff_disk_settings" {
      for_each = var.vm_os_disk.diff_disk_settings == null ? [] : [
        "diff_disk_settings"
      ]

      content {
        option    = var.vm_os_disk.diff_disk_settings.option
        placement = var.vm_os_disk.diff_disk_settings.placement
      }
    }
  }

  dynamic "additional_capabilities" {
    for_each = var.vm_additional_capabilities == null ? [] : [
      "additional_capabilities"
    ]

    content {
      ultra_ssd_enabled = var.vm_additional_capabilities.ultra_ssd_enabled
    }
  }
  dynamic "additional_unattend_content" {
    for_each = var.vm_additional_unattend_content

    content {
      content = additional_unattend_content.value.content
      setting = additional_unattend_content.value.setting
    }
  }
  dynamic "admin_ssh_key" {
    for_each = var.vm_admin_ssh_key

    content {
      public_key = admin_ssh_key.value.public_key
      username   = admin_ssh_key.value.username
    }
  }
  dynamic "boot_diagnostics" {
    for_each = var.vm_boot_diagnostics == null ? [] : ["boot_diagnostics"]

    content {
      storage_account_uri = var.vm_boot_diagnostics.storage_account_uri
    }
  }
  dynamic "gallery_application" {
    for_each = var.vm_gallery_application

    content {
      version_id             = gallery_application.value.version_id
      configuration_blob_uri = gallery_application.value.configuration_blob_uri
      order                  = gallery_application.value.order
      tag                    = gallery_application.value.tag
    }
  }
  dynamic "identity" {
    for_each = var.vm_identity == null ? [] : ["identity"]

    content {
      type         = var.vm_identity.type
      identity_ids = var.vm_identity.identity_ids
    }
  }
  dynamic "plan" {
    for_each = var.vm_plan == null ? [] : ["plan"]

    content {
      name      = var.vm_plan.name
      product   = var.vm_plan.product
      publisher = var.vm_plan.publisher
    }
  }
  dynamic "secret" {
    for_each = toset(var.vm_secrets)

    content {
      key_vault_id = secret.value.key_vault_id
      dynamic "certificate" {
        for_each = secret.value.certificate

        content {
          url   = certificate.value.url
          store = certificate.value.store
        }
      }
    }
  }
  dynamic "source_image_reference" {
    for_each = var.source_image_reference == null ? [] : [
      "source_image_reference"
    ]

    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }
  dynamic "termination_notification" {
    for_each = var.vm_termination_notification == null ? [] : [
      "termination_notification"
    ]

    content {
      enabled = var.vm_termination_notification.enabled
      timeout = var.vm_termination_notification.timeout
    }
  }
  dynamic "winrm_listener" {
    for_each = var.vm_winrm_listeners

    content {
      protocol        = ""
      certificate_url = ""
    }
  }
}

resource "azurerm_availability_set" "vm" {
  count = var.new_availability_set != null ? 1 : 0

  location                     = var.location
  name                         = var.new_availability_set.name
  resource_group_name          = var.resource_group_name
  managed                      = var.new_availability_set.managed
  platform_fault_domain_count  = var.new_availability_set.platform_fault_domain_count
  platform_update_domain_count = var.new_availability_set.platform_update_domain_count
  tags                         = var.tags
}

resource "azurerm_capacity_reservation_group" "vm" {
  count = var.new_capacity_reservation_group != null ? 1 : 0

  location            = var.location
  name                = "${var.vm_hostname}-capreserv"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_public_ip" "vm" {
  count = var.nb_public_ip

  allocation_method   = var.allocation_method
  location            = var.location
  name                = "${var.vm_hostname}-pip-${count.index}"
  resource_group_name = var.resource_group_name
  domain_name_label   = element(var.public_ip_dns, count.index)
  sku                 = var.public_ip_sku
  tags                = var.tags
  zones               = var.zone == null ? null : [var.zone]

  # To solve issue [#107](https://github.com/Azure/terraform-azurerm-compute/issues/107) we add such block to make `azurerm_network_interface.vm`'s update happen first.
  # Issue #107's root cause is Terraform will try to execute deletion before update, once we tried to delete the public ip, it is still attached on the network interface.
  # Declare this `create_before_destroy` will defer this public ip resource's deletion after creation and update so we can fix the issue.
  lifecycle {
    create_before_destroy = true
  }
}

# Dynamic public ip address will be got after it's assigned to a vm
data "azurerm_public_ip" "vm" {
  count = var.nb_public_ip

  name                = azurerm_public_ip.vm[count.index].name
  resource_group_name = var.resource_group_name

  depends_on = [
    azurerm_virtual_machine.vm_linux, azurerm_virtual_machine.vm_windows
  ]
}

resource "azurerm_network_security_group" "vm" {
  count = var.network_security_group == null ? 1 : 0

  location            = var.location
  name                = "${var.vm_hostname}-nsg"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

locals {
  network_security_group_id = var.network_security_group == null ? azurerm_network_security_group.vm[0].id : var.network_security_group.id
}

resource "azurerm_network_security_rule" "vm" {
  count = var.network_security_group == null && var.remote_port != "" ? 1 : 0

  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_remote_${coalesce(var.remote_port, module.os.calculated_remote_port)}_in_all"
  network_security_group_name = azurerm_network_security_group.vm[0].name
  priority                    = 101
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  description                 = "Allow remote protocol in from all locations"
  destination_address_prefix  = "*"
  destination_port_range      = coalesce(var.remote_port, module.os.calculated_remote_port)
  source_address_prefixes     = var.source_address_prefixes
  source_port_range           = "*"
}

resource "azurerm_network_interface" "vm" {
  count = var.nb_instances

  location                      = var.location
  name                          = "${var.vm_hostname}-nic-${count.index}"
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking
  tags                          = var.tags

  ip_configuration {
    name                          = "${var.vm_hostname}-ip-${count.index}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = length(azurerm_public_ip.vm[*].id) > 0 ? element(concat(azurerm_public_ip.vm[*].id, tolist([
      ""
    ])), count.index) : ""
    subnet_id = var.vnet_subnet_id
  }
}

resource "azurerm_network_interface_security_group_association" "test" {
  count = var.nb_instances

  network_interface_id      = azurerm_network_interface.vm[count.index].id
  network_security_group_id = local.network_security_group_id
}

