output "vm_id" {
  description = "Proxmox VM ID."
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "VM name."
  value       = proxmox_virtual_environment_vm.this.name
}

output "ipv4_address" {
  description = "Static IPv4 address requested through cloud-init."
  value       = var.ipv4_address
}

output "ssh_username" {
  description = "Initial user created by cloud-init."
  value       = var.username
}
