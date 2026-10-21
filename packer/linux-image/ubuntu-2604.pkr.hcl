# Ubuntu Server 26.04.1 LTS cloud-init template on Proxmox.
#
# Builder reference (packer-plugin-proxmox v1.2.4):
# https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox/latest/components/builder/iso
#
# The install is unattended through Ubuntu autoinstall. The installer reads
# user-data and meta-data from the small HTTP server Packer starts.
# Autoinstall reference:
# https://canonical-subiquity.readthedocs.io/en/latest/reference/autoinstall-reference.html

source "proxmox-iso" "ubuntu_2604" {
  # Connection and placement
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = var.proxmox_insecure
  node                     = var.proxmox_node
  vm_id                    = var.vm_id
  vm_name                  = var.vm_name
  template_name            = var.vm_name
  template_description     = "Ubuntu Server 26.04.1 LTS template. Built by Packer ${timestamp()}."
  tags                     = "ubuntu-2604;template;packer"
  task_timeout             = "30m"

  # Hardware
  os              = "l26"
  cores           = 2
  memory          = 2048
  cpu_type        = "x86-64-v2-AES"
  scsi_controller = "virtio-scsi-single"
  qemu_agent      = true

  disks {
    type         = "scsi"
    disk_size    = "20G"
    storage_pool = var.storage_pool
    discard      = true
    ssd          = true
    io_thread    = true
  }

  network_adapters {
    model    = "virtio"
    bridge   = var.bridge
    vlan_tag = var.vlan_tag
    firewall = true
  }

  # v1.2.4 takes the boot ISO through boot_iso. The older iso_file,
  # iso_storage_pool, iso_download_pve and unmount_iso arguments are deprecated.
  boot_iso {
    type         = "ide"
    iso_file     = var.iso_file
    iso_checksum = var.iso_checksum
    unmount      = true
  }

  # Autoinstall files are served from ./http.
  http_directory = "http"
  boot_wait      = "5s"

  # At the GRUB menu press e, move the cursor to the end of the linux line,
  # append the autoinstall kernel arguments, then boot with F10.
  # GRUB screen layout can differ between releases. Take a console screenshot
  # if the build drops to the installer UI.
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]

  ssh_username = var.build_username
  ssh_password = var.build_password
  ssh_timeout  = var.ssh_timeout

  # The finished template gets an empty cloud-init drive. Terraform injects
  # the per-VM identity, network settings and SSH keys into clones.
  cloud_init              = true
  cloud_init_storage_pool = var.storage_pool
}

build {
  name    = "ubuntu-2604"
  sources = ["source.proxmox-iso.ubuntu_2604"]

  # Leave the template clean enough for cloud-init to run on every clone.
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent",
      "sudo systemctl enable qemu-guest-agent",
      "sudo cloud-init clean --logs --seed",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm -f /var/lib/dbus/machine-id",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sync"
    ]
  }
}
