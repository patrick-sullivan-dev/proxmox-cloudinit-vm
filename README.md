# Proxmox VM Module

Terraform module for creating and bootstrapping Proxmox VE virtual machines with cloud-init. 

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.13.5)

- <a name="requirement_local"></a> [local](#requirement\_local) (>= 2.4.0)

- <a name="requirement_macaddress"></a> [macaddress](#requirement\_macaddress) (>= 0.3.2)

- <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) (>= 0.111.1)

## Providers

The following providers are used by this module:

- <a name="provider_local"></a> [local](#provider\_local) (>= 2.4.0)

- <a name="provider_macaddress"></a> [macaddress](#provider\_macaddress) (>= 0.3.2)

- <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) (>= 0.111.1)

## Modules

No modules.

## Resources

The following resources are used by this module:

- [local_file.rendered_network_config_debug](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (resource)
- [local_file.rendered_user_config_debug](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (resource)
- [macaddress_macaddress.this](https://registry.terraform.io/providers/ivoronin/macaddress/latest/docs/resources/macaddress) (resource)
- [proxmox_virtual_environment_file.network_data_cloud_config](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) (resource)
- [proxmox_virtual_environment_file.user_data_cloud_config](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) (resource)
- [proxmox_virtual_environment_vm.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) (resource)

## Required Inputs

The following input variables are required:

### <a name="input_cloud_init"></a> [cloud\_init](#input\_cloud\_init)

Description: Cloud-init configuration, datastore must allow content type 'snippets' and disk datastore must allow VM images

Type:

```hcl
object({
    datastore_id        = optional(string, "local")
    node_name           = optional(string)
    disk_datastore_id   = optional(string, "local-lvm")
    interface           = optional(string)
    file_format         = optional(string)
    vendor_data_file_id = optional(string)
    meta_data_file_id   = optional(string)

    hostname = optional(string, null)
    fqdn     = optional(string, null)

    user_data = optional(list(object({
      username        = optional(string, "ubuntu")
      password        = optional(string, null)
      groups          = optional(list(string), ["sudo"])
      shell           = optional(string, "/bin/bash")
      sudoers         = optional(string, "ALL=(ALL) NOPASSWD:ALL")
      ssh_import_ids  = optional(list(string), [])
      authorized_keys = optional(list(string), [])
    })), [{}])

    network_data = optional(list(object({
      interface_name = optional(string, "eth0")
      addresses      = optional(list(string), [])
      dhcp4          = optional(bool, null)
      dhcp6          = optional(bool, false)
      default_route  = optional(string, null)
      dns_servers    = optional(list(string), [])
      dns_domains    = optional(list(string), [])
      mac_prefix     = optional(list(number), [2])
    })), [{}])

    packages = optional(list(string), [])
  })
```

### <a name="input_disks"></a> [disks](#input\_disks)

Description: Disk specifications.

Specify only the disk interface type: scsi, sata, or virtio.  
Do not include an index such as scsi0; indexes are assigned automatically.

The import\_from and file\_id values are populated automatically for the  
first disk using the cloud\_image var.

Defaults to a single 25GB disk on local-lvm with scsi interface and raw format.

Type:

```hcl
list(object({
    aio               = optional(string)
    backup            = optional(bool)
    cache             = optional(string)
    datastore_id      = optional(string, "local-lvm")
    discard           = optional(string)
    file_format       = optional(string, "raw")
    file_id           = optional(string)
    import_from       = optional(string)
    interface         = optional(string, "scsi")
    iothread          = optional(bool)
    path_in_datastore = optional(string)
    queues            = optional(number)
    replicate         = optional(bool)
    serial            = optional(string)
    size              = optional(number)
    ssd               = optional(bool)
    speed = optional(object({
      iops_read            = optional(number)
      iops_read_burstable  = optional(number)
      iops_write           = optional(number)
      iops_write_burstable = optional(number)
      read                 = optional(number)
      read_burstable       = optional(number)
      write                = optional(number)
      write_burstable      = optional(number)
    }))
  }))
```

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the VM within Proxmox

Type: `string`

### <a name="input_node_name"></a> [node\_name](#input\_node\_name)

Description: Proxmox node to create the VM on

Type: `string`

### <a name="input_vm_id"></a> [vm\_id](#input\_vm\_id)

Description: The ID of the VM to be created

Type: `number`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_acpi"></a> [acpi](#input\_acpi)

Description: Whether to enable ACPI

Type: `bool`

Default: `true`

### <a name="input_agent"></a> [agent](#input\_agent)

Description: QEMU Guest Agent configuration

Type:

```hcl
object({
    enabled = optional(bool, true)
    timeout = optional(string)
    trim    = optional(bool)
    type    = optional(string)
    wait_for_ip = optional(object({
      disabled = optional(bool)
      ipv4     = optional(bool)
      ipv6     = optional(bool)
    }))
  })
```

Default: `{}`

### <a name="input_amd_sev"></a> [amd\_sev](#input\_amd\_sev)

Description: AMD SEV configuration

Type:

```hcl
object({
    type           = optional(string, "std")
    allow_smt      = optional(bool, true)
    kernel_hashes  = optional(bool, false)
    no_debug       = optional(bool, false)
    no_key_sharing = optional(bool, false)
  })
```

Default: `null`

### <a name="input_audio_device"></a> [audio\_device](#input\_audio\_device)

Description: Audio device configuration

Type:

```hcl
object({
    device  = optional(string, "intel-hda")
    driver  = optional(string, "spice")
    enabled = optional(bool, true)
  })
```

Default: `null`

### <a name="input_boot_order"></a> [boot\_order](#input\_boot\_order)

Description: Boot order configuration

Type: `list(string)`

Default: `null`

### <a name="input_cdrom"></a> [cdrom](#input\_cdrom)

Description: CD-ROM configuration

Type:

```hcl
object({
    enabled   = optional(bool, false)
    file_id   = optional(string, "none")
    interface = optional(string, "ide3")
  })
```

Default: `null`

### <a name="input_cloud_image"></a> [cloud\_image](#input\_cloud\_image)

Description: Cloud image used to initialize the VM.

Provide either import\_from or file\_id using a Proxmox file identifier.

Use one of the following, prefer import\_from unless using an iso or compressed image.  
import\_from: "<datastore\_id>:import/<file\_name>"  
file\_id: "<datastore\_id>:<content\_type>/<file\_name>"

A proxmox\_virtual\_environment\_download\_file resource id can also be used instead.

Type:

```hcl
object({
    import_from = optional(string)
    file_id     = optional(string)
  })
```

Default: `{}`

### <a name="input_cpu"></a> [cpu](#input\_cpu)

Description: CPU configuration, defaults to 2 x86-64-v2-AES cores

Type:

```hcl
object({
    architecture = optional(string, "x86_64")
    cores        = optional(number, 2)
    flags        = optional(list(string))
    hotplugged   = optional(number)
    limit        = optional(number)
    numa         = optional(bool)
    sockets      = optional(number)
    type         = optional(string, "x86-64-v2-AES")
    units        = optional(number)
    affinity     = optional(string)
  })
```

Default: `{}`

### <a name="input_debug_files"></a> [debug\_files](#input\_debug\_files)

Description: Whether to output debug files (e.g., cloud-init user-data and network-data files)

Type: `bool`

Default: `false`

### <a name="input_delete_unreferenced_disks_on_destroy"></a> [delete\_unreferenced\_disks\_on\_destroy](#input\_delete\_unreferenced\_disks\_on\_destroy)

Description: Whether to delete unreferenced disks when the VM is destroyed

Type: `bool`

Default: `true`

### <a name="input_description"></a> [description](#input\_description)

Description: The description of the VM within Proxmox

Type: `string`

Default: `"Managed by Terraform"`

### <a name="input_hook_script_file_id"></a> [hook\_script\_file\_id](#input\_hook\_script\_file\_id)

Description: Proxmox file ID for the hook script to be used with the VM

Type: `string`

Default: `null`

### <a name="input_hostpci"></a> [hostpci](#input\_hostpci)

Description: Host PCI passthrough configuration

Type:

```hcl
list(object({
    device   = string
    id       = optional(string)
    mapping  = optional(string)
    mdev     = optional(string)
    pcie     = optional(bool)
    rombar   = optional(bool)
    rom_file = optional(string)
    xvga     = optional(bool)
  }))
```

Default: `null`

### <a name="input_hotplug"></a> [hotplug](#input\_hotplug)

Description: Hotplug configuration, accepts 0 to disable, 1 to enable all, or a comma-separated list of cpu, disk, memory, network, and usb

Type: `string`

Default: `null`

### <a name="input_keyboard_layout"></a> [keyboard\_layout](#input\_keyboard\_layout)

Description: Keyboard layout within Proxmox

Type: `string`

Default: `null`

### <a name="input_kvm_arguments"></a> [kvm\_arguments](#input\_kvm\_arguments)

Description: Additional KVM arguments

Type: `string`

Default: `null`

### <a name="input_memory"></a> [memory](#input\_memory)

Description: Memory configuration (1GB = 1024), defaults to 2GB with ballooning enabled

Type:

```hcl
object({
    dedicated         = optional(number, 2048)
    ballooning_device = optional(bool, true)
    shared            = optional(number)
    hugepages         = optional(string)
    keep_hugepages    = optional(bool)
  })
```

Default: `{}`

### <a name="input_migrate"></a> [migrate](#input\_migrate)

Description: Whether to migrate (true) or recreate (false) the VM on node change

Type: `bool`

Default: `false`

### <a name="input_network_devices"></a> [network\_devices](#input\_network\_devices)

Description: Network interface configurations, defaults to one virtio interface on vmbr0 with firewall enabled.

Type:

```hcl
list(object({
    model        = optional(string, "virtio")
    bridge       = optional(string, "vmbr0")
    vlan_id      = optional(number)
    rate_limit   = optional(number)
    firewall     = optional(bool, true)
    disconnected = optional(bool)
    mtu          = optional(number)
    multi_queue  = optional(number)
    mac_address  = optional(string)
    trunks       = optional(string)
  }))
```

Default:

```json
[
  {}
]
```

### <a name="input_numa"></a> [numa](#input\_numa)

Description: The NUMA configuration

Type:

```hcl
list(object({
    device    = string
    cpus      = string
    memory    = number
    hostnodes = optional(list(string))
    policy    = optional(string)
  }))
```

Default: `null`

### <a name="input_on_boot"></a> [on\_boot](#input\_on\_boot)

Description: Whether to start the VM on system boot

Type: `bool`

Default: `true`

### <a name="input_pool_id"></a> [pool\_id](#input\_pool\_id)

Description: Proxmox pool to add the VM to

Type: `string`

Default: `null`

### <a name="input_protection"></a> [protection](#input\_protection)

Description: Sets the protection flag of the VM

Type: `bool`

Default: `false`

### <a name="input_purge_on_destroy"></a> [purge\_on\_destroy](#input\_purge\_on\_destroy)

Description: Whether to purge backup configs of the VM on destroy

Type: `bool`

Default: `true`

### <a name="input_reboot"></a> [reboot](#input\_reboot)

Description: Whether to reboot the VM after creation

Type: `bool`

Default: `false`

### <a name="input_reboot_after_update"></a> [reboot\_after\_update](#input\_reboot\_after\_update)

Description: Whether the provider may reboot or stop the VM when required to apply configuration updates

Type: `bool`

Default: `true`

### <a name="input_rng"></a> [rng](#input\_rng)

Description: RNG device configuration

Type:

```hcl
object({
    source    = optional(string, "/dev/urandom")
    max_bytes = optional(number)
    period    = optional(number)
  })
```

Default: `null`

### <a name="input_scsi_hardware"></a> [scsi\_hardware](#input\_scsi\_hardware)

Description: SCSI controller type

Type: `string`

Default: `"virtio-scsi-single"`

### <a name="input_serial_device"></a> [serial\_device](#input\_serial\_device)

Description: Serial device configuration

Type:

```hcl
list(object({
    device = optional(string, "socket")
  }))
```

Default:

```json
[
  {}
]
```

### <a name="input_smbios"></a> [smbios](#input\_smbios)

Description: SMBIOS type 1 configuration

Type:

```hcl
object({
    family       = optional(string)
    manufacturer = optional(string)
    product      = optional(string)
    serial       = optional(string)
    sku          = optional(string)
    uuid         = optional(string)
    version      = optional(string)
  })
```

Default: `null`

### <a name="input_started"></a> [started](#input\_started)

Description: Whether to start the VM after creation

Type: `bool`

Default: `true`

### <a name="input_startup"></a> [startup](#input\_startup)

Description: Startup configuration, time measured in seconds

Type:

```hcl
object({
    order      = optional(number)
    up_delay   = optional(number)
    down_delay = optional(number)
  })
```

Default: `null`

### <a name="input_stop_on_destroy"></a> [stop\_on\_destroy](#input\_stop\_on\_destroy)

Description: Whether to stop rather than shutdown VM before destroy

Type: `bool`

Default: `false`

### <a name="input_system"></a> [system](#input\_system)

Description: System configuration

EFI disk automatically created when bios is set to "ovmf".   
datastore\_id for EFI and TPM state default to local-lvm.

Defaults to q35 / ovmf / l26 with a 4m EFI disk and no TPM.

Type:

```hcl
object({
    machine = optional(string, "q35")
    bios    = optional(string, "ovmf")
    os_type = optional(string, "l26")
    efi_disk = optional(object({
      datastore_id      = optional(string)
      file_format       = optional(string)
      type              = optional(string, "4m")
      pre_enrolled_keys = optional(bool)
    }), {})
    tpm_state = optional(object({
      datastore_id = optional(string)
      version      = optional(string)
    }))
  })
```

Default: `{}`

### <a name="input_tablet_device"></a> [tablet\_device](#input\_tablet\_device)

Description: Whether to enable the USB tablet device

Type: `bool`

Default: `true`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: List of tags to add to the VM within Proxmox

Type: `list(string)`

Default: `[]`

### <a name="input_template"></a> [template](#input\_template)

Description: Whether to convert the VM into a template

Type: `bool`

Default: `false`

### <a name="input_timeout_create"></a> [timeout\_create](#input\_timeout\_create)

Description: Timeout for VM creation in seconds

Type: `number`

Default: `1800`

### <a name="input_timeout_migrate"></a> [timeout\_migrate](#input\_timeout\_migrate)

Description: Timeout for VM migration in seconds

Type: `number`

Default: `1800`

### <a name="input_timeout_reboot"></a> [timeout\_reboot](#input\_timeout\_reboot)

Description: Timeout for VM reboot in seconds

Type: `number`

Default: `1800`

### <a name="input_timeout_shutdown_vm"></a> [timeout\_shutdown\_vm](#input\_timeout\_shutdown\_vm)

Description: Timeout for VM shutdown in seconds

Type: `number`

Default: `1800`

### <a name="input_timeout_start_vm"></a> [timeout\_start\_vm](#input\_timeout\_start\_vm)

Description: Timeout for VM startup in seconds

Type: `number`

Default: `1800`

### <a name="input_timeout_stop_vm"></a> [timeout\_stop\_vm](#input\_timeout\_stop\_vm)

Description: Timeout for stopping the VM in seconds

Type: `number`

Default: `300`

### <a name="input_usb"></a> [usb](#input\_usb)

Description: USB device configuration

Type:

```hcl
list(object({
    host    = optional(string)
    mapping = optional(string)
    usb3    = optional(bool)
  }))
```

Default: `null`

### <a name="input_vga"></a> [vga](#input\_vga)

Description: VGA device configuration

Type:

```hcl
object({
    memory    = optional(number)
    type      = optional(string)
    clipboard = optional(string)
  })
```

Default: `null`

### <a name="input_virtiofs"></a> [virtiofs](#input\_virtiofs)

Description: Virtiofs share configuration

Type:

```hcl
list(object({
    mapping      = string
    cache        = optional(string)
    direct_io    = optional(bool)
    expose_acl   = optional(bool)
    expose_xattr = optional(bool)
  }))
```

Default: `null`

### <a name="input_watchdog"></a> [watchdog](#input\_watchdog)

Description: Watchdog device configuration

Type:

```hcl
object({
    enabled = optional(bool)
    model   = optional(string)
    action  = optional(string)
  })
```

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_id"></a> [id](#output\_id)

Description: The ID of the VM in Proxmox VE

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the VM in Proxmox VE

### <a name="output_node_name"></a> [node\_name](#output\_node\_name)

Description: The Proxmox VE node name where the VM exists

### <a name="output_proxmox_virtual_environment_vm"></a> [proxmox\_virtual\_environment\_vm](#output\_proxmox\_virtual\_environment\_vm)

Description: The Proxmox VE VM resource

### <a name="output_proxmox_virtual_environment_vm_ipv4_addresses"></a> [proxmox\_virtual\_environment\_vm\_ipv4\_addresses](#output\_proxmox\_virtual\_environment\_vm\_ipv4\_addresses)

Description: The IPv4 addresses of the VM

### <a name="output_proxmox_virtual_environment_vm_mac_addresses"></a> [proxmox\_virtual\_environment\_vm\_mac\_addresses](#output\_proxmox\_virtual\_environment\_vm\_mac\_addresses)

Description: The MAC addresses of the VM

### <a name="output_proxmox_virtual_environment_vm_network_interface_names"></a> [proxmox\_virtual\_environment\_vm\_network\_interface\_names](#output\_proxmox\_virtual\_environment\_vm\_network\_interface\_names)

Description: The network interface names of the VM

### <a name="output_user_data"></a> [user\_data](#output\_user\_data)

Description: The user data used for cloud-init

### <a name="output_vm_hostname"></a> [vm\_hostname](#output\_vm\_hostname)

Description: The hostname of the VM
<!-- END_TF_DOCS -->

## Contributing

Run the checks from the repository root:

```shell
terraform fmt -check -recursive -diff
tflint --format=compact --no-color
terraform init -backend=false -input=false
terraform validate
```

Validate the Cloud-init templates with placeholder variables:

```shell
tests/template-validation/validate.sh
```

The template validator only renders files in a temp directory and deletes them when 
it exits. It only uses test inputs found in main.tf (in the same dir as this file).
It does not use any user defined variables. 

## Sensitive data

Cloud-init file content is stored in the caller's Terraform state and Proxmox
snippets datastore. This is senstive data. It is recommended that you use an 
encrypted remote state backend, restrict access to the snippets datastore, and 
avoid using user_data plaintext passwords unless needed, or if you just don't care. 