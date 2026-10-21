output "vm_ids" {
  description = "VM name to Proxmox VM ID"
  value       = { for k, vm in proxmox_virtual_environment_vm.windows : k => vm.vm_id }
}

output "mac_addresses" {
  description = "VM name to NIC MAC. Use these for the OPNsense DHCP reservations."
  value       = { for k, vm in proxmox_virtual_environment_vm.windows : k => vm.mac_addresses }
}

output "ipv4_addresses" {
  description = "IPv4 addresses reported by the guest agent"
  value       = { for k, vm in proxmox_virtual_environment_vm.windows : k => vm.ipv4_addresses }
}
