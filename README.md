# terraform-azurerm-virtual-machine

## Deploys 1 Virtual Machines to your provided VNet

This Terraform module deploys one Virtual Machines in Azure with the following characteristics:

- Ability to specify a simple string to get the [latest marketplace image](https://docs.microsoft.com/cli/azure/vm/image?view=azure-cli-latest) using `var.os_simple`
- All VMs use [managed disks](https://azure.microsoft.com/services/managed-disks/)
- VM nic attached to an existed virtual network subnet via `var.subnet_id`.

This module will only create resources that **belong to** the virtual machine, like managed disk and network interface. It won't create resources that **don't belong to** this virtual machine, like network security group.

## Example Usage

```hcl
module "linux" {
  source = "../.."

  location                   = local.resource_group.location
  image_os                   = "linux"
  resource_group_name        = local.resource_group.name
  allow_extension_operations = false
  data_disks = [
    for i in range(2) : {
      name                 = "linuxdisk${random_id.id.hex}${i}"
      storage_account_type = "Standard_LRS"
      create_option        = "Empty"
      disk_size_gb         = 1
      attach_setting = {
        lun     = i
        caching = "ReadWrite"
      }
      disk_encryption_set_id = azurerm_disk_encryption_set.example.id
    }
  ]
  new_boot_diagnostics_storage_account = {
    customer_managed_key = {
      key_vault_key_id          = azurerm_key_vault_key.storage_account_key.id
      user_assigned_identity_id = azurerm_user_assigned_identity.storage_account_key_vault.id
    }
  }
  new_network_interface = {
    ip_forwarding_enabled = false
    ip_configurations = [
      {
        public_ip_address_id = try(azurerm_public_ip.pip[0].id, null)
        primary              = true
      }
    ]
  }
  admin_username = "azureuser"
  admin_ssh_keys = [
    {
      public_key = tls_private_key.ssh.public_key_openssh
    }
  ]
  name = "ubuntu-${random_id.id.hex}"
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  os_simple = "UbuntuServer"
  size      = var.size
  subnet_id = module.vnet.vnet_subnets[0]

  depends_on = [azurerm_key_vault_access_policy.des]
}
```

Please refer to the sub folders under `examples` folder. You can execute `terraform apply` command in `examples`'s sub folder to try the module. These examples are tested against every PR with the [E2E Test](#pre-commit--pr-check--test).

## Enable or disable tracing tags

We're using [BridgeCrew Yor](https://github.com/bridgecrewio/yor) and [yorbox](https://github.com/lonegunmanb/yorbox) to help manage tags consistently across infrastructure as code (IaC) frameworks. In this module you might see tags like:

```hcl
resource "azurerm_resource_group" "rg" {
  location = "eastus"
  name     = random_pet.name
  tags = merge(var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "3077cc6d0b70e29b6e106b3ab98cee6740c916f6"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-05-05 08:57:54"
    avm_git_org              = "lonegunmanb"
    avm_git_repo             = "terraform-yor-tag-test-module"
    avm_yor_trace            = "a0425718-c57d-401c-a7d5-f3d88b2551a4"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
}
```

To enable tracing tags, set the variable to true:

```hcl
module "example" {
  source               = <module_source>
  ...
  tracing_tags_enabled = true
}
```

The `tracing_tags_enabled` is default to `false`.

To customize the prefix for your tracing tags, set the `tracing_tags_prefix` variable value in your Terraform configuration:

```hcl
module "example" {
  source              = <module_source>
  ...
  tracing_tags_prefix = "custom_prefix_"
}
```

The actual applied tags would be:

```text
{
  custom_prefix_git_commit           = "3077cc6d0b70e29b6e106b3ab98cee6740c916f6"
  custom_prefix_git_file             = "main.tf"
  custom_prefix_git_last_modified_at = "2023-05-05 08:57:54"
  custom_prefix_git_org              = "lonegunmanb"
  custom_prefix_git_repo             = "terraform-yor-tag-test-module"
  custom_prefix_yor_trace            = "a0425718-c57d-401c-a7d5-f3d88b2551a4"
}
```

## Pre-Commit & Pr-Check & Test

### Configurations

- [Configure Terraform for Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure)

We assumed that you have setup service principal's credentials in your environment variables like below:

```shell
export ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
export ARM_TENANT_ID="<azure_subscription_tenant_id>"
export ARM_CLIENT_ID="<service_principal_appid>"
export ARM_CLIENT_SECRET="<service_principal_password>"
```

On Windows Powershell:

```shell
$env:ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
$env:ARM_TENANT_ID="<azure_subscription_tenant_id>"
$env:ARM_CLIENT_ID="<service_principal_appid>"
$env:ARM_CLIENT_SECRET="<service_principal_password>"
```

We provide a docker image to run the pre-commit checks and tests for you: `mcr.microsoft.com/azterraform:latest`

To run the pre-commit task, we can run the following command:

```shell
$ docker run --rm -v $(pwd):/src -w /src mcr.microsoft.com/azterraform:latest make pre-commit
```

On Windows Powershell:

```shell
$ docker run --rm -v ${pwd}:/src -w /src mcr.microsoft.com/azterraform:latest make pre-commit
```

In pre-commit task, we will:

1. Run `terraform fmt -recursive` command for your Terraform code.
2. Run `terrafmt fmt -f` command for markdown files and go code files to ensure that the Terraform code embedded in these files are well formatted.
3. Run `go mod tidy` and `go mod vendor` for test folder to ensure that all the dependencies have been synced.
4. Run `gofmt` for all go code files.
5. Run `gofumpt` for all go code files.
6. Run `terraform-docs` on `README.md` file, then run `markdown-table-formatter` to format markdown tables in `README.md`.

Then we can run the pr-check task to check whether our code meets our pipeline's requirement(We strongly recommend you run the following command before you commit):

```shell
$ docker run --rm -v $(pwd):/src -w /src mcr.microsoft.com/azterraform:latest make pr-check
```

On Windows Powershell:

```shell
$ docker run --rm -v ${pwd}:/src -w /src mcr.microsoft.com/azterraform:latest make pr-check
```

To run the e2e-test, we can run the following command:

```text
docker run --rm -v $(pwd):/src -w /src -e ARM_SUBSCRIPTION_ID -e ARM_TENANT_ID -e ARM_CLIENT_ID -e ARM_CLIENT_SECRET mcr.microsoft.com/azterraform:latest make e2e-test
```

On Windows Powershell:

```text
docker run --rm -v ${pwd}:/src -w /src -e ARM_SUBSCRIPTION_ID -e ARM_TENANT_ID -e ARM_CLIENT_ID -e ARM_CLIENT_SECRET mcr.microsoft.com/azterraform:latest make e2e-test
```

#### Prerequisites

- [Docker](https://www.docker.com/community-edition#/download)

## Authors

Originally created by [lonegunmanb](http://github.com/lonegunmanb)

## License

[MIT](LICENSE)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.11, < 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.11, < 4.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >=3.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.vm_linux](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_managed_disk.disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_network_interface.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_storage_account.boot_diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_virtual_machine_data_disk_attachment.attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.extensions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.vm_windows](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
| [random_id.vm_sa](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_unattend_contents"></a> [additional\_unattend\_contents](#input\_additional\_unattend\_contents) | list(object({<br>  content = "(Required) The XML formatted content that is added to the unattend.xml file for the specified path and component. Changing this forces a new resource to be created."<br>  setting = "(Required) The name of the setting to which the content applies. Possible values are `AutoLogon` and `FirstLogonCommands`. Changing this forces a new resource to be created."<br>})) | <pre>list(object({<br>    content = string<br>    setting = string<br>  }))</pre> | `[]` | no |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | (Optional) The Password which should be used for the local-administrator on this Virtual Machine Required when using Windows Virtual Machine. Changing this forces a new resource to be created. When an `admin_password` is specified `disable_password_authentication` must be set to `false`. One of either `admin_password` or `admin_ssh_key` must be specified. | `string` | `null` | no |
| <a name="input_admin_ssh_keys"></a> [admin\_ssh\_keys](#input\_admin\_ssh\_keys) | set(object({<br>  public\_key = "(Required) The Public Key which should be used for authentication, which needs to be at least 2048-bit and in `ssh-rsa` format. Changing this forces a new resource to be created."<br>  username   = "(Optional) The Username for which this Public SSH Key should be configured. Changing this forces a new resource to be created. The Azure VM Agent only allows creating SSH Keys at the path `/home/{admin_username}/.ssh/authorized_keys` - as such this public key will be written to the authorized keys file. If no username is provided this module will use var.admin\_username."<br>})) | <pre>set(object({<br>    public_key = string<br>    username   = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | (Optional) The admin username of the VM that will be deployed. | `string` | `"azureuser"` | no |
| <a name="input_allow_extension_operations"></a> [allow\_extension\_operations](#input\_allow\_extension\_operations) | (Optional) Should Extension Operations be allowed on this Virtual Machine? Defaults to `false`. | `bool` | `false` | no |
| <a name="input_automatic_updates_enabled"></a> [automatic\_updates\_enabled](#input\_automatic\_updates\_enabled) | (Optional) Specifies if Automatic Updates are Enabled for the Windows Virtual Machine. Changing this forces a new resource to be created. Defaults to `true`. | `bool` | `true` | no |
| <a name="input_availability_set_id"></a> [availability\_set\_id](#input\_availability\_set\_id) | (Optional) Specifies the ID of the Availability Set in which the Virtual Machine should exist. Cannot be used along with `new_availability_set`, `new_capacity_reservation_group`, `capacity_reservation_group_id`, `virtual_machine_scale_set_id`, `zone`. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_boot_diagnostics"></a> [boot\_diagnostics](#input\_boot\_diagnostics) | (Optional) Enable or Disable boot diagnostics. | `bool` | `false` | no |
| <a name="input_boot_diagnostics_storage_account_uri"></a> [boot\_diagnostics\_storage\_account\_uri](#input\_boot\_diagnostics\_storage\_account\_uri) | (Optional) The Primary/Secondary Endpoint for the Azure Storage Account which should be used to store Boot Diagnostics, including Console Output and Screenshots from the Hypervisor. | `string` | `null` | no |
| <a name="input_bypass_platform_safety_checks_on_user_schedule_enabled"></a> [bypass\_platform\_safety\_checks\_on\_user\_schedule\_enabled](#input\_bypass\_platform\_safety\_checks\_on\_user\_schedule\_enabled) | (Optional) Specifies whether to skip platform scheduled patching when a user schedule is associated with the VM. Only valid if patch\_mode is `AutomaticByPlatform`. | `bool` | `false` | no |
| <a name="input_capacity_reservation_group_id"></a> [capacity\_reservation\_group\_id](#input\_capacity\_reservation\_group\_id) | (Optional) Specifies the ID of the Capacity Reservation Group which the Virtual Machine should be allocated to. Cannot be used with `new_capacity_reservation_group`, `availability_set_id`, `new_availability_set`, `proximity_placement_group_id`. | `string` | `null` | no |
| <a name="input_computer_name"></a> [computer\_name](#input\_computer\_name) | (Optional) Specifies the Hostname which should be used for this Virtual Machine. If unspecified this defaults to the value for the `vm_name` field. If the value of the `vm_name` field is not a valid `computer_name`, then you must specify `computer_name`. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_custom_data"></a> [custom\_data](#input\_custom\_data) | (Optional) The Base64-Encoded Custom Data which should be used for this Virtual Machine. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_data_disks"></a> [data\_disks](#input\_data\_disks) | set(object({<br>  name                             = "(Required) Specifies the name of the Managed Disk. Changing this forces a new resource to be created."<br>  storage\_account\_type             = "(Required) The type of storage to use for the managed disk. Possible values are `Standard_LRS`, `StandardSSD_ZRS`, `Premium_LRS`, `PremiumV2_LRS`, `Premium_ZRS`, `StandardSSD_LRS` or `UltraSSD_LRS`. Azure Ultra Disk Storage is only available in a region that support availability zones and can only enabled on the following VM series: `ESv3`, `DSv3`, `FSv3`, `LSv2`, `M` and `Mv2`. For more information see the `Azure Ultra Disk Storage` [product documentation](https://docs.microsoft.com/azure/virtual-machines/windows/disks-enable-ultra-ssd)."<br>  create\_option                    = "(Required) The method to use when creating the managed disk. Changing this forces a new resource to be created. Possible values include: `Import`, `Empty`, `Copy`, `FromImage`, `Restore`, `Upload`."<br>  attach\_setting = object({<br>    lun                       = number<br>    caching                   = string<br>    create\_option             = optional(string, "Attach")<br>    write\_accelerator\_enabled = optional(bool, false)<br>  })<br>  disk\_encryption\_set\_id           = "(Optional) The ID of a Disk Encryption Set which should be used to encrypt this Managed Disk. Conflicts with `secure_vm_disk_encryption_set_id`. The Disk Encryption Set must have the `Reader` Role Assignment scoped on the Key Vault - in addition to an Access Policy to the Key Vault. Disk Encryption Sets are in Public Preview in a limited set of regions"<br>  disk\_iops\_read\_write             = "(Optional) The number of IOPS allowed for this disk; only settable for UltraSSD disks and PremiumV2 disks. One operation can transfer between 4k and 256k bytes."<br>  disk\_mbps\_read\_write             = "(Optional) The bandwidth allowed for this disk; only settable for UltraSSD disks and PremiumV2 disks. MBps means millions of bytes per second."<br>  disk\_iops\_read\_only              = "(Optional) The number of IOPS allowed across all VMs mounting the shared disk as read-only; only settable for UltraSSD disks and PremiumV2 disks with shared disk enabled. One operation can transfer between 4k and 256k bytes."<br>  disk\_mbps\_read\_only              = "(Optional) The bandwidth allowed across all VMs mounting the shared disk as read-only; only settable for UltraSSD disks and PremiumV2 disks with shared disk enabled. MBps means millions of bytes per second."<br>  logical\_sector\_size              = "(Optional) Logical Sector Size. Possible values are: `512` and `4096`. Changing this forces a new resource to be created. Setting logical sector size is supported only with `UltraSSD_LRS` disks and `PremiumV2_LRS` disks."<br>  source\_uri                       = "(Optional) URI to a valid VHD file to be used when `create_option` is `Import`. Changing this forces a new resource to be created."<br>  source\_resource\_id               = "(Optional) The ID of an existing Managed Disk or Snapshot to copy when `create_option` is `Copy` or the recovery point to restore when `create_option` is `Restore`. Changing this forces a new resource to be created."<br>  storage\_account\_id               = "(Optional) The ID of the Storage Account where the `source_uri` is located. Required when `create_option` is set to `Import`.  Changing this forces a new resource to be created."<br>  image\_reference\_id               = "(Optional) ID of an existing platform/marketplace disk image to copy when `create_option` is `FromImage`. This field cannot be specified if gallery\_image\_reference\_id is specified. Changing this forces a new resource to be created."<br>  gallery\_image\_reference\_id       = "(Optional) ID of a Gallery Image Version to copy when `create_option` is `FromImage`. This field cannot be specified if image\_reference\_id is specified. Changing this forces a new resource to be created."<br>  disk\_size\_gb                     = "(Optional) (Optional, Required for a new managed disk) Specifies the size of the managed disk to create in gigabytes. If `create_option` is `Copy` or `FromImage`, then the value must be equal to or greater than the source's size. The size can only be increased. In certain conditions the Data Disk size can be updated without shutting down the Virtual Machine, however only a subset of Virtual Machine SKUs/Disk combinations support this. More information can be found [for Linux Virtual Machines](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/expand-disks?tabs=azure-cli%2Cubuntu#expand-without-downtime) and [Windows Virtual Machines](https://learn.microsoft.com/azure/virtual-machines/windows/expand-os-disk#expand-without-downtime) respectively. If No Downtime Resizing is not available, be aware that changing this value is disruptive if the disk is attached to a Virtual Machine. The VM will be shut down and de-allocated as required by Azure to action the change. Terraform will attempt to start the machine again after the update if it was in a `running` state when the apply was started."<br>  upload\_size\_bytes                = "(Optional) Specifies the size of the managed disk to create in bytes. Required when `create_option` is `Upload`. The value must be equal to the source disk to be copied in bytes. Source disk size could be calculated with `ls -l` or `wc -c`. More information can be found at [Copy a managed disk](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/disks-upload-vhd-to-managed-disk-cli#copy-a-managed-disk). Changing this forces a new resource to be created."<br>  network\_access\_policy            = "(Optional) Policy for accessing the disk via network. Allowed values are `AllowAll`, `AllowPrivate`, and `DenyAll`."<br>  disk\_access\_id                   = "(Optional) The ID of the disk access resource for using private endpoints on disks. `disk_access_id` is only supported when `network_access_policy` is set to `AllowPrivate`."<br>  public\_network\_access\_enabled    = "(Optional) Whether it is allowed to access the disk via public network. Defaults to `true`."<br>  tier                             = "(Optional) The disk performance tier to use. Possible values are documented [here](https://docs.microsoft.com/azure/virtual-machines/disks-change-performance). This feature is currently supported only for premium SSDs. Changing this value is disruptive if the disk is attached to a Virtual Machine. The VM will be shut down and de-allocated as required by Azure to action the change. Terraform will attempt to start the machine again after the update if it was in a `running` state when the apply was started."<br>  max\_shares                       = "(Optional) The maximum number of VMs that can attach to the disk at the same time. Value greater than one indicates a disk that can be mounted on multiple VMs at the same time."<br>  trusted\_launch\_enabled           = "(Optional) Specifies if Trusted Launch is enabled for the Managed Disk. Changing this forces a new resource to be created."<br>  secure\_vm\_disk\_encryption\_set\_id = "(Optional) The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk when the Virtual Machine is a Confidential VM. Conflicts with `disk_encryption_set_id`. Changing this forces a new resource to be created. `secure_vm_disk_encryption_set_id` can only be specified when `security_type` is set to `ConfidentialVM_DiskEncryptedWithCustomerKey`."<br>  security\_type                    = "(Optional) Security Type of the Managed Disk when it is used for a Confidential VM. Possible values are `ConfidentialVM_VMGuestStateOnlyEncryptedWithPlatformKey`, `ConfidentialVM_DiskEncryptedWithPlatformKey` and `ConfidentialVM_DiskEncryptedWithCustomerKey`. Changing this forces a new resource to be created. `security_type` cannot be specified when `trusted_launch_enabled` is set to true. `secure_vm_disk_encryption_set_id` must be specified when `security_type` is set to `ConfidentialVM_DiskEncryptedWithCustomerKey`."<br>  hyper\_v\_generation               = "(Optional) The HyperV Generation of the Disk when the source of an `Import` or `Copy` operation targets a source that contains an operating system. Possible values are `V1` and `V2`. Changing this forces a new resource to be created."<br>  on\_demand\_bursting\_enabled       = "(Optional) Specifies if On-Demand Bursting is enabled for the Managed Disk. Credit-Based Bursting is enabled by default on all eligible disks. More information on [Credit-Based and On-Demand Bursting can be found in the documentation](https://docs.microsoft.com/azure/virtual-machines/disk-bursting#disk-level-bursting)."<br>  encryption\_settings              = optional(object({<br>    disk\_encryption\_key = optional(object({<br>      secret\_url      = "(Required) The URL to the Key Vault Secret used as the Disk Encryption Key. This can be found as `id` on the `azurerm_key_vault_secret` resource."<br>      source\_vault\_id = "(Required) The ID of the source Key Vault. This can be found as `id` on the `azurerm_key_vault` resource."<br>    }))<br>    key\_encryption\_key = optional(object({<br>      key\_url         = "(Required) The URL to the Key Vault Key used as the Key Encryption Key. This can be found as `id` on the `azurerm_key_vault_key` resource."<br>      source\_vault\_id = "(Required) The ID of the source Key Vault. This can be found as `id` on the `azurerm_key_vault` resource."<br>    }))<br>  }))<br>})) | <pre>set(object({<br>    name                 = string<br>    storage_account_type = string<br>    create_option        = string<br>    attach_setting = object({<br>      lun                       = number<br>      caching                   = string<br>      create_option             = optional(string, "Attach")<br>      write_accelerator_enabled = optional(bool, false)<br>    })<br>    disk_encryption_set_id           = optional(string)<br>    disk_iops_read_write             = optional(number)<br>    disk_mbps_read_write             = optional(number)<br>    disk_iops_read_only              = optional(number)<br>    disk_mbps_read_only              = optional(number)<br>    logical_sector_size              = optional(number)<br>    source_uri                       = optional(string)<br>    source_resource_id               = optional(string)<br>    storage_account_id               = optional(string)<br>    image_reference_id               = optional(string)<br>    gallery_image_reference_id       = optional(string)<br>    disk_size_gb                     = optional(number)<br>    upload_size_bytes                = optional(number)<br>    network_access_policy            = optional(string)<br>    disk_access_id                   = optional(string)<br>    public_network_access_enabled    = optional(bool, true)<br>    tier                             = optional(string)<br>    max_shares                       = optional(number)<br>    trusted_launch_enabled           = optional(bool)<br>    secure_vm_disk_encryption_set_id = optional(string)<br>    security_type                    = optional(string)<br>    hyper_v_generation               = optional(string)<br>    on_demand_bursting_enabled       = optional(bool)<br>    encryption_settings = optional(object({<br>      disk_encryption_key = optional(object({<br>        secret_url      = string<br>        source_vault_id = string<br>      }))<br>      key_encryption_key = optional(object({<br>        key_url         = string<br>        source_vault_id = string<br>      }))<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_dedicated_host_group_id"></a> [dedicated\_host\_group\_id](#input\_dedicated\_host\_group\_id) | (Optional) The ID of a Dedicated Host Group that this Linux Virtual Machine should be run within. Conflicts with `dedicated_host_id`. | `string` | `null` | no |
| <a name="input_dedicated_host_id"></a> [dedicated\_host\_id](#input\_dedicated\_host\_id) | (Optional) The ID of a Dedicated Host where this machine should be run on. Conflicts with `dedicated_host_group_id`. | `string` | `null` | no |
| <a name="input_disable_password_authentication"></a> [disable\_password\_authentication](#input\_disable\_password\_authentication) | (Optional) Should Password Authentication be disabled on this Virtual Machine? Defaults to `true`. Changing this forces a new resource to be created. | `bool` | `true` | no |
| <a name="input_edge_zone"></a> [edge\_zone](#input\_edge\_zone) | (Optional) Specifies the Edge Zone within the Azure Region where this Linux Virtual Machine should exist. Changing this forces a new Virtual Machine to be created. | `string` | `null` | no |
| <a name="input_encryption_at_host_enabled"></a> [encryption\_at\_host\_enabled](#input\_encryption\_at\_host\_enabled) | (Optional) Should all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host? | `bool` | `null` | no |
| <a name="input_eviction_policy"></a> [eviction\_policy](#input\_eviction\_policy) | (Optional) Specifies what should happen when the Virtual Machine is evicted for price reasons when using a Spot instance. Possible values are `Deallocate` and `Delete`. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_extensions"></a> [extensions](#input\_extensions) | Argument to create `azurerm_virtual_machine_extension` resource, the argument descriptions could be found at [the document](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension). | <pre>set(object({<br>    name                        = string<br>    publisher                   = string<br>    type                        = string<br>    type_handler_version        = string<br>    auto_upgrade_minor_version  = optional(bool)<br>    automatic_upgrade_enabled   = optional(bool)<br>    failure_suppression_enabled = optional(bool, false)<br>    settings                    = optional(string)<br>    protected_settings          = optional(string)<br>    protected_settings_from_key_vault = optional(object({<br>      secret_url      = string<br>      source_vault_id = string<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_extensions_time_budget"></a> [extensions\_time\_budget](#input\_extensions\_time\_budget) | (Optional) Specifies the duration allocated for all extensions to start. The time duration should be between 15 minutes and 120 minutes (inclusive) and should be specified in ISO 8601 format. Defaults to 90 minutes (`PT1H30M`). | `string` | `"PT1H30M"` | no |
| <a name="input_gallery_application"></a> [gallery\_application](#input\_gallery\_application) | list(object({<br>  version\_id             = "(Required) Specifies the Gallery Application Version resource ID."<br>  configuration\_blob\_uri = "(Optional) Specifies the URI to an Azure Blob that will replace the default configuration for the package if provided."<br>  order                  = "(Optional) Specifies the order in which the packages have to be installed. Possible values are between `0` and `2,147,483,647`."<br>  tag                    = "(Optional) Specifies a passthrough value for more generic context. This field can be any valid `string` value."<br>})) | <pre>list(object({<br>    version_id             = string<br>    configuration_blob_uri = optional(string)<br>    order                  = optional(number, 0)<br>    tag                    = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_hotpatching_enabled"></a> [hotpatching\_enabled](#input\_hotpatching\_enabled) | (Optional) Should the VM be patched without requiring a reboot? Possible values are `true` or `false`. Defaults to `false`. For more information about hot patching please see the [product documentation](https://docs.microsoft.com/azure/automanage/automanage-hotpatch). Hotpatching can only be enabled if the `patch_mode` is set to `AutomaticByPlatform`, the `provision_vm_agent` is set to `true`, your `source_image_reference` references a hotpatching enabled image, and the VM's `size` is set to a [Azure generation 2](https://docs.microsoft.com/azure/virtual-machines/generation-2#generation-2-vm-sizes) VM. An example of how to correctly configure a Windows Virtual Machine to use the `hotpatching_enabled` field can be found in the [`./examples/virtual-machines/windows/hotpatching-enabled`](https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples/virtual-machines/windows/hotpatching-enabled) directory within the GitHub Repository. | `bool` | `false` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | object({<br>  type         = "(Required) Specifies the type of Managed Service Identity that should be configured on this Linux Virtual Machine. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both)."<br>  identity\_ids = "(Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Linux Virtual Machine. This is required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`."<br>}) | <pre>object({<br>    type         = string<br>    identity_ids = optional(set(string))<br>  })</pre> | `null` | no |
| <a name="input_image_os"></a> [image\_os](#input\_image\_os) | (Required) Enum flag of virtual machine's os system | `string` | n/a | yes |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | (Optional) For Linux virtual machine specifies the BYOL Type for this Virtual Machine, possible values are `RHEL_BYOS` and `SLES_BYOS`. For Windows virtual machine specifies the type of on-premise license (also known as [Azure Hybrid Use Benefit](https://docs.microsoft.com/windows-server/get-started/azure-hybrid-benefit)) which should be used for this Virtual Machine, possible values are `None`, `Windows_Client` and `Windows_Server`. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) The Azure location where the Virtual Machine should exist. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_max_bid_price"></a> [max\_bid\_price](#input\_max\_bid\_price) | (Optional) The maximum price you're willing to pay for this Virtual Machine, in US Dollars; which must be greater than the current spot price. If this bid price falls below the current spot price the Virtual Machine will be evicted using the `eviction_policy`. Defaults to `-1`, which means that the Virtual Machine should not be evicted for price reasons. This can only be configured when `priority` is set to `Spot`. | `number` | `-1` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the Virtual Machine. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_network_interface_ids"></a> [network\_interface\_ids](#input\_network\_interface\_ids) | A list of Network Interface IDs which should be attached to this Virtual Machine. The first Network Interface ID in this list will be the Primary Network Interface on the Virtual Machine. Cannot be used along with `new_network_interface`. | `list(string)` | `null` | no |
| <a name="input_new_boot_diagnostics_storage_account"></a> [new\_boot\_diagnostics\_storage\_account](#input\_new\_boot\_diagnostics\_storage\_account) | object({<br>  name                             = "(Optional) Specifies the name of the storage account. Only lowercase Alphanumeric characters allowed. Omit this field would generate one. Changing this forces a new resource to be created. This must be unique across the entire Azure service, not just within the resource group."<br>  account\_kind                     = "(Optional) Defines the Kind of account. Valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`.  Defaults to `StorageV2`. Changing the `account_kind` value from `Storage` to `StorageV2` will not trigger a force new on the storage account, it will only upgrade the existing storage account from `Storage` to `StorageV2` keeping the existing storage account in place."<br>  account\_tier                     = "(Optional) Defines the Tier to use for this storage account. Valid options are `Standard` and `Premium`. For `BlockBlobStorage` and `FileStorage` accounts only `Premium` is valid. Defaults to `Standard`. Changing this forces a new resource to be created. Blobs with a tier of `Premium` are of account kind `StorageV2`."<br>  account\_replication\_type         = "(Optional) Defines the type of replication to use for this storage account. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`. Defaults to `LRS`. Changing this forces a new resource to be created when types `LRS`, `GRS` and `RAGRS` are changed to `ZRS`, `GZRS` or `RAGZRS` and vice versa."<br>  cross\_tenant\_replication\_enabled = "(Optional) Should cross Tenant replication be enabled? Defaults to `true`."<br>  access\_tier                      = "(Optional) Defines the access tier for `BlobStorage`, `FileStorage` and `StorageV2` accounts. Valid options are `Hot` and `Cool`, defaults to `Hot`."<br>  enable\_https\_traffic\_only        = "(Optional) Boolean flag which forces HTTPS if enabled, see [here](https://docs.microsoft.com/azure/storage/storage-require-secure-transfer/) for more information. Defaults to `true`."<br>  min\_tls\_version                  = "(Optional) The minimum supported TLS version for the storage account. Possible values are `TLS1_0`, `TLS1_1`, and `TLS1_2`. Defaults to `TLS1_2` for new storage accounts. At this time `min_tls_version` is only supported in the Public Cloud, China Cloud, and US Government Cloud."<br>  allow\_nested\_items\_to\_be\_public  = "(Optional) Allow or disallow nested items within this Account to opt into being public. Defaults to `true`. At this time `allow_nested_items_to_be_public` is only supported in the Public Cloud, China Cloud, and US Government Cloud."<br>  shared\_access\_key\_enabled        = "(Optional) Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). The default value is `true`. Terraform uses Shared Key Authorisation to provision Storage Containers, Blobs and other items - when Shared Key Access is disabled, you will need to enable [the `storage_use_azuread` flag in the Provider block](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#storage_use_azuread) to use Azure AD for authentication, however not all Azure Storage services support Active Directory authentication."<br>  public\_network\_access\_enabled    = "(Optional) Whether the public network access is enabled? Defaults to `false`."<br>  default\_to\_oauth\_authentication  = "(Optional) Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account. The default value is `false`"<br>  customer\_managed\_key             = optional(object({<br>    key\_vault\_key\_id          = "(Required) The ID of the Key Vault Key, supplying a version-less key ID will enable auto-rotation of this key."<br>    user\_assigned\_identity\_id = "(Required) The ID of a user assigned identity. `customer_managed_key` can only be set when the `account_kind` is set to `StorageV2` or `account_tier` set to `Premium`, and the identity type is `UserAssigned`."<br>  }))<br>  blob\_properties = optional(object({<br>    delete\_retention\_policy = optional(object({<br>      days = "(Optional) Specifies the number of days that the blob should be retained, between `1` and `365` days. Defaults to `7`."<br>    }))<br>    restore\_policy = optional(object({<br>      days = "(Required) Specifies the number of days that the blob can be restored, between `1` and `365` days. This must be less than the `days` specified for `delete_retention_policy`."<br>    }))<br>    container\_delete\_retention\_policy = optional(object({<br>      days = "(Optional) Specifies the number of days that the container should be retained, between `1` and `365` days. Defaults to `7`."<br>    }))<br>  }))<br>  identity = optional(object({<br>    type         = "(Required) Specifies the type of Managed Service Identity that should be configured on this Storage Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both)."<br>    identity\_ids = "(Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Storage Account. This is required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`."<br>  }))<br>}) | <pre>object({<br>    name                             = optional(string)<br>    account_kind                     = optional(string, "StorageV2")<br>    account_tier                     = optional(string, "Standard")<br>    account_replication_type         = optional(string, "LRS")<br>    cross_tenant_replication_enabled = optional(bool, true)<br>    access_tier                      = optional(string, "Hot")<br>    enable_https_traffic_only        = optional(bool, true)<br>    min_tls_version                  = optional(string, "TLS1_2")<br>    allow_nested_items_to_be_public  = optional(bool, true)<br>    shared_access_key_enabled        = optional(bool, true)<br>    public_network_access_enabled    = optional(bool, false)<br>    default_to_oauth_authentication  = optional(bool, false)<br>    customer_managed_key = optional(object({<br>      key_vault_key_id          = string<br>      user_assigned_identity_id = string<br>    }))<br>    blob_properties = optional(object({<br>      delete_retention_policy = optional(object({<br>        days = optional(number, 7)<br>      }))<br>      restore_policy = optional(object({<br>        days = number<br>      }))<br>      container_delete_retention_policy = optional(object({<br>        days = optional(number, 7)<br>      }))<br>    }))<br>    identity = optional(object({<br>      type         = string<br>      identity_ids = optional(list(string))<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_new_network_interface"></a> [new\_network\_interface](#input\_new\_network\_interface) | New Network Interface that should be created and attached to this Virtual Machine. Cannot be used along with `network_interface_ids`.<br>name = "(Optional) The name of the Network Interface. Omit this name would generate one. Changing this forces a new resource to be created."<br>ip\_configurations = list(object({<br>  name                                               = "(Optional) A name used for this IP Configuration. Omit this name would generate one. Changing this forces a new resource to be created."<br>  private\_ip\_address                                 = "(Optional) The Static IP Address which should be used. When `private_ip_address_allocation` is set to `Static` this field can be configured."<br>  private\_ip\_address\_version                         = "(Optional) The IP Version to use. Possible values are `IPv4` or `IPv6`. Defaults to `IPv4`."<br>  private\_ip\_address\_allocation                      = "(Required) The allocation method used for the Private IP Address. Possible values are `Dynamic` and `Static`. Defaults to `Dynamic`."<br>  public\_ip\_address\_id                               = "(Optional) Reference to a Public IP Address to associate with this NIC"<br>  primary                                            = "(Optional) Is this the Primary IP Configuration? Must be `true` for the first `ip_configuration`. Defaults to `false`."<br>  gateway\_load\_balancer\_frontend\_ip\_configuration\_id = "(Optional) The Frontend IP Configuration ID of a Gateway SKU Load Balancer."<br>}))<br>dns\_servers                    = "(Optional) A list of IP Addresses defining the DNS Servers which should be used for this Network Interface. Configuring DNS Servers on the Network Interface will override the DNS Servers defined on the Virtual Network."<br>edge\_zone                      = "(Optional) Specifies the Edge Zone within the Azure Region where this Network Interface should exist. Changing this forces a new Network Interface to be created."<br>accelerated\_networking\_enabled = "(Optional) Should Accelerated Networking be enabled? Defaults to `false`. Only certain Virtual Machine sizes are supported for Accelerated Networking - [more information can be found in this document](https://docs.microsoft.com/azure/virtual-network/create-vm-accelerated-networking-cli). To use Accelerated Networking in an Availability Set, the Availability Set must be deployed onto an Accelerated Networking enabled cluster."<br>ip\_forwarding\_enabled          = "(Optional) Should IP Forwarding be enabled? Defaults to `false`."<br>internal\_dns\_name\_label        = "(Optional) The (relative) DNS Name used for internal communications between Virtual Machines in the same Virtual Network." | <pre>object({<br>    name = optional(string)<br>    ip_configurations = list(object({<br>      name                                               = optional(string)<br>      private_ip_address                                 = optional(string)<br>      private_ip_address_version                         = optional(string, "IPv4")<br>      private_ip_address_allocation                      = optional(string, "Dynamic")<br>      public_ip_address_id                               = optional(string)<br>      primary                                            = optional(bool, false)<br>      gateway_load_balancer_frontend_ip_configuration_id = optional(string)<br>    }))<br>    dns_servers                    = optional(list(string))<br>    edge_zone                      = optional(string)<br>    accelerated_networking_enabled = optional(bool, false)<br>    ip_forwarding_enabled          = optional(bool, false)<br>    internal_dns_name_label        = optional(string)<br>  })</pre> | <pre>{<br>  "accelerated_networking_enabled": null,<br>  "dns_servers": null,<br>  "edge_zone": null,<br>  "internal_dns_name_label": null,<br>  "ip_configurations": [<br>    {<br>      "gateway_load_balancer_frontend_ip_configuration_id": null,<br>      "name": null,<br>      "primary": true,<br>      "private_ip_address": null,<br>      "private_ip_address_allocation": null,<br>      "private_ip_address_version": null,<br>      "public_ip_address_id": null<br>    }<br>  ],<br>  "ip_forwarding_enabled": null,<br>  "name": null<br>}</pre> | no |
| <a name="input_os_disk"></a> [os\_disk](#input\_os\_disk) | object({<br>  caching                          = "(Required) The Type of Caching which should be used for the Internal OS Disk. Possible values are `None`, `ReadOnly` and `ReadWrite`."<br>  storage\_account\_type             = "(Required) The Type of Storage Account which should back this the Internal OS Disk. Possible values are `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`, `StandardSSD_ZRS` and `Premium_ZRS`. Changing this forces a new resource to be created."<br>  disk\_encryption\_set\_id           = "(Optional) The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk. Conflicts with `secure_vm_disk_encryption_set_id`. The Disk Encryption Set must have the `Reader` Role Assignment scoped on the Key Vault - in addition to an Access Policy to the Key Vault"<br>  disk\_size\_gb                     = "(Optional) The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine is sourced from. If specified this must be equal to or larger than the size of the Image the Virtual Machine is based on. When creating a larger disk than exists in the image you'll need to repartition the disk to use the remaining space."<br>  name                             = "(Optional) The name which should be used for the Internal OS Disk. Changing this forces a new resource to be created."<br>  secure\_vm\_disk\_encryption\_set\_id = "(Optional) The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk when the Virtual Machine is a Confidential VM. Conflicts with `disk_encryption_set_id`. Changing this forces a new resource to be created. `secure_vm_disk_encryption_set_id` can only be specified when `security_encryption_type` is set to `DiskWithVMGuestState`."<br>  security\_encryption\_type         = "(Optional) Encryption Type when the Virtual Machine is a Confidential VM. Possible values are `VMGuestStateOnly` and `DiskWithVMGuestState`. Changing this forces a new resource to be created. `vtpm_enabled` must be set to `true` when `security_encryption_type` is specified. `encryption_at_host_enabled` cannot be set to `true` when `security_encryption_type` is set to `DiskWithVMGuestState`."<br>  write\_accelerator\_enabled        = "(Optional) Should Write Accelerator be Enabled for this OS Disk? Defaults to `false`. This requires that the `storage_account_type` is set to `Premium_LRS` and that `caching` is set to `None`."<br>  diff\_disk\_settings               = optional(object({<br>    option    = "(Required) Specifies the Ephemeral Disk Settings for the OS Disk. At this time the only possible value is `Local`. Changing this forces a new resource to be created."<br>    placement = "(Optional) Specifies where to store the Ephemeral Disk. Possible values are `CacheDisk` and `ResourceDisk`. Defaults to `CacheDisk`. Changing this forces a new resource to be created."<br>  }), [])<br>}) | <pre>object({<br>    caching                          = string<br>    storage_account_type             = string<br>    disk_encryption_set_id           = optional(string)<br>    disk_size_gb                     = optional(number)<br>    name                             = optional(string)<br>    secure_vm_disk_encryption_set_id = optional(string)<br>    security_encryption_type         = optional(string)<br>    write_accelerator_enabled        = optional(bool, false)<br>    diff_disk_settings = optional(object({<br>      option    = string<br>      placement = optional(string, "CacheDisk")<br>    }), null)<br>  })</pre> | n/a | yes |
| <a name="input_os_simple"></a> [os\_simple](#input\_os\_simple) | Specify UbuntuServer, WindowsServer, RHEL, openSUSE-Leap, CentOS, Debian, CoreOS and SLES to get the latest image version of the specified os.  Do not provide this value if a custom value is used for vm\_os\_publisher, vm\_os\_offer, and vm\_os\_sku. | `string` | `null` | no |
| <a name="input_os_version"></a> [os\_version](#input\_os\_version) | The version of the image that you want to deploy. This is ignored when vm\_os\_id or vm\_os\_simple are provided. | `string` | `"latest"` | no |
| <a name="input_patch_assessment_mode"></a> [patch\_assessment\_mode](#input\_patch\_assessment\_mode) | (Optional) Specifies the mode of VM Guest Patching for the Virtual Machine. Possible values are `AutomaticByPlatform` or `ImageDefault`. Defaults to `ImageDefault`. | `string` | `"ImageDefault"` | no |
| <a name="input_patch_mode"></a> [patch\_mode](#input\_patch\_mode) | (Optional) Specifies the mode of in-guest patching to this Linux Virtual Machine. Possible values are `AutomaticByPlatform` and `ImageDefault`. Defaults to `ImageDefault`. For more information on patch modes please see the [product documentation](https://docs.microsoft.com/azure/virtual-machines/automatic-vm-guest-patching#patch-orchestration-modes). | `string` | `null` | no |
| <a name="input_plan"></a> [plan](#input\_plan) | object({<br>  name      = "(Required) Specifies the Name of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created."<br>  product   = "(Required) Specifies the Product of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created."<br>  publisher = "(Required) Specifies the Publisher of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created."<br>}) | <pre>object({<br>    name      = string<br>    product   = string<br>    publisher = string<br>  })</pre> | `null` | no |
| <a name="input_platform_fault_domain"></a> [platform\_fault\_domain](#input\_platform\_fault\_domain) | (Optional) Specifies the Platform Fault Domain in which this Virtual Machine should be created. Defaults to `null`, which means this will be automatically assigned to a fault domain that best maintains balance across the available fault domains. `virtual_machine_scale_set_id` is required with it. Changing this forces new Virtual Machine to be created. | `number` | `null` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | (Optional) Specifies the priority of this Virtual Machine. Possible values are `Regular` and `Spot`. Defaults to `Regular`. Changing this forces a new resource to be created. | `string` | `"Regular"` | no |
| <a name="input_provision_vm_agent"></a> [provision\_vm\_agent](#input\_provision\_vm\_agent) | (Optional) Should the Azure VM Agent be provisioned on this Virtual Machine? Defaults to `true`. Changing this forces a new resource to be created. If `provision_vm_agent` is set to `false` then `allow_extension_operations` must also be set to `false`. | `bool` | `true` | no |
| <a name="input_proximity_placement_group_id"></a> [proximity\_placement\_group\_id](#input\_proximity\_placement\_group\_id) | (Optional) The ID of the Proximity Placement Group which the Virtual Machine should be assigned to. Conflicts with `capacity_reservation_group_id`. | `string` | `null` | no |
| <a name="input_reboot_setting"></a> [reboot\_setting](#input\_reboot\_setting) | (Optional) Specifies the reboot setting for platform scheduled patching. Possible values are `Always`, `IfRequired` and `Never`. Only valid if `patch_mode` is `AutomaticByPlatform`. | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the Resource Group in which the Virtual Machine should be exist. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | list(object({<br>  key\_vault\_id = "(Required) The ID of the Key Vault from which all Secrets should be sourced."<br>  certificate  = set(object({<br>    url   = "(Required) The Secret URL of a Key Vault Certificate. This can be sourced from the `secret_id` field within the `azurerm_key_vault_certificate` Resource."<br>    store = "(Optional) The certificate store on the Virtual Machine where the certificate should be added. Required when use with Windows Virtual Machine."<br>  }))<br>})) | <pre>list(object({<br>    key_vault_id = string<br>    certificate = set(object({<br>      url   = string<br>      store = optional(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_secure_boot_enabled"></a> [secure\_boot\_enabled](#input\_secure\_boot\_enabled) | (Optional) Specifies whether secure boot should be enabled on the virtual machine. Changing this forces a new resource to be created. | `bool` | `null` | no |
| <a name="input_size"></a> [size](#input\_size) | (Required) The SKU which should be used for this Virtual Machine, such as `Standard_F2`. | `string` | n/a | yes |
| <a name="input_source_image_id"></a> [source\_image\_id](#input\_source\_image\_id) | (Optional) The ID of the Image which this Virtual Machine should be created from. Changing this forces a new resource to be created. Possible Image ID types include `Image ID`s, `Shared Image ID`s, `Shared Image Version ID`s, `Community Gallery Image ID`s, `Community Gallery Image Version ID`s, `Shared Gallery Image ID`s and `Shared Gallery Image Version ID`s. One of either `source_image_id` or `source_image_reference` must be set. | `string` | `null` | no |
| <a name="input_source_image_reference"></a> [source\_image\_reference](#input\_source\_image\_reference) | object({<br>  publisher = "(Required) Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created."<br>  offer     = "(Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created."<br>  sku       = "(Required) Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created."<br>  version   = "(Required) Specifies the version of the image used to create the virtual machines. Changing this forces a new resource to be created."<br>}) | <pre>object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  })</pre> | `null` | no |
| <a name="input_standard_os"></a> [standard\_os](#input\_standard\_os) | map(object({<br>  publisher = "(Required) Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created."<br>  offer     = "(Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created."<br>  sku       = "(Required) Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created."<br>})) | <pre>map(object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>  }))</pre> | <pre>{<br>  "CentOS": {<br>    "offer": "CentOS",<br>    "publisher": "OpenLogic",<br>    "sku": "7.6"<br>  },<br>  "CoreOS": {<br>    "offer": "CoreOS",<br>    "publisher": "CoreOS",<br>    "sku": "Stable"<br>  },<br>  "Debian": {<br>    "offer": "Debian",<br>    "publisher": "credativ",<br>    "sku": "9"<br>  },<br>  "RHEL": {<br>    "offer": "RHEL",<br>    "publisher": "RedHat",<br>    "sku": "8.2"<br>  },<br>  "SLES": {<br>    "offer": "SLES",<br>    "publisher": "SUSE",<br>    "sku": "12-SP2"<br>  },<br>  "UbuntuServer": {<br>    "offer": "UbuntuServer",<br>    "publisher": "Canonical",<br>    "sku": "18.04-LTS"<br>  },<br>  "WindowsServer": {<br>    "offer": "WindowsServer",<br>    "publisher": "MicrosoftWindowsServer",<br>    "sku": "2019-Datacenter"<br>  },<br>  "openSUSE-Leap": {<br>    "offer": "openSUSE-Leap",<br>    "publisher": "SUSE",<br>    "sku": "15.1"<br>  }<br>}</pre> | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | (Required) The subnet id of the virtual network where the virtual machines will reside. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of the tags to use on the resources that are deployed with this module. | `map(string)` | <pre>{<br>  "source": "terraform"<br>}</pre> | no |
| <a name="input_termination_notification"></a> [termination\_notification](#input\_termination\_notification) | object({<br>  enabled = bool<br>  timeout = optional(string, "PT5M")<br>}) | <pre>object({<br>    enabled = bool<br>    timeout = optional(string, "PT5M")<br>  })</pre> | `null` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | (Optional) Specifies the Time Zone which should be used by the Virtual Machine, [the possible values are defined here](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/). Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_tracing_tags_enabled"></a> [tracing\_tags\_enabled](#input\_tracing\_tags\_enabled) | Whether enable tracing tags that generated by BridgeCrew Yor. | `bool` | `false` | no |
| <a name="input_tracing_tags_prefix"></a> [tracing\_tags\_prefix](#input\_tracing\_tags\_prefix) | Default prefix for generated tracing tags | `string` | `"avm_"` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | (Optional) The Base64-Encoded User Data which should be used for this Virtual Machine. | `string` | `null` | no |
| <a name="input_virtual_machine_scale_set_id"></a> [virtual\_machine\_scale\_set\_id](#input\_virtual\_machine\_scale\_set\_id) | (Optional) Specifies the Orchestrated Virtual Machine Scale Set that this Virtual Machine should be created within. Conflicts with `availability_set_id`. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_vm_additional_capabilities"></a> [vm\_additional\_capabilities](#input\_vm\_additional\_capabilities) | object({<br>  ultra\_ssd\_enabled = "(Optional) Should the capacity to enable Data Disks of the `UltraSSD_LRS` storage account type be supported on this Virtual Machine? Defaults to `false`."<br>}) | <pre>object({<br>    ultra_ssd_enabled = optional(bool, false)<br>  })</pre> | `null` | no |
| <a name="input_vtpm_enabled"></a> [vtpm\_enabled](#input\_vtpm\_enabled) | (Optional) Specifies whether vTPM should be enabled on the virtual machine. Changing this forces a new resource to be created. | `bool` | `null` | no |
| <a name="input_winrm_listeners"></a> [winrm\_listeners](#input\_winrm\_listeners) | set(object({<br>  protocol        = "(Required) Specifies Specifies the protocol of listener. Possible values are `Http` or `Https`"<br>  certificate\_url = "(Optional) The Secret URL of a Key Vault Certificate, which must be specified when `protocol` is set to `Https`. Changing this forces a new resource to be created."<br>})) | <pre>set(object({<br>    protocol        = string<br>    certificate_url = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | (Optional) The Availability Zone which the Virtual Machine should be allocated in, only one zone would be accepted. If set then this module won't create `azurerm_availability_set` resource. Changing this forces a new resource to be created. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data_disk_ids"></a> [data\_disk\_ids](#output\_data\_disk\_ids) | The list of data disk IDs attached to this Virtual Machine. |
| <a name="output_network_interface_id"></a> [network\_interface\_id](#output\_network\_interface\_id) | Id of the vm nic that created by this module. `null` if `var.network_interface_ids` is provided. |
| <a name="output_network_interface_private_ip"></a> [network\_interface\_private\_ip](#output\_network\_interface\_private\_ip) | Private ip address of the vm nic that created by this module. `null` if `var.network_interface_ids` is provided. |
| <a name="output_vm_admin_username"></a> [vm\_admin\_username](#output\_vm\_admin\_username) | The username of the administrator configured in the Virtual Machine. |
| <a name="output_vm_availability_set_id"></a> [vm\_availability\_set\_id](#output\_vm\_availability\_set\_id) | The ID of the Availability Set in which the Virtual Machine exists. |
| <a name="output_vm_dedicated_host_group_id"></a> [vm\_dedicated\_host\_group\_id](#output\_vm\_dedicated\_host\_group\_id) | The ID of a Dedicated Host Group that this Linux Virtual Machine runs within |
| <a name="output_vm_dedicated_host_id"></a> [vm\_dedicated\_host\_id](#output\_vm\_dedicated\_host\_id) | The ID of a Dedicated Host where this machine runs on |
| <a name="output_vm_id"></a> [vm\_id](#output\_vm\_id) | Virtual machine ids created. |
| <a name="output_vm_identity"></a> [vm\_identity](#output\_vm\_identity) | map with key `Virtual Machine Id`, value `list of identity` created for the Virtual Machine. |
| <a name="output_vm_name"></a> [vm\_name](#output\_vm\_name) | Virtual machine names created. |
| <a name="output_vm_virtual_machine_scale_set_id"></a> [vm\_virtual\_machine\_scale\_set\_id](#output\_vm\_virtual\_machine\_scale\_set\_id) | The Orchestrated Virtual Machine Scale Set id that this Virtual Machine was created within. |
| <a name="output_vm_zone"></a> [vm\_zone](#output\_vm\_zone) | The Availability Zones in which this Virtual Machine is located. |
<!-- END_TF_DOCS -->
