#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
exec "$script_dir/run_incremental_validation.sh" prepare \
  --name rocq90_batch1 \
  --config "$script_dir/../tooling/rocq90_batch1_descriptor.json" \
  --hooks "$script_dir/../tooling/rocq90_batch1_hooks.sh"
