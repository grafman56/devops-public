# Terraform

Two independent root modules. Each has its own state file. Run `terraform`
inside the directory you mean, never from the repository root.

| Root | Purpose |
|---|---|
| `terraform/` | Windows Server 2025 estate: clones the win2025 template |
| `terraform/linux/` | Linux VMs: clones the Ubuntu template, injects cloud-init |
| `terraform/modules/proxmox-vm/` | Reusable Linux VM module |

Provider: `bpg/proxmox` 0.117.0. Terraform 1.16 or newer. Source links are in
`../VERSIONS.md`.

## Linux VMs

The module clones the Packer template, sets CPU, memory, disk, bridge and
VLAN, then hands cloud-init a static address, DNS settings and SSH keys.

```
cd terraform/linux
cp terraform.tfvars.example terraform.tfvars
# edit the placeholders

export PROXMOX_VE_API_TOKEN='terraform@pve!tf=<uuid secret>'
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out plan.bin
terraform apply plan.bin
```

Read the outputs, then put the addresses into the Ansible inventory:

```
terraform output -json vms
```

### What the module accepts

See `modules/proxmox-vm/variables.tf`. The important ones:

- `template_vm_id`: the Packer template, for example 9001.
- `ipv4_address`: CIDR notation. The module passes it straight to cloud-init.
- `ssh_public_keys`: list of public keys for the initial user.
- `vlan_id`: null for untagged.
- `disk_size`: Proxmox cannot shrink a disk later, so start small.

### Why user_account and not user_data_file_id

The provider rejects `initialization.user_account` together with
`initialization.user_data_file_id`. The module uses `user_account` because it
needs no snippet datastore. If you want cloud-init `packages`, `runcmd` or
`write_files`, switch to `user_data_file_id` and upload a snippet. The provider
documents both paths.

## State, backends and drift

Local state is the default. `../backend.tf.example` shows the shape of a remote
backend for the Windows root. For a shared lab, use one backend per root, with
separate keys or buckets. Never share one state file between the Windows and
Linux roots.

Exercises that teach state safely:

1. `terraform state list` in `terraform/linux`.
2. `terraform state show 'module.linux_vm["web01"].proxmox_virtual_environment_vm.this'`.
3. Change `memory` for `web01` in `terraform.tfvars`. Run `plan` and read the
   in-place update. Apply it.
4. Remove one entry from `vms`. Run `plan` and read the destroy before you
   apply. Add it back if you want to keep the VM.
5. Change a VM's `vm_id` and watch Terraform plan a replacement. Do not apply
   that on a machine you care about.

For imports, read the resource documentation first, then use
`terraform import` with the Proxmox identifier the provider documents. Import
does not generate configuration; write the resource, then import.

## Validation in this repository

The Linux root passes `terraform fmt -check` and `terraform validate` with
provider 0.117.0. Nothing here has been applied to a live cluster. Treat the
first `plan` as the real test.

## References

- Provider: https://registry.terraform.io/providers/bpg/proxmox/0.117.0/docs
- VM resource: https://registry.terraform.io/providers/bpg/proxmox/0.117.0/docs/resources/virtual_environment_vm
- Module syntax: https://developer.hashicorp.com/terraform/language/modules
- Backends: https://developer.hashicorp.com/terraform/language/backend
