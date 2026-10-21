locals {
  # One entry per VM. Add a host here, then add it to the Ansible inventory.
  # VM IDs stay inside 9100-9199 so they never collide with Containerlab nodes.
  vms = {
    dc01 = {
      vm_id     = 9101
      role      = "dc"
      cores     = 2
      memory    = 4096
      disk_size = 60
    }
    app01 = {
      vm_id     = 9102
      role      = "member"
      cores     = 2
      memory    = 4096
      disk_size = 60
    }
  }
}

resource "proxmox_virtual_environment_vm" "windows" {
  for_each = local.vms

  name        = each.key
  description = "Managed by Terraform. Image ${var.template_name}. Role ${each.value.role}."
  tags        = ["win2025", each.value.role, "terraform"]

  node_name = var.proxmox_node
  vm_id     = each.value.vm_id

  started         = true
  on_boot         = var.start_on_boot
  stop_on_destroy = true

  clone {
    vm_id        = var.template_vm_id
    node_name    = var.template_node
    datastore_id = var.storage_pool
    full         = true
    retries      = 3
  }

  # Requires qemu-guest-agent, which the image installs from the virtio-win
  # ISO. Without it, destroy and shutdown fall back to ACPI and usually hang.
  agent {
    enabled = true
    timeout = "15m"
    trim    = true
  }

  cpu {
    cores = each.value.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = each.value.memory
    # floating stays 0. Ballooning depends on a working guest driver, and a
    # silent memory squeeze on a domain controller is not worth the debugging.
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = each.value.disk_size
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge   = var.bridge
    model    = "virtio"
    vlan_id  = var.vlan_id
    firewall = true
  }

  operating_system {
    # win11 is valid in provider 0.117.0 and covers Windows 11 and Server 2025.
    # The Packer plugin cannot set it, so the template is created as win10 and
    # switched with: qm set 9000 --ostype win11
    type = "win11"
  }
}
