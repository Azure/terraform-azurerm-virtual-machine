variable "image_os" {
  type        = string
  description = "(Required) Enum flag of virtual machine's os system"
  nullable    = false

  validation {
    condition     = contains(["windows", "linux"], var.image_os)
    error_message = "`image_os` must be either `windows` or `linux`."
  }
}

variable "location" {
  type        = string
  description = "(Required) The Azure location where the Virtual Machine should exist. Changing this forces a new resource to be created."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) The name of the Virtual Machine. Changing this forces a new resource to be created."
  nullable    = false
}

variable "os_disk" {
  type = object({
    caching                          = string
    storage_account_type             = string
    disk_encryption_set_id           = optional(string)
    disk_size_gb                     = optional(number)
    name                             = optional(string)
    secure_vm_disk_encryption_set_id = optional(string)
    security_encryption_type         = optional(string)
    write_accelerator_enabled        = optional(bool, false)
    diff_disk_settings = optional(object({
      option    = string
      placement = optional(string, "CacheDisk")
    }), null)
  })
  description = <<-EOT
  object({
    caching                          = "(Required) The Type of Caching which should be used for the Internal OS Disk. Possible values are `None`, `ReadOnly` and `ReadWrite`."
    storage_account_type             = "(Required) The Type of Storage Account which should back this the Internal OS Disk. Possible values are `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`, `StandardSSD_ZRS` and `Premium_ZRS`. Changing this forces a new resource to be created."
    disk_encryption_set_id           = "(Optional) The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk. Conflicts with `secure_vm_disk_encryption_set_id`. The Disk Encryption Set must have the `Reader` Role Assignment scoped on the Key Vault - in addition to an Access Policy to the Key Vault"
    disk_size_gb                     = "(Optional) The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine is sourced from. If specified this must be equal to or larger than the size of the Image the Virtual Machine is based on. When creating a larger disk than exists in the image you'll need to repartition the disk to use the remaining space."
    name                             = "(Optional) The name which should be used for the Internal OS Disk. Changing this forces a new resource to be created."
    secure_vm_disk_encryption_set_id = "(Optional) The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk when the Virtual Machine is a Confidential VM. Conflicts with `disk_encryption_set_id`. Changing this forces a new resource to be created. `secure_vm_disk_encryption_set_id` can only be specified when `security_encryption_type` is set to `DiskWithVMGuestState`."
    security_encryption_type         = "(Optional) Encryption Type when the Virtual Machine is a Confidential VM. Possible values are `VMGuestStateOnly` and `DiskWithVMGuestState`. Changing this forces a new resource to be created. `vtpm_enabled` must be set to `true` when `security_encryption_type` is specified. `encryption_at_host_enabled` cannot be set to `true` when `security_encryption_type` is set to `DiskWithVMGuestState`."
    write_accelerator_enabled        = "(Optional) Should Write Accelerator be Enabled for this OS Disk? Defaults to `false`. This requires that the `storage_account_type` is set to `Premium_LRS` and that `caching` is set to `None`."
    diff_disk_settings               = optional(object({
      option    = "(Required) Specifies the Ephemeral Disk Settings for the OS Disk. At this time the only possible value is `Local`. Changing this forces a new resource to be created."
      placement = "(Optional) Specifies where to store the Ephemeral Disk. Possible values are `CacheDisk` and `ResourceDisk`. Defaults to `CacheDisk`. Changing this forces a new resource to be created."
    }), [])
  })
  EOT
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group in which the Virtual Machine should be exist. Changing this forces a new resource to be created."
  nullable    = false
}

variable "size" {
  type        = string
  description = "(Required) The SKU which should be used for this Virtual Machine, such as `Standard_F2`."
  nullable    = false
}

variable "subnet_id" {
  type        = string
  description = "(Required) The subnet id of the virtual network where the virtual machines will reside."
  nullable    = false
}

variable "additional_unattend_contents" {
  type = list(object({
    content = string
    setting = string
  }))
  default     = []
  description = <<-EOT
  list(object({
    content = "(Required) The XML formatted content that is added to the unattend.xml file for the specified path and component. Changing this forces a new resource to be created."
    setting = "(Required) The name of the setting to which the content applies. Possible values are `AutoLogon` and `FirstLogonCommands`. Changing this forces a new resource to be created."
  }))
  EOT
}

variable "admin_password" {
  type        = string
  default     = null
  description = "(Optional) The Password which should be used for the local-administrator on this Virtual Machine Required when using Windows Virtual Machine. Changing this forces a new resource to be created. When an `admin_password` is specified `disable_password_authentication` must be set to `false`. One of either `admin_password` or `admin_ssh_key` must be specified."
  sensitive   = true
}

variable "admin_ssh_keys" {
  type = set(object({
    public_key = string
    username   = optional(string)
  }))
  default     = []
  description = <<-EOT
  set(object({
    public_key = "(Required) The Public Key which should be used for authentication, which needs to be at least 2048-bit and in `ssh-rsa` format. Changing this forces a new resource to be created."
    username   = "(Optional) The Username for which this Public SSH Key should be configured. Changing this forces a new resource to be created. The Azure VM Agent only allows creating SSH Keys at the path `/home/{admin_username}/.ssh/authorized_keys` - as such this public key will be written to the authorized keys file. If no username is provided this module will use var.admin_username."
  }))
  EOT
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "(Optional) The admin username of the VM that will be deployed."
  nullable    = false
}

