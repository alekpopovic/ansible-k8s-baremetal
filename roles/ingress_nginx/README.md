# ingress_nginx

Optionally installs ingress-nginx after CNI and, when required, MetalLB.

## Scope

The role runs only on the first host in the `kube_control_plane` inventory
group. When `ingress_nginx_enabled: false`, all installation and validation
tasks are skipped.

## What It Does

- Applies the ingress-nginx manifest from `ingress_nginx_manifest_url`.
- Reads the controller Service type.
- Patches the controller Service when it differs from
  `ingress_nginx_service_type`.
- Waits for the ingress-nginx controller Deployment rollout.
- Validates pods in the ingress-nginx namespace.
- Validates services in the ingress-nginx namespace.

## Variables

```yaml
ingress_nginx_enabled: false
ingress_nginx_namespace: ingress-nginx
ingress_nginx_manifest_url: "https://example.invalid/deploy.yaml"
kubeconfig_path: /etc/kubernetes/admin.conf
ingress_nginx_service_type: LoadBalancer
```

Additional defaults:

```yaml
ingress_nginx_role_enabled: true
ingress_nginx_manifest_base_url: https://raw.githubusercontent.com/kubernetes/ingress-nginx
ingress_nginx_manifest_ref: controller-v1.11.3
ingress_nginx_manifest_path: deploy/static/provider/cloud/deploy.yaml
ingress_nginx_controller_service_name: ingress-nginx-controller
ingress_nginx_controller_deployment_name: ingress-nginx-controller
ingress_nginx_wait_timeout_seconds: 300
```

## Bare-Metal LoadBalancer Note

On bare metal, `ingress_nginx_service_type: LoadBalancer` requires a
LoadBalancer implementation such as MetalLB. Enable and validate MetalLB before
enabling ingress-nginx with a `LoadBalancer` Service type, or use another
service type such as `NodePort`.

## Tags

- `ingress`
