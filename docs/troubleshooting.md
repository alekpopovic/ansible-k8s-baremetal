# Troubleshooting

Common bootstrap and operations checks.

## HA API Endpoint

Check HAProxy configuration on an `lb_nodes` host:

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl status haproxy
```

Check Keepalived:

```bash
systemctl status keepalived
ip address show dev eth0
```

Replace `eth0` with `k8s_api_vip_interface`.

Confirm the VIP answers on the Kubernetes API port:

```bash
nc -vz 192.0.2.10 6443
```

If the VIP is not present:

- Verify `ha_api_enabled=true`.
- Verify `k8s_api_vip` and `k8s_api_vip_interface`.
- Verify `keepalived_auth_pass` is provided by Ansible Vault.
- Verify `keepalived_virtual_router_id` is unique on the LAN.
- Verify VRRP is allowed between `lb_nodes`.
- Verify HAProxy is running, because Keepalived tracks the HAProxy process.

If kubeadm cannot reach `control_plane_endpoint`, confirm that
`control_plane_endpoint` matches `k8s_api_vip:k8s_api_port` for HA layouts and
that all control-plane backends are listed in `/etc/haproxy/haproxy.cfg`.
