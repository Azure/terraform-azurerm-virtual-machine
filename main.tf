resource "random_id" "vm_sa" {
  byte_length = 6
  keepers = {
    vm_name = var.name
  }
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
  tags = merge(var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "c01af1788f09558cf2ea3faea035bd95751da759"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2022-12-29 13:09:50"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-virtual-machine"
    avm_yor_trace            = "c5b495dd-366d-4c38-b402-6e9996c6c530"
    } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/), (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_yor_name = "boot_diagnostics"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))

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
  #checkov:skip=CKV2_AZURE_1
  #checkov:skip=CKV2_AZURE_18
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

  admin_username                                         = var.admin_username
  location                                               = var.location
  name                                                   = var.name
  network_interface_ids                                  = local.network_interface_ids
  resource_group_name                                    = var.resource_group_name
  size                                                   = var.size
  admin_password                                         = var.admin_password
  allow_extension_operations                             = var.allow_extension_operations
  availability_set_id                                    = var.availability_set_id
  bypass_platform_safety_checks_on_user_schedule_enabled = var.bypass_platform_safety_checks_on_user_schedule_enabled
  capacity_reservation_group_id                          = var.capacity_reservation_group_id
  computer_name                                          = coalesce(var.computer_name, var.name)
  custom_data                                            = var.custom_data
  dedicated_host_group_id                                = var.dedicated_host_group_id
  dedicated_host_id                                      = var.dedicated_host_id
  disable_password_authentication                        = var.disable_password_authentication
  edge_zone                                              = var.edge_zone
  encryption_at_host_enabled                             = var.encryption_at_host_enabled
  eviction_policy                                        = var.eviction_policy
  extensions_time_budget                                 = var.extensions_time_budget
  license_type                                           = var.license_type
  max_bid_price                                          = var.max_bid_price
  patch_assessment_mode                                  = var.patch_assessment_mode
  patch_mode                                             = local.patch_mode
  platform_fault_domain                                  = var.platform_fault_domain
  priority                                               = var.priority
  provision_vm_agent                                     = var.provision_vm_agent
  proximity_placement_group_id                           = var.proximity_placement_group_id
  reboot_setting                                         = var.reboot_setting
  secure_boot_enabled                                    = var.secure_boot_enabled
  source_image_id                                        = var.source_image_id
  tags = merge(var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "b64ecfc706205b7c0a1e9c91feae63a35f32b3da"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-11-23 13:50:04"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-virtual-machine"
    avm_yor_trace            = "b2236e7a-5f3d-4d34-8fa7-867bf4e3be7c"
    } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/), (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_yor_name = "vm_linux"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
  user_data                    = var.user_data
  virtual_machine_scale_set_id = var.virtual_machine_scale_set_id
  vtpm_enabled                 = var.vtpm_enabled
  zone                         = var.zone

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
      username   = coalesce(admin_ssh_key.value.username, var.admin_username)
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
      condition     = var.network_interface_ids != null || var.new_network_interface != null
      error_message = "Either `new_network_interface` or `network_interface_ids` must be provided."
    }
    #Public keys can only be added to authorized_keys file for 'admin_username' due to a known issue in Linux provisioning agent.
    precondition {
      condition     = alltrue([for value in var.admin_ssh_keys : value.username == var.admin_username || value.username == null])
      error_message = "`username` in var.admin_ssh_keys should be the same as `admin_username` or `null`."
    }
    precondition {
      condition     = !var.bypass_platform_safety_checks_on_user_schedule_enabled || local.patch_mode == "AutomaticByPlatform"
      error_message = "`bypass_platform_safety_checks_on_user_schedule_enabled` can only be set when patch_mode is `AutomaticByPlatform`"
    }
    precondition {
      condition     = var.reboot_setting == null || local.patch_mode == "AutomaticByPlatform"
      error_message = "`reboot_setting` can only be set when patch_mode is `AutomaticByPlatform`"
    }
  }
}

