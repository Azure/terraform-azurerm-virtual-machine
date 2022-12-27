resource "random_id" "vm_sa" {
  keepers = {
    vm_name = var.vm_name
  }

  byte_length = 6
}

resource "azurerm_storage_account" "boot_diagnostics" {
  count = var.boot_diagnostics && var.vm_boot_diagnostics == null ? 1 : 0

  account_replication_type = element(split("_", var.boot_diagnostics_sa_type), 1)
  account_tier             = element(split("_", var.boot_diagnostics_sa_type), 0)
  location                 = var.location
  name                     = "bootdiag${lower(random_id.vm_sa.hex)}"
  resource_group_name      = var.resource_group_name
  tags                     = var.tags
}

resource "azurerm_linux_virtual_machine" "vm_linux" {
  count = local.is_linux ? 1 : 0

  admin_username        = var.admin_username
  location              = var.location
  license_type          = var.license_type
  name                  = var.vm_name
  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_password                  = var.admin_password
  allow_extension_operations      = var.allow_extension_operations
  availability_set_id             = local.availability_set_id
  capacity_reservation_group_id   = local.capacity_reservation_group_id
  computer_name                   = coalesce(var.compute_name, var.vm_name)
  custom_data                     = var.custom_data
  dedicated_host_id               = var.dedicated_host_id
  dedicated_host_group_id         = local.dedicated_host_group_id
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
  source_image_id                 = var.vm_source_image_id
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
    for_each = {for key in var.vm_admin_ssh_key : jsonencode(key) => key}

    content {
      public_key = admin_ssh_key.value.public_key
      username   = admin_ssh_key.value.username
    }
  }
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics ? ["boot_diagnostics"] : []

    content {
      storage_account_uri = try(azurerm_storage_account.boot_diagnostics[0].primary_blob_endpoint, var.vm_boot_diagnostics.storage_account_uri)
    }
  }
  dynamic "gallery_application" {
    for_each = {for app in var.vm_gallery_application : jsonencode(app) => app}

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
    for_each = var.vm_source_image_reference == null ? [] : [
      "source_image_reference"
    ]

    content {
      publisher = var.vm_source_image_reference.publisher
      offer     = var.vm_source_image_reference.offer
      sku       = var.vm_source_image_reference.sku
      version   = var.vm_source_image_reference.version
    }
  }
  dynamic "source_image_reference" {
    for_each = var.vm_os_simple != null && var.vm_source_image_id == null ? [
      "source_image_reference"
    ] : []

    content {
      publisher = var.standard_os[var.vm_os_simple].publisher
      offer     = var.standard_os[var.vm_os_simple].offer
      sku       = var.standard_os[var.vm_os_simple].sku
      version   = var.vm_os_version
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

  lifecycle {
    precondition {
      condition = length([
        for b in [
          var.vm_source_image_id != null, var.vm_source_image_reference != null,
          var.vm_os_simple != null
        ] : b if b
      ]) == 1
      error_message = "Must provide one and only one of `vm_source_image_id`, `vm_source_image_reference` and `vm_os_simple`."
    }
  }
}

resource "azurerm_windows_virtual_machine" "vm_windows" {
  count = local.is_windows ? 1 : 0

  admin_password        = var.admin_password
  admin_username        = var.admin_username
  location              = var.location
  license_type          = var.license_type
  name                  = var.vm_name
  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]
  resource_group_name           = var.resource_group_name
  size                          = var.vm_size
  allow_extension_operations    = var.allow_extension_operations
  availability_set_id           = local.availability_set_id
  capacity_reservation_group_id = local.capacity_reservation_group_id
  computer_name                 = coalesce(var.compute_name, var.vm_name)
  custom_data                   = var.custom_data
  dedicated_host_id             = var.dedicated_host_id
  dedicated_host_group_id       = local.dedicated_host_group_id
  edge_zone                     = var.edge_zone
  enable_automatic_updates      = var.vm_automatic_updates_enabled
  encryption_at_host_enabled    = var.encryption_at_host_enabled
  eviction_policy               = var.eviction_policy
  extensions_time_budget        = var.extensions_time_budget
  hotpatching_enabled           = var.vm_hotpatching_enabled
  patch_assessment_mode         = var.patch_assessment_mode
  patch_mode                    = local.patch_mode
  platform_fault_domain         = var.platform_fault_domain
  priority                      = var.priority
  provision_vm_agent            = var.provision_vm_agent
  proximity_placement_group_id  = var.proximity_placement_group_id
  secure_boot_enabled           = var.secure_boot_enabled
  source_image_id               = var.vm_source_image_id
  user_data                     = var.user_data
  max_bid_price                 = var.max_bid_price
  vtpm_enabled                  = var.vtpm_enabled
  virtual_machine_scale_set_id  = var.virtual_machine_scale_set_id
  tags                          = var.tags
  timezone                      = var.vm_timezone
  zone                          = var.zone

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
    for_each = {
      for c in var.vm_additional_unattend_contents : jsonencode(c) =>c
    }

    content {
      content = additional_unattend_content.value.content
      setting = additional_unattend_content.value.setting
    }
  }
  dynamic "boot_diagnostics" {
    for_each = var.vm_boot_diagnostics == null ? [] : ["boot_diagnostics"]

    content {
      storage_account_uri = var.vm_boot_diagnostics.storage_account_uri
    }
  }
  dynamic "gallery_application" {
    for_each = {for app in var.vm_gallery_application : jsonencode(app) => app}

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
    for_each = var.vm_source_image_reference == null ? [] : [
      "source_image_reference"
    ]

    content {
      publisher = var.vm_source_image_reference.publisher
      offer     = var.vm_source_image_reference.offer
      sku       = var.vm_source_image_reference.sku
      version   = var.vm_source_image_reference.version
    }
  }
  dynamic "source_image_reference" {
    for_each = var.vm_os_simple != null && var.vm_source_image_id == null ? [
      "source_image_reference"
    ] : []

    content {
      publisher = var.standard_os[var.vm_os_simple].publisher
      offer     = var.standard_os[var.vm_os_simple].offer
      sku       = var.standard_os[var.vm_os_simple].sku
      version   = var.vm_os_version
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
    for_each = {for l in var.vm_winrm_listeners : jsonencode(l) => l}

    content {
      protocol        = winrm_listener.value.protocol
      certificate_url = winrm_listener.value.certificate_url
    }
  }

  lifecycle {
    precondition {
      condition = length([
        for b in [
          var.vm_source_image_id != null, var.vm_source_image_reference != null,
          var.vm_os_simple != null
        ] : b if b
      ]) == 1
      error_message = "Must provide one and only one of `vm_source_image_id`, `vm_source_image_reference` and `vm_os_simple`."
    }
  }
}

