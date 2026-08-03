resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = var.proxmox_storage.snippets_id
  node_name    = coalesce(var.proxmox_storage.snippets_node, var.node_name)

  source_raw {
    data = templatefile("${path.module}/templates/user-data-cloud-config.tftpl", {
      user_data = var.user_data
      hostname  = var.vm_hostname
      fqdn      = var.vm_fqdn
      packages  = var.packages
    })
    file_name = "${var.id}-user-data-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "network_data_cloud_config" {
  content_type = "snippets"
  datastore_id = var.proxmox_storage.snippets_id
  node_name    = coalesce(var.proxmox_storage.snippets_node, var.node_name)

  source_raw {
    data = templatefile("${path.module}/templates/network-data-cloud-config.tftpl", {
      network_data = local.network_data
    })
    file_name = "${var.id}-network-data-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  vm_id       = var.id
  name        = var.name
  description = var.description
  tags        = var.tags
  node_name   = var.node_name

  machine = var.system.machine
  bios    = var.system.bios

  migrate = var.migrate
  on_boot  = var.on_boot

  keyboard_layout = var.keyboard_layout

  operating_system {
    type = var.system.os_type
  }

  pool_id = var.pool_id

  agent {
    enabled = true
    timeout = var.system.qemu_agent.timeout
    trim    = var.system.qemu_agent.trim
    type    = var.system.qemu_agent.type
  }

  cpu {
    cores  = var.hardware.core_count
    type   = var.hardware.cpu_type
  }

  memory {
    dedicated = var.hardware.memory
    floating  = var.hardware.memory_ballooning ? var.hardware.memory : 0
  }

  dynamic "tpm_state" {
    for_each = var.system.tpm.version != "none" ? [1] : []
    content {
      datastore_id = var.proxmox_storage.efi_id
      version      = var.system.tpm.version
    }
  }

  dynamic "efi_disk" {
    for_each = var.system.bios == "ovmf" ? [1] : []
    content {
      datastore_id      = coalesce(var.system.efi_disk.datastore_id, var.proxmox_storage.disk_id)
      file_format       = var.system.efi_disk.file_format
      type              = var.system.efi_disk.type
      pre_enrolled_keys = var.system.efi_disk.pre_enrolled_keys
    }
  }

  serial_device {}

  scsi_hardware = var.scsi_hardware

  disk {
    aio          = local.boot_disk.aio
    backup       = local.boot_disk.backup
    cache        = local.boot_disk.cache
    datastore_id = coalesce(
      local.boot_disk.datastore_id,
      var.proxmox_storage.disk_id,
    )
    discard     = local.boot_disk.discard
    file_format = local.boot_disk.file_format
    file_id     = local.boot_disk.file_id
    import_from = local.boot_disk.import_from
    interface   = local.boot_disk.interface
    iothread    = local.boot_disk.iothread
    queues      = local.boot_disk.queues
    replicate   = local.boot_disk.replicate
    serial      = local.boot_disk.serial
    size        = local.boot_disk.size
    ssd         = local.boot_disk.ssd

    dynamic "speed" {
      for_each = local.boot_disk.speed == null ? [] : [local.boot_disk.speed]

      content {
        iops_read            = speed.value.iops_read
        iops_read_burstable  = speed.value.iops_read_burstable
        iops_write           = speed.value.iops_write
        iops_write_burstable = speed.value.iops_write_burstable
        read                 = speed.value.read
        read_burstable       = speed.value.read_burstable
        write                = speed.value.write
        write_burstable      = speed.value.write_burstable
      }
    }
  }

  dynamic "disk" {
    for_each = local.disks

    content {
      aio          = disk.value.aio
      backup       = disk.value.backup
      cache        = disk.value.cache
      datastore_id = coalesce(
        disk.value.datastore_id,
        var.proxmox_storage.disk_id,
      )
      discard     = disk.value.discard
      file_format = disk.value.file_format
      file_id     = disk.value.file_id
      import_from = disk.value.import_from
      interface   = disk.value.interface
      iothread    = disk.value.iothread
      queues      = disk.value.queues
      replicate   = disk.value.replicate
      serial      = disk.value.serial
      size        = disk.value.size
      ssd         = disk.value.ssd

      dynamic "speed" {
        for_each = disk.value.speed == null ? [] : [disk.value.speed]

        content {
          iops_read            = speed.value.iops_read
          iops_read_burstable  = speed.value.iops_read_burstable
          iops_write           = speed.value.iops_write
          iops_write_burstable = speed.value.iops_write_burstable
          read                 = speed.value.read
          read_burstable       = speed.value.read_burstable
          write                = speed.value.write
          write_burstable      = speed.value.write_burstable
        }
      }
    }
  }

  dynamic "network_device" {
    for_each = local.network_data
    content {
      enabled      = true
      model        = network_device.value.model
      mtu          = network_device.value.mtu
      queues       = network_device.value.multi_queue
      disconnected = network_device.value.disconnected
      firewall     = network_device.value.firewall
      rate_limit   = network_device.value.rate_limit
      bridge       = network_device.value.bridge
      mac_address  = network_device.value.macaddress
      vlan_id      = network_device.value.vlan_id
    }
  }

  initialization {
    user_data_file_id    = proxmox_virtual_environment_file.user_data_cloud_config.id
    network_data_file_id = proxmox_virtual_environment_file.network_data_cloud_config.id
  }

  startup {
    order      = var.startup.order
    up_delay   = var.startup.up_delay
    down_delay = var.startup.down_delay
  }

  depends_on = [proxmox_virtual_environment_file.user_data_cloud_config]

  lifecycle {
    precondition {
      condition = (
        (local.boot_disk.file_id != null) !=
        (local.boot_disk.import_from != null)
      )

      error_message = "Either configure cloud_image, or supply the first disk with either file_id or import_from."
    }
  }
}

resource "macaddress" "this" {
  for_each = { for idx, net in var.network : idx => net }
  prefix   = each.value.mac_prefix
}

locals {
  network_data = [
    for idx, net in var.network : merge(net, {
      macaddress = macaddress.this[idx].address
    })
  ]

  boot_disk = merge(
    var.disks[0],
    {
      interface = "${var.disks[0].interface}0"
      import_from = try(coalesce(var.disks[0].import_from, var.cloud_image.import_from), null)
      file_id     = try(coalesce(var.disks[0].file_id, var.cloud_image.file_id), null)
    }
  )

  disks = [
    for idx, disk in slice(var.disks, 1, length(var.disks)) : merge(
      disk,
      {
        idx = idx

        interface = "${disk.interface}${idx + 1}"
        datastore_id = coalesce(
          disk.datastore_id,
          var.proxmox_storage.disk_id
        )
      }
    )
  ]
}

resource "local_file" "rendered_network_config_debug" {
  count = var.debug_files ? 1 : 0
  content  = templatefile("${path.module}/templates/network-data-cloud-config.tftpl", {
    network_data = local.network_data
  })
  filename = "${path.module}/debug-${var.name}-network-cloud-config.yaml"
  depends_on = [
    proxmox_virtual_environment_file.user_data_cloud_config,
  ]
}

resource "local_file" "rendered_user_config_debug" {
  count = var.debug_files ? 1 : 0
  content  = templatefile("${path.module}/templates/user-data-cloud-config.tftpl", {
    user_data = var.user_data
    hostname  = var.vm_hostname
    fqdn      = var.vm_fqdn
    packages  = var.packages
  })
  filename = "${path.module}/debug-${var.name}-user-cloud-config.yaml"
  depends_on = [
    proxmox_virtual_environment_file.user_data_cloud_config,
  ]
}