resource "azurerm_windows_virtual_machine" "vm_windows" {
  count = local.is_windows ? 1 : 0

  admin_password                                         = var.admin_password
  admin_username                                         = var.admin_username
  location                                               = var.location
  name                                                   = var.name
  network_interface_ids                                  = local.network_interface_ids
  resource_group_name                                    = var.resource_group_name
  size                                                   = var.size
  allow_extension_operations                             = var.allow_extension_operations
  availability_set_id                                    = var.availability_set_id
  bypass_platform_safety_checks_on_user_schedule_enabled = var.bypass_platform_safety_checks_on_user_schedule_enabled
  capacity_reservation_group_id                          = var.capacity_reservation_group_id
  computer_name                                          = coalesce(var.computer_name, var.name)
  custom_data                                            = var.custom_data
  dedicated_host_group_id                                = var.dedicated_host_group_id
  dedicated_host_id                                      = var.dedicated_host_id
  edge_zone                                              = var.edge_zone
  enable_automatic_updates                               = var.automatic_updates_enabled
  encryption_at_host_enabled                             = var.encryption_at_host_enabled
  eviction_policy                                        = var.eviction_policy
  extensions_time_budget                                 = var.extensions_time_budget
  hotpatching_enabled                                    = var.hotpatching_enabled
  license_type                                           = var.license_type
  max_bid_price                                          = var.max_bid_price
  patch_assessment_mode                                  = var.patch_assessment_mode
  patch_mode                                             = local.patch_mode
  platform_fault_domain                                  = var.platform_fault_domain
  priority                                               = var.priority
  provision_vm_agent                                     = var.provision_vm_agent
  proximity_placement_group_id                           = var.proximity_placement_group_id
  reboot_setting                                         = var.reboot_setting
  secure_boot_enabled                                    = var.secure_boot_enabled
  source_image_id                                        = var.source_image_id
  tags = merge(var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "b64ecfc706205b7c0a1e9c91feae63a35f32b3da"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-11-23 13:50:04"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-virtual-machine"
    avm_yor_trace            = "2c38c76d-7f2e-47f5-93ea-efb78960f1a6"
    } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/), (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_yor_name = "vm_windows"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
  timezone                     = var.timezone
  user_data                    = var.user_data
  virtual_machine_scale_set_id = var.virtual_machine_scale_set_id
  vtpm_enabled                 = var.vtpm_enabled
  zone                         = var.zone

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
      condition     = var.network_interface_ids != null || var.new_network_interface != null
      error_message = "Either `new_network_interface` or `network_interface_ids` must be provided."
    }
    precondition {
      condition     = !var.bypass_platform_safety_checks_on_user_schedule_enabled || local.patch_mode == "AutomaticByPlatform"
      error_message = "`bypass_platform_safety_checks_on_user_schedule_enabled` can only be set when patch_mode is `AutomaticByPlatform`"
    }
    precondition {
      condition     = var.reboot_setting == null || local.patch_mode == "AutomaticByPlatform"
      error_message = "`reboot_setting` can only be set when patch_mode is `AutomaticByPlatform`"
    }
  }
}

