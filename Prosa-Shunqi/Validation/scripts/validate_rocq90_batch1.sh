#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
"$script_dir/setup_rocq90_environment.sh"
"$script_dir/../tooling/setup_validation_tooling.sh"
"$script_dir/finalize_rocq90_batch1.sh"