variable "allow_extension_operations" {
  type        = bool
  default     = false
  description = "(Optional) Should Extension Operations be allowed on this Virtual Machine? Defaults to `false`."
}

variable "automatic_updates_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Specifies if Automatic Updates are Enabled for the Windows Virtual Machine. Changing this forces a new resource to be created. Defaults to `true`."
}

variable "availability_set_id" {
  type        = string
  default     = null
  description = "(Optional) Specifies the ID of the Availability Set in which the Virtual Machine should exist. Cannot be used along with `new_availability_set`, `new_capacity_reservation_group`, `capacity_reservation_group_id`, `virtual_machine_scale_set_id`, `zone`. Changing this forces a new resource to be created."
}

variable "boot_diagnostics" {
  type        = bool
  default     = false
  description = "(Optional) Enable or Disable boot diagnostics."
  nullable    = false
}

variable "boot_diagnostics_storage_account_uri" {
  type        = string
  default     = null
  description = "(Optional) The Primary/Secondary Endpoint for the Azure Storage Account which should be used to store Boot Diagnostics, including Console Output and Screenshots from the Hypervisor."
}

variable "bypass_platform_safety_checks_on_user_schedule_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Specifies whether to skip platform scheduled patching when a user schedule is associated with the VM. Only valid if patch_mode is `AutomaticByPlatform`."
  nullable    = false
}

variable "capacity_reservation_group_id" {
  type        = string
  default     = null
  description = "(Optional) Specifies the ID of the Capacity Reservation Group which the Virtual Machine should be allocated to. Cannot be used with `new_capacity_reservation_group`, `availability_set_id`, `new_availability_set`, `proximity_placement_group_id`."
}

variable "computer_name" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Hostname which should be used for this Virtual Machine. If unspecified this defaults to the value for the `vm_name` field. If the value of the `vm_name` field is not a valid `computer_name`, then you must specify `computer_name`. Changing this forces a new resource to be created."
}

variable "custom_data" {
  type        = string
  default     = null
  description = "(Optional) The Base64-Encoded Custom Data which should be used for this Virtual Machine. Changing this forces a new resource to be created."

  validation {
    condition     = var.custom_data == null ? true : can(base64decode(var.custom_data))
    error_message = "The `custom_data` must be either `null` or a valid Base64-Encoded string."
  }
}