locals {
  virtual_machine = local.is_windows ? {
    id                            = azurerm_windows_virtual_machine.vm_windows[0].id
    name                          = azurerm_windows_virtual_machine.vm_windows[0].name
    network_interface_ids         = azurerm_windows_virtual_machine.vm_windows[0].network_interface_ids
    availability_set_id           = azurerm_windows_virtual_machine.vm_windows[0].availability_set_id
    capacity_reservation_group_id = azurerm_windows_virtual_machine.vm_windows[0].capacity_reservation_group_id
    computer_name                 = azurerm_windows_virtual_machine.vm_windows[0].computer_name
    dedicated_host_id             = azurerm_windows_virtual_machine.vm_windows[0].dedicated_host_id
    dedicated_host_group_id       = azurerm_windows_virtual_machine.vm_windows[0].dedicated_host_group_id
    patch_mode                    = azurerm_windows_virtual_machine.vm_windows[0].patch_mode
    proximity_placement_group_id  = azurerm_windows_virtual_machine.vm_windows[0].proximity_placement_group_id
    source_image_id               = azurerm_windows_virtual_machine.vm_windows[0].source_image_id
    virtual_machine_scale_set_id  = azurerm_windows_virtual_machine.vm_windows[0].virtual_machine_scale_set_id
    timezone                      = azurerm_windows_virtual_machine.vm_windows[0].timezone
    zone                          = azurerm_windows_virtual_machine.vm_windows[0].zone
    identity                      = azurerm_windows_virtual_machine.vm_windows[0].identity
    source_image_reference        = azurerm_windows_virtual_machine.vm_windows[0].source_image_reference
  } : {
    id                            = azurerm_linux_virtual_machine.vm_linux[0].id
    name                          = azurerm_linux_virtual_machine.vm_linux[0].name
    network_interface_ids         = azurerm_linux_virtual_machine.vm_linux[0].network_interface_ids
    availability_set_id           = azurerm_linux_virtual_machine.vm_linux[0].availability_set_id
    capacity_reservation_group_id = azurerm_linux_virtual_machine.vm_linux[0].capacity_reservation_group_id
    computer_name                 = azurerm_linux_virtual_machine.vm_linux[0].computer_name
    dedicated_host_id             = azurerm_linux_virtual_machine.vm_linux[0].dedicated_host_id
    dedicated_host_group_id       = azurerm_linux_virtual_machine.vm_linux[0].dedicated_host_group_id
    patch_mode                    = azurerm_linux_virtual_machine.vm_linux[0].patch_mode
    proximity_placement_group_id  = azurerm_linux_virtual_machine.vm_linux[0].proximity_placement_group_id
    source_image_id               = azurerm_linux_virtual_machine.vm_linux[0].source_image_id
    virtual_machine_scale_set_id  = azurerm_linux_virtual_machine.vm_linux[0].virtual_machine_scale_set_id
    timezone                      = null
    zone                          = azurerm_linux_virtual_machine.vm_linux[0].zone
    identity                      = azurerm_linux_virtual_machine.vm_linux[0].identity
    source_image_reference        = azurerm_linux_virtual_machine.vm_linux[0].source_image_reference
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
  name                = "${var.vm_name}-capreserv"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_dedicated_host_group" "vm" {
  count = var.new_dedicated_host_group != null ? 1 : 0

  location                    = var.location
  name                        = var.new_dedicated_host_group.name
  platform_fault_domain_count = var.new_dedicated_host_group.platform_fault_domain_count
  resource_group_name         = var.resource_group_name
  automatic_placement_enabled = var.new_dedicated_host_group.automatic_placement_enabled
}

resource "azurerm_public_ip" "vm" {
  count = var.create_public_ip ? 1 : 0

  allocation_method   = var.allocation_method
  location            = var.location
  name                = "${var.vm_name}-pip"
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
  count = var.create_public_ip ? 1 : 0

  name                = azurerm_public_ip.vm[count.index].name
  resource_group_name = var.resource_group_name

  depends_on = [
    azurerm_linux_virtual_machine.vm_linux,
    azurerm_windows_virtual_machine.vm_windows
  ]
}

resource "azurerm_network_security_group" "vm" {
  count = var.network_security_group == null ? 1 : 0

  location            = var.location
  name                = "${var.vm_name}-nsg"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

locals {
  network_security_group_id = try(azurerm_network_security_group.vm[0].id, var.network_security_group.id)
}

resource "azurerm_network_security_rule" "vm" {
  count = var.network_security_group == null && var.nsg_public_open_port != null ? 1 : 0

  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_remote_${var.nsg_public_open_port}_in_all"
  network_security_group_name = azurerm_network_security_group.vm[0].name
  priority                    = 101
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  description                 = "Allow remote protocol in from all locations"
  destination_address_prefix  = "*"
  destination_port_range      = var.nsg_public_open_port
  source_address_prefixes     = var.nsg_source_address_prefixes
  source_port_range           = "*"
}

resource "azurerm_network_interface" "vm" {
  location                      = var.location
  name                          = "${var.vm_name}-nic"
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking
  tags                          = var.tags

  ip_configuration {
    name                          = "${var.vm_name}-ip"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.vm[0].id, null)
    subnet_id                     = var.vnet_subnet_id
  }
}

resource "azurerm_network_interface_security_group_association" "test" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = local.network_security_group_id
}

