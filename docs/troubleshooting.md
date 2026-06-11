# Troubleshooting

Practical checks for bootstrap and day-two operations.

## First Checks

```bash
ansible all -i inventories/production/hosts.ini -m ping
kubectl get nodes -o wide
kubectl get pods -A
kubectl -n kube-system get pods
```

On a node:

```bash
systemctl status kubelet
journalctl -u kubelet -n 100 --no-pager
systemctl status containerd
journalctl -u containerd -n 100 --no-pager
```

## kubelet Not Starting

Check logs:

```bash
journalctl -u kubelet -n 200 --no-pager
```

Common causes:

- Swap is enabled.
- containerd is not running.
- cgroup driver mismatch.
- `/etc/kubernetes/kubelet.conf` is missing on joined nodes.
- The node cannot reach the Kubernetes API endpoint.

Useful checks:

```bash
swapon --show
systemctl is-active containerd
grep -R SystemdCgroup /etc/containerd/config.toml
test -f /etc/kubernetes/kubelet.conf
nc -vz 10.0.0.10 6443
```

## Swap Enabled

Kubernetes expects swap to be disabled unless explicitly configured otherwise.

```bash
swapon --show
grep -n swap /etc/fstab
```

The `os_base` role can disable active swap and comment swap entries when
`os_base_disable_swap=true`.

## containerd cgroup mismatch

Check containerd:

```bash
grep -n "SystemdCgroup" /etc/containerd/config.toml
systemctl restart containerd
systemctl restart kubelet
```

The expected setting is:

```toml
SystemdCgroup = true
```

## Nodes NotReady

```bash
kubectl describe node <node>
kubectl get pods -A -o wide
kubectl -n calico-system get pods -o wide
```

Common causes:

- CNI is not installed or not healthy.
- kubelet cannot contact containerd.
- Node firewall blocks pod networking.
- Node cannot reach the API endpoint.

## CoreDNS Pending

```bash
kubectl -n kube-system describe pod -l k8s-app=kube-dns
kubectl get nodes
kubectl -n calico-system get pods
```

Common causes:

- No Ready worker/control-plane nodes.
- Calico is not ready.
- Control-plane taints and no schedulable workers.

## Calico Pods Failing

```bash
kubectl -n calico-system get pods -o wide
kubectl -n calico-system describe pod <pod>
kubectl get installation default -o yaml
```

Check:

- `pod_cidr` matches kubeadm networking.
- Node-to-node firewall allows the selected Calico mode.
- VXLAN mode can use UDP `4789`.
- BGP mode needs TCP `179`.

## LoadBalancer Pending

```bash
kubectl -n metallb-system get pods
kubectl -n metallb-system get ipaddresspools
kubectl -n metallb-system get l2advertisements
kubectl get svc -A
```

Common causes:

- `metallb_enabled=false`.
- `metallb_address_pool` is empty.
- Address pool overlaps DHCP or used host IPs.
- MetalLB speaker pods are not running.

## ingress-nginx Has No External IP

```bash
kubectl -n ingress-nginx get svc
kubectl -n metallb-system get pods
```

If `ingress_nginx_service_type=LoadBalancer`, MetalLB or another load balancer
implementation must be working. Use `NodePort` if you do not want MetalLB.

## Certificate Or Join Token Expired

Worker join tokens expire. Generate a fresh command on the first control-plane
node:

```bash
kubeadm token create --ttl 2h --print-join-command
```

For control-plane joins, upload certs again and treat the printed key as
sensitive:

```bash
kubeadm init phase upload-certs --upload-certs
```

Do not commit join commands or certificate keys.

## HA API Endpoint

Check HAProxy:

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl status haproxy
```

Check Keepalived:

```bash
systemctl status keepalived
ip address show dev eth0
```

Replace `eth0` with `k8s_api_vip_interface`.

Confirm the VIP answers:

```bash
nc -vz 10.0.0.10 6443
```

If the VIP is not present:

- Verify `ha_api_enabled=true`.
- Verify `k8s_api_vip` and `k8s_api_vip_interface`.
- Verify `keepalived_auth_pass` is provided by Ansible Vault.
- Verify `keepalived_virtual_router_id` is unique on the LAN.
- Verify VRRP is allowed between `lb_nodes`.
- Verify HAProxy is running, because Keepalived tracks the HAProxy process.

## kubeadm init Fails

Check:

```bash
kubeadm init phase preflight --config /root/kubeadm-config.yaml
journalctl -u kubelet -n 100 --no-pager
systemctl status containerd
```

Common causes:

- API endpoint VIP is not reachable.
- Swap is enabled.
- containerd is not configured with systemd cgroups.
- Required ports are blocked.
- `pod_cidr` or `service_cidr` overlaps existing networks.

## Destructive Recovery Warning

Do not run these casually:

```bash
kubeadm reset
rm -rf /var/lib/etcd
rm -rf /etc/kubernetes
```

Use destructive commands only with a written recovery plan and verified backups.
