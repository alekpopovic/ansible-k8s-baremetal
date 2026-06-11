# cni_calico

Installs Calico CNI with the Tigera operator after the first control-plane node
has been initialized.

This role installs only Calico. It does not install or configure any other CNI.

## Scope

The role runs only on the first host in the `kube_control_plane` inventory
group. Other hosts skip the installation tasks.

## What It Does

- Downloads the Tigera operator manifest for `calico_version`.
- Renders Calico custom resources using `pod_cidr`.
- Applies the Tigera operator with `kubectl apply`.
- Applies Calico custom resources with `kubectl apply`.
- Waits for pods to appear in the `calico-system` namespace.
- Validates `kubectl get pods -n calico-system`.
- Validates `kubectl get nodes`.

## Variables

```yaml
cni_calico_enabled: true
calico_enabled: true
calico_version: "v3.28.0"
pod_cidr: "192.168.0.0/16"
calico_encapsulation: VXLAN
calico_nat_outgoing: Enabled
calico_block_size: 26
kubeconfig_path: /etc/kubernetes/admin.conf
```

Additional defaults:

```yaml
calico_manifest_dir: /root/calico
calico_operator_manifest_path: /root/calico/tigera-operator.yaml
calico_custom_resources_path: /root/calico/custom-resources.yaml
calico_wait_timeout_seconds: 300
```

## Notes

The role expects the first control-plane node to have a valid kubeconfig at
`kubeconfig_path`. By default this is `/etc/kubernetes/admin.conf`, created by
`kubeadm init`.

`kubectl apply` tasks report changed when output contains `created` or
`configured`.

## Tags

- `cni`
- `calico`
