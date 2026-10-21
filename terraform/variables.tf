variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint"
  default     = "https://pve.example.internal:8006/"
}

variable "proxmox_insecure" {
  type        = bool
  description = "Skip TLS verification for the lab self-signed certificate"
  default     = true
}

variable "proxmox_node" {
  type        = string
  description = "Node that runs the clones"
  default     = "pve"
}

variable "template_node" {
  type        = string
  description = "Node that holds the Packer template"
  default     = "pve"
}

variable "template_vm_id" {
  type        = number
  description = "VM ID of the Packer-built template"
  default     = 9000
}

variable "template_name" {
  type        = string
  description = "Template name, recorded in the VM description only"
  default     = "tpl-win2025-dc"
}

variable "storage_pool" {
  type        = string
  description = "Storage pool for clone disks"
  default     = "local-lvm"
}

variable "bridge" {
  type        = string
  description = "Bridge for the VM NIC"
  default     = "vmbr0"
}

variable "vlan_id" {
  type        = number
  description = "VLAN tag for the VM NIC. Null means untagged."
  default     = null
}

variable "cpu_type" {
  type        = string
  description = "CPU model presented to the guest"
  default     = "x86-64-v2-AES"
}

variable "start_on_boot" {
  type        = bool
  description = "Start the VMs when the Proxmox node boots"
  default     = false
}
