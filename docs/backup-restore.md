# Backup And Restore

Backups are operational artifacts, not source code. Never store backups,
kubeconfigs, private keys, tokens, or database dumps in this repository.

## What To Back Up

- etcd snapshots for control-plane state.
- Application data from persistent volumes.
- Kubernetes manifests, Helm values, and GitOps repositories.
- External databases used by workloads.
- Secrets through an approved secret-management process.

## etcd Snapshot Concept

kubeadm control-plane nodes run etcd as a static pod. An etcd snapshot captures
Kubernetes API state, including objects and Secrets.

Example snapshot command on a control-plane node:

```bash
export ETCDCTL_API=3
etcdctl snapshot save /var/backups/etcd/snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

Verify the snapshot:

```bash
etcdctl snapshot status /var/backups/etcd/snapshot.db --write-out=table
```

Store snapshots on protected storage outside the repository and outside the
failed control-plane host.

## Restore Concept

Restoring etcd is a high-risk operation. Practice in a lab first.

High-level flow:

1. Stop kubelet on affected control-plane nodes.
2. Move existing etcd data aside.
3. Restore the snapshot with `etcdctl snapshot restore`.
4. Update static pod manifests or data paths as required.
5. Start kubelet.
6. Verify the API server and etcd health.

Do not overwrite etcd data without a tested restore plan and a known-good
snapshot.

## Velero Concept

Velero can back up Kubernetes objects and persistent volume snapshots when
configured with compatible storage.

Typical Velero uses:

- Scheduled namespace backups.
- Restoring workloads after accidental deletion.
- Migrating application objects between clusters.

Velero does not replace etcd snapshots for full control-plane disaster recovery.
Use both when possible.

## Where Not To Store Backups

Do not store backups in:

- This Git repository.
- `/tmp`.
- A single control-plane node only.
- Unencrypted object storage.
- Developer laptops without an approved security process.

## Minimum Backup Checklist

Before upgrades or destructive maintenance:

```bash
kubectl get nodes -o wide
kubectl get pods -A
etcdctl snapshot status /var/backups/etcd/snapshot.db --write-out=table
```

Confirm the snapshot has been copied to durable storage before proceeding.
