# Operations

Operational runbooks for day-to-day cluster use.

## Prepare Inventory

Copy the production examples:

```bash
cp inventories/production/hosts.ini.example inventories/production/hosts.ini
cp inventories/production/group_vars/all.yml.example \
  inventories/production/group_vars/all.yml
cp inventories/production/group_vars/kube_cluster.yml.example \
  inventories/production/group_vars/kube_cluster.yml
```

Edit the inventory:

```bash
vim inventories/production/hosts.ini
vim inventories/production/group_vars/all.yml
vim inventories/production/group_vars/kube_cluster.yml
```

Check SSH:

```bash
ansible all -i inventories/production/hosts.ini -m ping
```

Run syntax check:

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml --syntax-check
```

Run the playbook:

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml
```

## Run By Tags

Useful phased runs:

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml --tags preflight
ansible-playbook -i inventories/production/hosts.ini site.yml --tags os
ansible-playbook -i inventories/production/hosts.ini site.yml --tags containerd
ansible-playbook -i inventories/production/hosts.ini site.yml --tags kubernetes
ansible-playbook -i inventories/production/hosts.ini site.yml --tags control-plane
ansible-playbook -i inventories/production/hosts.ini site.yml --tags workers
ansible-playbook -i inventories/production/hosts.ini site.yml --tags cni
ansible-playbook -i inventories/production/hosts.ini site.yml --tags metallb
ansible-playbook -i inventories/production/hosts.ini site.yml --tags ingress
ansible-playbook -i inventories/production/hosts.ini site.yml --tags validation
```

## Retrieve Kubeconfig

Copy the admin kubeconfig from the first control-plane node:

```bash
scp root@cp-01:/etc/kubernetes/admin.conf ./admin.conf
chmod 600 ./admin.conf
export KUBECONFIG="$PWD/admin.conf"
kubectl get nodes -o wide
```

Do not commit kubeconfig files.

## Verify Cluster Health

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl -n kube-system get pods
kubectl cluster-info
kubectl get svc -A
kubectl wait --for=condition=Ready nodes --all --timeout=300s
```

Check Calico:

```bash
kubectl -n calico-system get pods
kubectl get installation default -o yaml
```

Check MetalLB when enabled:

```bash
kubectl -n metallb-system get pods
kubectl -n metallb-system get ipaddresspools
kubectl -n metallb-system get l2advertisements
```

Check ingress-nginx when enabled:

```bash
kubectl -n ingress-nginx get pods
kubectl -n ingress-nginx get svc
```

## Enable MetalLB

Set:

```yaml
metallb_enabled: true
metallb_address_pool:
  - "10.0.0.240-10.0.0.250"
```

Run:

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml --tags metallb
```

Warning: every address in `metallb_address_pool` must be unused on the LAN and
outside DHCP scopes.

## Enable ingress-nginx

With MetalLB:

```yaml
ingress_nginx_enabled: true
ingress_nginx_service_type: LoadBalancer
```

Without MetalLB:

```yaml
ingress_nginx_enabled: true
ingress_nginx_service_type: NodePort
```

Run:

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml --tags ingress
```

## Add A Worker Node

1. Install the OS and ensure SSH access.
2. Add the host to `[kube_workers]`.
3. Run preflight and node preparation.
4. Run the worker join role.

```bash
ansible all -i inventories/production/hosts.ini -m ping
ansible-playbook -i inventories/production/hosts.ini site.yml \
  --limit new-worker-01 \
  --tags preflight,os,containerd,kubernetes,workers
```

Verify:

```bash
kubectl get nodes -o wide
kubectl describe node new-worker-01
```

## Replace A Failed Worker Node

Warning: node removal affects workloads. Drain when possible.

If the node is still reachable:

```bash
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data
```

Delete the old node object:

```bash
kubectl delete node worker-01
```

Reinstall or replace the host, keep inventory accurate, then run:

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml \
  --limit worker-01 \
  --tags preflight,os,containerd,kubernetes,workers
```

Do not run `kubeadm reset` from this repository unless a future role explicitly
adds a guarded, documented reset path.

## Add A Control-Plane Node

1. Add the host to `[kube_control_plane]`.
2. Ensure `control_plane_endpoint` points at a working VIP or stable API
   endpoint.
3. Run base setup on the new node.
4. Run the control-plane role for the new node.

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml \
  --limit cp-04 \
  --tags preflight,os,containerd,kubernetes,control-plane
```

For HA clusters, join one additional control-plane node at a time. Verify etcd
and node status after each join:

```bash
kubectl get nodes -o wide
kubectl -n kube-system get pods -l component=etcd
```

## Rotate Join Token

On the first control-plane node:

```bash
kubeadm token create --ttl 2h --print-join-command
```

For additional control-plane joins, upload certs and capture the certificate key
securely:

```bash
kubeadm init phase upload-certs --upload-certs
```

Treat the printed certificate key as sensitive.
