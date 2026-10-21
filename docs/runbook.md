# Windows Server 2025 estate runbook

Operating notes for the estate that `win2025-estate` builds. Read this before
changing anything by hand, because every manual change is a drift the next
Ansible run will revert.

## Topology

| Host | VM ID | Role | Address | Built by |
|---|---|---|---|---|
| `dc01` | 9101 | First DC, DNS for `lab.example.internal` | DHCP reservation | Terraform clone of 9000 |
| `app01` | 9102 | Member server, IIS test site | DHCP reservation | Terraform clone of 9000 |
| template | 9000 | Gold image, never started | none | Packer |

Node: `pve` on pve.example.internal. Storage pool: fill in. Bridge and VLAN: fill in.

## Rebuild from nothing

1. `cd win-image && make answer-iso` with `ADMIN_PASSWORD` exported.
2. Upload `build/win2025-autounattend.iso` to the Proxmox ISO store.
3. `make build`. Expect 25 to 40 minutes. The log is `build/packer.log`.
4. `qm set 9000 --ostype win11`, because the Packer plugin cannot set that type.
5. `cd terraform && ./tf apply`. Expect under five minutes.
6. `terraform output mac_addresses`, then set the DHCP reservations.
7. `cd ansible && ansible-playbook site.yml --ask-vault-pass`.
8. Run it again. `changed=0` is the proof the estate converged.

## Break-glass

When Ansible cannot reach a host:

1. Open the Proxmox console for the VM. The image has RDP disabled on purpose,
   and WinRM is the only remote path.
2. Log in as the local `Administrator` with the build password from Vault under
   `secret/example/windows-estate`.
3. Check the management channel before anything else:

```
Get-Service WinRM
winrm enumerate winrm/config/Listener
Get-NetFirewallRule -Name WinRM-HTTPS | Select Enabled,Profile
Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -like "CN=*"
```

A renamed host with an old certificate is the common failure. The channel
works anyway because certificate validation is disabled, so the symptom is
usually a firewall profile or a stopped service, not the certificate.

## Known sharp edges

The evaluation clock runs 180 days from the install. Rebuilding the image is
the fix, and it costs one pipeline run. Record the expiry date here whenever
you rebuild.

`sysprep /generalize` resets the local Administrator password to the value in
`C:\Windows\System32\Sysprep\unattend.xml`, which is the build password. The
Ansible vault holds the same value. Change one, change both.

The hardening role restricts NTLM to audit by default. Moving to block is a
deliberate change per host. Blocking before a domain join breaks the join, and
the error looks like a credential problem.

Terraform destroys clones cleanly only because the image ships
`qemu-guest-agent`. If a destroy hangs, the agent is not running, and
`stop_on_destroy = true` in `main.tf` is what saves you from a hung apply.

## Drift drill

Run this monthly, because it is the claim the whole repository makes:

```
# 1. Break something by hand on app01
#    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' RequireSecuritySignature 0

# 2. Show the drift, change nothing
ansible-playbook site.yml --check --diff --ask-vault-pass --limit app01

# 3. Fix it
ansible-playbook site.yml --ask-vault-pass --limit app01

# 4. Prove convergence
ansible-playbook site.yml --ask-vault-pass --limit app01
# expected: changed=0
```

## Retiring the estate

```
cd terraform && ./tf destroy
```

Then delete template 9000 in Proxmox if the image itself is being replaced.
Check for orphan disks first:

```
pvesh get /nodes/pve/storage/local-lvm/content --content images
```
