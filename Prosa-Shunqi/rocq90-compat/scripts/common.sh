#!/usr/bin/env bash

set -u

EXPERIMENT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OPAM_ROOT="$EXPERIMENT_ROOT/environment/opam-root"
ROCQ_SWITCH="$EXPERIMENT_ROOT/environment/rocq-9.0"
SOURCE_ROOT="$EXPERIMENT_ROOT/source"
IMPORTER_ROOT="$EXPERIMENT_ROOT/importer/rocq-lean-import"
VALIDATION_ROOT="$EXPERIMENT_ROOT/validation"

rocq_exec() {
  OPAMROOT="$OPAM_ROOT" opam exec --switch="$ROCQ_SWITCH" -- "$@"
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

run_logged() {
  local log_file=$1
  local exit_file=$2
  shift 2
  set +e
  "$@" >"$log_file" 2>&1
  local rc=$?
  set -e
  printf '%s\n' "$rc" >"$exit_file"
  return "$rc"
}
