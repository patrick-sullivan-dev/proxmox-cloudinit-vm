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
      version = var.system.tpm.version
    }
  }

  dynamic "efi_disk" {
    for_each = var.system.bios == "ovmf" ? [1] : []
    content {
      datastore_id      = var.proxmox_storage.efi_id
      file_format       = "raw"
      type              = var.disk.efi_disk.type
      pre_enrolled_keys = var.disk.efi_disk.pre_enrolled_keys
    }
  }

  serial_device {}

  scsi_hardware = var.disk.hardware

  disk {
    datastore_id = var.proxmox_storage.disk_id
    import_from  = var.disk.import_from == null ? proxmox_virtual_environment_download_file.latest_noble_qcow2_img["default"].id : "${var.proxmox_storage.imports_id}:import/${var.disk.import_from}"
    interface    = var.disk.interface
    aio          = var.disk.aio
    cache        = var.disk.cache
    discard      = var.disk.discard
    iothread     = var.disk.iothread
    file_format  = var.disk.file_format
    backup       = var.disk.backup
    replicate    = var.disk.replicate
    size         = var.disk.disk_size
    ssd          = var.disk.ssd
    serial      = var.disk.serial
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