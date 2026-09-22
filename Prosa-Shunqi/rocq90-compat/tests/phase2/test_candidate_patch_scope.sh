#!/usr/bin/env bash

set -euo pipefail
TEST_ROOT=$(cd "$(dirname "$0")" && pwd)
EXPERIMENT_ROOT=$(cd "$TEST_ROOT/../.." && pwd)
PATCH="$EXPERIMENT_ROOT/importer/patches/phase2-check-universes.patch"
APPLIED="$EXPERIMENT_ROOT/.work/phase2/importer-candidate/src/lean.ml"

[[ $(rg -c '^diff --git ' "$PATCH") == 1 ]]
rg -q '^diff --git a/src/lean\.ml b/src/lean\.ml$' "$PATCH"
rg -q 'check_universes = false' "$PATCH"
! rg -q 'check_guarded = false|check_positive = false' "$PATCH"

# Both normal and exceptional exits restore the complete saved flag record.
[[ $(rg -c 'Global\.set_typing_flags flags;' "$APPLIED") == 2 ]]
rg -q 'let e = Exninfo\.capture e' "$APPLIED"
rg -q 'Exninfo\.iraise e' "$APPLIED"

# Keep the existing squash boundary rather than widening the bypass.
rg -q '^      assert \($' "$APPLIED"
rg -q 'squashy\.lean_squashes' "$APPLIED"
rg -q 'mind_squashed == None' "$APPLIED"

echo 'candidate patch scope and restoration paths: PASS'
