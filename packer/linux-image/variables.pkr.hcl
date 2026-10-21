variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL including /api2/json. Set PROXMOX_URL."
  default     = env("PROXMOX_URL")
}

variable "proxmox_username" {
  type        = string
  description = "API token ID, for example packer@pve!packer. Set PROXMOX_USERNAME."
  default     = env("PROXMOX_USERNAME")
}

variable "proxmox_token" {
  type        = string
  description = "API token secret. Set PROXMOX_TOKEN."
  default     = env("PROXMOX_TOKEN")
  sensitive   = true
}

variable "proxmox_insecure" {
  type        = bool
  description = "Skip TLS verification against a self-signed Proxmox certificate."
  default     = true
}

variable "proxmox_node" {
  type        = string
  description = "Node that builds the template."
  default     = "pve01"
}

variable "vm_id" {
  type        = number
  description = "VM ID of the finished template."
  default     = 9001
}

variable "vm_name" {
  type        = string
  description = "Template name and build VM name."
  default     = "ubuntu-2604-template"
}

variable "storage_pool" {
  type        = string
  description = "Datastore for the disk and the cloud-init drive."
  default     = "local-lvm"
}

variable "bridge" {
  type        = string
  description = "Bridge for the build network."
  default     = "vmbr0"
}

variable "vlan_tag" {
  type        = string
  description = "VLAN tag for the build network. Empty means untagged."
  default     = ""
}

variable "iso_file" {
  type        = string
  description = "Datastore path of the Ubuntu live-server ISO. Upload it first."
  default     = "local:iso/ubuntu-26.04.1-live-server-amd64.iso"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum from releases.ubuntu.com/26.04/SHA256SUMS."
  default     = "sha256:cc8a95cde20f6ced61a322420de00f10cc3c90ced545daa46cb9c1a117f1d927"
}

variable "build_username" {
  type        = string
  description = "Temporary installer user. The template does not keep it."
  default     = "packer"
}

variable "build_password" {
  type        = string
  description = "Temporary installer password. Set BUILD_PASSWORD. The hash in http/user-data matches 'packer'."
  default     = env("BUILD_PASSWORD")
  sensitive   = true
}

variable "ssh_timeout" {
  type        = string
  description = "How long Packer waits for SSH after the install."
  default     = "30m"
}
