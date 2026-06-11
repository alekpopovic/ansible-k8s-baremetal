# kubernetes_packages

Installs `kubelet`, `kubeadm`, and `kubectl` from the official
`pkgs.k8s.io` repository for the configured Kubernetes minor version.

This role only installs packages and enables kubelet. It does not initialize a
cluster, join nodes, write kubeadm configuration, or modify Kubernetes cluster
state.

## What It Does

- Creates `/etc/apt/keyrings`.
- Downloads the Kubernetes `Release.key` for `k8s_minor`.
- Dearmors the key into the configured apt keyring path.
- Adds the official `pkgs.k8s.io` apt repository.
- Updates apt cache.
- Installs `kubelet`, `kubeadm`, and `kubectl`.
- Optionally installs an exact package version.
- Holds or unholds Kubernetes packages.
- Enables the kubelet service.
- Validates `kubeadm version`.
- Validates `kubelet --version`.
- Validates `kubectl version --client=true`.

## Variables

```yaml
k8s_minor: "1.36"
k8s_version: ""
kubernetes_packages_hold: true
kubernetes_apt_keyring_path: /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

Additional defaults:

```yaml
kubernetes_packages_enabled: true
kubernetes_packages_names:
  - kubelet
  - kubeadm
  - kubectl

kubernetes_apt_keyring_dir: /etc/apt/keyrings
kubernetes_apt_release_key_path: /etc/apt/keyrings/kubernetes-release.key
kubernetes_apt_repository_file: kubernetes
kubernetes_package_version_suffix: "-1.1"
```

## Version Behavior

When `k8s_version` is empty, apt installs the latest package available from the
configured minor repository:

```yaml
k8s_minor: "1.36"
k8s_version: ""
```

When `k8s_version` is set to a Kubernetes version without an apt package suffix,
the role appends `kubernetes_package_version_suffix`:

```yaml
k8s_version: "1.36.0"
# Installs kubelet=1.36.0-1.1, kubeadm=1.36.0-1.1, kubectl=1.36.0-1.1
```

When `k8s_version` already includes a package suffix, it is used as-is:

```yaml
k8s_version: "1.36.0-1.1"
```

## Repository

The generated apt repository follows the official `pkgs.k8s.io` stable pattern:

```text
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /
```

## Tags

- `kubernetes`
- `packages`
