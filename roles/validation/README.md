# validation

Runs post-install Kubernetes cluster validation from the first control-plane
node.

## Scope

The role runs validation commands only on the first host in the
`kube_control_plane` inventory group.

## Default Checks

- `kubectl get nodes -o wide`
- `kubectl get pods -A`
- `kubectl get componentstatuses`
- `kubectl -n kube-system get pods`
- `kubectl wait --for=condition=Ready nodes --all`

`componentstatuses` is deprecated in newer Kubernetes releases. The role runs
it when available but does not fail if the command is unavailable or deprecated.

## Optional Smoke Workload

Set `validation_create_test_workload: true` to create:

- A test namespace.
- A simple nginx Deployment.
- A ClusterIP Service.
- A LoadBalancer Service when `metallb_enabled: true`.

Set `validation_cleanup_test_workload: true` to remove the test namespace after
validation.

## Variables

```yaml
validation_enabled: true
kubeconfig_path: /etc/kubernetes/admin.conf
validation_node_ready_timeout: 300s

validation_create_test_workload: false
validation_cleanup_test_workload: true
validation_test_namespace: k8s-validation
validation_test_app: validation-nginx
validation_test_image: nginx:stable-alpine
validation_test_replicas: 1
validation_clusterip_service_name: validation-nginx
validation_loadbalancer_service_name: validation-nginx-lb
validation_loadbalancer_timeout: 180
```

## Tags

- `validation`
