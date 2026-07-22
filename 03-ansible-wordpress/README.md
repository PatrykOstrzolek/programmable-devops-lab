# 03 — Ansible + WordPress

## Goal

Configure an EC2 server with a repeatable Ansible playbook.

## Outcome

The server receives the required packages, web server configuration, PHP, a database, and WordPress; rerunning the playbook makes no unnecessary changes.

## To do

- [x] Create an inventory that points to the server from stage 02.
- [x] Split the configuration into `common`, `web`, `database`, and `wordpress` roles.
- [x] Store passwords using Ansible Vault or CI secrets.
- [x] Run the playbook twice and confirm idempotency.

## Inventory

`inventory/hosts.ini` points to the stage 02 EC2 instance (`51.102.110.245`,
`ansible_user=ubuntu`). `ansible.cfg` sets the default inventory path and the
private key file (`~/.ssh/id_ed25519`, matching the key pair from stage 02).

Run this from `03-ansible-wordpress/`:

```bash
ansible all -m ping
```

Verification: `ping` returns `pong` for the host.

### Known limitation for CI

This static inventory and `ansible.cfg` are meant for local, manual runs. They will
not work as-is from GitHub Actions in stage 04:

- `private_key_file = ~/.ssh/id_ed25519` assumes a local key on disk. CI will need to
  write the private key from a GitHub Secret to a temporary file and point to it via
  `--private-key` or `ANSIBLE_PRIVATE_KEY_FILE`.
- `host_key_checking = True` will fail on a fresh runner with no `known_hosts` entry
  for the host. CI will need an `ssh-keyscan` step (or another way to establish trust)
  before running Ansible.
- The hardcoded IP here will be replaced by the dynamic inventory sourced from the
  Terraform output, per the stage 04 plan.

## `common` role

Runs `apt` update, a full `dist` upgrade, and installs a small baseline package set
(`curl`, `unzip`, `ca-certificates`), defined in `roles/common/defaults/main.yml`.
Wired into `site.yml`, the top-level playbook for this stage.

Run this from `03-ansible-wordpress/`:

```bash
ansible-playbook site.yml
```

Verification: ran twice. First run reported `changed=3`; second run reported
`changed=0`, confirming idempotency.

## `web` role

Installs Nginx and PHP-FPM 8.3 with the extensions WordPress needs (`php-mysql`,
`php-curl`, `php-gd`, `php-mbstring`, `php-xml`, `php-zip`, `php-intl`). Deploys an
Nginx server block (`roles/web/templates/nginx-site.conf.j2`) that serves
`{{ web_document_root }}` (default `/var/www/wordpress`) and proxies `.php` requests
to PHP-FPM over its Unix socket. Removes the default Nginx site so it does not
conflict.

During development this role temporarily deployed an `info.php` (`phpinfo()`) page
to verify PHP was wired up correctly. It was removed once the `wordpress` role
existed: the two roles fought over that file on every run (`web` recreating it,
`wordpress` deleting it), which broke idempotency (`changed` never reached `0`
with the full stack). Verified at the time with `curl` returning `200` and
`PHP Version 8.3.6`.

Run this from `03-ansible-wordpress/`:

```bash
ansible-playbook site.yml
```

## `database` role

Installs `mysql-server` and `python3-pymysql` (required by the Ansible MySQL
modules on the target), then creates the `wordpress` database and a `wordpress`
database user scoped to it (`ALL` privileges on `wordpress.*`, `localhost` only —
MySQL is not exposed outside the instance). Uses `ansible.mysql.mysql_db` and
`ansible.mysql.mysql_user` (the `community.mysql` equivalents are deprecated),
declared in `requirements.yml`. Authenticates to MySQL via the `root` Unix socket,
matching Ubuntu's default `auth_socket` setup — no root password is needed or
stored.

The database password is never written in plaintext. It is generated with
`openssl rand -base64 24` and stored Ansible Vault-encrypted in
`group_vars/web/vault.yml`, decrypted automatically via `vault_password_file` in
`ansible.cfg` pointing at `.vault_pass` (gitignored, local-only, not committed).
The `mysql_user` task also sets `no_log: true` so the password never appears in
playbook output, even in verbose mode.

Run this from `03-ansible-wordpress/`:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

Verification: ran twice. First run reported `changed=3`; second run reported
`changed=0`, confirming idempotency.

## `wordpress` role

Downloads the latest WordPress release (`wordpress.org/latest.tar.gz`, not pinned to
a specific version — acceptable for this learning lab), extracts it, and deploys the
core files to `{{ web_document_root }}`. Renders `wp-config.php` from
`roles/wordpress/templates/wp-config.php.j2` with the database credentials and
unique authentication salts.

The salts (`AUTH_KEY`, `SECURE_AUTH_KEY`, etc.) are generated once via Ansible's
`password` lookup, which caches each value to a local, gitignored file under
`.wp_salts/` on the control machine — so the same salts are reused on every run
instead of being regenerated (regenerating them on every apply would invalidate all
logged-in sessions and break idempotency). Declared in `group_vars/web/vars.yml`.
The `wp-config.php` template task sets `no_log: true` so the database password
never appears in playbook output.

Run this from `03-ansible-wordpress/`:

```bash
ansible-playbook site.yml
```

Verification: `curl -sL -o /dev/null -w '%{http_code}' http://51.102.110.245/`
returned `200` after following the redirect to `/wp-admin/install.php`, and the page
contained "WordPress" — confirming Nginx, PHP-FPM, WordPress, and the database
connection all work end to end. Completing the WordPress install wizard itself
(creating the site title and admin user) is a manual browser step, out of scope
here.

## Full stack idempotency

Ran `ansible-playbook site.yml` (all four roles) twice in a row: `changed=0` on the
second run, confirming the complete `common` + `web` + `database` + `wordpress`
stack is idempotent.
