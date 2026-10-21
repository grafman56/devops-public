# Packer: Ubuntu Server 26.04.1 LTS template

Builds a Proxmox template with:

- Ubuntu Server 26.04.1 LTS, unattended through autoinstall
- `qemu-guest-agent`, so Terraform can shut the clone down cleanly
- a cloud-init drive, so each clone gets its own identity and network
- a cleaned machine ID and cloud-init state, so clones are not duplicates

Builder and plugin are pinned: Packer 1.16 or newer, `hashicorp/proxmox`
1.2.4. Source links are in `../../VERSIONS.md`.

## Prerequisites

1. Upload `ubuntu-26.04.1-live-server-amd64.iso` to a Proxmox ISO store.
   The builder does not download the ISO.
2. Verify the upload against the published checksum:

```
sha256sum ubuntu-26.04.1-live-server-amd64.iso
# cc8a95cde20f6ced61a322420de00f10cc3c90ced545daa46cb9c1a117f1d927
```

3. Create a Proxmox API token for Packer. It needs `VM.Allocate`,
   `VM.Config.*`, `VM.Audit`, `VM.PowerMgmt` on `/vms` and
   `Datastore.AllocateSpace` on the target storage. Do not use `root@pam`.
4. Confirm the target datastore supports cloud-init drives. `local-lvm` does.

## Build

```
cd packer/linux-image
cp build.pkrvars.hcl.example build.pkrvars.hcl
# edit the placeholders

export PROXMOX_URL='https://pve.example.internal:8006/api2/json'
export PROXMOX_USERNAME='packer@pve!packer'
export PROXMOX_TOKEN='<uuid secret>'
export BUILD_PASSWORD='packer'

make validate
make build
```

`make build` writes `build/packer.log`. Watch the Proxmox console during the
first build. The GRUB edit in `boot_command` is the step most likely to need
one adjustment on a new release.

## After the build

The builder converts the VM to a template. Check it:

```
qm config 9001 | grep -E 'template|ide2|agent'
```

`ide2` is the cloud-init drive. `agent` must be enabled. Then use the template
ID in `terraform/linux/terraform.tfvars`.

## What is deliberately not automated

- The ISO upload and checksum.
- The API token.
- DNS records for the clones.
- UEFI. The build uses the default SeaBIOS path. To switch, set `bios = "ovmf"`
  and add an `efi_config` block; the plugin documents both.

## References

- Builder: https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox/latest/components/builder/iso
- Autoinstall reference: https://canonical-subiquity.readthedocs.io/en/latest/reference/autoinstall-reference.html
- Ubuntu 26.04 download and checksums: https://releases.ubuntu.com/26.04/
