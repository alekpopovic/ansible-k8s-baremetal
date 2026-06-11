# preflight

Validates that target hosts are suitable for kubeadm-based Kubernetes
bare-metal installation before any system-changing roles run.

This role is intentionally read-only. It uses gathered facts, assertions, debug
messages, and read-only `apt-cache policy` checks.

## Checks

- OS family is Debian.
- Distribution is Ubuntu 22.04, Ubuntu 24.04, or Debian 12.
- Minimum RAM:
  - control-plane: 2 GB
  - worker: 2 GB
- Minimum CPU:
  - control-plane: 2 vCPU
  - worker: 1 vCPU
- Hostname is unique across the active inventory.
- Each host has `ansible_host` or `ansible_default_ipv4.address`.
- Swap is disabled, or a warning is emitted when configured as non-fatal.
- Required base packages have apt install candidates.
- At least one supported time sync package has an apt install candidate.
- `control_plane_endpoint` is defined.
- When `ha_api_enabled=true`, `control_plane_endpoint` uses `k8s_api_vip`.
- `pod_cidr` and `service_cidr` are defined and are not equal.

The role does not verify that every node can SSH to every other node. The
Ansible control node must be able to SSH to all targets. Node-to-node network
connectivity is validated by later Kubernetes and CNI operations.

## Variables

```yaml
preflight_enabled: true
preflight_allow_unsupported_os: false
preflight_fail_on_swap: true

preflight_min_control_plane_ram_mb: 2048
preflight_min_worker_ram_mb: 2048
preflight_min_control_plane_vcpus: 2
preflight_min_worker_vcpus: 1

preflight_required_apt_packages:
  - apt-transport-https
  - ca-certificates
  - conntrack
  - curl
  - ebtables
  - ethtool
  - gnupg
  - iproute2
  - socat

preflight_time_sync_apt_packages:
  - chrony
  - systemd-timesyncd
```

Set `preflight_allow_unsupported_os: true` only for explicit lab testing on an
unsupported distribution. Production inventory should use a supported release.

Set `preflight_fail_on_swap: false` to warn instead of fail when swap is
enabled.

## Required Inventory Variables

The cluster inventory must define:

```yaml
control_plane_endpoint: "192.0.2.11:6443"
pod_cidr: "192.168.0.0/16"
service_cidr: "10.96.0.0/12"
```

## Firewall Port Reference

Open only the ports required for the selected topology. Exact firewall policy is
environment-specific and is not changed by this role.

Control-plane nodes commonly require:

| Port | Protocol | Purpose |
| --- | --- | --- |
| 6443 | TCP | Kubernetes API server |
| 2379-2380 | TCP | etcd server client and peer traffic |
| 10250 | TCP | kubelet API |
| 10257 | TCP | kube-controller-manager |
| 10259 | TCP | kube-scheduler |

Worker nodes commonly require:

| Port | Protocol | Purpose |
| --- | --- | --- |
| 10250 | TCP | kubelet API |
| 30000-32767 | TCP/UDP | NodePort services when used |

Calico requirements depend on the configured dataplane and encapsulation mode.
Common defaults include:

| Port | Protocol | Purpose |
| --- | --- | --- |
| 179 | TCP | BGP when Calico BGP is enabled |
| 4789 | UDP | VXLAN encapsulation |
| 5473 | TCP | Calico Typha when used |
| 51820-51821 | UDP | WireGuard encryption when enabled |

HA load balancer nodes commonly require:

| Port | Protocol | Purpose |
| --- | --- | --- |
| 6443 | TCP | Kubernetes API virtual endpoint |
| 112 | IP protocol | VRRP for Keepalived |

MetalLB requirements depend on layer 2 or BGP mode. For BGP mode, allow TCP 179
between MetalLB speakers and configured peers.
