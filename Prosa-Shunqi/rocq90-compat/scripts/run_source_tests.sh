#!/usr/bin/env bash

set -u
source "$(dirname "$0")/common.sh"

mkdir -p "$EXPERIMENT_ROOT/logs/source"

compile_one() {
  local label=$1
  local relative=$2
  local log="$EXPERIMENT_ROOT/logs/source/${label}.log"
  local exit_file="$EXPERIMENT_ROOT/logs/source/${label}.exit"
  set +e
  /usr/bin/time -p env OPAMROOT="$OPAM_ROOT" \
    opam exec --switch="$ROCQ_SWITCH" -- \
    rocq c -R "$SOURCE_ROOT" prosa "$SOURCE_ROOT/$relative" \
    >"$log" 2>&1
  local rc=$?
  set -e
  printf '%s\n' "$rc" >"$exit_file"
  printf '%-18s exit=%s\n' "$label" "$rc"
  return 0
}

# Exact dependency order reported by `rocq dep -sort` for the five targets.
compile_one tactics util/tactics.v
compile_one nat_dependency util/nat.v
compile_one subadditivity_dependency util/subadditivity.v
compile_one div_mod util/div_mod.v
compile_one supremum_dependency util/supremum.v
compile_one list util/list.v
compile_one search_arg util/search_arg.v
compile_one seqset util/seqset.v

for relative in \
  util/tactics.v util/seqset.v util/search_arg.v util/list.v util/div_mod.v; do
  shasum -a 256 "$SOURCE_ROOT/$relative"
done >"$EXPERIMENT_ROOT/logs/source/target-sha256.txt"