variable "data_disks" {
  type = set(object({
    name                 = string
    storage_account_type = string
    create_option        = string
    attach_setting = object({
      lun                       = number
      caching                   = string
      create_option             = optional(string, "Attach")
      write_accelerator_enabled = optional(bool, false)
    })
    disk_encryption_set_id           = optional(string)
    disk_iops_read_write             = optional(number)
    disk_mbps_read_write             = optional(number)
    disk_iops_read_only              = optional(number)
    disk_mbps_read_only              = optional(number)
    logical_sector_size              = optional(number)
    source_uri                       = optional(string)
    source_resource_id               = optional(string)
    storage_account_id               = optional(string)
    image_reference_id               = optional(string)
    gallery_image_reference_id       = optional(string)
    disk_size_gb                     = optional(number)
    upload_size_bytes                = optional(number)
    network_access_policy            = optional(string)
    disk_access_id                   = optional(string)
    public_network_access_enabled    = optional(bool, true)
    tier                             = optional(string)
    max_shares                       = optional(number)
    trusted_launch_enabled           = optional(bool)
    secure_vm_disk_encryption_set_id = optional(string)
    security_type                    = optional(string)
    hyper_v_generation               = optional(string)
    on_demand_bursting_enabled       = optional(bool)
    encryption_settings = optional(object({
      disk_encryption_key = optional(object({
        secret_url      = string
        source_vault_id = string
      }))
      key_encryption_key = optional(object({
        key_url         = string
        source_vault_id = string
      }))
    }))
  }))
  default     = []
  description = <<-EOT
  set(object({
    name                             = "(Required) Specifies the name of the Managed Disk. Changing this forces a new resource to be created."
    storage_account_type             = "(Required) The type of storage to use for the managed disk. Possible values are `Standard_LRS`, `StandardSSD_ZRS`, `Premium_LRS`, `PremiumV2_LRS`, `Premium_ZRS`, `StandardSSD_LRS` or `UltraSSD_LRS`. Azure Ultra Disk Storage is only available in a region that support availability zones and can only enabled on the following VM series: `ESv3`, `DSv3`, `FSv3`, `LSv2`, `M` and `Mv2`. For more information see the `Azure Ultra Disk Storage` [product documentation](https://docs.microsoft.com/azure/virtual-machines/windows/disks-enable-ultra-ssd)."
    create_option                    = "(Required) The method to use when creating the managed disk. Changing this forces a new resource to be created. Possible values include: `Import`, `Empty`, `Copy`, `FromImage`, `Restore`, `Upload`."
    attach_setting = object({
      lun                       = number
      caching                   = string
      create_option             = optional(string, "Attach")
      write_accelerator_enabled = optional(bool, false)
    })
    disk_encryption_set_id           = "(Optional) The ID of a Disk Encryption Set which should be used to encrypt this Managed Disk. Conflicts with `secure_vm_disk_encryption_set_id`. The Disk Encryption Set must have the `Reader` Role Assignment scoped on the Key Vault - in addition to an Access Policy to the Key Vault. Disk Encryption Sets are in Public Preview in a limited set of regions"
    disk_iops_read_write             = "(Optional) The number of IOPS allowed for this disk; only settable for UltraSSD disks and PremiumV2 disks. One operation can transfer between 4k and 256k bytes."
    disk_mbps_read_write             = "(Optional) The bandwidth allowed for this disk; only settable for UltraSSD disks and PremiumV2 disks. MBps means millions of bytes per second."
    disk_iops_read_only              = "(Optional) The number of IOPS allowed across all VMs mounting the shared disk as read-only; only settable for UltraSSD disks and PremiumV2 disks with shared disk enabled. One operation can transfer between 4k and 256k bytes."
    disk_mbps_read_only              = "(Optional) The bandwidth allowed across all VMs mounting the shared disk as read-only; only settable for UltraSSD disks and PremiumV2 disks with shared disk enabled. MBps means millions of bytes per second."
    logical_sector_size              = "(Optional) Logical Sector Size. Possible values are: `512` and `4096`. Changing this forces a new resource to be created. Setting logical sector size is supported only with `UltraSSD_LRS` disks and `PremiumV2_LRS` disks."
    source_uri                       = "(Optional) URI to a valid VHD file to be used when `create_option` is `Import`. Changing this forces a new resource to be created."
    source_resource_id               = "(Optional) The ID of an existing Managed Disk or Snapshot to copy when `create_option` is `Copy` or the recovery point to restore when `create_option` is `Restore`. Changing this forces a new resource to be created."
    storage_account_id               = "(Optional) The ID of the Storage Account where the `source_uri` is located. Required when `create_option` is set to `Import`.  Changing this forces a new resource to be created."
    image_reference_id               = "(Optional) ID of an existing platform/marketplace disk image to copy when `create_option` is `FromImage`. This field cannot be specified if gallery_image_reference_id is specified. Changing this forces a new resource to be created."
    gallery_image_reference_id       = "(Optional) ID of a Gallery Image Version to copy when `create_option` is `FromImage`. This field cannot be specified if image_reference_id is specified. Changing this forces a new resource to be created."
    disk_size_gb                     = "(Optional) (Optional, Required for a new managed disk) Specifies the size of the managed disk to create in gigabytes. If `create_option` is `Copy` or `FromImage`, then the value must be equal to or greater than the source's size. The size can only be increased. In certain conditions the Data Disk size can be updated without shutting down the Virtual Machine, however only a subset of Virtual Machine SKUs/Disk combinations support this. More information can be found [for Linux Virtual Machines](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/expand-disks?tabs=azure-cli%2Cubuntu#expand-without-downtime) and [Windows Virtual Machines](https://learn.microsoft.com/azure/virtual-machines/windows/expand-os-disk#expand-without-downtime) respectively. If No Downtime Resizing is not available, be aware that changing this value is disruptive if the disk is attached to a Virtual Machine. The VM will be shut down and de-allocated as required by Azure to action the change. Terraform will attempt to start the machine again after the update if it was in a `running` state when the apply was started."
    upload_size_bytes                = "(Optional) Specifies the size of the managed disk to create in bytes. Required when `create_option` is `Upload`. The value must be equal to the source disk to be copied in bytes. Source disk size could be calculated with `ls -l` or `wc -c`. More information can be found at [Copy a managed disk](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/disks-upload-vhd-to-managed-disk-cli#copy-a-managed-disk). Changing this forces a new resource to be created."
    network_access_policy            = "(Optional) Policy for accessing the disk via network. Allowed values are `AllowAll`, `AllowPrivate`, and `DenyAll`."
    disk_access_id                   = "(Optional) The ID of the disk access resource for using private endpoints on disks. `disk_access_id` is only supported when `network_access_policy` is set to `AllowPrivate`."
    public_network_access_enabled    = "(Optional) Whether it is allowed to access the disk via public network. Defaults to `true`."
    tier                             = "(Optional) The disk performance tier to use. Possible values are documented [here](https://docs.microsoft.com/azure/virtual-machines/disks-change-performance). This feature is currently supported only for premium SSDs. Changing this value is disruptive if the disk is attached to a Virtual Machine. The VM will be shut down and de-allocated as required by Azure to action the change. Terraform will attempt to start the machine again after the update if it was in a `running` state when the apply was started."
    max_shares                       = "(Optional) The maximum number of VMs that can attach to the disk at the same time. Value greater than one indicates a disk that can be mounted on multiple VMs at the same time."
    trusted_launch_enabled           = "(Optional) Specifies if Trusted Launch is enabled for the Managed Disk. Changing this forces a new resource to be created."
    secure_vm_disk_encryption_set_id = "(Optional) The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk when the Virtual Machine is a Confidential VM. Conflicts with `disk_encryption_set_id`. Changing this forces a new resource to be created. `secure_vm_disk_encryption_set_id` can only be specified when `security_type` is set to `ConfidentialVM_DiskEncryptedWithCustomerKey`."
    security_type                    = "(Optional) Security Type of the Managed Disk when it is used for a Confidential VM. Possible values are `ConfidentialVM_VMGuestStateOnlyEncryptedWithPlatformKey`, `ConfidentialVM_DiskEncryptedWithPlatformKey` and `ConfidentialVM_DiskEncryptedWithCustomerKey`. Changing this forces a new resource to be created. `security_type` cannot be specified when `trusted_launch_enabled` is set to true. `secure_vm_disk_encryption_set_id` must be specified when `security_type` is set to `ConfidentialVM_DiskEncryptedWithCustomerKey`."
    hyper_v_generation               = "(Optional) The HyperV Generation of the Disk when the source of an `Import` or `Copy` operation targets a source that contains an operating system. Possible values are `V1` and `V2`. Changing this forces a new resource to be created."
    on_demand_bursting_enabled       = "(Optional) Specifies if On-Demand Bursting is enabled for the Managed Disk. Credit-Based Bursting is enabled by default on all eligible disks. More information on [Credit-Based and On-Demand Bursting can be found in the documentation](https://docs.microsoft.com/azure/virtual-machines/disk-bursting#disk-level-bursting)."
    encryption_settings              = optional(object({
      disk_encryption_key = optional(object({
        secret_url      = "(Required) The URL to the Key Vault Secret used as the Disk Encryption Key. This can be found as `id` on the `azurerm_key_vault_secret` resource."
        source_vault_id = "(Required) The ID of the source Key Vault. This can be found as `id` on the `azurerm_key_vault` resource."
      }))
      key_encryption_key = optional(object({
        key_url         = "(Required) The URL to the Key Vault Key used as the Key Encryption Key. This can be found as `id` on the `azurerm_key_vault_key` resource."
        source_vault_id = "(Required) The ID of the source Key Vault. This can be found as `id` on the `azurerm_key_vault` resource."
      }))
    }))
  }))
  EOT
  nullable    = false

  validation {
    condition = length(var.data_disks) == length(distinct([
      for d in var.data_disks : d.attach_setting.lun
    ]))
    error_message = "`data_disks.attach_setting.lun` must be unique."
  }
}

