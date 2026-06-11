# AGENTS.md

Guidance for AI agents and contributors working in this repository.

This repository is intended to become an Ansible-based Kubernetes bare-metal
bootstrap project using kubeadm, kubelet, kubectl, containerd, Calico, optional
HA control plane support with HAProxy/Keepalived, and optional MetalLB.

## Project Principles

- Use Ansible best practices and keep every task idempotent.
- Prefer explicit variables in `group_vars` over hardcoded values.
- Keep host-, cluster-, and environment-specific values configurable.
- Support Ubuntu 22.04, Ubuntu 24.04, and Debian 12 where practical.
- Use `kubeadm`, `kubelet`, `kubectl`, and `containerd`.
- Align kubelet and containerd on the `systemd` cgroup driver.
- Support both single control-plane and HA control-plane layouts.
- Prefer fully qualified Ansible collection names, such as
  `ansible.builtin.apt`, `ansible.builtin.template`, and
  `ansible.builtin.systemd_service`.

## Security Rules

- Never store tokens, certificate keys, kubeconfig contents, passwords, private
  SSH keys, or production secrets in this repository.
- Use Ansible Vault placeholders for secret values.
- Keep example secret files clearly marked as examples or placeholders.
- Do not print sensitive values in task output. Use `no_log: true` for tasks
  that may expose secrets.
- Do not commit generated kubeconfig files, certificates, private keys, join
  tokens, or kubeadm certificate keys.

## Expected Repository Shape

When project files are added, prefer a conventional Ansible layout:

```text
.
├── ansible.cfg
├── inventories/
│   └── example/
│       ├── hosts.yml
│       └── group_vars/
├── playbooks/
├── roles/
├── docs/
├── runbooks/
├── .ansible-lint
├── .yamllint.yml
└── README.md
```

Every role should include:

- `defaults/main.yml`
- `tasks/main.yml`
- `handlers/main.yml` when handlers are relevant
- `README.md`

Use role defaults for safe baseline values. Use inventory `group_vars` for
cluster-specific values.

## Required Tags

Use tags for major operational phases so operators can run targeted playbook
steps:

- `preflight`
- `os`
- `containerd`
- `kubernetes`
- `control-plane`
- `workers`
- `cni`
- `metallb`
- `ingress`
- `validation`

Apply tags consistently at the play, role, block, or task level where they make
operational sense.

## Kubernetes Bootstrap Rules

- Use kubeadm for cluster initialization and node joins.
- Support single control-plane clusters.
- Support HA control-plane clusters with a virtual endpoint backed by
  HAProxy/Keepalived when enabled.
- Make HA behavior optional and controlled by explicit variables.
- Install and configure containerd before kubeadm initialization.
- Configure containerd and kubelet to use the `systemd` cgroup driver.
- Use Calico as the primary CNI.
- Make MetalLB optional and variable-driven.
- Do not assume cloud provider integrations.

## Idempotency And Command Usage

- Prefer Ansible modules over shell commands.
- Any `ansible.builtin.shell` or `ansible.builtin.command` task must include
  appropriate `changed_when`, `failed_when`, `creates`, or `removes` handling.
- Register command output and make change detection explicit.
- Do not use shell pipelines when a module or simpler command is available.
- Avoid tasks that report changed on every run.
- Add comments in YAML where operational risk exists, especially around
  firewall changes, kernel settings, kubeadm init/join, node reset, certificate
  rotation, or load balancer changes.

## Destructive Actions

- Add safety checks before destructive actions.
- Never run `kubeadm reset` automatically unless an explicit variable enables
  it, for example `kubeadm_reset_enabled: true`.
- Destructive tasks must be opt-in, clearly named, tagged appropriately, and
  documented.
- Before deleting Kubernetes, containerd, CNI, or etcd data, verify the target
  path and require an explicit variable gate.
- Do not remove host firewall, network, storage, or cluster state without a
  documented rollback or recovery note.

## Variables

- Prefer explicit variables in `group_vars` and role defaults.
- Keep variable names descriptive and stable.
- Avoid embedding IP ranges, Kubernetes versions, VIPs, interface names, pod
  CIDRs, service CIDRs, or registry endpoints directly inside tasks.
- Document important variables in the relevant role `README.md`.
- Provide safe defaults where possible, but require explicit values for risky
  cluster-specific settings such as control-plane endpoint, node addresses, and
  MetalLB address pools.

## Formatting And Linting

- Keep YAML compatible with `ansible-lint` and `yamllint`.
- Use two-space YAML indentation.
- Use explicit booleans: `true` and `false`.
- Quote strings only when it improves YAML clarity or avoids parsing surprises.
- Give tasks clear `name` values.
- Keep lines reasonably short and readable.
- Prefer block style for complex YAML values.

## Testing And Validation

Add static validation as the project grows:

```bash
yamllint .
ansible-lint
ansible-playbook --syntax-check -i inventories/example/hosts.yml playbooks/site.yml
```

Where possible, document check-mode usage:

```bash
ansible-playbook -i inventories/example/hosts.yml playbooks/site.yml --check --diff
```

Check mode may not be reliable for kubeadm, package repository setup, CNI
application, or tasks that depend on live cluster state. Document those limits
near the affected playbooks or runbooks.

## Manual Verification Runbook

Add or update runbooks with manual verification commands as features are added.
At minimum, document checks similar to:

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl -n kube-system get pods
kubectl get componentstatuses
kubectl cluster-info
kubectl get svc -A
```

For HA clusters, include checks for:

```bash
kubectl get nodes -l node-role.kubernetes.io/control-plane
systemctl status haproxy
systemctl status keepalived
```

For MetalLB, include checks for:

```bash
kubectl -n metallb-system get pods
kubectl get ipaddresspools -A
kubectl get l2advertisements -A
```

## Documentation Expectations

- Keep `README.md` focused on project overview, requirements, quick start, and
  supported layouts.
- Add role-specific operational notes to each role `README.md`.
- Add validation and troubleshooting docs for cluster bootstrap, HA control
  plane, Calico, MetalLB, and ingress as those features are introduced.
- Document required inventory groups, expected host variables, and example
  `group_vars`.
- Include rollback or recovery notes for risky operations.

## Agent Workflow

- Read existing files before making changes.
- Keep changes narrow and aligned with the repository structure.
- Do not create broad scaffolding unless explicitly requested.
- Do not introduce secrets, generated cluster state, or local machine artifacts.
- When adding tasks, include idempotency controls and validation in the same
  change when practical.
- When adding a role, include its defaults, tasks, handlers when relevant, and
  README.
- When adding operationally risky behavior, include variable gates, comments,
  and documentation.
- Run or document relevant validation commands after changes.
- After every user prompt that results in repository changes, run `git add`,
  create a commit with a clear message, and push the commit to the configured
  remote.
