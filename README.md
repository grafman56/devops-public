# server-admin

Infrastructure-as-code templates for learning: Packer images, Terraform
infrastructure, Ansible configuration, and Kubernetes manifests.

No file here targets a real device. Addresses come from the RFC 5737
documentation range or from a placeholder 192.0.2.0/24 network. Replace them
with your own values.

| Track | Directory | What it teaches |
|---|---|---|
| Windows image | `win-image/` | Packer, autounattend, sysprep, WinRM |
| Linux image | `packer/linux-image/` | Packer, Ubuntu autoinstall, cloud-init |
| Windows estate | `terraform/`, `ansible/roles/ad_dc`, `ansible/roles/app01` | Clone, domain join, IIS |
| Linux VMs | `terraform/linux/`, `terraform/modules/proxmox-vm/` | Modules, for_each, cloud-init identity |
| Linux services | `ansible/roles/*` | Users and SSH keys, nginx, PostgreSQL, Docker |
| Windows IIS | `ansible/roles/windows_iis/` | IIS site, app pool, firewall |
| Kubernetes | `kubernetes/` | Deployments, StatefulSets, probes, NetworkPolicy, Kustomize, Helm |

Pinned versions with source links: `VERSIONS.md`.
Suggested learning order: `docs/learning-path.md`.

The Windows estate section below is the original worked example. It stays
accurate for its own directories.

## Windows Server 2025 estate

Windows Server 2025 golden image and estate on Proxmox, built by Packer,
provisioned by Terraform, configured by Ansible.

Three layers, deliberately separate:

| Layer | Tool | Owns |
|---|---|---|
| Image | Packer | OS install, drivers, guest agent, WinRM, sysprep |
| Shape | Terraform | VM exists, CPU, RAM, disk, bridge, VLAN, tags |
| Configuration | Ansible | hostname, DNS, domain, roles, hardening |

Provisioning stays separate from configuration so a rebuild never means
reinstalling Windows, and a configuration change never means a new VM.

## Pinned versions

Windows estate versions, verified 2026-10-20 against the upstream registries.
The full table for every track is in `VERSIONS.md`.

- Packer 1.11 or newer
- packer-plugin-proxmox v1.2.4 (github.com/hashicorp/proxmox)
- Terraform 1.9 or newer
- terraform-provider-proxmox 0.117.0 (bpg/proxmox)
- ansible-core 2.21.5
- pywinrm 0.5.0

## Prerequisites, all manual, once

1. Upload the Windows Server 2025 evaluation ISO and the `virtio-win` ISO to
   the Proxmox ISO store on the node. The Packer builder does not download
   them.
2. Build the answer ISO from this repo, then upload it the same way.
3. Create a Proxmox API token for Packer and a separate token for Terraform.
   Both need `VM.Allocate`, `VM.Config.*`, `VM.Audit`, `VM.PowerMgmt` on `/vms`
   and `Datastore.AllocateSpace` on the target storage. No `root@pam`.
4. DHCP reservations on OPNsense for the two VM MACs, or let them take DHCP
   leases and record the addresses in the Ansible inventory.
5. Store the Administrator password, the two API tokens and the domain
   recovery password in Vault under `secret/example/windows-estate`.

## Order of operations

Build the image:

```
cd win-image
export ADMIN_PASSWORD='...'
make answer-iso
# upload build/win2025-autounattend.iso to local:iso/ on pve.example.internal
export PROXMOX_URL='https://pve.example.internal:8006/api2/json'
export PROXMOX_TOKEN_ID='packer@pve!packer'
export PROXMOX_TOKEN_SECRET='...'
make validate
make build
```

Create the VMs:

```
cd terraform
export PROXMOX_VE_API_TOKEN='terraform@pve!tf=xxxxxxxx-...'
./tf init
./tf plan -out plan.bin
./tf apply plan.bin
```

Configure them:

```
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-vault encrypt inventories/windows/group_vars/secrets.yml   # once
ansible-playbook site.yml --ask-vault-pass
ansible-playbook site.yml --ask-vault-pass   # second run must report changed=0
```

## Decisions worth knowing before you run this

Boot mode is SeaBIOS with a virtio-scsi disk. UEFI is not used, because Windows
Server 2025 evaluation media plus OVMF plus Secure Boot adds a signing problem
you do not need for a lab. The comment in `win2025.pkr.hcl` shows where to
change it if you want UEFI later.

The Packer plugin's `os` enum stops at `win10`, so the build uses `win10`.
Proxmox applies the same Windows tuning either way. After the build, put the
template on the correct type for the record:

```
qm set 9000 --ostype win11
```

Terraform then clones with `operating_system.type = "win11"`, which provider
0.117.0 supports.

The install needs the virtio-scsi driver from the virtio-win ISO. The answer
file points the driver search at four drive letters, because Windows PE assigns
CD letters unpredictably when three discs are attached. Missing paths are
skipped with a warning. If driver injection fights you, set
`scsi_controller = "lsi"` in `win2025.pkr.hcl`. Windows has a built-in LSI
driver, so the install proceeds with no injection at all. You lose some disk
performance and gain a working build.

The image is sysprep-generalized. Each clone boots through OOBE using the
cached deploy answer file at `C:\Windows\System32\Sysprep\unattend.xml`, which
sets the same local Administrator password from Vault. A clone is not
domain-joined; Ansible renames it, points DNS at the DC, then joins. This is
the supported path. Skipping generalization is faster but leaves duplicate
machine SIDs and is unsupported for cloned servers.

Terraform does not configure the guest. There is no cloud-init on Windows, and
cloudbase-init would be a fourth moving part. Terraform gives you a MAC
address and a VM; Ansible owns identity and network settings. DHCP reservations
on the firewall keep addresses stable without a first-boot agent.

## What is not here

Untested against live Proxmox. The files validate as YAML and XML, the HCL is
written against the pinned provider and plugin documentation, but no build has
run. Expect the answer file to need one round of edits on the first build. That
is normal for Windows imaging and it is why `make build` logs to
`build/packer.log`.
