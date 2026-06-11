# Architecture

This repository deploys Kubernetes on bare-metal Linux hosts with Ansible and
kubeadm. It uses containerd as the runtime, Calico as the CNI, and optional
MetalLB and ingress-nginx for service exposure.

## Topologies

### Single Control Plane

Use one host in `kube_control_plane` and one or more hosts in `kube_workers`.

```ini
[kube_control_plane]
cp-01 ansible_host=10.0.0.11

[kube_workers]
worker-01 ansible_host=10.0.0.21
worker-02 ansible_host=10.0.0.22
```

Set the control-plane endpoint directly to the control-plane node:

```yaml
ha_api_enabled: false
control_plane_endpoint: "10.0.0.11:6443"
```

### HA Control Plane

Use three or more control-plane nodes when possible:

```ini
[kube_control_plane]
cp-01 ansible_host=10.0.0.11
cp-02 ansible_host=10.0.0.12
cp-03 ansible_host=10.0.0.13
```

Set `control_plane_endpoint` to a stable address, usually a VIP or DNS name:

```yaml
control_plane_endpoint: "10.0.0.10:6443"
```

Additional control-plane joins should be run serially. Avoid joining multiple
new control-plane nodes at exactly the same time.

### Optional External LB/VIP

Add `lb_nodes` when using the repository's HAProxy and Keepalived roles:

```ini
[lb_nodes]
lb-01 ansible_host=10.0.0.10
lb-02 ansible_host=10.0.0.9
```

Enable the HA API endpoint in inventory-wide vars:

```yaml
ha_api_enabled: true
k8s_api_vip: "10.0.0.10"
k8s_api_vip_interface: eth0
k8s_api_port: 6443
control_plane_endpoint: "10.0.0.10:6443"
keepalived_virtual_router_id: 51
keepalived_auth_pass: "{{ vault_keepalived_auth_pass }}"
```

`keepalived_auth_pass` must be stored in Ansible Vault or another secret source.
Do not commit the plaintext value.

## Inventory Groups

- `kube_control_plane`: Kubernetes API server, controller-manager, scheduler,
  and etcd nodes.
- `kube_workers`: Kubernetes worker nodes.
- `kube_cluster`: child group containing `kube_control_plane` and
  `kube_workers`.
- `lb_nodes`: optional HAProxy/Keepalived nodes for the Kubernetes API VIP.

`lb_nodes` are intentionally separate from `kube_cluster`. With the default
`haproxy_k8s_api_bind_address: "*"`, do not place HAProxy on a control-plane
host because HAProxy and kube-apiserver would both bind TCP `6443`.

## Network Requirements

All nodes must have stable hostnames, stable IPs, and reliable node-to-node
connectivity.

Required traffic:

| Purpose | Ports |
| --- | --- |
| SSH from Ansible control node | TCP 22 |
| Kubernetes API | TCP 6443 |
| etcd client and peer traffic | TCP 2379-2380 |
| kubelet API | TCP 10250 |
| kube-controller-manager | TCP 10257 |
| kube-scheduler | TCP 10259 |
| NodePort Services | TCP/UDP 30000-32767 |
| Calico VXLAN | UDP 4789 |
| Calico BGP, if enabled | TCP 179 |
| Keepalived VRRP | IP protocol 112 |
| HAProxy stats, if enabled | TCP 8404 by default |

CIDR planning:

- `pod_cidr` must not overlap node networks, service networks, or VPN ranges.
- `service_cidr` must not overlap node networks or pod networks.
- `metallb_address_pool` must contain free LAN IPs outside DHCP scopes.
- `k8s_api_vip` must be free and reachable on `k8s_api_vip_interface`.

## Bootstrap Flow

The playbook order is:

1. Validate optional HA API endpoint inventory.
2. Configure HAProxy and Keepalived on `lb_nodes` when `ha_api_enabled=true`.
3. Run preflight checks on Kubernetes nodes.
4. Prepare OS settings.
5. Install containerd.
6. Install Kubernetes packages.
7. Initialize the first control-plane node.
8. Join additional control-plane nodes.
9. Join workers.
10. Install Calico.
11. Optionally install MetalLB.
12. Optionally install ingress-nginx.
13. Run validation.

## Important Variables

```yaml
k8s_minor: "1.30"
k8s_version: "1.30.0"
pod_cidr: "192.168.0.0/16"
service_cidr: "10.96.0.0/12"
cluster_dns_domain: cluster.local
control_plane_endpoint: "10.0.0.11:6443"
cri_socket: "unix:///run/containerd/containerd.sock"
calico_version: "v3.28.0"
calico_encapsulation: VXLAN
metallb_enabled: false
ingress_nginx_enabled: false
```

Optional smoke validation:

```yaml
validation_create_test_workload: true
validation_cleanup_test_workload: true
```
