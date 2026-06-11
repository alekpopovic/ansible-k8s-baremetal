# haproxy_k8s_api

Installs and configures HAProxy as a TCP load balancer for the Kubernetes API.

This role is disabled unless `ha_api_enabled: true`.

Use dedicated `lb_nodes` with the default `haproxy_k8s_api_bind_address: "*"`.
If an advanced deployment co-locates HAProxy with a control-plane host, bind
HAProxy only to the VIP address to avoid conflicting with kube-apiserver on
TCP `6443`.

## Variables

```yaml
ha_api_enabled: false
k8s_api_vip: "10.0.0.10"
k8s_api_vip_interface: eth0
k8s_api_port: 6443
haproxy_stats_enabled: false
haproxy_stats_port: 8404
```

## Behavior

- Installs `haproxy`.
- Templates `/etc/haproxy/haproxy.cfg`.
- Adds every host in `kube_control_plane` as a backend on `k8s_api_port`.
- Uses TCP mode and TCP health checks.
- Validates HAProxy configuration before writing it.
- Restarts HAProxy only when configuration changes.

## Tags

- `control-plane`
- `haproxy`
