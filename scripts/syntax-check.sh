#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ansible-playbook is required. Install ansible-core before running ${0}." >&2
  exit 127
fi

ansible-playbook -i inventories/lab/hosts.ini site.yml --syntax-check
