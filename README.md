# ansible-k8s-baremetal

An Ansible-based bootstrap repository for Kubernetes on bare-metal hosts using
`kubeadm`, `kubelet`, `kubectl`, and `containerd`.

The project is intentionally conservative: tasks should be idempotent, major
settings should live in inventory variables, and destructive operations should
require explicit opt-in variables.

## Goal

Provide a clean, repeatable Kubernetes deployment flow for lab and production
bare-metal environments. The repository will support operating system
preparation, container runtime setup, Kubernetes package installation,
control-plane bootstrap, worker joins, Calico CNI, optional MetalLB, optional
ingress-nginx, and validation.

## Supported Topology

- Single control-plane cluster.
- HA control-plane cluster with an explicit `control_plane_endpoint`.
- Optional external or in-cluster load balancer nodes through `lb_nodes`.
- Worker nodes joined through kubeadm.
- Calico as the default CNI.
- Optional MetalLB for bare-metal `LoadBalancer` services.
- Optional ingress-nginx.

Target operating systems are Ubuntu 22.04, Ubuntu 24.04, and Debian 12 where
practical.

## Prerequisites

- Ansible installed on the control machine.
- SSH access from the control machine to all target nodes.
- Passwordless privilege escalation or a documented become password flow.
- Supported Linux distribution on each target node.
- Stable node hostnames and IP addresses.
- Kernel, firewall, and network settings reviewed for Kubernetes.
- A non-overlapping pod CIDR, service CIDR, and MetalLB address pool.

Install required collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Quick Start

Review and edit the lab inventory:

```bash
cp inventories/production/hosts.ini.example inventories/production/hosts.ini
cp inventories/production/group_vars/kube_cluster.yml.example \
  inventories/production/group_vars/kube_cluster.yml
```

For the default lab inventory, update:

```text
inventories/lab/hosts.ini
inventories/lab/group_vars/kube_cluster.yml
```

Run a syntax check:

```bash
ansible-playbook --syntax-check site.yml
```

Run static validation when the tools are available:

```bash
yamllint .
ansible-lint
```

Preview where possible:

```bash
ansible-playbook site.yml --check --diff
```

Apply the playbook only after reviewing inventory values and safety notes:

```bash
ansible-playbook site.yml
```

## Safety Notes

- Do not commit secrets, kubeconfig contents, join tokens, certificate keys,
  private SSH keys, or passwords.
- Use Ansible Vault placeholders for secret material.
- Do not run destructive actions unless the related opt-in variable is clearly
  enabled and documented.
- `kubeadm reset` must never run automatically.
- Check mode may be limited for kubeadm, package repository setup, CNI
  application, and tasks that depend on live cluster state.
- Review `docs/operations.md` and `docs/troubleshooting.md` as operational
  content is added.