variable "dedicated_host_group_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of a Dedicated Host Group that this Linux Virtual Machine should be run within. Conflicts with `dedicated_host_id`."
}

variable "dedicated_host_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of a Dedicated Host where this machine should be run on. Conflicts with `dedicated_host_group_id`."
}

variable "disable_password_authentication" {
  type        = bool
  default     = true
  description = "(Optional) Should Password Authentication be disabled on this Virtual Machine? Defaults to `true`. Changing this forces a new resource to be created."
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Linux Virtual Machine should exist. Changing this forces a new Virtual Machine to be created."
}

variable "encryption_at_host_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Should all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host?"
}

variable "eviction_policy" {
  type        = string
  default     = null
  description = "(Optional) Specifies what should happen when the Virtual Machine is evicted for price reasons when using a Spot instance. Possible values are `Deallocate` and `Delete`. Changing this forces a new resource to be created."
}

variable "extensions" {
  type = set(object({
    name                        = string
    publisher                   = string
    type                        = string
    type_handler_version        = string
    auto_upgrade_minor_version  = optional(bool)
    automatic_upgrade_enabled   = optional(bool)
    failure_suppression_enabled = optional(bool, false)
    settings                    = optional(string)
    protected_settings          = optional(string)
    protected_settings_from_key_vault = optional(object({
      secret_url      = string
      source_vault_id = string
    }))
  }))
  # tflint-ignore: terraform_sensitive_variable_no_default
  default     = []
  description = "Argument to create `azurerm_virtual_machine_extension` resource, the argument descriptions could be found at [the document](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension)."
  nullable    = false
  sensitive   = true # Because `protected_settings` is sensitive

  validation {
    condition = length(var.extensions) == length(distinct([
      for e in var.extensions : e.type
    ]))
    error_message = "`type` in `vm_extensions` must be unique."
  }
}

variable "extensions_time_budget" {
  type        = string
  default     = "PT1H30M"
  description = "(Optional) Specifies the duration allocated for all extensions to start. The time duration should be between 15 minutes and 120 minutes (inclusive) and should be specified in ISO 8601 format. Defaults to 90 minutes (`PT1H30M`)."
}

