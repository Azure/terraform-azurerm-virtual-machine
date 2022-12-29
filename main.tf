resource "random_id" "vm_sa" {
  keepers = {
    vm_name = var.name
  }

  byte_length = 6
}

resource "azurerm_storage_account" "boot_diagnostics" {
  count = var.boot_diagnostics && var.new_boot_diagnostics_storage_account != null ? 1 : 0

  account_replication_type         = var.new_boot_diagnostics_storage_account.account_replication_type
  account_tier                     = var.new_boot_diagnostics_storage_account.account_tier
  location                         = var.location
  name                             = coalesce(var.new_boot_diagnostics_storage_account.name, "bootdiag${lower(random_id.vm_sa.hex)}")
  resource_group_name              = var.resource_group_name
  access_tier                      = var.new_boot_diagnostics_storage_account.access_tier
  allow_nested_items_to_be_public  = var.new_boot_diagnostics_storage_account.allow_nested_items_to_be_public
  cross_tenant_replication_enabled = var.new_boot_diagnostics_storage_account.cross_tenant_replication_enabled
  default_to_oauth_authentication  = var.new_boot_diagnostics_storage_account.default_to_oauth_authentication
  enable_https_traffic_only        = var.new_boot_diagnostics_storage_account.enable_https_traffic_only
  min_tls_version                  = var.new_boot_diagnostics_storage_account.min_tls_version
  public_network_access_enabled    = var.new_boot_diagnostics_storage_account.public_network_access_enabled
  shared_access_key_enabled        = var.new_boot_diagnostics_storage_account.shared_access_key_enabled
  tags                             = var.tags

  dynamic "blob_properties" {
    for_each = var.new_boot_diagnostics_storage_account.blob_properties == null ? [] : [
      "blob_properties"
    ]

    content {
      dynamic "container_delete_retention_policy" {
        for_each = var.new_boot_diagnostics_storage_account.blob_properties.container_delete_retention_policy == null ? [] : [
          "container_delete_retention_policy"
        ]

        content {
          days = var.new_boot_diagnostics_storage_account.blob_properties.container_delete_retention_policy.days
        }
      }
      dynamic "delete_retention_policy" {
        for_each = var.new_boot_diagnostics_storage_account.blob_properties.delete_retention_policy == null ? [] : [
          "delete_retention_policy"
        ]

        content {
          days = var.new_boot_diagnostics_storage_account.blob_properties.delete_retention_policy.days
        }
      }
      dynamic "restore_policy" {
        for_each = var.new_boot_diagnostics_storage_account.blob_properties.restore_policy == null ? [] : [
          "restore_policy"
        ]

        content {
          days = var.new_boot_diagnostics_storage_account.blob_properties.restore_policy.days
        }
      }
    }
  }
  dynamic "customer_managed_key" {
    for_each = var.new_boot_diagnostics_storage_account.customer_managed_key == null ? [] : [
      "customer_managed_key"
    ]

    content {
      key_vault_key_id          = var.new_boot_diagnostics_storage_account.customer_managed_key.key_vault_key_id
      user_assigned_identity_id = var.new_boot_diagnostics_storage_account.customer_managed_key.user_assigned_identity_id
    }
  }
  dynamic "identity" {
    for_each = var.new_boot_diagnostics_storage_account.identity == null ? [] : [
      "identity"
    ]

    content {
      type         = var.new_boot_diagnostics_storage_account.identity.type
      identity_ids = var.new_boot_diagnostics_storage_account.identity.identity_ids
    }
  }
}

