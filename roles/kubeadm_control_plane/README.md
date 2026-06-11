# kubeadm_control_plane

Initializes the first Kubernetes control-plane node with kubeadm and optionally
joins additional control-plane nodes.

This role does not join worker nodes and does not install a CNI. Those steps are
handled by later roles.

## Supported Groups

- `kube_control_plane`
- `kube_workers`
- `kube_cluster`

The first host in `kube_control_plane` is treated as the bootstrap
control-plane node.

## What It Does

- Checks whether `/etc/kubernetes/admin.conf` exists.
- Renders the kubeadm init config on the first control-plane node.
- Runs `kubeadm init --config ... --upload-certs` only when the first
  control-plane node is not initialized.
- Creates `/root/.kube`.
- Copies `admin.conf` to `/root/.kube/config`.
- Generates a worker join command and stores it as a host fact on the first
  control-plane node.
- Uploads certificates and stores the certificate key as a hidden host fact when
  additional control-plane nodes are present.
- Joins additional control-plane nodes when they are not already initialized.

Sensitive join material is hidden with `no_log`.

## Variables

```yaml
control_plane_endpoint: "192.0.2.10:6443"
pod_cidr: "192.168.0.0/16"
service_cidr: "10.96.0.0/12"
cluster_dns_domain: cluster.local
k8s_version: "1.36.0"
cri_socket: "unix:///run/containerd/containerd.sock"

kubeadm_upload_certs: true
kubeadm_config_path: /root/kubeadm-config.yaml
kubeconfig_root_path: /root/.kube/config
kubeadm_admin_conf_path: /etc/kubernetes/admin.conf
kubeadm_root_kube_dir: /root/.kube
kubeadm_join_token_ttl: 2h
kubeadm_config_api_version: kubeadm.k8s.io/v1beta4
kubeadm_kubelet_config_api_version: kubelet.config.k8s.io/v1beta1
kubeadm_audit_policy_enabled: false
kubeadm_audit_policy_path: /etc/kubernetes/audit-policy.yaml
kubeadm_audit_log_path: /var/log/kubernetes/audit.log
```

## HA Notes

Additional control-plane nodes require a working `control_plane_endpoint`
before they join. In HA layouts this is usually a virtual IP or DNS name backed
by HAProxy/Keepalived or another load balancer.

For HA clusters, run control-plane joins serially. This can be handled by a
dedicated play with `serial: 1`, or by running the control-plane role against
one new control-plane host at a time. Avoid joining multiple additional
control-plane nodes concurrently.

## Generated Facts

The first control-plane host stores:

- `kubeadm_worker_join_command`
- `kubeadm_certificate_key` when more than one control-plane host exists
- `kubeadm_control_plane_join_command` when more than one control-plane host
  exists

Worker join roles should read the join command from:

```yaml
hostvars[groups['kube_control_plane'][0]].kubeadm_worker_join_command
```

## Optional API Audit Policy

Set `kubeadm_audit_policy_enabled: true` before the first `kubeadm init` to
render an audit policy and mount it into the kube-apiserver static pod through
the kubeadm configuration.

```yaml
kubeadm_audit_policy_enabled: true
```

Changing audit settings on an existing cluster requires careful manual review of
the kube-apiserver static pod configuration.

## Tags

- `control-plane`
- `kubeadm`