variable "gallery_application" {
  type = list(object({
    version_id             = string
    configuration_blob_uri = optional(string)
    order                  = optional(number, 0)
    tag                    = optional(string)
  }))
  default     = []
  description = <<-EOT
  list(object({
    version_id             = "(Required) Specifies the Gallery Application Version resource ID."
    configuration_blob_uri = "(Optional) Specifies the URI to an Azure Blob that will replace the default configuration for the package if provided."
    order                  = "(Optional) Specifies the order in which the packages have to be installed. Possible values are between `0` and `2,147,483,647`."
    tag                    = "(Optional) Specifies a passthrough value for more generic context. This field can be any valid `string` value."
  }))
  EOT
}

variable "hotpatching_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Should the VM be patched without requiring a reboot? Possible values are `true` or `false`. Defaults to `false`. For more information about hot patching please see the [product documentation](https://docs.microsoft.com/azure/automanage/automanage-hotpatch). Hotpatching can only be enabled if the `patch_mode` is set to `AutomaticByPlatform`, the `provision_vm_agent` is set to `true`, your `source_image_reference` references a hotpatching enabled image, and the VM's `size` is set to a [Azure generation 2](https://docs.microsoft.com/azure/virtual-machines/generation-2#generation-2-vm-sizes) VM. An example of how to correctly configure a Windows Virtual Machine to use the `hotpatching_enabled` field can be found in the [`./examples/virtual-machines/windows/hotpatching-enabled`](https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples/virtual-machines/windows/hotpatching-enabled) directory within the GitHub Repository."
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(set(string))
  })
  default     = null
  description = <<-EOT
  object({
    type         = "(Required) Specifies the type of Managed Service Identity that should be configured on this Linux Virtual Machine. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both)."
    identity_ids = "(Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Linux Virtual Machine. This is required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`."
  })
  EOT
}

variable "license_type" {
  type        = string
  default     = null
  description = "(Optional) For Linux virtual machine specifies the BYOL Type for this Virtual Machine, possible values are `RHEL_BYOS` and `SLES_BYOS`. For Windows virtual machine specifies the type of on-premise license (also known as [Azure Hybrid Use Benefit](https://docs.microsoft.com/windows-server/get-started/azure-hybrid-benefit)) which should be used for this Virtual Machine, possible values are `None`, `Windows_Client` and `Windows_Server`."
}

variable "max_bid_price" {
  type        = number
  default     = -1
  description = "(Optional) The maximum price you're willing to pay for this Virtual Machine, in US Dollars; which must be greater than the current spot price. If this bid price falls below the current spot price the Virtual Machine will be evicted using the `eviction_policy`. Defaults to `-1`, which means that the Virtual Machine should not be evicted for price reasons. This can only be configured when `priority` is set to `Spot`."
}

variable "network_interface_ids" {
  type        = list(string)
  default     = null
  description = "A list of Network Interface IDs which should be attached to this Virtual Machine. The first Network Interface ID in this list will be the Primary Network Interface on the Virtual Machine. Cannot be used along with `new_network_interface`."

  validation {
    condition     = var.network_interface_ids == null ? true : length(var.network_interface_ids) > 0
    error_message = "`network_interface_ids` must be `null` or a non-empty list."
  }
}