resource "azurerm_linux_virtual_machine" "vm_linux" {
  count = local.is_linux ? 1 : 0

  admin_username = var.admin_username
  location       = var.location
  name           = var.name
  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]
  resource_group_name             = var.resource_group_name
  size                            = var.size
  admin_password                  = var.admin_password
  allow_extension_operations      = var.allow_extension_operations
  availability_set_id             = var.availability_set_id
  capacity_reservation_group_id   = var.capacity_reservation_group_id
  computer_name                   = coalesce(var.compute_name, var.name)
  custom_data                     = var.custom_data
  dedicated_host_group_id         = var.dedicated_host_group_id
  dedicated_host_id               = var.dedicated_host_id
  disable_password_authentication = var.disable_password_authentication
  edge_zone                       = var.edge_zone
  encryption_at_host_enabled      = var.encryption_at_host_enabled
  eviction_policy                 = var.eviction_policy
  extensions_time_budget          = var.extensions_time_budget
  license_type                    = var.license_type
  max_bid_price                   = var.max_bid_price
  patch_assessment_mode           = var.patch_assessment_mode
  patch_mode                      = local.patch_mode
  platform_fault_domain           = var.platform_fault_domain
  priority                        = var.priority
  provision_vm_agent              = var.provision_vm_agent
  proximity_placement_group_id    = var.proximity_placement_group_id
  secure_boot_enabled             = var.secure_boot_enabled
  source_image_id                 = var.source_image_id
  tags                            = var.tags
  user_data                       = var.user_data
  virtual_machine_scale_set_id    = var.virtual_machine_scale_set_id
  vtpm_enabled                    = var.vtpm_enabled
  zone                            = var.zone

  os_disk {
    caching                          = var.os_disk.caching
    storage_account_type             = var.os_disk.storage_account_type
    disk_encryption_set_id           = var.os_disk.disk_encryption_set_id
    disk_size_gb                     = var.os_disk.disk_size_gb
    name                             = var.os_disk.name
    secure_vm_disk_encryption_set_id = var.os_disk.secure_vm_disk_encryption_set_id
    security_encryption_type         = var.os_disk.security_encryption_type
    write_accelerator_enabled        = var.os_disk.write_accelerator_enabled

    dynamic "diff_disk_settings" {
      for_each = var.os_disk.diff_disk_settings == null ? [] : [
        "diff_disk_settings"
      ]

      content {
        option    = var.os_disk.diff_disk_settings.option
        placement = var.os_disk.diff_disk_settings.placement
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
    for_each = { for key in var.admin_ssh_keys : jsonencode(key) => key }

    content {
      public_key = admin_ssh_key.value.public_key
      username   = admin_ssh_key.value.username
    }
  }
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics ? ["boot_diagnostics"] : []

    content {
      storage_account_uri = try(azurerm_storage_account.boot_diagnostics[0].primary_blob_endpoint, var.boot_diagnostics_storage_account_uri)
    }
  }
  dynamic "gallery_application" {
    for_each = { for app in var.gallery_application : jsonencode(app) => app }

    content {
      version_id             = gallery_application.value.version_id
      configuration_blob_uri = gallery_application.value.configuration_blob_uri
      order                  = gallery_application.value.order
      tag                    = gallery_application.value.tag
    }
  }
  dynamic "identity" {
    for_each = var.identity == null ? [] : ["identity"]

    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }
  }
  dynamic "plan" {
    for_each = var.plan == null ? [] : ["plan"]

    content {
      name      = var.plan.name
      product   = var.plan.product
      publisher = var.plan.publisher
    }
  }
  dynamic "secret" {
    for_each = toset(var.secrets)

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
      offer     = var.source_image_reference.offer
      publisher = var.source_image_reference.publisher
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }
  dynamic "source_image_reference" {
    for_each = var.os_simple != null && var.source_image_id == null ? [
      "source_image_reference"
    ] : []

    content {
      offer     = var.standard_os[var.os_simple].offer
      publisher = var.standard_os[var.os_simple].publisher
      sku       = var.standard_os[var.os_simple].sku
      version   = var.os_version
    }
  }
  dynamic "termination_notification" {
    for_each = var.termination_notification == null ? [] : [
      "termination_notification"
    ]

    content {
      enabled = var.termination_notification.enabled
      timeout = var.termination_notification.timeout
    }
  }

  lifecycle {
    precondition {
      condition = length([
        for b in [
          var.source_image_id != null, var.source_image_reference != null,
          var.os_simple != null
        ] : b if b
      ]) == 1
      error_message = "Must provide one and only one of `vm_source_image_id`, `vm_source_image_reference` and `vm_os_simple`."
    }
    precondition {
      condition     = !var.boot_diagnostics ? true : var.new_boot_diagnostics_storage_account != null || var.boot_diagnostics_storage_account_uri != null
      error_message = "Either `new_boot_diagnostics_storage_account` or `vm_boot_diagnostics_storage_account_uri` must be provided if `boot_diagnostics` is `true`."
    }
  }
}

