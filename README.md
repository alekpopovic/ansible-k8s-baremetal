# ansible-k8s-baremetal

An Ansible-based bootstrap repository for Kubernetes on bare-metal hosts using
`kubeadm`, `kubelet`, `kubectl`, `containerd`, Calico, optional MetalLB,
optional ingress-nginx, and optional HAProxy/Keepalived for a highly available
Kubernetes API endpoint.

The project is intentionally conservative: tasks should be idempotent, cluster
settings should live in inventory variables, and destructive operations should
require explicit operator action.

## Supported Topologies

- Single control-plane node plus workers.
- HA control-plane nodes plus workers.
- Optional external load balancer nodes in `lb_nodes` using HAProxy and
  Keepalived with a shared VIP.
- Calico CNI.
- Optional MetalLB for bare-metal `LoadBalancer` Services.
- Optional ingress-nginx.

Supported target operating systems are Ubuntu 22.04, Ubuntu 24.04, and Debian
12 where practical.

## Inventory

Start from the production examples:

```bash
cp inventories/production/hosts.ini.example inventories/production/hosts.ini
cp inventories/production/group_vars/all.yml.example \
  inventories/production/group_vars/all.yml
cp inventories/production/group_vars/kube_cluster.yml.example \
  inventories/production/group_vars/kube_cluster.yml
```

Required groups:

```ini
[kube_control_plane]
cp-01 ansible_host=10.0.0.11

[kube_workers]
worker-01 ansible_host=10.0.0.21

[lb_nodes]
# lb-01 ansible_host=10.0.0.10

[kube_cluster:children]
kube_control_plane
kube_workers
```

Core variables:

```yaml
k8s_minor: "1.30"
k8s_version: "1.30.0"
pod_cidr: "192.168.0.0/16"
service_cidr: "10.96.0.0/12"
cluster_dns_domain: cluster.local
control_plane_endpoint: "10.0.0.10:6443"
cri_socket: "unix:///run/containerd/containerd.sock"
calico_version: "v3.28.0"
```

For HA API endpoint support:

```yaml
ha_api_enabled: true
k8s_api_vip: "10.0.0.10"
k8s_api_vip_interface: eth0
k8s_api_port: 6443
control_plane_endpoint: "10.0.0.10:6443"
keepalived_auth_pass: "{{ vault_keepalived_auth_pass }}"
```

`keepalived_auth_pass` must come from Ansible Vault or another secret source.
Never commit the plaintext value.

## Network Requirements

At minimum, allow:

- SSH from the Ansible control machine to all managed hosts.
- Kubernetes API: TCP `6443` to the control-plane endpoint.
- etcd between control-plane nodes: TCP `2379-2380`.
- kubelet API: TCP `10250`.
- kube-controller-manager and scheduler on control-plane nodes: TCP `10257` and
  `10259`.
- NodePort Services when used: TCP/UDP `30000-32767`.
- Calico traffic according to the selected mode. VXLAN commonly uses UDP
  `4789`; BGP mode uses TCP `179`.
- VRRP between `lb_nodes` when Keepalived is enabled.

All Kubernetes nodes need stable node-to-node connectivity. Pod CIDR, service
CIDR, node IPs, VIPs, and MetalLB pools must not overlap.

## Local Tooling

Install required collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Install local validation tools when needed:

```bash
python -m pip install ansible-core ansible-lint yamllint
```

Run validation:

```bash
scripts/lint.sh
scripts/syntax-check.sh
```

The syntax check does not SSH to hosts or run tasks:

```bash
ansible-playbook -i inventories/lab/hosts.ini site.yml --syntax-check
```

## Bootstrap

Check SSH and privilege escalation:

```bash
ansible all -i inventories/lab/hosts.ini -m ping
```

Run the full playbook:

```bash
ansible-playbook -i inventories/lab/hosts.ini site.yml
```

Run selected phases by tag:

```bash
ansible-playbook -i inventories/lab/hosts.ini site.yml --tags preflight
ansible-playbook -i inventories/lab/hosts.ini site.yml --tags os,containerd
ansible-playbook -i inventories/lab/hosts.ini site.yml --tags kubernetes
ansible-playbook -i inventories/lab/hosts.ini site.yml --tags control-plane
ansible-playbook -i inventories/lab/hosts.ini site.yml --tags workers,cni
ansible-playbook -i inventories/lab/hosts.ini site.yml --tags metallb,ingress
ansible-playbook -i inventories/lab/hosts.ini site.yml --tags validation
```

## Kubeconfig

After bootstrap, retrieve the admin kubeconfig from the first control-plane
node:

```bash
scp root@cp-01:/etc/kubernetes/admin.conf ./admin.conf
chmod 600 ./admin.conf
export KUBECONFIG="$PWD/admin.conf"
kubectl get nodes -o wide
```

Do not commit kubeconfig files.

## Common Add-Ons

Enable MetalLB:

```yaml
metallb_enabled: true
metallb_address_pool:
  - "10.0.0.240-10.0.0.250"
```

The selected addresses must be free on the LAN and outside DHCP scopes.

Enable ingress-nginx:

```yaml
ingress_nginx_enabled: true
ingress_nginx_service_type: LoadBalancer
```

On bare metal, `LoadBalancer` requires MetalLB or another load balancer
implementation. Use `NodePort` if you are not enabling MetalLB.

## Documentation

- [Architecture](docs/architecture.md)
- [Operations](docs/operations.md)
- [Upgrade](docs/upgrade.md)
- [Backup And Restore](docs/backup-restore.md)
- [Security](docs/security.md)
- [Troubleshooting](docs/troubleshooting.md)

## Safety Notes

- Do not commit tokens, certificate keys, kubeconfig contents, passwords,
  private SSH keys, or plaintext secrets.
- Use Ansible Vault placeholders for secrets.
- Do not run `kubeadm reset` automatically.
- Back up etcd and important workloads before upgrades or destructive work.
- Treat node replacement, control-plane replacement, and manual etcd recovery as
  high-risk operations.