variable "new_boot_diagnostics_storage_account" {
  type = object({
    name                             = optional(string)
    account_kind                     = optional(string, "StorageV2")
    account_tier                     = optional(string, "Standard")
    account_replication_type         = optional(string, "LRS")
    cross_tenant_replication_enabled = optional(bool, true)
    access_tier                      = optional(string, "Hot")
    enable_https_traffic_only        = optional(bool, true)
    min_tls_version                  = optional(string, "TLS1_2")
    allow_nested_items_to_be_public  = optional(bool, true)
    shared_access_key_enabled        = optional(bool, true)
    public_network_access_enabled    = optional(bool, false)
    default_to_oauth_authentication  = optional(bool, false)
    customer_managed_key = optional(object({
      key_vault_key_id          = string
      user_assigned_identity_id = string
    }))
    blob_properties = optional(object({
      delete_retention_policy = optional(object({
        days = optional(number, 7)
      }))
      restore_policy = optional(object({
        days = number
      }))
      container_delete_retention_policy = optional(object({
        days = optional(number, 7)
      }))
    }))
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
  })
  default     = null
  description = <<-EOT
  object({
    name                             = "(Optional) Specifies the name of the storage account. Only lowercase Alphanumeric characters allowed. Omit this field would generate one. Changing this forces a new resource to be created. This must be unique across the entire Azure service, not just within the resource group."
    account_kind                     = "(Optional) Defines the Kind of account. Valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`.  Defaults to `StorageV2`. Changing the `account_kind` value from `Storage` to `StorageV2` will not trigger a force new on the storage account, it will only upgrade the existing storage account from `Storage` to `StorageV2` keeping the existing storage account in place."
    account_tier                     = "(Optional) Defines the Tier to use for this storage account. Valid options are `Standard` and `Premium`. For `BlockBlobStorage` and `FileStorage` accounts only `Premium` is valid. Defaults to `Standard`. Changing this forces a new resource to be created. Blobs with a tier of `Premium` are of account kind `StorageV2`."
    account_replication_type         = "(Optional) Defines the type of replication to use for this storage account. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`. Defaults to `LRS`. Changing this forces a new resource to be created when types `LRS`, `GRS` and `RAGRS` are changed to `ZRS`, `GZRS` or `RAGZRS` and vice versa."
    cross_tenant_replication_enabled = "(Optional) Should cross Tenant replication be enabled? Defaults to `true`."
    access_tier                      = "(Optional) Defines the access tier for `BlobStorage`, `FileStorage` and `StorageV2` accounts. Valid options are `Hot` and `Cool`, defaults to `Hot`."
    enable_https_traffic_only        = "(Optional) Boolean flag which forces HTTPS if enabled, see [here](https://docs.microsoft.com/azure/storage/storage-require-secure-transfer/) for more information. Defaults to `true`."
    min_tls_version                  = "(Optional) The minimum supported TLS version for the storage account. Possible values are `TLS1_0`, `TLS1_1`, and `TLS1_2`. Defaults to `TLS1_2` for new storage accounts. At this time `min_tls_version` is only supported in the Public Cloud, China Cloud, and US Government Cloud."
    allow_nested_items_to_be_public  = "(Optional) Allow or disallow nested items within this Account to opt into being public. Defaults to `true`. At this time `allow_nested_items_to_be_public` is only supported in the Public Cloud, China Cloud, and US Government Cloud."
    shared_access_key_enabled        = "(Optional) Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). The default value is `true`. Terraform uses Shared Key Authorisation to provision Storage Containers, Blobs and other items - when Shared Key Access is disabled, you will need to enable [the `storage_use_azuread` flag in the Provider block](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#storage_use_azuread) to use Azure AD for authentication, however not all Azure Storage services support Active Directory authentication."
    public_network_access_enabled    = "(Optional) Whether the public network access is enabled? Defaults to `false`."
    default_to_oauth_authentication  = "(Optional) Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account. The default value is `false`"
    customer_managed_key             = optional(object({
      key_vault_key_id          = "(Required) The ID of the Key Vault Key, supplying a version-less key ID will enable auto-rotation of this key."
      user_assigned_identity_id = "(Required) The ID of a user assigned identity. `customer_managed_key` can only be set when the `account_kind` is set to `StorageV2` or `account_tier` set to `Premium`, and the identity type is `UserAssigned`."
    }))
    blob_properties = optional(object({
      delete_retention_policy = optional(object({
        days = "(Optional) Specifies the number of days that the blob should be retained, between `1` and `365` days. Defaults to `7`."
      }))
      restore_policy = optional(object({
        days = "(Required) Specifies the number of days that the blob can be restored, between `1` and `365` days. This must be less than the `days` specified for `delete_retention_policy`."
      }))
      container_delete_retention_policy = optional(object({
        days = "(Optional) Specifies the number of days that the container should be retained, between `1` and `365` days. Defaults to `7`."
      }))
    }))
    identity = optional(object({
      type         = "(Required) Specifies the type of Managed Service Identity that should be configured on this Storage Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both)."
      identity_ids = "(Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Storage Account. This is required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`."
    }))
  })
  EOT
}

variable "new_network_interface" {
  type = object({
    name = optional(string)
    ip_configurations = list(object({
      name                                               = optional(string)
      private_ip_address                                 = optional(string)
      private_ip_address_version                         = optional(string, "IPv4")
      private_ip_address_allocation                      = optional(string, "Dynamic")
      public_ip_address_id                               = optional(string)
      primary                                            = optional(bool, false)
      gateway_load_balancer_frontend_ip_configuration_id = optional(string)
    }))
    dns_servers                    = optional(list(string))
    edge_zone                      = optional(string)
    accelerated_networking_enabled = optional(bool, false)
    ip_forwarding_enabled          = optional(bool, false)
    internal_dns_name_label        = optional(string)
  })
  default = {
    name = null
    ip_configurations = [
      {
        name                                               = null
        private_ip_address                                 = null
        private_ip_address_version                         = null
        public_ip_address_id                               = null
        private_ip_address_allocation                      = null
        primary                                            = true
        gateway_load_balancer_frontend_ip_configuration_id = null
      }
    ]
    dns_servers                    = null
    edge_zone                      = null
    accelerated_networking_enabled = null
    ip_forwarding_enabled          = null
    internal_dns_name_label        = null
  }
  description = <<-EOT
  New Network Interface that should be created and attached to this Virtual Machine. Cannot be used along with `network_interface_ids`.
  name = "(Optional) The name of the Network Interface. Omit this name would generate one. Changing this forces a new resource to be created."
  ip_configurations = list(object({
    name                                               = "(Optional) A name used for this IP Configuration. Omit this name would generate one. Changing this forces a new resource to be created."
    private_ip_address                                 = "(Optional) The Static IP Address which should be used. When `private_ip_address_allocation` is set to `Static` this field can be configured."
    private_ip_address_version                         = "(Optional) The IP Version to use. Possible values are `IPv4` or `IPv6`. Defaults to `IPv4`."
    private_ip_address_allocation                      = "(Required) The allocation method used for the Private IP Address. Possible values are `Dynamic` and `Static`. Defaults to `Dynamic`."
    public_ip_address_id                               = "(Optional) Reference to a Public IP Address to associate with this NIC"
    primary                                            = "(Optional) Is this the Primary IP Configuration? Must be `true` for the first `ip_configuration`. Defaults to `false`."
    gateway_load_balancer_frontend_ip_configuration_id = "(Optional) The Frontend IP Configuration ID of a Gateway SKU Load Balancer."
  }))
  dns_servers                    = "(Optional) A list of IP Addresses defining the DNS Servers which should be used for this Network Interface. Configuring DNS Servers on the Network Interface will override the DNS Servers defined on the Virtual Network."
  edge_zone                      = "(Optional) Specifies the Edge Zone within the Azure Region where this Network Interface should exist. Changing this forces a new Network Interface to be created."
  accelerated_networking_enabled = "(Optional) Should Accelerated Networking be enabled? Defaults to `false`. Only certain Virtual Machine sizes are supported for Accelerated Networking - [more information can be found in this document](https://docs.microsoft.com/azure/virtual-network/create-vm-accelerated-networking-cli). To use Accelerated Networking in an Availability Set, the Availability Set must be deployed onto an Accelerated Networking enabled cluster."
  ip_forwarding_enabled          = "(Optional) Should IP Forwarding be enabled? Defaults to `false`."
  internal_dns_name_label        = "(Optional) The (relative) DNS Name used for internal communications between Virtual Machines in the same Virtual Network."
  EOT

  validation {
    condition     = var.new_network_interface == null ? true : var.new_network_interface.ip_configurations == null ? false : length(var.new_network_interface.ip_configurations) > 0
    error_message = "`new_network_interface.ip_configurations` cannot be `null` or empty."
  }
}

