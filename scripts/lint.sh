#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

if ! command -v yamllint >/dev/null 2>&1; then
  echo "yamllint is required. Install it before running ${0}." >&2
  exit 127
fi

if ! command -v ansible-lint >/dev/null 2>&1; then
  echo "ansible-lint is required. Install it before running ${0}." >&2
  exit 127
fi

yamllint .
ansible-lint .
