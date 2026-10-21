# Ansible templates

Linux and Windows configuration examples. Every module name and option was
checked against the pinned collection version, not against memory. The pins
are in `requirements.yml`; the source links are in `../VERSIONS.md`.

## Layout

```
ansible.cfg                     existing Windows estate settings
requirements.yml                exact collection pins
inventories/
  windows/hosts.yml             existing AD estate
  windows-iis/hosts.yml         Windows IIS example
  linux/hosts.yml               web, database, docker_hosts
  linux/group_vars/all.yml      users, SSH keys, sysctl, packages
  linux/group_vars/web.yml      nginx sites
  linux/group_vars/database.yml PostgreSQL roles, databases, pg_hba rules
  linux/group_vars/docker_hosts.yml compose project
  linux/group_vars/vault.yml.example
playbooks/
  linux-baseline.yml
  web.yml
  database.yml
  containers.yml
  windows-iis.yml
roles/
  linux_baseline/               users, authorized keys, sudoers, sshd, sysctl
  nginx_web/                    nginx sites, optional self-signed TLS
  postgresql/                   roles, databases, pg_hba, nightly dump
  docker_app/                   Docker Engine plus a compose application
  windows_iis/                  IIS, app pool, site, firewall rule
```

## Install the collections

```
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-galaxy collection list | grep -E 'ansible.posix|community.docker|microsoft.iis'
```

## Prepare the inventory and secrets

1. Edit `inventories/linux/hosts.yml`. The addresses there are placeholders.
2. Edit `inventories/linux/group_vars/all.yml`. Replace the example SSH public
   keys with your own. Never put private keys in the repository.
3. Create the vault file:

```
cd ansible
cp inventories/linux/group_vars/vault.yml.example inventories/linux/group_vars/vault.yml
# edit the three values
ansible-vault encrypt inventories/linux/group_vars/vault.yml
```

The PostgreSQL role needs `python3-psycopg2` on the target. The role installs
it. The Docker role needs `docker-compose-plugin`; it comes from Docker's
repository.

## Run the playbooks

Every Linux command below uses `-i` because `ansible.cfg` still points at the
Windows estate inventory.

```
cd ansible
ansible-playbook -i inventories/linux/hosts.yml playbooks/linux-baseline.yml --ask-vault-pass
ansible-playbook -i inventories/linux/hosts.yml playbooks/web.yml --ask-vault-pass
ansible-playbook -i inventories/linux/hosts.yml playbooks/database.yml --ask-vault-pass
ansible-playbook -i inventories/linux/hosts.yml playbooks/containers.yml --ask-vault-pass
```

Windows:

```
cd ansible
cp inventories/windows-iis/group_vars/vault.yml.example inventories/windows-iis/group_vars/vault.yml
ansible-vault encrypt inventories/windows-iis/group_vars/vault.yml
ansible-playbook -i inventories/windows-iis/hosts.yml playbooks/windows-iis.yml --ask-vault-pass
```

## Prove idempotency

Run each playbook twice. The second run must report `changed=0`.

```
ansible-playbook -i inventories/linux/hosts.yml playbooks/web.yml --ask-vault-pass
```

Check the result on the host:

```
curl -sS http://<web-host>/ | head -5
nginx -t
ss -lntp | grep -E ':80|:443'
```

For the database host:

```
sudo -u postgres psql -c '\du'
sudo -u postgres psql -c '\l'
sudo -u postgres psql -c 'SHOW hba_file'
sudo -u postgres psql -c "SHOW listen_addresses"
```

For the container host:

```
sudo docker compose -f /opt/example/compose.yaml ps
curl -sS http://127.0.0.1:8080/ | head -5
```

## Deliberate break-fix exercises

1. Set `baseline_ssh_permit_root_login: "yes"` and run the baseline playbook.
   Confirm the change with `sshd -T | grep permitrootlogin`, then set it back.
   Do this on a console-accessible VM only.
2. Add a second entry to `nginx_sites` with `tls: true`. The role creates a
   self-signed certificate under `/etc/nginx/tls`.
3. Add a user to `baseline_users` with no `ssh_keys`. The role creates the
   account and installs no key, which is the correct outcome.
4. Break `pg_hba` by setting `method: trust` for your app subnet, then change
   it back to `scram-sha-256`. Watch the handler reload PostgreSQL.

## References

- Module index: https://docs.ansible.com/ansible/latest/collections/index_module.html
- `ansible.posix.authorized_key`: https://docs.ansible.com/ansible/latest/collections/ansible/posix/authorized_key_module.html
- `community.postgresql.postgresql_pg_hba`: https://docs.ansible.com/ansible/latest/collections/community/postgresql/postgresql_pg_hba_module.html
- `community.docker.docker_compose_v2`: https://docs.ansible.com/ansible/latest/collections/community/docker/docker_compose_v2_module.html
- `microsoft.iis.website`: https://docs.ansible.com/ansible/latest/collections/microsoft/iis/website_module.html
- `ansible.windows.win_user`: https://docs.ansible.com/ansible/latest/collections/ansible/windows/win_user_module.html