variable "os_simple" {
  type        = string
  default     = null
  description = "Specify UbuntuServer, WindowsServer, RHEL, openSUSE-Leap, CentOS, Debian, CoreOS and SLES to get the latest image version of the specified os.  Do not provide this value if a custom value is used for vm_os_publisher, vm_os_offer, and vm_os_sku."
}

variable "os_version" {
  type        = string
  default     = "latest"
  description = "The version of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  nullable    = false
}

variable "patch_assessment_mode" {
  type        = string
  default     = "ImageDefault"
  description = "(Optional) Specifies the mode of VM Guest Patching for the Virtual Machine. Possible values are `AutomaticByPlatform` or `ImageDefault`. Defaults to `ImageDefault`."
}

variable "patch_mode" {
  type        = string
  default     = null
  description = "(Optional) Specifies the mode of in-guest patching to this Linux Virtual Machine. Possible values are `AutomaticByPlatform` and `ImageDefault`. Defaults to `ImageDefault`. For more information on patch modes please see the [product documentation](https://docs.microsoft.com/azure/virtual-machines/automatic-vm-guest-patching#patch-orchestration-modes)."
}

variable "plan" {
  type = object({
    name      = string
    product   = string
    publisher = string
  })
  default     = null
  description = <<-EOT
  object({
    name      = "(Required) Specifies the Name of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created."
    product   = "(Required) Specifies the Product of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created."
    publisher = "(Required) Specifies the Publisher of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created."
  })
  EOT
}

variable "platform_fault_domain" {
  type = number
  # Why use `null` instead of [`-1`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine#platform_fault_domain) as default value? `platform_fault_domain` must be set along with `virtual_machine_scale_set_id` so the default value must be `null` for this module if we don't want to use `virtual_machine_scale_set_id`.
  default     = null
  description = "(Optional) Specifies the Platform Fault Domain in which this Virtual Machine should be created. Defaults to `null`, which means this will be automatically assigned to a fault domain that best maintains balance across the available fault domains. `virtual_machine_scale_set_id` is required with it. Changing this forces new Virtual Machine to be created."
}

variable "priority" {
  type        = string
  default     = "Regular"
  description = "(Optional) Specifies the priority of this Virtual Machine. Possible values are `Regular` and `Spot`. Defaults to `Regular`. Changing this forces a new resource to be created."
}

variable "provision_vm_agent" {
  type        = bool
  default     = true
  description = "(Optional) Should the Azure VM Agent be provisioned on this Virtual Machine? Defaults to `true`. Changing this forces a new resource to be created. If `provision_vm_agent` is set to `false` then `allow_extension_operations` must also be set to `false`."
}

variable "proximity_placement_group_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the Proximity Placement Group which the Virtual Machine should be assigned to. Conflicts with `capacity_reservation_group_id`."
}

variable "reboot_setting" {
  type        = string
  default     = null
  description = "(Optional) Specifies the reboot setting for platform scheduled patching. Possible values are `Always`, `IfRequired` and `Never`. Only valid if `patch_mode` is `AutomaticByPlatform`."

  validation {
    condition     = var.reboot_setting == null ? true : contains(["Always", "IfRequired", "Never"], var.reboot_setting)
    error_message = "`var.reboot_setting` is not a valid value. Use one of: `Always`, `IfRequired`, `Never`"
  }
}

