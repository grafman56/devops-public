// Values come from environment variables so nothing secret lands on disk.
// Prefix is PKR_VAR_, for example PKR_VAR_proxmox_token_secret.

variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL including the /api2/json suffix"
  default     = "https://pve.example.internal:8006/api2/json"
}

variable "proxmox_token_id" {
  type        = string
  description = "API token ID, for example packer@pve!packer"
}

variable "proxmox_token_secret" {
  type        = string
  description = "API token secret"
  sensitive   = true
}

variable "proxmox_insecure" {
  type        = bool
  description = "Skip TLS verification. True for the lab self-signed certificate."
  default     = true
}

variable "proxmox_node" {
  type        = string
  description = "Node that runs the build"
  default     = "pve"
}

variable "vm_id" {
  type        = number
  description = "Build VM ID, reused as the template ID"
  default     = 9000
}

variable "vm_name" {
  type        = string
  description = "Name of the build VM"
  default     = "win2025-gold"
}

variable "template_name" {
  type        = string
  description = "Name of the resulting template"
  default     = "tpl-win2025-dc"
}

variable "os_type" {
  type        = string
  description = "Proxmox OS type. The Packer plugin enum stops at win10; win10 is correct here because Proxmox applies the same Windows tuning. Set the template to win11 after the build with: qm set <template-id> --ostype win11"
  default     = "win10"
}

variable "cores" {
  type        = number
  description = "vCPU count during the build"
  default     = 2
}

variable "memory" {
  type        = number
  description = "RAM in MB during the build"
  default     = 4096
}

variable "disk_size" {
  type        = string
  description = "System disk size, grown later by Terraform"
  default     = "60G"
}

variable "storage_pool" {
  type        = string
  description = "Proxmox storage pool for the system disk"
  default     = "local-lvm"
}

variable "bridge" {
  type        = string
  description = "Proxmox bridge"
  default     = "vmbr0"
}

variable "vlan_tag" {
  type        = string
  description = "VLAN tag on the build NIC. Empty string means untagged."
  default     = ""
}

variable "windows_iso" {
  type        = string
  description = "Datastore path to the Windows Server 2025 evaluation ISO"
  default     = "local:iso/Windows_Server_2025_Eval_x64.iso"
}

variable "virtio_iso" {
  type        = string
  description = "Datastore path to the virtio-win ISO"
  default     = "local:iso/virtio-win.iso"
}

variable "answer_iso" {
  type        = string
  description = "Datastore path to the answer-file ISO built by make answer-iso"
  default     = "local:iso/win2025-autounattend.iso"
}

variable "admin_password" {
  type        = string
  description = "Local Administrator password baked into the image and the deploy answer file"
  sensitive   = true
}
