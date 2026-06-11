# Security

Security guidance for operating this bare-metal Kubernetes repository.

## Secret Handling

Never commit:

- kubeconfig files
- kubeadm join commands
- kubeadm certificate keys
- Kubernetes certificates or private keys
- SSH private keys
- passwords
- plaintext Ansible Vault passwords

Use Ansible Vault for secrets:

```bash
ansible-vault create inventories/production/group_vars/vault.yml
ansible-vault edit inventories/production/group_vars/vault.yml
```

Example reference from non-secret inventory:

```yaml
keepalived_auth_pass: "{{ vault_keepalived_auth_pass }}"
```

Run playbooks with a Vault prompt:

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml --ask-vault-pass
```

Do not store Vault password files in this repository.

## SSH Access Model

The Ansible control node needs SSH access to every managed host. Prefer named
administrator accounts, SSH keys with passphrases, host key checking, and
network controls that limit who can reach SSH.

Avoid shared private keys across teams. Remove departed operators from hosts and
from any bastion systems.

## sudo/become Assumptions

The playbook uses privilege escalation for system changes. Operators should use
least-privilege sudo policy where possible and keep sudo access auditable.

Validate access before bootstrap:

```bash
ansible all -i inventories/production/hosts.ini -m ping
ansible all -i inventories/production/hosts.ini -m command -a id --become
```

## kubeconfig Protection

`/etc/kubernetes/admin.conf` grants cluster-admin access. Protect it like a
root password.

Recommended handling:

```bash
scp root@cp-01:/etc/kubernetes/admin.conf ./admin.conf
chmod 600 ./admin.conf
export KUBECONFIG="$PWD/admin.conf"
```

Do not commit kubeconfigs or send them through chat, tickets, or email.

## API Endpoint Exposure

Restrict TCP `6443` to trusted management networks, worker nodes, and required
automation systems. For HA deployments, protect the VIP in the same way.

If HAProxy stats are enabled, bind them only to trusted networks or protect them
with additional controls.

## Firewall Recommendations

Allow only required traffic:

- SSH from trusted administration networks.
- Kubernetes API TCP `6443`.
- etcd TCP `2379-2380` between control-plane nodes only.
- kubelet TCP `10250` from control-plane nodes.
- NodePort TCP/UDP `30000-32767` only when needed.
- Calico VXLAN UDP `4789` or BGP TCP `179` depending on mode.
- VRRP between `lb_nodes` when Keepalived is enabled.

Do not expose etcd to worker nodes or external networks.

## Image Provenance

Pin image versions where practical. Prefer official upstream images or trusted
internal registries. For production, consider mirroring critical images,
scanning images before rollout, enforcing admission controls, and avoiding
mutable tags such as `latest`.

The validation smoke workload uses nginx only when explicitly enabled.

## API Audit Policy

Set `kubeadm_audit_policy_enabled: true` before initial cluster creation to
render an audit policy into the kubeadm configuration.

```yaml
kubeadm_audit_policy_enabled: true
```

Review audit log volume, retention, and forwarding before enabling this in
production.

## Pod Security Admission

Pod Security Admission labels can be applied by the validation role when
explicitly enabled:

```yaml
pod_security_admission_labels_enabled: true
pod_security_admission_namespaces:
  - default
pod_security_admission_enforce: baseline
pod_security_admission_audit: restricted
pod_security_admission_warn: restricted
```

Start with `warn` and `audit` before enforcing `restricted` on application
namespaces.

## NetworkPolicy Examples

Examples live in `examples/network-policies/`:

```bash
kubectl apply -f examples/network-policies/default-deny-ingress.yaml
kubectl apply -f examples/network-policies/allow-same-namespace.yaml
kubectl apply -f examples/network-policies/allow-dns-egress.yaml
```

Review namespace names before applying examples.

## RBAC Example

A read-only cluster viewer example lives in `examples/rbac/`:

```bash
kubectl apply -f examples/rbac/readonly-cluster-viewer.yaml
```

Bind real users and groups through your identity provider where possible.

## Backup Encryption

etcd snapshots contain Kubernetes Secrets. Encrypt backups at rest and in
transit. Store them outside the repository and outside the failed cluster. Limit
restore permissions to trusted operators.
