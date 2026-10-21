locals {
  # One module instance per entry in var.vms. Add a host in the tfvars file,
  # then add the same name to the Ansible inventory.
  vms = var.vms
}

module "linux_vm" {
  source   = "../modules/proxmox-vm"
  for_each = local.vms

  name      = each.key
  vm_id     = each.value.vm_id
  node_name = var.proxmox_node

  template_vm_id     = var.template_vm_id
  template_node_name = var.template_node

  datastore_id = var.datastore_id
  disk_size    = each.value.disk_size

  cores  = each.value.cores
  memory = each.value.memory

  bridge  = var.bridge
  vlan_id = var.vlan_id

  ipv4_address = each.value.ipv4_address
  ipv4_gateway = var.ipv4_gateway

  dns_servers = var.dns_servers
  dns_domain  = var.dns_domain

  username         = var.initial_username
  ssh_public_keys  = var.ssh_public_keys
  initial_password = var.initial_password

  tags = concat(["terraform", "linux"], each.value.tags)
}
