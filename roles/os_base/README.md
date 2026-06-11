# os_base

Prepares Debian-family Linux hosts for Kubernetes installation with
kubeadm and containerd.

This role performs operating system changes. Run the `preflight` role first and
review inventory variables before applying it.

## What It Does

- Installs base packages required for Kubernetes bootstrap and diagnostics.
- Enables and starts `chrony`.
- Optionally disables active swap.
- Optionally comments swap entries in `/etc/fstab`.
- Loads the `overlay` and `br_netfilter` kernel modules.
- Persists Kubernetes kernel modules in `/etc/modules-load.d/k8s.conf`.
- Configures Kubernetes networking sysctl values.
- Persists sysctl values in `/etc/sysctl.d/99-kubernetes-cri.conf`.
- Optionally manages cluster host entries in `/etc/hosts`.

## Variables

```yaml
os_base_enabled: true
os_base_disable_swap: true
os_base_manage_hosts_file: false

os_base_packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gpg
  - gnupg
  - lsb-release
  - software-properties-common
  - chrony
  - iproute2
  - iptables
  - socat
  - conntrack

os_base_kernel_modules:
  - overlay
  - br_netfilter

os_base_sysctl_settings:
  net.bridge.bridge-nf-call-iptables: 1
  net.bridge.bridge-nf-call-ip6tables: 1
  net.ipv4.ip_forward: 1
```

## Swap

`os_base_disable_swap: true` disables active swap with `swapoff -a` and comments
swap entries in `/etc/fstab`. The `/etc/fstab` task creates a backup before
editing.

Set `os_base_disable_swap: false` only when you intentionally plan to configure
kubelet swap behavior yourself.

## Hosts File Management

Set `os_base_manage_hosts_file: true` to add an Ansible-managed block to
`/etc/hosts` for hosts in the `kube_cluster` inventory group. The role uses
`ansible_host` when available and falls back to `ansible_default_ipv4.address`.

## Tags

- `os`
- `kernel`
- `swap`
- `sysctl`
