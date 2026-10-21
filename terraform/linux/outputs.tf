output "vms" {
  description = "Everything Ansible needs to reach the new hosts."
  value = {
    for name, vm in module.linux_vm : name => {
      vm_id        = vm.vm_id
      ipv4_address = vm.ipv4_address
      ssh_username = vm.ssh_username
    }
  }
}
