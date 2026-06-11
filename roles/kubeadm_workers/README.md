# kubeadm_workers

Joins worker nodes to a kubeadm Kubernetes cluster.

This role never runs `kubeadm reset`. It only joins workers that do not already
have `/etc/kubernetes/kubelet.conf`.

## Inputs

The worker join command is read from the first control-plane host:

```yaml
hostvars[groups['kube_control_plane'][0]].kubeadm_worker_join_command
```

The `cri_socket` variable must also be defined, for example:

```yaml
cri_socket: "unix:///run/containerd/containerd.sock"
```

## What It Does

- Checks whether `/etc/kubernetes/kubelet.conf` exists.
- Runs the kubeadm join command with `--cri-socket` only when kubelet
  configuration is missing.
- Enables and starts kubelet on worker nodes.
- Validates `systemctl is-active kubelet`.
- Validates that `/etc/kubernetes/kubelet.conf` exists.

Join command output is hidden with `no_log`.

## Variables

```yaml
kubeadm_workers_enabled: true
kubeadm_worker_kubelet_conf_path: /etc/kubernetes/kubelet.conf
kubeadm_worker_kubelet_service_name: kubelet
```

## Tags

- `workers`
- `kubeadm`