resource "azurerm_windows_virtual_machine" "vm_windows" {
  count = local.is_windows ? 1 : 0

  admin_password = var.admin_password
  admin_username = var.admin_username
  location       = var.location
  name           = var.name
  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]
  resource_group_name           = var.resource_group_name
  size                          = var.size
  allow_extension_operations    = var.allow_extension_operations
  availability_set_id           = var.availability_set_id
  capacity_reservation_group_id = var.capacity_reservation_group_id
  computer_name                 = coalesce(var.compute_name, var.name)
  custom_data                   = var.custom_data
  dedicated_host_group_id       = var.dedicated_host_group_id
  dedicated_host_id             = var.dedicated_host_id
  edge_zone                     = var.edge_zone
  enable_automatic_updates      = var.automatic_updates_enabled
  encryption_at_host_enabled    = var.encryption_at_host_enabled
  eviction_policy               = var.eviction_policy
  extensions_time_budget        = var.extensions_time_budget
  hotpatching_enabled           = var.hotpatching_enabled
  license_type                  = var.license_type
  max_bid_price                 = var.max_bid_price
  patch_assessment_mode         = var.patch_assessment_mode
  patch_mode                    = local.patch_mode
  platform_fault_domain         = var.platform_fault_domain
  priority                      = var.priority
  provision_vm_agent            = var.provision_vm_agent
  proximity_placement_group_id  = var.proximity_placement_group_id
  secure_boot_enabled           = var.secure_boot_enabled
  source_image_id               = var.source_image_id
  tags                          = var.tags
  timezone                      = var.timezone
  user_data                     = var.user_data
  virtual_machine_scale_set_id  = var.virtual_machine_scale_set_id
  vtpm_enabled                  = var.vtpm_enabled
  zone                          = var.zone

  os_disk {
    caching                          = var.os_disk.caching
    storage_account_type             = var.os_disk.storage_account_type
    disk_encryption_set_id           = var.os_disk.disk_encryption_set_id
    disk_size_gb                     = var.os_disk.disk_size_gb
    name                             = var.os_disk.name
    secure_vm_disk_encryption_set_id = var.os_disk.secure_vm_disk_encryption_set_id
    security_encryption_type         = var.os_disk.security_encryption_type
    write_accelerator_enabled        = var.os_disk.write_accelerator_enabled

    dynamic "diff_disk_settings" {
      for_each = var.os_disk.diff_disk_settings == null ? [] : [
        "diff_disk_settings"
      ]

      content {
        option    = var.os_disk.diff_disk_settings.option
        placement = var.os_disk.diff_disk_settings.placement
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
      for c in var.additional_unattend_contents : jsonencode(c) => c
    }

    content {
      content = additional_unattend_content.value.content
      setting = additional_unattend_content.value.setting
    }
  }
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics ? ["boot_diagnostics"] : []

    content {
      storage_account_uri = try(azurerm_storage_account.boot_diagnostics[0].primary_blob_endpoint, var.boot_diagnostics_storage_account_uri)
    }
  }
  dynamic "gallery_application" {
    for_each = { for app in var.gallery_application : jsonencode(app) => app }

    content {
      version_id             = gallery_application.value.version_id
      configuration_blob_uri = gallery_application.value.configuration_blob_uri
      order                  = gallery_application.value.order
      tag                    = gallery_application.value.tag
    }
  }
  dynamic "identity" {
    for_each = var.identity == null ? [] : ["identity"]

    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }
  }
  dynamic "plan" {
    for_each = var.plan == null ? [] : ["plan"]

    content {
      name      = var.plan.name
      product   = var.plan.product
      publisher = var.plan.publisher
    }
  }
  dynamic "secret" {
    for_each = toset(var.secrets)

    content {
      key_vault_id = secret.value.key_vault_id

      dynamic "certificate" {
        for_each = secret.value.certificate

        content {
          store = certificate.value.store
          url   = certificate.value.url
        }
      }
    }
  }
  dynamic "source_image_reference" {
    for_each = var.source_image_reference == null ? [] : [
      "source_image_reference"
    ]

    content {
      offer     = var.source_image_reference.offer
      publisher = var.source_image_reference.publisher
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }
  dynamic "source_image_reference" {
    for_each = var.os_simple != null && var.source_image_id == null ? [
      "source_image_reference"
    ] : []

    content {
      offer     = var.standard_os[var.os_simple].offer
      publisher = var.standard_os[var.os_simple].publisher
      sku       = var.standard_os[var.os_simple].sku
      version   = var.os_version
    }
  }
  dynamic "termination_notification" {
    for_each = var.termination_notification == null ? [] : [
      "termination_notification"
    ]

    content {
      enabled = var.termination_notification.enabled
      timeout = var.termination_notification.timeout
    }
  }
  dynamic "winrm_listener" {
    for_each = { for l in var.winrm_listeners : jsonencode(l) => l }

    content {
      protocol        = winrm_listener.value.protocol
      certificate_url = winrm_listener.value.certificate_url
    }
  }

  lifecycle {
    precondition {
      condition = length([
        for b in [
          var.source_image_id != null, var.source_image_reference != null,
          var.os_simple != null
        ] : b if b
      ]) == 1
      error_message = "Must provide one and only one of `vm_source_image_id`, `vm_source_image_reference` and `vm_os_simple`."
    }
    precondition {
      condition     = !var.boot_diagnostics ? true : var.new_boot_diagnostics_storage_account != null || var.boot_diagnostics_storage_account_uri != null
      error_message = "Either `new_boot_diagnostics_storage_account` or `vm_boot_diagnostics_storage_account_uri` must be provided if `boot_diagnostics` is `true`."
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

resource "azurerm_network_security_group" "vm" {
  count = var.network_security_group == null ? 1 : 0

  location            = var.location
  name                = "${var.name}-nsg"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

locals {
  network_security_group_id   = try(azurerm_network_security_group.vm[0].id, var.network_security_group.id)
  network_security_group_name = try(azurerm_network_security_group.vm[0].name, var.network_security_group.name)
}

resource "azurerm_network_security_rule" "vm" {
  count = var.nsg_public_open_port != null ? 1 : 0

  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_remote_${var.nsg_public_open_port}_in_all"
  network_security_group_name = local.network_security_group_name
  priority                    = 101
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  description                 = "Allow remote protocol in from all locations"
  destination_address_prefix  = "*"
  destination_port_range      = var.nsg_public_open_port
  source_address_prefixes     = var.nsg_source_address_prefixes
  source_port_range           = "*"

  lifecycle {
    precondition {
      condition     = var.network_security_group == null ? true : (var.network_security_group.name != null)
      error_message = "`network_security_group.name` is required when `nsg_public_open_port` is not `null` and `network_security_group` is not `null`."
    }
  }
}

resource "azurerm_network_interface" "vm" {
  location                      = var.location
  name                          = coalesce(var.new_network_interface.name, "${var.name}-nic")
  resource_group_name           = var.resource_group_name
  dns_servers                   = var.new_network_interface.dns_servers
  edge_zone                     = var.new_network_interface.edge_zone
  enable_accelerated_networking = var.new_network_interface.accelerated_networking_enabled
  enable_ip_forwarding          = var.new_network_interface.ip_forwarding_enabled
  internal_dns_name_label       = var.new_network_interface.internal_dns_name_label
  tags                          = var.tags

  dynamic "ip_configuration" {
    for_each = local.network_interface_ip_configuration_indexes

    content {
      name                                               = coalesce(var.new_network_interface.ip_configurations[ip_configuration.value].name, "${var.name}-nic${ip_configuration.value}")
      private_ip_address_allocation                      = var.new_network_interface.ip_configurations[ip_configuration.value].private_ip_address_allocation
      gateway_load_balancer_frontend_ip_configuration_id = var.new_network_interface.ip_configurations[ip_configuration.value].gateway_load_balancer_frontend_ip_configuration_id
      primary                                            = var.new_network_interface.ip_configurations[ip_configuration.value].primary
      private_ip_address                                 = var.new_network_interface.ip_configurations[ip_configuration.value].private_ip_address
      private_ip_address_version                         = var.new_network_interface.ip_configurations[ip_configuration.value].private_ip_address_version
      public_ip_address_id                               = var.new_network_interface.ip_configurations[ip_configuration.value].public_ip_address_id
      subnet_id                                          = var.subnet_id
    }
  }
}

resource "azurerm_network_interface_security_group_association" "test" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = local.network_security_group_id
}

