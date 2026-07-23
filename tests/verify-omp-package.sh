#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
work_root=$(mktemp -d)
trap 'rm -rf "$work_root"' EXIT

command -v omp >/dev/null

omp install "$repo_root" --dry-run --json >"$work_root/local-install.json"
omp install github:unger1984/codepatrol --dry-run --json >"$work_root/github-install.json"
OMP_PROFILE="codepatrol-verify-$$" omp install "$repo_root"

test -f "$repo_root/.pi/extensions/codepatrol.ts"

grep -Fq 'using-codepatrol' "$repo_root/.pi/extensions/codepatrol.ts"
grep -Fq 'platforms' "$repo_root/.pi/extensions/codepatrol.ts"
grep -Fq 'omp-agents' "$repo_root/.pi/extensions/codepatrol.ts"

python3 - <<'PY' "$work_root/local-install.json" "$work_root/github-install.json"
import json, sys
local_data = json.load(open(sys.argv[1]))
github_data = json.load(open(sys.argv[2]))
assert local_data["name"] in ("codepatrol", "."), local_data
assert github_data["name"] == "github:unger1984/codepatrol", github_data
PY
