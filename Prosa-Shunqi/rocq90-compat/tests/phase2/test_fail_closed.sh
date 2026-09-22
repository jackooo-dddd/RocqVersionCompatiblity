#!/usr/bin/env bash

set -euo pipefail
TEST_ROOT=$(cd "$(dirname "$0")" && pwd)
RUNNER="$TEST_ROOT/../../scripts/phase2_run_ab_imports.sh"

set +e
PHASE2_SELF_TEST=1 "$RUNNER"
rc=$?
set -e

if (( rc != 97 )); then
  echo "failure injection was swallowed (expected 97, got $rc)" >&2
  exit 1
fi

echo 'fail-closed harness: PASS'
