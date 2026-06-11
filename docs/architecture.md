# Architecture

This repository supports kubeadm-based Kubernetes on bare-metal hosts with a
single control plane or an optional highly available API endpoint.

## Inventory Groups

- `kube_control_plane`: Kubernetes control-plane nodes.
- `kube_workers`: Kubernetes worker nodes.
- `kube_cluster`: Ansible child group containing control-plane and worker nodes.
- `lb_nodes`: Optional HAProxy/Keepalived nodes for the Kubernetes API VIP.

`lb_nodes` are configured by a separate play before Kubernetes bootstrap. They
do not need to be members of `kube_cluster`.

## Single Control Plane

For a single control-plane deployment, set:

```yaml
ha_api_enabled: false
control_plane_endpoint: "192.0.2.11:6443"
```

The control-plane endpoint can point directly at the first control-plane node.

## HA API Endpoint

For HA layouts, enable HAProxy and Keepalived on `lb_nodes`:

```yaml
ha_api_enabled: true
k8s_api_vip: "192.0.2.10"
k8s_api_vip_interface: eth0
k8s_api_port: 6443
control_plane_endpoint: "192.0.2.10:6443"
keepalived_virtual_router_id: 51
keepalived_auth_pass: "{{ vault_keepalived_auth_pass }}"
```

HAProxy listens on the Kubernetes API VIP and forwards TCP traffic to every host
in `kube_control_plane` on port `6443`. Keepalived advertises the VIP with VRRP
and tracks the HAProxy process.

`keepalived_auth_pass` must be provided from Ansible Vault or another secret
source. Do not commit the plaintext value.

## Bootstrap Order

1. Configure optional HA API endpoint on `lb_nodes`.
2. Prepare Kubernetes nodes.
3. Install containerd.
4. Install Kubernetes packages.
5. Initialize or join control-plane nodes.
6. Join workers.
7. Install Calico.
8. Optionally install MetalLB.
9. Optionally install ingress-nginx.

When `ha_api_enabled: true`, the VIP must be reachable before kubeadm
initializes the first control-plane node.
