#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

WORK_ROOT="$EXPERIMENT_ROOT/.work/phase2"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase2/build"
mkdir -p "$LOG_ROOT"

"$(dirname "$0")/phase2_check_environment.sh"
"$(dirname "$0")/phase2_prepare_importers.sh"

build_one() {
  local variant=$1
  local importer="$WORK_ROOT/importer-$variant"
  local log="$LOG_ROOT/$variant.log"
  local exit_file="$LOG_ROOT/$variant.exit"
  local rc

  set +e
  OPAMROOT="$OPAM_ROOT" opam exec --switch="$ROCQ_SWITCH" -- \
    make -C "$importer" -j4 >"$log" 2>&1
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$exit_file"
  if (( rc != 0 )); then
    echo "$variant importer build failed; see $log" >&2
    return "$rc"
  fi
  shasum -a 256 "$importer/src/lean_import.cmxs" "$importer/src/Lean.vo" \
    >"$LOG_ROOT/$variant-artifacts.sha256"
}

build_one baseline
build_one candidate