locals {
  virtual_machine = local.is_windows ? {
    id                            = try(azurerm_windows_virtual_machine.vm_windows[0].id, null)
    name                          = try(azurerm_windows_virtual_machine.vm_windows[0].name, null)
    admin_username                = try(azurerm_windows_virtual_machine.vm_windows[0].admin_username, null)
    network_interface_ids         = try(azurerm_windows_virtual_machine.vm_windows[0].network_interface_ids, null)
    availability_set_id           = try(azurerm_windows_virtual_machine.vm_windows[0].availability_set_id, null)
    capacity_reservation_group_id = try(azurerm_windows_virtual_machine.vm_windows[0].capacity_reservation_group_id, null)
    computer_name                 = try(azurerm_windows_virtual_machine.vm_windows[0].computer_name, null)
    dedicated_host_id             = try(azurerm_windows_virtual_machine.vm_windows[0].dedicated_host_id, null)
    dedicated_host_group_id       = try(azurerm_windows_virtual_machine.vm_windows[0].dedicated_host_group_id, null)
    patch_mode                    = try(azurerm_windows_virtual_machine.vm_windows[0].patch_mode, null)
    proximity_placement_group_id  = try(azurerm_windows_virtual_machine.vm_windows[0].proximity_placement_group_id, null)
    source_image_id               = try(azurerm_windows_virtual_machine.vm_windows[0].source_image_id, null)
    virtual_machine_scale_set_id  = try(azurerm_windows_virtual_machine.vm_windows[0].virtual_machine_scale_set_id, null)
    timezone                      = try(azurerm_windows_virtual_machine.vm_windows[0].timezone, null)
    zone                          = try(azurerm_windows_virtual_machine.vm_windows[0].zone, null)
    identity                      = try(azurerm_windows_virtual_machine.vm_windows[0].identity, null)
    source_image_reference        = try(azurerm_windows_virtual_machine.vm_windows[0].source_image_reference, null)
    } : {
    id                            = try(azurerm_linux_virtual_machine.vm_linux[0].id, null)
    name                          = try(azurerm_linux_virtual_machine.vm_linux[0].name, null)
    admin_username                = try(azurerm_linux_virtual_machine.vm_linux[0].admin_username, null)
    network_interface_ids         = try(azurerm_linux_virtual_machine.vm_linux[0].network_interface_ids, null)
    availability_set_id           = try(azurerm_linux_virtual_machine.vm_linux[0].availability_set_id, null)
    capacity_reservation_group_id = try(azurerm_linux_virtual_machine.vm_linux[0].capacity_reservation_group_id, null)
    computer_name                 = try(azurerm_linux_virtual_machine.vm_linux[0].computer_name, null)
    dedicated_host_id             = try(azurerm_linux_virtual_machine.vm_linux[0].dedicated_host_id, null)
    dedicated_host_group_id       = try(azurerm_linux_virtual_machine.vm_linux[0].dedicated_host_group_id, null)
    patch_mode                    = try(azurerm_linux_virtual_machine.vm_linux[0].patch_mode, null)
    proximity_placement_group_id  = try(azurerm_linux_virtual_machine.vm_linux[0].proximity_placement_group_id, null)
    source_image_id               = try(azurerm_linux_virtual_machine.vm_linux[0].source_image_id, null)
    virtual_machine_scale_set_id  = try(azurerm_linux_virtual_machine.vm_linux[0].virtual_machine_scale_set_id, null)
    timezone                      = null
    zone                          = try(azurerm_linux_virtual_machine.vm_linux[0].zone, null)
    identity                      = try(azurerm_linux_virtual_machine.vm_linux[0].identity, null)
    source_image_reference        = try(azurerm_linux_virtual_machine.vm_linux[0].source_image_reference, null)
  }
}

resource "azurerm_network_interface" "vm" {
  count = var.new_network_interface != null ? 1 : 0

  location                      = var.location
  name                          = coalesce(var.new_network_interface.name, "${var.name}-nic")
  resource_group_name           = var.resource_group_name
  dns_servers                   = var.new_network_interface.dns_servers
  edge_zone                     = var.new_network_interface.edge_zone
  enable_accelerated_networking = var.new_network_interface.accelerated_networking_enabled
  #checkov:skip=CKV_AZURE_118
  enable_ip_forwarding    = var.new_network_interface.ip_forwarding_enabled
  internal_dns_name_label = var.new_network_interface.internal_dns_name_label
  tags = merge(var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "c6c30c1119c3d25829b29efc3cc629b5d4767301"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-01-17 02:03:20"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-virtual-machine"
    avm_yor_trace            = "7a9b7092-4618-41a8-aaca-d429e526a767"
    } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/), (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_yor_name = "vm"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))

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

  lifecycle {
    precondition {
      condition     = var.network_interface_ids == null
      error_message = "`new_network_interface` cannot be used along with `network_interface_ids`."
    }
  }
}

locals {
  network_interface_ids = var.new_network_interface != null ? [
    azurerm_network_interface.vm[0].id
  ] : var.network_interface_ids
}

