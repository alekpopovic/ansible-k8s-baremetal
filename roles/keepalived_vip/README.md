# keepalived_vip

Installs and configures Keepalived VRRP for an optional Kubernetes API VIP.

This role is disabled unless `ha_api_enabled: true`.

## Variables

```yaml
ha_api_enabled: false
k8s_api_vip: "10.0.0.10"
k8s_api_vip_interface: eth0
k8s_api_port: 6443
keepalived_virtual_router_id: 51
keepalived_auth_pass: "{{ vault_keepalived_auth_pass }}"
```

`keepalived_auth_pass` must come from Ansible Vault or another secret source.
Never commit the plaintext value. Keepalived VRRP `PASS` authentication supports
up to 8 characters.

Optional priority override:

```yaml
keepalived_priority: 150
```

Without an explicit `keepalived_priority`, priority is calculated from the
`lb_nodes` inventory order.

## Behavior

- Installs `keepalived`.
- Templates `/etc/keepalived/keepalived.conf`.
- Uses VRRP with a shared VIP.
- Tracks the HAProxy process.
- Starts and enables Keepalived.
- Restarts Keepalived only when configuration changes.

## Tags

- `control-plane`
- `keepalived`
