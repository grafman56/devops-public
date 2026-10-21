# One Linux VM cloned from the Packer template.
#
# The template must have a cloud-init drive. The Packer build in
# ../../packer/linux-image sets cloud_init = true for that reason.
#
# Every argument below is documented in the bpg/proxmox provider 0.117.0:
# https://registry.terraform.io/providers/bpg/proxmox/0.117.0/docs/resources/virtual_environment_vm

resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = "Managed by Terraform. Template ${var.template_vm_id}. Do not edit by hand."
  tags        = var.tags

  node_name = var.node_name
  vm_id     = var.vm_id

  started         = var.started
  on_boot         = var.on_boot
  stop_on_destroy = true

  clone {
    vm_id        = var.template_vm_id
    node_name    = var.template_node_name
    datastore_id = var.datastore_id
    full         = true
    retries      = 3
  }

  # qemu-guest-agent is installed by the Packer template. Without it,
  # shutdown and destroy fall back to ACPI and often hang.
  agent {
    enabled = true
    timeout = "15m"
    trim    = true
  }

  cpu {
    cores = var.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
    # floating stays 0. Ballooning needs a working guest driver, and a silent
    # memory squeeze is not worth the debugging in a learning lab.
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size
    discard      = true
    ssd          = var.disk_ssd
  }

  network_device {
    bridge   = var.bridge
    model    = "virtio"
    vlan_id  = var.vlan_id
    firewall = var.firewall
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    # user_account and user_data_file_id conflict. This module uses the
    # provider-native account block so SSH keys arrive without a snippet
    # datastore. Use user_data_file_id instead when you need cloud-init
    # modules such as runcmd or packages.
    user_account {
      username = var.username
      keys     = var.ssh_public_keys
      password = var.initial_password
    }
  }

  operating_system {
    type = "l26"
  }
}