resource "azurerm_managed_disk" "disk" {
  for_each = { for d in var.data_disks : d.attach_setting.lun => d }

  create_option                    = each.value.create_option
  location                         = var.location
  name                             = each.value.name
  resource_group_name              = var.resource_group_name
  storage_account_type             = each.value.storage_account_type
  disk_access_id                   = each.value.disk_access_id
  disk_encryption_set_id           = each.value.disk_encryption_set_id
  disk_iops_read_only              = each.value.disk_iops_read_only
  disk_iops_read_write             = each.value.disk_iops_read_write
  disk_mbps_read_only              = each.value.disk_mbps_read_only
  disk_mbps_read_write             = each.value.disk_mbps_read_write
  disk_size_gb                     = each.value.disk_size_gb
  edge_zone                        = var.edge_zone
  gallery_image_reference_id       = each.value.gallery_image_reference_id
  hyper_v_generation               = each.value.hyper_v_generation
  image_reference_id               = each.value.image_reference_id
  logical_sector_size              = each.value.logical_sector_size
  max_shares                       = each.value.max_shares
  network_access_policy            = each.value.network_access_policy
  on_demand_bursting_enabled       = each.value.on_demand_bursting_enabled
  os_type                          = title(var.image_os)
  public_network_access_enabled    = each.value.public_network_access_enabled
  secure_vm_disk_encryption_set_id = each.value.secure_vm_disk_encryption_set_id
  security_type                    = each.value.security_type
  source_resource_id               = each.value.source_resource_id
  source_uri                       = each.value.source_uri
  storage_account_id               = each.value.storage_account_id
  tags = merge(var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "c6c30c1119c3d25829b29efc3cc629b5d4767301"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-01-17 02:03:20"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-virtual-machine"
    avm_yor_trace            = "939ede21-d86f-435b-b663-41059b740f0c"
    } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/), (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_yor_name = "disk"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
  tier                   = each.value.tier
  trusted_launch_enabled = each.value.trusted_launch_enabled
  upload_size_bytes      = each.value.upload_size_bytes
  zone                   = var.zone

  dynamic "encryption_settings" {
    for_each = each.value.encryption_settings == null ? [] : [
      "encryption_settings"
    ]

    content {
      dynamic "disk_encryption_key" {
        for_each = each.value.encryption_settings.disk_encryption_key == null ? [] : [
          "disk_encryption_key"
        ]

        content {
          secret_url      = each.value.encryption_settings.disk_encryption_key.secret_url
          source_vault_id = each.value.encryption_settings.disk_encryption_key.source_vault_id
        }
      }
      dynamic "key_encryption_key" {
        for_each = each.value.encryption_settings.key_encryption_key == null ? [] : [
          "key_encryption_key"
        ]

        content {
          key_url         = each.value.encryption_settings.key_encryption_key.key_url
          source_vault_id = each.value.encryption_settings.key_encryption_key.source_vault_id
        }
      }
    }
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "attachment" {
  for_each = {
    for d in var.data_disks : d.attach_setting.lun => d.attach_setting
  }

  caching                   = each.value.caching
  lun                       = each.value.lun
  managed_disk_id           = azurerm_managed_disk.disk[each.key].id
  virtual_machine_id        = local.virtual_machine.id
  create_option             = each.value.create_option
  write_accelerator_enabled = each.value.write_accelerator_enabled
}

resource "azurerm_virtual_machine_extension" "extensions" {
  # The `sensitive` inside `nonsensitive` is a workaround for https://github.com/terraform-linters/tflint-ruleset-azurerm/issues/229
  for_each = nonsensitive({ for e in var.extensions : e.name => e })

  name                        = each.key
  publisher                   = each.value.publisher
  type                        = each.value.type
  type_handler_version        = each.value.type_handler_version
  virtual_machine_id          = local.virtual_machine.id
  auto_upgrade_minor_version  = each.value.auto_upgrade_minor_version
  automatic_upgrade_enabled   = each.value.automatic_upgrade_enabled
  failure_suppression_enabled = each.value.failure_suppression_enabled
  protected_settings          = each.value.protected_settings
  settings                    = each.value.settings
  tags = merge(var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "e5c54b8f98757681c2d2215530ea0ec6bca2588f"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-05-31 08:40:27"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-virtual-machine"
    avm_yor_trace            = "98632022-de3e-4b59-aeb3-3bd7704d2dd7"
    } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/), (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_yor_name = "extensions"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))

  dynamic "protected_settings_from_key_vault" {
    for_each = each.value.protected_settings_from_key_vault == null ? [] : [
      "protected_settings_from_key_vault"
    ]

    content {
      secret_url      = each.value.protected_settings_from_key_vault.secret_url
      source_vault_id = each.value.protected_settings_from_key_vault.source_vault_id
    }
  }

  depends_on = [azurerm_virtual_machine_data_disk_attachment.attachment]
}
