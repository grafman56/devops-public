variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, including /api2/json."
  type        = string

  validation {
    condition     = can(regex("^https://.+/api2/json/?$", var.proxmox_endpoint))
    error_message = "Use the full API path, for example https://pve.example.internal:8006/api2/json."
  }
}

variable "proxmox_insecure" {
  description = "Skip TLS verification. True only for a lab with a self-signed certificate."
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Proxmox node that runs the VMs."
  type        = string
}

variable "template_vm_id" {
  description = "VM ID of the Linux cloud-init template built by Packer."
  type        = number
}

variable "template_node" {
  description = "Node that holds the template. Null means proxmox_node."
  type        = string
  default     = null
}

variable "datastore_id" {
  description = "Datastore for VM disks and cloud-init drives."
  type        = string
}

variable "bridge" {
  description = "Bridge for the primary network device."
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN tag for the primary network device. Null means untagged."
  type        = number
  default     = null
}

variable "dns_servers" {
  description = "DNS servers handed to every guest."
  type        = list(string)
  default     = ["192.0.2.53"]
}

variable "dns_domain" {
  description = "DNS search domain handed to every guest."
  type        = string
  default     = "lab.example.internal"
}

variable "ssh_public_keys" {
  description = "SSH public keys installed for the initial user on every VM."
  type        = list(string)

  validation {
    condition     = length(var.ssh_public_keys) > 0
    error_message = "Add at least one SSH public key. Password-only access is not supported by this example."
  }
}

variable "vms" {
  description = "VM definitions keyed by hostname. Addresses use the RFC 5737 documentation ranges until you replace them."

  type = map(object({
    vm_id        = number
    ipv4_address = string
    cores        = optional(number, 2)
    memory       = optional(number, 2048)
    disk_size    = optional(number, 20)
    tags         = optional(list(string), [])
  }))

  default = {
    web01 = {
      vm_id        = 9201
      ipv4_address = "192.0.2.11/24"
      cores        = 2
      memory       = 2048
      disk_size    = 20
      tags         = ["web"]
    }
    db01 = {
      vm_id        = 9202
      ipv4_address = "192.0.2.12/24"
      cores        = 4
      memory       = 4096
      disk_size    = 40
      tags         = ["database"]
    }
  }

  validation {
    condition = alltrue([
      for name, vm in var.vms : can(cidrhost(vm.ipv4_address, 0))
    ])
    error_message = "Every ipv4_address must be valid CIDR notation, for example 192.0.2.11/24."
  }

  validation {
    condition     = length(distinct([for vm in values(var.vms) : vm.vm_id])) == length(var.vms)
    error_message = "VM IDs must be unique."
  }
}

variable "ipv4_gateway" {
  description = "Default gateway for every guest."
  type        = string
  default     = "192.0.2.1"
}

variable "initial_username" {
  description = "Initial Linux user created by cloud-init. Ansible connects as this user."
  type        = string
  default     = "ansible"
}

variable "initial_password" {
  description = "Optional initial password. Prefer SSH keys and leave this null."
  type        = string
  default     = null
  sensitive   = true
}
