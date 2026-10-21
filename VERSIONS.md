# Pinned versions

Every version below was read from the upstream registry on 2026-10-21.
Nothing is guessed from memory. Recheck before a new build.

| Component | Pin | Source |
|---|---|---|
| Terraform | 1.16.6 | https://releases.hashicorp.com/terraform/ |
| terraform-provider-proxmox | bpg/proxmox 0.117.0 | https://registry.terraform.io/providers/bpg/proxmox/0.117.0 |
| Packer | 1.16.1 | https://releases.hashicorp.com/packer/ |
| packer-plugin-proxmox | hashicorp/proxmox 1.2.4 | https://github.com/hashicorp/packer-plugin-proxmox/releases/tag/v1.2.4 |
| ansible-core | 2.21.5 | https://pypi.org/project/ansible-core/2.21.5/ |
| ansible-lint | 26.10.1 | https://pypi.org/project/ansible-lint/ |
| ansible.posix | 2.2.2 | https://galaxy.ansible.com/ui/repo/published/ansible/posix/ |
| community.general | 13.5.0 | https://galaxy.ansible.com/ui/repo/published/community/general/ |
| community.crypto | 3.5.1 | https://galaxy.ansible.com/ui/repo/published/community/crypto/ |
| community.docker | 5.4.0 | https://galaxy.ansible.com/ui/repo/published/community/docker/ |
| community.postgresql | 5.0.0 | https://galaxy.ansible.com/ui/repo/published/community/postgresql/ |
| ansible.windows | 3.9.1 | https://galaxy.ansible.com/ui/repo/published/ansible/windows/ |
| community.windows | 3.3.0 | https://galaxy.ansible.com/ui/repo/published/community/windows/ |
| microsoft.ad | 1.12.1 | https://galaxy.ansible.com/ui/repo/published/microsoft/ad/ |
| microsoft.iis | 1.3.0 | https://galaxy.ansible.com/ui/repo/published/microsoft/iis/ |
| Kubernetes | 1.37.1 | https://dl.k8s.io/release/stable.txt |
| ingress-nginx chart | 4.15.1 (controller 1.15.1) | https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.15.1 |
| nginx image | 1.30.6-alpine | https://hub.docker.com/_/nginx |
| PostgreSQL image | 18.6-trixie | https://hub.docker.com/_/postgres |
| Ubuntu Server ISO | 26.04.1 LTS | https://releases.ubuntu.com/26.04/ |
| Ubuntu ISO checksum | sha256:cc8a95cde20f6ced61a322420de00f10cc3c90ced545daa46cb9c1a117f1d927 | https://releases.ubuntu.com/26.04/SHA256SUMS |
| Debian (alternative base) | 13.7.0 | https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/ |

## What this repository has actually run

- `terraform fmt -check -recursive`, `terraform init -backend=false` and
  `terraform validate` pass for `terraform/linux/` with provider 0.117.0.
- `packer fmt -check` and `packer validate` pass for
  `packer/linux-image/` with plugin 1.2.4.
- `kubectl kustomize` builds both overlays with Kustomize v5.8.1.
- `kubeconform -strict -kubernetes-version 1.37.1` reports 14 of 14 objects
  valid for each overlay.
- Every YAML file in the repository parses.
- Ansible role task files were checked for one module per task and a name on
  every task. A full `ansible-playbook --syntax-check` was not run because
  ansible-core is not installed in the authoring environment.
- No Packer build, no `terraform apply` and no cluster apply has run. Those
  need the lab.
