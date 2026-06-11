# metallb

Optionally installs and configures MetalLB for bare-metal Kubernetes
`LoadBalancer` services.

## Scope

The role runs only on the first host in the `kube_control_plane` inventory
group. When `metallb_enabled: false`, all installation and configuration tasks
are skipped.

## What It Does

- Downloads the MetalLB native manifest for `metallb_version`.
- Applies the MetalLB manifest with `kubectl apply`.
- Waits for controller and speaker pods to become ready.
- Renders an `IPAddressPool`.
- Renders an `L2Advertisement`.
- Applies both resources with `kubectl apply`.
- Validates MetalLB pods, IP address pools, and L2 advertisements.

## Variables

```yaml
metallb_enabled: false
metallb_namespace: metallb-system
metallb_version: v0.14.9
metallb_address_pool: []
kubeconfig_path: /etc/kubernetes/admin.conf
```

Example address pool:

```yaml
metallb_address_pool:
  - "10.10.10.240-10.10.10.250"
```

Additional defaults:

```yaml
metallb_role_enabled: true
metallb_manifest_dir: /root/metallb
metallb_manifest_path: /root/metallb/metallb-native.yaml
metallb_ipaddresspool_path: /root/metallb/ipaddresspool.yaml
metallb_l2advertisement_path: /root/metallb/l2advertisement.yaml
metallb_wait_timeout_seconds: 300
```

## Safety Warning

Every address in `metallb_address_pool` must be free on the LAN and outside any
DHCP scope or statically assigned host address. MetalLB can create address
conflicts if the selected IPs are already in use.

## Tags

- `metallb`
