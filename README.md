# Proxmox VM Module

## Dev checks

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.5 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_macaddress"></a> [macaddress](#requirement\_macaddress) | >= 0.3.2 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.111.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.4.0 |
| <a name="provider_macaddress"></a> [macaddress](#provider\_macaddress) | >= 0.3.2 |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | >= 0.111.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_file.rendered_network_config_debug](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.rendered_user_config_debug](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [macaddress_macaddress.this](https://registry.terraform.io/providers/ivoronin/macaddress/latest/docs/resources/macaddress) | resource |
| [proxmox_virtual_environment_file.network_data_cloud_config](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_file.user_data_cloud_config](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_vm.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acpi"></a> [acpi](#input\_acpi) | Whether to enable ACPI | `bool` | `true` | no |
| <a name="input_agent"></a> [agent](#input\_agent) | QEMU Guest Agent configuration | <pre>object({<br/>    enabled = optional(bool, true)<br/>    timeout = optional(string)<br/>    trim    = optional(bool)<br/>    type    = optional(string)<br/>    wait_for_ip = optional(object({<br/>      disabled = optional(bool)<br/>      ipv4     = optional(bool)<br/>      ipv6     = optional(bool)<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_amd_sev"></a> [amd\_sev](#input\_amd\_sev) | AMD SEV configuration | <pre>object({<br/>    type           = optional(string, "std")<br/>    allow_smt      = optional(bool, true)<br/>    kernel_hashes  = optional(bool, false)<br/>    no_debug       = optional(bool, false)<br/>    no_key_sharing = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_audio_device"></a> [audio\_device](#input\_audio\_device) | Audio device configuration | <pre>object({<br/>    device  = optional(string, "intel-hda")<br/>    driver  = optional(string, "spice")<br/>    enabled = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_boot_order"></a> [boot\_order](#input\_boot\_order) | Boot order configuration | `list(string)` | `null` | no |
| <a name="input_cdrom"></a> [cdrom](#input\_cdrom) | CD-ROM configuration | <pre>object({<br/>    enabled   = optional(bool, false)<br/>    file_id   = optional(string, "none")<br/>    interface = optional(string, "ide3")<br/>  })</pre> | `null` | no |
| <a name="input_cloud_image"></a> [cloud\_image](#input\_cloud\_image) | Cloud image used to initialize the VM.<br/><br/>Provide either import\_from or file\_id using a Proxmox file identifier.<br/><br/>For uncompressed images stored with content type "import":<br/><br/>  cloud\_image = {<br/>    import\_from = "<datastore\_id>:import/<file\_name>"<br/>  }<br/><br/>For images stored under another supported content type, such as "iso":<br/><br/>  cloud\_image = {<br/>    file\_id = "<datastore\_id>:<content\_type>/<file\_name>"<br/>  }<br/><br/>Either value may also reference the ID returned by a<br/>proxmox\_virtual\_environment\_download\_file resource:<br/><br/>  cloud\_image = {<br/>    import\_from = proxmox\_virtual\_environment\_download\_file.ubuntu\_cloud\_image.id<br/>  }<br/><br/>  cloud\_image = {<br/>    file\_id = proxmox\_virtual\_environment\_download\_file.ubuntu\_cloud\_image.id<br/>  } | <pre>object({<br/>    import_from = optional(string)<br/>    file_id     = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_cloud_init"></a> [cloud\_init](#input\_cloud\_init) | Cloud-init configuration, datastore must allow content type 'snippets' and disk datastore must allow VM images | <pre>object({<br/>    datastore_id        = string<br/>    node_name           = optional(string)<br/>    disk_datastore_id   = optional(string, "local-lvm")<br/>    interface           = optional(string)<br/>    file_format         = optional(string)<br/>    vendor_data_file_id = optional(string)<br/>    meta_data_file_id   = optional(string)<br/><br/>    hostname = optional(string, null)<br/>    fqdn     = optional(string, null)<br/><br/>    user_data = optional(list(object({<br/>      username        = optional(string, "ubuntu")<br/>      password        = optional(string, null)<br/>      groups          = optional(list(string), ["sudo"])<br/>      shell           = optional(string, "/bin/bash")<br/>      sudoers         = optional(string, "ALL=(ALL) NOPASSWD:ALL")<br/>      ssh_import_ids  = optional(list(string), [])<br/>      authorized_keys = optional(list(string), [])<br/>    })), [{}])<br/><br/>    network_data = optional(list(object({<br/>      interface_name = optional(string, "eth0")<br/>      addresses      = optional(list(string), [])<br/>      dhcp4          = optional(bool, null)<br/>      dhcp6          = optional(bool, false)<br/>      default_route  = optional(string, null)<br/>      dns_servers    = optional(list(string), [])<br/>      dns_domains    = optional(list(string), [])<br/>      mac_prefix     = optional(list(number), [2])<br/>    })), [{}])<br/><br/>    packages = optional(list(string), [])<br/>  })</pre> | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU configuration, defaults to 2 x86-64-v2-AES cores | <pre>object({<br/>    architecture = optional(string, "x86_64")<br/>    cores        = optional(number, 2)<br/>    flags        = optional(list(string))<br/>    hotplugged   = optional(number)<br/>    limit        = optional(number)<br/>    numa         = optional(bool)<br/>    sockets      = optional(number)<br/>    type         = optional(string, "x86-64-v2-AES")<br/>    units        = optional(number)<br/>    affinity     = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_debug_files"></a> [debug\_files](#input\_debug\_files) | Whether to output debug files (e.g., cloud-init user-data and network-data files) | `bool` | `false` | no |
| <a name="input_delete_unreferenced_disks_on_destroy"></a> [delete\_unreferenced\_disks\_on\_destroy](#input\_delete\_unreferenced\_disks\_on\_destroy) | Whether to delete unreferenced disks when the VM is destroyed | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | The description of the VM within Proxmox | `string` | `"Managed by Terraform"` | no |
| <a name="input_disks"></a> [disks](#input\_disks) | Disk specifications.<br/><br/>Specify only the disk interface type: scsi, sata, or virtio.<br/>Do not include an index such as scsi0; indexes are assigned automatically.<br/><br/>The import\_from and file\_id values are populated automatically for the<br/>first disk using the cloud\_image var. | <pre>list(object({<br/>    aio               = optional(string)<br/>    backup            = optional(bool)<br/>    cache             = optional(string)<br/>    datastore_id      = optional(string, "local-lvm")<br/>    discard           = optional(string)<br/>    file_format       = optional(string, "raw")<br/>    file_id           = optional(string)<br/>    import_from       = optional(string)<br/>    interface         = optional(string, "scsi")<br/>    iothread          = optional(bool)<br/>    path_in_datastore = optional(string)<br/>    queues            = optional(number)<br/>    replicate         = optional(bool)<br/>    serial            = optional(string)<br/>    size              = optional(number)<br/>    ssd               = optional(bool)<br/>    speed = optional(object({<br/>      iops_read            = optional(number)<br/>      iops_read_burstable  = optional(number)<br/>      iops_write           = optional(number)<br/>      iops_write_burstable = optional(number)<br/>      read                 = optional(number)<br/>      read_burstable       = optional(number)<br/>      write                = optional(number)<br/>      write_burstable      = optional(number)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_hook_script_file_id"></a> [hook\_script\_file\_id](#input\_hook\_script\_file\_id) | Proxmox file ID for the hook script to be used with the VM | `string` | `null` | no |
| <a name="input_hostpci"></a> [hostpci](#input\_hostpci) | Host PCI passthrough configuration | <pre>list(object({<br/>    device   = string<br/>    id       = optional(string)<br/>    mapping  = optional(string)<br/>    mdev     = optional(string)<br/>    pcie     = optional(bool)<br/>    rombar   = optional(bool)<br/>    rom_file = optional(string)<br/>    xvga     = optional(bool)<br/>  }))</pre> | `null` | no |
| <a name="input_hotplug"></a> [hotplug](#input\_hotplug) | Hotplug configuration, accepts 0 to disable, 1 to enable all, or a comma-separated list of cpu, disk, memory, network, and usb | `string` | `null` | no |
| <a name="input_keyboard_layout"></a> [keyboard\_layout](#input\_keyboard\_layout) | Keyboard layout within Proxmox | `string` | `null` | no |
| <a name="input_kvm_arguments"></a> [kvm\_arguments](#input\_kvm\_arguments) | Additional KVM arguments | `string` | `null` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory configuration (1GB = 1024), defaults to 2GB with ballooning enabled | <pre>object({<br/>    dedicated         = optional(number, 2048)<br/>    ballooning_device = optional(bool, true)<br/>    shared            = optional(number)<br/>    hugepages         = optional(string)<br/>    keep_hugepages    = optional(bool)<br/>  })</pre> | `{}` | no |
| <a name="input_migrate"></a> [migrate](#input\_migrate) | Whether to migrate (true) or recreate (false) the VM on node change | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the VM within Proxmox | `string` | n/a | yes |
| <a name="input_network_devices"></a> [network\_devices](#input\_network\_devices) | Network interface configurations | <pre>list(object({<br/>    model        = optional(string, "virtio")<br/>    bridge       = optional(string, "vmbr0")<br/>    vlan_id      = optional(number)<br/>    rate_limit   = optional(number)<br/>    firewall     = optional(bool, true)<br/>    disconnected = optional(bool)<br/>    mtu          = optional(number)<br/>    multi_queue  = optional(number)<br/>    mac_address  = optional(string)<br/>    trunks       = optional(string)<br/>  }))</pre> | <pre>[<br/>  {}<br/>]</pre> | no |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | Proxmox node to create the VM on | `string` | n/a | yes |
| <a name="input_numa"></a> [numa](#input\_numa) | The NUMA configuration | <pre>list(object({<br/>    device    = string<br/>    cpus      = string<br/>    memory    = number<br/>    hostnodes = optional(list(string))<br/>    policy    = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_on_boot"></a> [on\_boot](#input\_on\_boot) | Whether to start the VM on system boot | `bool` | `true` | no |
| <a name="input_pool_id"></a> [pool\_id](#input\_pool\_id) | Proxmox pool to add the VM to | `string` | `null` | no |
| <a name="input_protection"></a> [protection](#input\_protection) | Sets the protection flag of the VM | `bool` | `false` | no |
| <a name="input_purge_on_destroy"></a> [purge\_on\_destroy](#input\_purge\_on\_destroy) | Whether to purge backup configs of the VM on destroy | `bool` | `true` | no |
| <a name="input_reboot"></a> [reboot](#input\_reboot) | Whether to reboot the VM after creation | `bool` | `false` | no |
| <a name="input_reboot_after_update"></a> [reboot\_after\_update](#input\_reboot\_after\_update) | Whether the provider may reboot or stop the VM when required to apply configuration updates | `bool` | `true` | no |
| <a name="input_rng"></a> [rng](#input\_rng) | RNG device configuration | <pre>object({<br/>    source    = optional(string, "/dev/urandom")<br/>    max_bytes = optional(number)<br/>    period    = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_scsi_hardware"></a> [scsi\_hardware](#input\_scsi\_hardware) | SCSI controller type | `string` | `"virtio-scsi-single"` | no |
| <a name="input_serial_device"></a> [serial\_device](#input\_serial\_device) | Serial device configuration | <pre>list(object({<br/>    device = optional(string, "socket")<br/>  }))</pre> | <pre>[<br/>  {}<br/>]</pre> | no |
| <a name="input_smbios"></a> [smbios](#input\_smbios) | SMBIOS type 1 configuration | <pre>object({<br/>    family       = optional(string)<br/>    manufacturer = optional(string)<br/>    product      = optional(string)<br/>    serial       = optional(string)<br/>    sku          = optional(string)<br/>    uuid         = optional(string)<br/>    version      = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_started"></a> [started](#input\_started) | Whether to start the VM after creation | `bool` | `true` | no |
| <a name="input_startup"></a> [startup](#input\_startup) | Startup configuration, time measured in seconds | <pre>object({<br/>    order      = optional(number)<br/>    up_delay   = optional(number)<br/>    down_delay = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_stop_on_destroy"></a> [stop\_on\_destroy](#input\_stop\_on\_destroy) | Whether to stop rather than shutdown VM before destroy | `bool` | `false` | no |
| <a name="input_system"></a> [system](#input\_system) | System configuration, defaults to q35 / ovmf / l26 with a 4m EFI disk and no TPM.<br/><br/>EFI disk automatically created when bios is set to "ovmf", only need to change if not happy with defaults.<br/>Datastores for EFI and TPM state default to local-lvm and can be overridden with datastore\_id. | <pre>object({<br/>    machine = optional(string, "q35")<br/>    bios    = optional(string, "ovmf")<br/>    os_type = optional(string, "l26")<br/>    efi_disk = optional(object({<br/>      datastore_id      = optional(string)<br/>      file_format       = optional(string)<br/>      type              = optional(string, "4m")<br/>      pre_enrolled_keys = optional(bool)<br/>    }), {})<br/>    tpm_state = optional(object({<br/>      datastore_id = optional(string)<br/>      version      = optional(string)<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_tablet_device"></a> [tablet\_device](#input\_tablet\_device) | Whether to enable the USB tablet device | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | List of tags to add to the VM within Proxmox | `list(string)` | `[]` | no |
| <a name="input_template"></a> [template](#input\_template) | Whether to convert the VM into a template | `bool` | `false` | no |
| <a name="input_timeout_create"></a> [timeout\_create](#input\_timeout\_create) | Timeout for VM creation in seconds | `number` | `1800` | no |
| <a name="input_timeout_migrate"></a> [timeout\_migrate](#input\_timeout\_migrate) | Timeout for VM migration in seconds | `number` | `1800` | no |
| <a name="input_timeout_reboot"></a> [timeout\_reboot](#input\_timeout\_reboot) | Timeout for VM reboot in seconds | `number` | `1800` | no |
| <a name="input_timeout_shutdown_vm"></a> [timeout\_shutdown\_vm](#input\_timeout\_shutdown\_vm) | Timeout for VM shutdown in seconds | `number` | `1800` | no |
| <a name="input_timeout_start_vm"></a> [timeout\_start\_vm](#input\_timeout\_start\_vm) | Timeout for VM startup in seconds | `number` | `1800` | no |
| <a name="input_timeout_stop_vm"></a> [timeout\_stop\_vm](#input\_timeout\_stop\_vm) | Timeout for stopping the VM in seconds | `number` | `300` | no |
| <a name="input_usb"></a> [usb](#input\_usb) | USB device configuration | <pre>list(object({<br/>    host    = optional(string)<br/>    mapping = optional(string)<br/>    usb3    = optional(bool)<br/>  }))</pre> | `null` | no |
| <a name="input_vga"></a> [vga](#input\_vga) | VGA device configuration | <pre>object({<br/>    memory    = optional(number)<br/>    type      = optional(string)<br/>    clipboard = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_virtiofs"></a> [virtiofs](#input\_virtiofs) | Virtiofs share configuration | <pre>list(object({<br/>    mapping      = string<br/>    cache        = optional(string)<br/>    direct_io    = optional(bool)<br/>    expose_acl   = optional(bool)<br/>    expose_xattr = optional(bool)<br/>  }))</pre> | `null` | no |
| <a name="input_vm_id"></a> [vm\_id](#input\_vm\_id) | The ID of the VM to be created | `number` | n/a | yes |
| <a name="input_watchdog"></a> [watchdog](#input\_watchdog) | Watchdog device configuration | <pre>object({<br/>    enabled = optional(bool)<br/>    model   = optional(string)<br/>    action  = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The ID of the VM in Proxmox VE |
| <a name="output_name"></a> [name](#output\_name) | The name of the VM in Proxmox VE |
| <a name="output_node_name"></a> [node\_name](#output\_node\_name) | The Proxmox VE node name where the VM exists |
| <a name="output_proxmox_virtual_environment_vm"></a> [proxmox\_virtual\_environment\_vm](#output\_proxmox\_virtual\_environment\_vm) | The Proxmox VE VM resource |
| <a name="output_proxmox_virtual_environment_vm_ipv4_addresses"></a> [proxmox\_virtual\_environment\_vm\_ipv4\_addresses](#output\_proxmox\_virtual\_environment\_vm\_ipv4\_addresses) | The IPv4 addresses of the VM |
| <a name="output_proxmox_virtual_environment_vm_mac_addresses"></a> [proxmox\_virtual\_environment\_vm\_mac\_addresses](#output\_proxmox\_virtual\_environment\_vm\_mac\_addresses) | The MAC addresses of the VM |
| <a name="output_proxmox_virtual_environment_vm_network_interface_names"></a> [proxmox\_virtual\_environment\_vm\_network\_interface\_names](#output\_proxmox\_virtual\_environment\_vm\_network\_interface\_names) | The network interface names of the VM |
| <a name="output_user_data"></a> [user\_data](#output\_user\_data) | The user data used for cloud-init |
| <a name="output_vm_hostname"></a> [vm\_hostname](#output\_vm\_hostname) | The hostname of the VM |
<!-- END_TF_DOCS -->