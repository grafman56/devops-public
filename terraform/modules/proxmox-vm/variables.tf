variable "name" {
  description = "VM name. Must be a valid DNS name."
  type        = string
}

variable "vm_id" {
  description = "Proxmox VM ID. Must be unique across the cluster."
  type        = number
}

variable "node_name" {
  description = "Proxmox node that runs the VM."
  type        = string
}

variable "template_vm_id" {
  description = "VM ID of the cloud-init template built by Packer."
  type        = number
}

variable "template_node_name" {
  description = "Node that holds the template. Leave null when the template is on node_name."
  type        = string
  default     = null
}

variable "datastore_id" {
  description = "Datastore for the VM disk and cloud-init drive."
  type        = string
}

variable "disk_size" {
  description = "Disk size in gigabytes. Resizing to a smaller value is not supported by Proxmox."
  type        = number
  default     = 20
}

variable "disk_ssd" {
  description = "Present the disk to the guest as an SSD."
  type        = bool
  default     = true
}

variable "cores" {
  description = "Number of vCPU cores."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Dedicated memory in megabytes. Ballooning stays off."
  type        = number
  default     = 2048
}

variable "cpu_type" {
  description = "Proxmox CPU type. host passes through the host CPU features."
  type        = string
  default     = "x86-64-v2-AES"
}

variable "bridge" {
  description = "Proxmox bridge for the primary network device."
  type        = string
}

variable "vlan_id" {
  description = "VLAN tag for the primary network device. Null means untagged."
  type        = number
  default     = null
}

variable "firewall" {
  description = "Enable the Proxmox firewall on the network device."
  type        = bool
  default     = true
}

variable "ipv4_address" {
  description = "Static IPv4 address in CIDR notation, for example 192.0.2.11/24."
  type        = string
}

variable "ipv4_gateway" {
  description = "IPv4 default gateway."
  type        = string
}

variable "dns_servers" {
  description = "DNS servers the guest receives through cloud-init."
  type        = list(string)
}

variable "dns_domain" {
  description = "DNS search domain the guest receives through cloud-init."
  type        = string
}

variable "username" {
  description = "Initial Linux user created by cloud-init."
  type        = string
  default     = "ansible"
}

variable "ssh_public_keys" {
  description = "SSH public keys installed for the initial user."
  type        = list(string)
}

variable "initial_password" {
  description = "Optional initial password. Prefer SSH keys. Stored in state when set."
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "Proxmox tags."
  type        = list(string)
  default     = ["terraform", "linux"]
}

variable "started" {
  description = "Start the VM after creation."
  type        = bool
  default     = true
}

variable "on_boot" {
  description = "Start the VM when the node boots."
  type        = bool
  default     = true
}