variable "secrets" {
  type = list(object({
    key_vault_id = string
    certificate = set(object({
      url   = string
      store = optional(string)
    }))
  }))
  default     = []
  description = <<-EOT
  list(object({
    key_vault_id = "(Required) The ID of the Key Vault from which all Secrets should be sourced."
    certificate  = set(object({
      url   = "(Required) The Secret URL of a Key Vault Certificate. This can be sourced from the `secret_id` field within the `azurerm_key_vault_certificate` Resource."
      store = "(Optional) The certificate store on the Virtual Machine where the certificate should be added. Required when use with Windows Virtual Machine."
    }))
  }))
  EOT
  nullable    = false
}

variable "secure_boot_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Specifies whether secure boot should be enabled on the virtual machine. Changing this forces a new resource to be created."
}

variable "source_image_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the Image which this Virtual Machine should be created from. Changing this forces a new resource to be created. Possible Image ID types include `Image ID`s, `Shared Image ID`s, `Shared Image Version ID`s, `Community Gallery Image ID`s, `Community Gallery Image Version ID`s, `Shared Gallery Image ID`s and `Shared Gallery Image Version ID`s. One of either `source_image_id` or `source_image_reference` must be set."
}

variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default     = null
  description = <<-EOT
  object({
    publisher = "(Required) Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created."
    offer     = "(Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created."
    sku       = "(Required) Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created."
    version   = "(Required) Specifies the version of the image used to create the virtual machines. Changing this forces a new resource to be created."
  })
  EOT
}

variable "standard_os" {
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
  }))
  default = {
    UbuntuServer = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
    }
    WindowsServer = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
    }
    RHEL = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "8.2"
    }
    openSUSE-Leap = {
      publisher = "SUSE"
      offer     = "openSUSE-Leap"
      sku       = "15.1"
    }
    CentOS = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7.6"
    }
    Debian = {
      publisher = "credativ"
      offer     = "Debian"
      sku       = "9"
    }
    CoreOS = {
      publisher = "CoreOS"
      offer     = "CoreOS"
      sku       = "Stable"
    }
    SLES = {
      publisher = "SUSE"
      offer     = "SLES"
      sku       = "12-SP2"
    }
  }
  description = <<-EOT
  map(object({
    publisher = "(Required) Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created."
    offer     = "(Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created."
    sku       = "(Required) Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created."
  }))
  EOT
  nullable    = false
}

variable "tags" {
  type = map(string)
  default = {
    source = "terraform"
  }
  description = "A map of the tags to use on the resources that are deployed with this module."
}

variable "termination_notification" {
  type = object({
    enabled = bool
    timeout = optional(string, "PT5M")
  })
  default     = null
  description = <<-EOT
  object({
    enabled = bool
    timeout = optional(string, "PT5M")
  })
  EOT
}

variable "timezone" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Time Zone which should be used by the Virtual Machine, [the possible values are defined here](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/). Changing this forces a new resource to be created."
}

# tflint-ignore: terraform_unused_declarations
variable "tracing_tags_enabled" {
  type        = bool
  default     = false
  description = "Whether enable tracing tags that generated by BridgeCrew Yor."
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tracing_tags_prefix" {
  type        = string
  default     = "avm_"
  description = "Default prefix for generated tracing tags"
  nullable    = false
}

variable "user_data" {
  type        = string
  default     = null
  description = "(Optional) The Base64-Encoded User Data which should be used for this Virtual Machine."

  validation {
    condition     = var.user_data == null ? true : can(base64decode(var.user_data))
    error_message = "`user_data` must be either `null` or valid base64 encoded string."
  }
}

variable "virtual_machine_scale_set_id" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Orchestrated Virtual Machine Scale Set that this Virtual Machine should be created within. Conflicts with `availability_set_id`. Changing this forces a new resource to be created."
}

variable "vm_additional_capabilities" {
  type = object({
    ultra_ssd_enabled = optional(bool, false)
  })
  default     = null
  description = <<-EOT
  object({
    ultra_ssd_enabled = "(Optional) Should the capacity to enable Data Disks of the `UltraSSD_LRS` storage account type be supported on this Virtual Machine? Defaults to `false`."
  })
  EOT
}

variable "vtpm_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Specifies whether vTPM should be enabled on the virtual machine. Changing this forces a new resource to be created."
}

variable "winrm_listeners" {
  type = set(object({
    protocol        = string
    certificate_url = optional(string)
  }))
  default     = []
  description = <<-EOT
  set(object({
    protocol        = "(Required) Specifies Specifies the protocol of listener. Possible values are `Http` or `Https`"
    certificate_url = "(Optional) The Secret URL of a Key Vault Certificate, which must be specified when `protocol` is set to `Https`. Changing this forces a new resource to be created."
  }))
  EOT
  nullable    = false
}

variable "zone" {
  type        = string
  default     = null
  description = "(Optional) The Availability Zone which the Virtual Machine should be allocated in, only one zone would be accepted. If set then this module won't create `azurerm_availability_set` resource. Changing this forces a new resource to be created."
}
