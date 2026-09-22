#!/usr/bin/env bash

set -u
source "$(dirname "$0")/common.sh"

mkdir -p "$EXPERIMENT_ROOT/logs/importer/imports"

compile_import() {
  local module=$1
  local log="$EXPERIMENT_ROOT/logs/importer/imports/${module}.log"
  local exit_file="$EXPERIMENT_ROOT/logs/importer/imports/${module}.exit"
  set +e
  (
    cd "$VALIDATION_ROOT/imported"
    rocq_exec rocq c -Q "$IMPORTER_ROOT/src" LeanImport \
      -I "$IMPORTER_ROOT/src" \
      -Q "$VALIDATION_ROOT/imported" FoundationImported \
      "Imported${module}.v"
  ) >"$log" 2>&1
  local rc=$?
  set -e
  printf '%s\n' "$rc" >"$exit_file"
  printf '%-18s exit=%s\n' "$module" "$rc"
}

compile_import Time
compile_import Tactics
compile_import Subadditivity
compile_import SearchArg
compile_import ListSimple
compile_import ListLast
compile_import Bigcat
