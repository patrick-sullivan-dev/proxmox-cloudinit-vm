# ===================================================
# General VM Settings
# ===================================================
variable "id" {
  description = "The ID of the VM to be created"
  type        = number
}

variable "name" {
  description = "The name of the VM within Proxmox"
  type        = string
}

variable "description" {
  description = "The description of the VM within Proxmox"
  type        = string
  default     = "Managed by Terraform"
  nullable    = false
}

variable "tags" {
  description = "List of tags to add to the VM within Proxmox"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "node_name" {
  description = "Proxmox node to create the VM on"
  type        = string
}

variable "vm_hostname" {
  description = "The hostname of the VM"
  type        = string
  default     = null
  nullable    = true
}

variable "vm_fqdn" {
  description = "The FQDN of the VM"
  type        = string
  default     = null
  nullable    = true
}

variable "pool_id" {
  description = "Optional pool to assign VM to"
  type        = string
  default     = null
}

variable "on_boot" {
  description = "Whether to start VM on boot"
  type        = bool
  default     = true
  nullable    = false
}

# ===================================================
# System / OS Settings
# ===================================================
variable "system" {
  description = "System and OS specifications for the VM"
  type = object({
    machine      = optional(string, "q35")
    bios         = optional(string, "ovmf")
    os_type      = optional(string, "l26")
    tpm          = optional(object({ version = string }), { version = "none" })
    qemu_agent   = optional(object({
      timeout = optional(string, "15m")
      trim    = optional(bool, false)
      type    = optional(string, "virtio")
    }), { enabled = true, timeout = "15m", trim = false, type = "virtio" })
  })

  default = {
    machine    = "q35"
    bios       = "ovmf"
    os_type    = "l26"
    tpm        = { version = "none" }
    qemu_agent = { timeout = "15m", trim = false, type = "virtio" }
  }
  nullable = false

  validation {
    condition     = contains(["pc", "q35"], var.system.machine)
    error_message = "Machine type must be either q35 or pc"
  }
  validation {
    condition     = contains(["ovmf", "seabios"], var.system.bios)
    error_message = "Bios must be ovmf or seabios"
  }
  validation {
    condition     = contains(["virtio", "isa"], var.system.qemu_agent.type)
    error_message = "QEMU agent type must be either virtio or isa"
  }
  validation {
    condition     = contains(["v2.0", "v1.2", "none"], var.system.tpm.version)
    error_message = "TPM version must be either v1.2, v2.0, or none"
  }
}

# ===================================================
# CPU & Memory Settings
# ===================================================
variable "hardware" {
  description = "CPU and memory specifications for the VM"
  type = object({
    core_count        = number
    cpu_type          = optional(string, "x86-64-v2-AES")
    memory            = number
    memory_ballooning = optional(bool, true)
  })

  validation {
    condition     = var.hardware.core_count > 0
    error_message = "VM must have at least 1 vCPU assigned"
  }
}

# ===================================================
# Disk Settings
# ===================================================
variable "disk" {
  description = "Disk specifications for the VM"
  type = object({
    disk_size   = number
    hardware    = optional(string, "virtio-scsi-single")
    cache       = optional(string, "none")
    discard     = optional(string, "ignore")
    interface   = optional(string, "scsi0")
    iothread    = optional(bool, true)
    aio         = optional(string, "threads")
    file_format = optional(string, "raw")
    backup      = optional(bool, true)
    replicate   = optional(bool, true)
    ssd         = optional(bool, false)
    efi_disk    = optional(object({ type = string, pre_enrolled_keys = bool }), { type = "2m", pre_enrolled_keys = false })
    serial      = optional(string, null)
    import_from = optional(string, null)
  })
}

variable "proxmox_storage" {
  description = "Storage configuration for the VM"
  type = object({
    snippets_id   = optional(string, "local")
    snippets_node = optional(string, null)
    imports_id    = optional(string, "local")
    imports_node  = optional(string, null)
    disk_id       = optional(string, "local-lvm")
    efi_id        = optional(string, "local-lvm")
  })
}

# ===================================================
# Network Settings
# ===================================================
variable "network" {
  description = "VM network interface configurations"
  type = list(object({
    interface_name = optional(string, "eth0")
    model          = optional(string, "virtio")
    addresses      = optional(list(string), [])
    dhcp4          = optional(bool, null)
    dhcp6          = optional(bool, null)
    gateway4       = optional(string, null)
    gateway6       = optional(string, null)
    bridge         = optional(string, "vmbr0")
    vlan_id        = optional(number, null)
    rate_limit     = optional(number, null)
    firewall       = optional(bool, true)
    disconnected   = optional(bool, false)
    mtu            = optional(number, null)
    multi_queue    = optional(number, null)
    dns_servers    = optional(list(string), [])
    dns_domains    = optional(list(string), [])
    mac_prefix     = optional(list(number), [2])
  }))

  default = [{
    interface_name = "eth0"
    model          = "virtio"
    addresses      = []
    dhcp4          = true
    dhcp6          = false
    gateway4       = null
    gateway6       = null
    bridge         = "vmbr0"
    vlan_id        = null
    rate_limit     = null
    firewall       = true
    disconnected   = false
    mtu            = null
    multi_queue    = null
    dns_servers    = []
    dns_domains    = []
    mac_prefix     = [2]

    gateway4       = null
    bridge         = "vmbr0"
    vlan_id        = null
    rate_limit     = null
    firewall       = true
    disconnected   = false
    mtu            = null
    multi_queue    = null
    dns_servers    = []
    dns_domains    = []
    mac_prefix     = [2]
  }]
  nullable = false
}

# ===================================================
# Cloud-Init / User Data
# ===================================================
variable "user_data" {
  description = "Cloud-init user-data configuration"
  type = list(object({
    username        = optional(string, "ubuntu")
    password        = optional(string, null)
    groups          = optional(list(string), ["sudo"])
    shell           = optional(string, "/bin/bash")
    sudo            = optional(string, "ALL=(ALL) NOPASSWD:ALL")
    ssh_import_ids  = optional(list(string), [])
    authorized_keys = optional(list(string), [])
  }))

  default = [{
    username        = "ubuntu"
    password        = null
    groups          = ["sudo"]
    shell           = "/bin/bash"
    sudo            = "ALL=(ALL) NOPASSWD:ALL"
    ssh_import_ids  = []
    authorized_keys = []
  }]
  nullable = false
}

variable "packages" {
  description = "List of packages to install via cloud-init"
  type        = list(string)
  default     = []
  nullable    = false
}

# ===================================================
# Advanced / Optional Features
# ===================================================

variable "keyboard_layout" {
  description = "Keyboard layout for the VM"
  type        = string
  default     = "en-us"
  nullable    = false
}

variable "migrate" {
  description = "Whether to migrate/recreate the VM on node change"
  type        = bool
  default     = false
  nullable    = false
}

variable "startup" {
  description = "Startup and shutdown order configuration"
  type = object({
    order      = number
    up_delay   = optional(number, 0)
    down_delay = optional(number, 0)
  })
  default  = { order = 0, up_delay = 0, down_delay = 0 }
  nullable = false
}

# ===================================================
# Misc
# ===================================================
variable "debug_files" {
  description = "Whether to output debug files (e.g., cloud-init user-data and network-data files)"
  type        = bool
  default     = false
  nullable    = false
}
