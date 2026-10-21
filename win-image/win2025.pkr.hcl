packer {
  required_version = ">= 1.11.0"

  required_plugins {
    proxmox = {
      version = ">= 1.2.4"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "win2025" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_token_id
  token                    = var.proxmox_token_secret
  insecure_skip_tls_verify = var.proxmox_insecure

  node = var.proxmox_node

  # Build VM only. The template keeps this ID after conversion.
  vm_id   = var.vm_id
  vm_name = var.vm_name
  os      = var.os_type
  bios    = "seabios" # switch to "ovmf" plus an efi_config block for UEFI
  machine = "q35"

  scsi_controller = "virtio-scsi-single"
  qemu_agent      = true
  cores           = var.cores
  memory          = var.memory
  onboot          = false

  boot      = "order=ide2;scsi0"
  boot_wait = "8s"

  # The Windows ISO waits five seconds for a keypress before it gives up and
  # tries the next boot device. One spacebar keeps it on the installer.
  # If the installer still does not start, delete this line and rely on the
  # boot order above.
  boot_command = ["<spacebar><wait>"]

  disks {
    type         = "scsi"
    disk_size    = var.disk_size
    storage_pool = var.storage_pool
    format       = "raw"
    discard      = true
    ssd          = true
  }

  network_adapters {
    model    = "virtio"
    bridge   = var.bridge
    vlan_tag = var.vlan_tag
    firewall = true
  }

  boot_iso {
    type     = "ide"
    index    = "2"
    iso_file = var.windows_iso
    unmount  = true
  }

  # Driver media. Keep this attached for the whole build.
  additional_iso_files {
    type     = "ide"
    index    = "3"
    iso_file = var.virtio_iso
    unmount  = true
  }

  # Answer file and bootstrap script live at the root of this ISO.
  additional_iso_files {
    type     = "ide"
    index    = "4"
    iso_file = var.answer_iso
    unmount  = true
  }

  template_name        = var.template_name
  template_description = "Windows Server 2025, Packer-built ${timestamp()}. Do not configure by hand; rebuild from win-image/."

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = var.admin_password
  winrm_port     = 5986
  winrm_use_ssl  = true
  winrm_insecure = true # the image certificate is self-signed, lab only
  winrm_timeout  = "45m"

  # Sysprep generalizes, then shuts down. Packer then converts the VM to a
  # template. The cached answer file at this path handles OOBE on every clone.
  shutdown_command = "C:\\Windows\\System32\\Sysprep\\sysprep.exe /generalize /oobe /shutdown /quiet /unattend:C:\\Windows\\System32\\Sysprep\\unattend.xml"
  shutdown_timeout = "20m"
}

build {
  name    = "win2025"
  sources = ["source.proxmox-iso.win2025"]

  # Upload the deploy answer file before cleanup moves it into place.
  provisioner "file" {
    source      = "answer/unattend-deploy.xml"
    destination = "C:\\Windows\\Temp\\unattend-deploy.xml"
    direction   = "upload"
  }

  provisioner "powershell" {
    script = "scripts/cleanup.ps1"
  }

  # Evidence for the build log. If this is missing from the artifact, the
  # provisioning step did not really run.
  provisioner "powershell" {
    inline = [
      "Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber | Format-List",
      "Get-WinEvent -ListLog Setup | Select-Object -First 1 | Out-String",
      "Write-Output 'BUILD-MARKER win2025 ${timestamp()}' | Out-File C:\\build-marker.txt -Encoding ascii"
    ]
  }
}
