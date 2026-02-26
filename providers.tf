terraform {
  required_version = ">= 1.13.5"
  required_providers {
    local = {
      source = "hashicorp/local"
      version = ">= 2.4.0"
    }
    proxmox = {
      source = "bpg/proxmox"
      version = ">= 0.87.0"
    }
    macaddress = {
      source = "ivoronin/macaddress"
      version = ">= 0.3.2"
    }
  }
}
