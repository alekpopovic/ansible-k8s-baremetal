# Upgrade

High-level Kubernetes upgrade flow for kubeadm clusters.

Always read the upstream Kubernetes release notes before upgrading. Upgrade one
minor version at a time. Back up etcd and important workloads first.

## Preflight

Check cluster health:

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl -n kube-system get pods
```

Confirm backups exist:

```bash
ls -lh /var/backups/etcd
```

Update inventory versions:

```yaml
k8s_minor: "1.31"
k8s_version: "1.31.0"
```

Run syntax checks:

```bash
scripts/lint.sh
scripts/syntax-check.sh
```

## Control Plane Upgrade Flow

Upgrade `kubeadm` first on the first control-plane node:

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml \
  --limit cp-01 \
  --tags kubernetes
```

On `cp-01`, review the plan:

```bash
kubeadm upgrade plan
```

Apply the control-plane upgrade:

```bash
kubeadm upgrade apply v1.31.0
```

Drain the node before upgrading kubelet:

```bash
kubectl drain cp-01 --ignore-daemonsets --delete-emptydir-data
```

Upgrade kubelet and kubectl through the package role, then restart kubelet if
needed:

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml \
  --limit cp-01 \
  --tags kubernetes
systemctl restart kubelet
```

Uncordon:

```bash
kubectl uncordon cp-01
```

Repeat for each additional control-plane node:

```bash
kubeadm upgrade node
kubectl drain cp-02 --ignore-daemonsets --delete-emptydir-data
ansible-playbook -i inventories/production/hosts.ini site.yml \
  --limit cp-02 \
  --tags kubernetes
systemctl restart kubelet
kubectl uncordon cp-02
```

## Worker Upgrade Flow

For each worker:

```bash
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data
ansible-playbook -i inventories/production/hosts.ini site.yml \
  --limit worker-01 \
  --tags kubernetes
ssh root@worker-01 systemctl restart kubelet
kubectl uncordon worker-01
```

Verify:

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

## Add-On Upgrades

Calico:

```yaml
calico_version: "v3.29.0"
```

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml --tags cni
kubectl -n calico-system get pods
```

MetalLB:

```yaml
metallb_version: v0.14.9
```

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml --tags metallb
kubectl -n metallb-system get pods
```

ingress-nginx:

```yaml
ingress_nginx_manifest_ref: controller-v1.11.3
```

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml --tags ingress
kubectl -n ingress-nginx get pods
```

## Warnings

- Do not skip minor versions.
- Do not upgrade all nodes at once.
- Do not upgrade kubelet ahead of kubeadm.
- Do not drain a node without understanding workload disruption.
- Keep etcd backups outside the repository.
