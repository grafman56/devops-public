# Learning path

The repository is a small version of a real platform team's setup. One image
pipeline builds known-good operating systems. One infrastructure layer creates
machines. One configuration layer makes them do work. Containers and Kubernetes
run the same application with a different ownership model.

Work through the stages in order. Each stage has a goal, the files to read, the
commands to run, and something to observe. Versions are pinned in
`../VERSIONS.md`.

## Stage 0: secrets and version hygiene

Goal: learn where credentials live before you build anything.

Read: `.gitignore`, `ansible/inventories/linux/group_vars/vault.yml.example`,
`terraform/linux/providers.tf`.

Practice:

- API tokens stay in environment variables.
- Ansible secrets go in vault files, encrypted.
- `*.tfvars` and `*.pkrvars.hcl` stay out of Git.
- Provider lock files stay in Git.

Enterprise link: an estate fails an audit on leaked secrets faster than on a
broken deployment. The same split, environment for tokens and vault for
application secrets, works at any scale.

## Stage 1: one image, many machines

Goal: stop configuring operating systems by hand.

Read: `packer/linux-image/ubuntu-2604.pkr.hcl`, `packer/linux-image/http/user-data`.

Run:

```
cd packer/linux-image
make validate
make build
```

Observe: the Proxmox task log, then `qm config 9001`. The template has a
cloud-init drive and the guest agent. The installer ran with no keyboard input.

Enterprise link: a golden image pipeline is how a team ships a patched base OS
to hundreds of VMs without touching each one. Packer makes the image
reproducible, and the checksum makes the input verifiable.

## Stage 2: infrastructure as data

Goal: create VMs from a declaration, not from the Proxmox web UI.

Read: `terraform/modules/proxmox-vm/main.tf`, `terraform/linux/main.tf`,
`terraform/linux/variables.tf`.

Run:

```
cd terraform/linux
terraform init
terraform plan -out plan.bin
terraform apply plan.bin
terraform output -json vms
```

Observe: `for_each` creates one module instance per map entry. The `plan`
output shows the address, keys and VLAN that cloud-init will receive.

Exercise: add a third VM to `vms`. Plan it. Then change its `memory`. Read the
difference between create and in-place update.

Enterprise link: modules are the unit of reuse. A platform team publishes one
module, and product teams call it with their own variables. State separation
keeps one team's changes from breaking another team's resources.

## Stage 3: configuration that converges

Goal: reach the same state on every run, and prove it.

Read: `ansible/roles/linux_baseline/tasks/main.yml`, then
`ansible/roles/nginx_web/tasks/main.yml`.

Run the baseline, then the web role:

```
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventories/linux/hosts.yml playbooks/linux-baseline.yml --ask-vault-pass
ansible-playbook -i inventories/linux/hosts.yml playbooks/web.yml --ask-vault-pass
ansible-playbook -i inventories/linux/hosts.yml playbooks/web.yml --ask-vault-pass
```

Observe: the second run reports `changed=0`. Users exist, keys are installed,
sudoers is validated by `visudo`, sshd config is validated by `sshd -t`, and
nginx is validated by `nginx -t` before it reloads.

Then run the database role and the container role on their own hosts:

```
ansible-playbook -i inventories/linux/hosts.yml playbooks/database.yml --ask-vault-pass
ansible-playbook -i inventories/linux/hosts.yml playbooks/containers.yml --ask-vault-pass
```

Enterprise link: configuration management is where access control, patching
and service state become auditable. Validation before reload is the difference
between a change window and an outage.

## Stage 4: the same application in containers

Goal: see what the container moves into the image and what it leaves to the
orchestrator.

Read: `ansible/roles/docker_app/templates/compose.yaml.j2`.

Observe:

```
sudo docker compose -f /opt/example/compose.yaml ps
sudo docker compose -f /opt/example/compose.yaml logs --tail=20 db
curl -sS http://127.0.0.1:8080/
```

The dependency between web and database is a health condition, not a sleep.
The PostgreSQL password comes from a mode 0600 `.env` file, and the compose
file stays free of secrets.

Enterprise link: compose is a single-host contract. It is the right tool for a
lab and for small internal services. Kubernetes takes over when you need
scheduling, rollout control and self-healing across hosts.

## Stage 5: orchestration

Goal: run the same two-tier application with declared desired state.

Read: `kubernetes/base/deployment.yaml`, `kubernetes/base/postgres/statefulset.yaml`,
`kubernetes/base/networkpolicy.yaml`.

Run: follow `../kubernetes/README.md` to install the ingress controller, create
the secret, and apply the dev overlay.

Observe:

- `kubectl -n example-dev get pods` shows a Deployment pod and a StatefulSet
  pod. Only the StatefulSet pod has a stable name.
- `kubectl -n example-dev describe pod db-0` shows the claim mount.
- Delete `db-0`. It returns with the same name and claim.
- `kubectl -n example-dev describe hpa web` shows live CPU metrics after load.

Exercise: change the deployment image tag in an overlay patch, apply, and watch
the rolling update respect `maxUnavailable: 0`.

Enterprise link: probes, resource requests, disruption budgets and network
policies are the controls that make a cluster usable by many teams. Kustomize
overlays show how one base ships to several environments without forks.

## Stage 6: Windows alongside Linux

Goal: apply the same three-layer split to Windows.

Read: `ansible/roles/windows_iis/tasks/main.yml`, then the existing
`win-image/` and `terraform/main.tf`.

Run:

```
cd ansible
ansible-playbook -i inventories/windows-iis/hosts.yml playbooks/windows-iis.yml --ask-vault-pass
```

Observe: IIS is installed as a Windows feature, the app pool runs as a named
local account, and the firewall rule opens only the site port. The website
module and the authentication module come from `microsoft.iis` 1.3.0.

Enterprise link: most estates are mixed. The same image, shape and
configuration split applies. Windows adds WinRM, sysprep and domain joins, but
the ownership boundaries stay the same.

## Where to go next

- Replace local Terraform state with a shared backend, one per root module.
- Move the Ansible vault to a real secret store.
- Add a CI job that runs `terraform validate`, `packer validate`, `kubectl
  kustomize` and `kubeconform` on every pull request.
- Add a Kubernetes RBAC example with a namespace-scoped ServiceAccount.
- Add a second environment to the Packer build, for example Debian 13.
