#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
exec "$script_dir/run_incremental_validation.sh" finalize \
  --name rocq90_batch3 \
  --config "$script_dir/../tooling/rocq90_batch3_descriptor.json" \
  --hooks "$script_dir/../tooling/rocq90_batch3_hooks.sh"
